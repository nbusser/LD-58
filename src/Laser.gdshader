shader_type canvas_item;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

uniform int laser_count : hint_range(0, 8) = 2;
uniform vec2 resolution = vec2(256, 256);
uniform vec2 laser_points[24];
uniform float laser_states[12];
uniform float laser_hue : hint_range(0.0, 360.0) = 0.0;
uniform float intensity : hint_range(0.0, .3) = .2;
uniform float beam_width : hint_range(0.0, 1.0) = 0.71;
uniform float core_width : hint_range(0.0, 1.0) = 0.17;
uniform float edge_softness : hint_range(0.01, 0.5) = 0.15;
uniform float pulse_speed : hint_range(0.0, 10.0) = .85;
uniform float pulse_amplitude : hint_range(0.0, 1.0) = 0.12;
uniform float noise_scale : hint_range(0.0, 50.0) = 17.0;
uniform float noise_speed : hint_range(0.0, 10.0) = 4.67;
uniform float noise_intensity : hint_range(0.0, 1.0) = 1.0;
uniform float energy_flow_speed : hint_range(0.0, 10.0) = 8.0;
uniform float glow_radius : hint_range(0.0, 2.0) = 1.55;
uniform float distortion_amount : hint_range(0.0, 0.2) = 0.11;
uniform vec4 distortion_freqs : source_color = vec4(0.47058824, 0.14901961, 0.36078432, 0.64705884);
uniform float flicker_speed : hint_range(0.0, 20.0) = 8.0;
uniform float flicker_intensity : hint_range(0.0, 1.0) = 0.2;

float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

