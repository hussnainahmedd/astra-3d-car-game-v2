shader_type spatial;
render_mode cull_disabled;
varying vec3 world_pos;
void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	float ripple = sin(world_pos.x * 0.43 + world_pos.z * 0.7 + TIME * 0.75);
	ripple += sin(world_pos.z * 1.3 - TIME * 0.55) * 0.4;
	ALBEDO = mix(vec3(0.13, 0.32, 0.36), vec3(0.22, 0.43, 0.46), ripple * 0.21 + 0.45);
	ROUGHNESS = 0.34;
	METALLIC = 0.18;
}
