shader_type canvas_item;

uniform bool apply = true;
uniform bool applyColor1 = false; // red
uniform bool applyColor2 = false; // cyan
uniform float amount = 1.0;
uniform sampler2D offsetTexture : hint_default_white;

void fragment() {
	// Called for every pixel the material is visible on.
	vec4 textureColor = texture(TEXTURE, UV);
	vec4 color = textureColor;
	
	if (apply) {
		float adjustedAmount = amount / 100.0;
		if (applyColor1)
			color.r = texture(TEXTURE, vec2(UV.x + adjustedAmount, UV.y)).r;
			
		color.g = texture(TEXTURE, UV).g;
		
		if (applyColor2)
			color.b = texture(TEXTURE, vec2(UV.x - adjustedAmount, UV.y)).b;
	}
	
	COLOR = color;
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
