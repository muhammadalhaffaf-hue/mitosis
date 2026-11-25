shader_type canvas_item;
// Mengubah gambar jadi abu-abu lembut supaya cocok dengan gaya hitam-putih game.
uniform float gelap = 0.34;
uniform float terang = 0.62;

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float l = pow(dot(c.rgb, vec3(0.299, 0.587, 0.114)), 0.7);
	COLOR = vec4(vec3(mix(gelap, terang, l)), c.a);
}
