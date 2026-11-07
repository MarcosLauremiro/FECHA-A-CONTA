shader_type canvas_item;

// Tela de caixa eletrônico: linhas de varredura, escurecimento nas bordas e um leve tremor de brilho.
// Desenhado por cima da janela da tela; não bloqueia cliques.

uniform float scanline_alpha : hint_range(0.0, 1.0) = 0.12;
uniform float vignette_alpha : hint_range(0.0, 1.0) = 0.42;
uniform float flicker_alpha : hint_range(0.0, 0.2) = 0.025;
uniform float window_height = 551.0;

void fragment() {
	// uma linha escura a cada 3 pixels da janela
	float scan = step(0.5, fract(UV.y * window_height / 3.0));
	vec2 d = UV - vec2(0.5);
	float vig = smoothstep(0.30, 0.78, length(d * vec2(1.2, 1.0)));
	float flick = (sin(TIME * 47.0) * 0.5 + 0.5) * flicker_alpha;
	float a = scan * scanline_alpha + vig * vignette_alpha + flick;
	COLOR = vec4(0.0, 0.03, 0.02, clamp(a, 0.0, 0.9));
}
