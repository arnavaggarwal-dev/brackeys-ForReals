shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, repeat_disable, filter_nearest;
uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform float tear : hint_range(0.0, 1.0) = 0.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(41.31, 289.7))) * 43758.5453);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	float t = TIME;

	float band = floor(uv.y * 60.0);
	float stuck = step(0.90 - tear * 0.6, hash(vec2(band, floor(t * 4.0))));
	uv.x -= stuck * (0.012 * intensity + 0.06 * tear) * hash(vec2(band, 3.0));

	float tear_line = hash(vec2(floor(t * 6.0), 11.0));
	if (tear > 0.01 && uv.y > tear_line) {
		uv.x += (hash(vec2(floor(t * 6.0), 5.0)) - 0.5) * 0.05 * tear;
	}

	vec3 col = texture(screen_tex, uv).rgb;

	float steps = mix(255.0, 6.0, clamp(intensity * 0.85 + tear, 0.0, 1.0));
	col = floor(col * steps + 0.5) / steps;

	col = mix(col, vec3(dot(col, vec3(0.299, 0.587, 0.114))), stuck * intensity * 0.7);

	float scan = 1.0 - step(0.5, fract(FRAGCOORD.y * 0.5)) * (0.05 * intensity + 0.16 * tear);
	col *= scan;

	COLOR = vec4(col, 1.0);
}
