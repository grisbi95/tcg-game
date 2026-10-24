shader_type canvas_item;
// 201.4.11 : une pièce endormie montre sa zone d'art en niveaux de gris. COLOR porte déjà la
// texture (ou le tracé) multipliée par la couleur du sommet.

const vec3 LUMA = vec3(0.299, 0.587, 0.114);

void fragment() {
	float grey = dot(COLOR.rgb, LUMA);
	COLOR = vec4(vec3(grey), COLOR.a);
}
