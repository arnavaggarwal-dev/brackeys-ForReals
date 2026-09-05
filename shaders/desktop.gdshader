shader_type canvas_item;

uniform vec4 desktop_color : source_color = vec4(0.0, 0.502, 0.502, 1.0);
uniform float dither = 0.018;

float bayer(vec2 p) {
	int x = int(mod(p.x, 4.0));
	int y = int(mod(p.y, 4.0));
	int i = y * 4 + x;
	float m[16] = float[16](
		0.0, 8.0, 2.0, 10.0,
		12.0, 4.0, 14.0, 6.0,
		3.0, 11.0, 1.0, 9.0,
		15.0, 7.0, 13.0, 5.0
	);
	return m[i] / 16.0 - 0.5;
}

void fragment() {
	vec3 col = desktop_color.rgb;
	float g = UV.y * 0.10;
	col *= 1.0 - g;
	col += bayer(FRAGCOORD.xy) * dither;
	COLOR = vec4(col, 1.0);
}
