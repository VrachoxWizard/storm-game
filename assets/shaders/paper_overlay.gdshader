shader_type canvas_item;

// War-Journal Post-Process: parchment fiber texture sampling, ink bleed feathering,
// aged moisture edge vignette, sepia tone, and combat chromatic shock aberration.

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D paper_texture : filter_linear_mipmap, repeat_enable;
uniform float grain_strength : hint_range(0.0, 0.3) = 0.05;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.35;
uniform float sepia_amount : hint_range(0.0, 1.0) = 0.22;
uniform float ink_bleed : hint_range(0.0, 5.0) = 0.8;
uniform float shock_aberration : hint_range(0.0, 0.1) = 0.0;
uniform float paper_blend : hint_range(0.0, 1.0) = 0.22;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 screen_uv = SCREEN_UV;
	vec3 col;

	// 1. Combat Chromatic Shock Aberration (R/B channel offset along radial shockwave)
	if (shock_aberration > 0.0001) {
		vec2 dir = screen_uv - vec2(0.5);
		float dist_center = length(dir);
		vec2 shock_dir = dist_center > 0.001 ? normalize(dir) : vec2(1.0, 0.0);
		vec2 offset = shock_dir * shock_aberration;
		float r = textureLod(screen_texture, screen_uv + offset, 0.0).r;
		float g = textureLod(screen_texture, screen_uv, 0.0).g;
		float b = textureLod(screen_texture, screen_uv - offset, 0.0).b;
		col = vec3(r, g, b);
	} else {
		col = textureLod(screen_texture, screen_uv, 0.0).rgb;
	}

	// 2. Soft Ink-Bleed Edge Feathering
	if (ink_bleed > 0.001) {
		ivec2 tex_sz = textureSize(screen_texture, 0);
		vec2 step_uv = (vec2(1.0) / max(vec2(tex_sz), vec2(1.0, 1.0))) * ink_bleed;
		vec3 bleed_sample = (
			textureLod(screen_texture, screen_uv + vec2(step_uv.x, 0.0), 0.0).rgb +
			textureLod(screen_texture, screen_uv - vec2(step_uv.x, 0.0), 0.0).rgb +
			textureLod(screen_texture, screen_uv + vec2(0.0, step_uv.y), 0.0).rgb +
			textureLod(screen_texture, screen_uv - vec2(0.0, step_uv.y), 0.0).rgb
		) * 0.25;
		col = mix(col, min(col, bleed_sample), 0.12);
	}

	// 3. Parchment Fiber Texture Sampling & Blending
	vec3 paper = texture(paper_texture, screen_uv * 2.0).rgb;
	col = mix(col, col * (paper * 1.15), paper_blend);

	// 4. Edge Moisture Vignette & Corner Darkening
	float dist = distance(screen_uv, vec2(0.5));
	float vig = smoothstep(0.35, 0.95, dist);
	col *= 1.0 - vig * vignette_strength;

	// 5. Sepia Tone & Moisture Discoloration
	vec3 sepia = vec3(
		dot(col, vec3(0.393, 0.769, 0.189)),
		dot(col, vec3(0.349, 0.686, 0.168)),
		dot(col, vec3(0.272, 0.534, 0.131))
	);
	col = mix(col, sepia, sepia_amount + vig * 0.12);

	// 6. Paper Fiber Grain Noise
	float n = hash(screen_uv * 800.0 + TIME);
	col += (n - 0.5) * grain_strength;

	COLOR = vec4(clamp(col, 0.0, 1.0), 1.0);
}
