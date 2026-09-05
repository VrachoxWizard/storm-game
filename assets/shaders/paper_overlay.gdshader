shader_type canvas_item;

// Paper grain + sepia vignette — samples the screen so UI/game remain visible.

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float grain_strength : hint_range(0.0, 0.3) = 0.06;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.35;
uniform float sepia_amount : hint_range(0.0, 1.0) = 0.25;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec4 col = textureLod(screen_texture, SCREEN_UV, 0.0);
	float n = hash(SCREEN_UV * 800.0 + TIME);
	col.rgb += (n - 0.5) * grain_strength;

	float dist = distance(SCREEN_UV, vec2(0.5));
	float vig = smoothstep(0.4, 1.0, dist);
	col.rgb *= 1.0 - vig * vignette_strength;

	vec3 sepia = vec3(
		dot(col.rgb, vec3(0.393, 0.769, 0.189)),
		dot(col.rgb, vec3(0.349, 0.686, 0.168)),
		dot(col.rgb, vec3(0.272, 0.534, 0.131))
	);
	col.rgb = mix(col.rgb, sepia, sepia_amount);
	COLOR = vec4(col.rgb, 1.0);
}
