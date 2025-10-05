shader_type canvas_item;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

uniform float desaturate_amount = 1.0;
uniform vec3 overlay_color = vec3(0.95, 0.95, 1.0);
uniform float overlay_amount = 0.0;
uniform float bloom_intensity = 1.0; // How strong the bloom is

const int k = 3;
const float resolution = 512.0;
vec3 get_bloom(vec2 uv) {
	float offset = 1.0 / resolution;
	vec3 bloom = vec3(0.0);
	for (int x = -k; x <= k; x++) {
		for (int y = -k; y <= k; y++) {
			vec2 sample_uv = uv + vec2(float(x), float(y)) * offset;
			vec3 sample = texture(screen_texture, sample_uv).rgb;
			float luminance = dot(sample, vec3(0.299, 0.587, 0.114));
			bloom += sample * step(0.7, luminance); // Only add bright pixels
		}
	}
	return bloom / 9.0;
}

vec3 get_horizontal_blur(vec2 uv) {
	float offset = 1.0 / resolution;
	vec3 blur = vec3(0.0);
	for (int x = -3; x <= 3; x++) {
		vec2 sample_uv = uv + vec2(float(x), 0.0) * offset;
		blur += texture(screen_texture, sample_uv).rgb;
	}
	return blur / 3.0;
}

void fragment() {
	vec4 src = texture(screen_texture, SCREEN_UV);
	float gray = dot(src.rgb, vec3(0.299, 0.587, 0.114));
	vec3 desat = mix(src.rgb, vec3(gray), clamp(desaturate_amount, 0.0, 1.0));
	vec3 tinted = mix(desat, overlay_color, clamp(overlay_amount, 0.0, 1.0));

	// Apply bloom and brightness if desaturated
	if (desaturate_amount > 0.0) {
		vec3 bloom = get_bloom(SCREEN_UV) * bloom_intensity * desaturate_amount;
		tinted += bloom;
		// Apply slight horizontal blur
		tinted = mix(tinted, get_horizontal_blur(SCREEN_UV), desaturate_amount * 0.5);
	}

	COLOR = vec4(tinted, src.a);
}