float noise(vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

vec3 oklch_to_rgb(vec3 oklch) {
  float L = oklch.x;
  float C = oklch.y;
  float h = oklch.z * 6.28318530718; // Convert to radians

  float a = cos(h) * C;
  float b = sin(h) * C;

  float L_ = L + 0.3963377774 * a + 0.2158037573 * b;
  float M_ = L - 0.1055613458 * a - 0.0638541728 * b;
  float S_ = L - 0.0894841775 * a - 1.291485548 * b;

  float L3 = L_ * L_ * L_;
  float M3 = M_ * M_ * M_;
  float S3 = S_ * S_ * S_;

  float r = 4.0767416621 * L3 - 3.3077115913 * M3 + 0.2309699292 * S3;
  float g = -1.2684380046 * L3 + 2.6097574011 * M3 - 0.3413193965 * S3;
  b = -0.0041960863 * L3 - 0.7034186147 * M3 + 1.707614701 * S3;

  return vec3(r, g, b);
}


vec4 get_laser_color(float along_axis, float across_axis, float state) {
    float time = TIME;
    vec4 laser_color = vec4(oklch_to_rgb(vec3(0.7, 0.25, laser_hue / 360.0)), 1.0);
	vec4 core_color = vec4(oklch_to_rgb(vec3(0.9, 0.3, laser_hue / 360.0)), 1.0);

    vec4 distortion_x = distortion_freqs * 16.0 * along_axis + vec4(time * 3.0, time * 2.0, time * 1.5, time * 1.0);
	float distortion = dot(sin(distortion_x), vec4(0.25)) * distortion_amount;
    across_axis -= distortion;

    float noise_distortion = (noise(vec2(along_axis * noise_scale, time * noise_speed)) - 0.5) * noise_intensity;
    across_axis -= noise_distortion * 0.1;

    float pulse = 1.0 + sin(time * pulse_speed) * pulse_amplitude;

    float flicker = 1.0 + sin(time * flicker_speed + random(vec2(floor(time * 10.0), 0.0)) * 6.28) * flicker_intensity;

    // State modifiers
    float state_intensity = 1.0;
    float state_width = 1.0;
    float state_core_only = 0.0;
    float state_alpha = 1.0;

    if (state < 1.0) {
        // Warning phase (0 to 1)
        float warning_t = state;

        // 0-0.3: fade in core only, very thin
        if (warning_t < 0.3) {
            float t = warning_t / 0.3;
            state_intensity = t;
            state_width = .65;
            state_core_only = .9;
            state_alpha = t * .7;
        }
        // 0.3-0.6: fade out
        else if (warning_t < 0.6) {
            float t = (warning_t - 0.3) / 0.3;
            state_intensity = (1.0 - t);
            state_width = .65;
            state_core_only = 0.9;
            state_alpha = (1.0 - t) * .7;
        }
        // 0.6-0.8: bright flash
        else if (warning_t < 0.8) {
            float t = (warning_t - 0.6) / 0.2;
            state_intensity = mix(0.0, 2.0, t);
            state_width = mix(0.1, 1.5, t);
            state_core_only = 1.0 - t;
            state_alpha = t;
        }
        // 0.8-1.0: settle to normal
        else {
            float t = (warning_t - 0.8) / 0.2;
            state_intensity = mix(2.0, 1.0, t);
            state_width = mix(1.5, 1.0, t);
            state_core_only = 0.0;
            state_alpha = 1.0;
        }
    }
    else if (state > 1.0) {
        // Dying phase (1 to 2)
        float dying_t = state - 1.0;
        state_intensity = 1.0 - dying_t;
        state_alpha = 1.0 - dying_t;
    }

    float beam_edge = beam_width * pulse * 0.5 * state_width;
    float beam_mask = 1.0 - smoothstep(beam_edge - edge_softness, beam_edge, across_axis);

    float core_edge = core_width * pulse * 0.5 * max(state_width, 0.2);
    float core_mask = 1.0 - smoothstep(0.0, core_edge, across_axis);

    float energy_flow = noise(vec2(along_axis * 5.0 - time * energy_flow_speed, 0.0));
    energy_flow = pow(energy_flow, 2.0) * .5 + .7;

    float glow_edge = (beam_width + glow_radius) * pulse * 0.5 * state_width;
    float glow_mask = 1.0 - smoothstep(beam_edge, glow_edge, across_axis);
    glow_mask *= (1.0 - state_core_only);

    float alpha = max(max(glow_mask, core_mask), beam_mask) * state_alpha;
    float final_lightness = mix(0.65, 1.8, max(beam_mask, core_mask) * flicker) * state_intensity;

    float edge_highlight = pow(1.0 - beam_mask, 3.0) * beam_mask;

    float final_intensity = (intensity * flicker * energy_flow + edge_highlight) * state_intensity;
    return vec4(final_lightness, final_intensity, laser_hue / 360.0, alpha);
}

float dist_to_line(vec2 p, vec2 a, vec2 b) {
	vec2 pa = p - a;
	vec2 ba = b - a;
	float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
	return length(pa - ba * h) * min(resolution.x, resolution.y) * .02;
}

vec2 where_am_i_on_laser(vec2 uv, vec2 a, vec2 b) {
	vec2 p = uv;
	float min_dist = dist_to_line(p, a, b);
	vec2 ab = b - a;
	float ab_len = length(ab);
	// float t = dot(p - a, ab) / (ab_len * ab_len);
	// not squared so it scales with the real size and not normalized
	float t = dot(p - a, ab) / ab_len;
	if (a == b) t = 0.0;
	return vec2(min_dist, t);
}

// result is a if t=0 and b if t=1, and interpolated in between, taking into account angle wrapping
float mixAngle(float a, float b, float t) {
    float delta = mod(b - a + .5, 1) - .5;
    return a + delta * t;
}

void fragment() {
    vec2 uv = UV;
    uv = floor(uv * resolution) / resolution;
    vec2 ratio = resolution / min(resolution.x, resolution.y);

    vec2 global_coords = uv * ratio;

    vec4 final_color = vec4(0.0, 0.0, laser_hue / 360.0, 0.0);
    for (int i = 0; i < laser_count; i++) {
		vec2 a = laser_points[i * 2] * ratio;
		vec2 b = laser_points[i * 2 + 1] * ratio;
		float state = laser_states[i];
		vec2 coords_in_laser = where_am_i_on_laser(global_coords, a, b);
		vec4 local_color = get_laser_color(coords_in_laser.y, coords_in_laser.x, state);

		final_color.xy = max(final_color.xy, local_color.xy);
		// uncomment if we want multiple laser colors at once
		// final_color.z = mixAngle(final_color.z, local_color.z, local_color.a / float(laser_count));
		final_color.w = max(final_color.w, local_color.w);
	}

    // float scanline = sin(uv.y * 200.0) * 0.05 + 1.0;
    // final_color.y *= scanline;

	final_color.rgb = oklch_to_rgb(final_color.xyz);

    // COLOR = final_color;
    // COLOR.a = clamp(COLOR.a, 0.0, 1.0);

    vec4 screen_color = texture(screen_texture, UV);
    // COLOR = mix(screen_color, final_color, final_color.a);
    COLOR = screen_color + (final_color * final_color.a);
}
