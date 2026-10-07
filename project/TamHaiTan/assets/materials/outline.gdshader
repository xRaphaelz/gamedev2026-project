shader_type spatial;
// เส้นขอบตัวละครแบบ inverted hull: ขยายผิวออกตาม normal แล้ววาดเฉพาะด้านหลังเป็นสีเข้ม
render_mode unshaded, cull_front, depth_draw_opaque;

uniform vec4 outline_color : source_color = vec4(0.16, 0.08, 0.05, 1.0);
uniform float thickness = 0.012;

void vertex() {
	VERTEX += normalize(NORMAL) * thickness;
}

void fragment() {
	ALBEDO = outline_color.rgb;
}
