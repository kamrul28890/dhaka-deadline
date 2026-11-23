shader_type spatial;

varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = world_position.xz / vec2(0.42, 0.72);
	p.x += mod(floor(p.y), 2.0) * 0.5;
	vec2 edge = min(fract(p), 1.0 - fract(p));
	float grout = smoothstep(0.015, 0.04, min(edge.x, edge.y));
	float variation = fract(sin(dot(floor(p), vec2(127.1, 311.7))) * 43758.5453);
	vec3 tile = mix(vec3(0.31, 0.30, 0.27), vec3(0.43, 0.41, 0.36), variation);
	ALBEDO = mix(vec3(0.16, 0.16, 0.145), tile, grout);
	ROUGHNESS = 0.94;
}
