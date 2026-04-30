shader_type canvas_item;

uniform bool active = false;
uniform vec3 flash_color : source_color = vec3(1.0, 1.0, 1.0);

void fragment() {
	vec4 t = texture(TEXTURE, UV);
	if (active) {
		COLOR = vec4(flash_color, t.a);
	} else {
		COLOR = t;
	}
}
