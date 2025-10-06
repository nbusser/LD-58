shader_type canvas_item;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

uniform float desaturate_amount = 1.0;
uniform vec3 overlay_color = vec3(0.95, 0.95, 1.0);
uniform float overlay_amount = 0.0;
uniform float bloom_intensity = 1.0; // How strong the bloom is

const int k = 3;
const float bloom_resolution = 512.0;

void compute_bloom_and_blur(vec2 uv, out vec3 bloom, out vec3 horizontal_blur) {
	float offset = 1.0 / bloom_resolution;
	bloom = vec3(0.0);
	horizontal_blur = vec3(0.0);
	for (int x = -k; x <= k; x++) {
		for (int y = -k; y <= k; y++) {
			vec2 sample_uv = uv + vec2(float(x), float(y)) * offset;
			vec3 sample = texture(screen_texture, sample_uv).rgb;
			float luminance = dot(sample, vec3(0.299, 0.587, 0.114));
			bloom += sample * step(0.7, luminance); // Only add bright pixels
			if (y == 0) {
				horizontal_blur += sample;
			}
		}
	}
	bloom /= 9.0;
	horizontal_blur /= 3.0;
}
const vec2 resolution = vec2(800.0, 450.0);
void fragment() {
	vec2 uv = SCREEN_UV;

	// Pixelate
	uv = floor(uv * resolution) / resolution;

	vec4 src = texture(screen_texture, uv);
	float gray = dot(src.rgb, vec3(0.299, 0.587, 0.114));
	vec3 desat = mix(src.rgb, vec3(gray), clamp(desaturate_amount, 0.0, 1.0));
	vec3 tinted = mix(desat, overlay_color, clamp(overlay_amount, 0.0, 1.0));

	// Apply bloom and brightness if desaturated
	if (desaturate_amount > 0.0) {
		vec3 bloom;
		vec3 horizontal_blur;
		compute_bloom_and_blur(uv, bloom, horizontal_blur);
		bloom *= bloom_intensity * desaturate_amount;
		tinted += bloom;
		// Apply slight horizontal blur from the combined pass
		tinted = mix(tinted, horizontal_blur, desaturate_amount * 0.5);
	}

	COLOR = vec4(tinted, src.a);
}
