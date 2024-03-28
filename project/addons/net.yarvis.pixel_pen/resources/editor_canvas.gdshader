shader_type canvas_item;

uniform vec2 origin;
uniform float tile_size = 16;
uniform float lock_to_global = 1.0;

varying vec2 world_vertex;

void vertex() {
	world_vertex = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy - origin;
	world_vertex = mix(VERTEX, world_vertex, lock_to_global);
}

void fragment() {
	vec2 coor = mod(world_vertex, tile_size * 2.0);
	vec2 checker = step(coor, vec2(tile_size));
	COLOR.rgb = vec3(mix(1.0 - checker.x, checker.x, checker.y)) * 0.2 + 0.5;
}
