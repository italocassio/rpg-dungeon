shader_type spatial;
render_mode unshaded, cull_disabled, blend_premul_alpha, depth_draw_never, depth_test_disabled;

// Área de perigo no chão. Enche conforme o golpe se aproxima.
// Com blend_premul_alpha, ALPHA 0 soma e ALPHA maior que 0 mistura; ALBEDO sai já multiplicado pelo alfa.
//
// hostile = false: a marca de aliado (m_meteor, p_judgement), exatamente como antes da OS-022:
//   só aditiva, na cor da habilidade, sem faixa escura, sem serrilha, no tamanho lógico.
// hostile = true: zona de perigo de inimigo, em duas camadas: preenchimento por mistura e borda por soma.

uniform vec3 tint : source_color = vec3(1.0, 0.25, 0.2);
uniform int shape = 0; // 0 círculo, 1 cone, 2 retângulo
uniform float half_angle = 0.8;
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform bool hostile = false;

// Zona hostil. Medidas em metros do mundo.
uniform vec3 fill_color : source_color = vec3(0.627, 0.063, 0.188);
uniform vec3 band_color : source_color = vec3(0.133, 0.016, 0.063);
uniform vec3 edge_color : source_color = vec3(1.0, 0.416, 0.302);
uniform vec3 warn_color : source_color = vec3(1.0, 0.604, 0.478);
uniform vec3 crack_color : source_color = vec3(0.133, 0.016, 0.063);
uniform vec2 quad_size = vec2(2.0, 2.0);
uniform float draw_radius = 1.0;
uniform float tooth_length = 0.0;
uniform float tooth_count = 0.0;
uniform float logic_length = 0.0;
uniform float draw_half_width = 0.0;
uniform float back_margin = 0.4;
uniform int cracks = 0;
uniform float crack_phase = 0.0;
uniform bool rings = false;
uniform bool chevrons = false;

const float BAND_WIDTH = 0.35;
const float EDGE_WIDTH = 0.14;
const float CRACK_HALF = 0.09;
const float CRACK_THREAD = 0.025;
const float LATERAL_MARGIN = 0.4;

float triangle_wave(float x) {
	return abs(fract(x) * 2.0 - 1.0);
}

void hostile_mark(vec2 uv, out vec3 color, out float alpha, out vec3 added) {
	vec2 p = uv * 2.0 - 1.0;
	float depth_in = 0.0;  // distância para dentro da borda, em metros
	float reach = 0.0;     // 0 no centro (ou no começo da linha), 1 na borda
	bool tooth = false;
	vec2 metric = vec2(0.0);
	float radius = 0.0;
	float theta = 0.0;
	float along = 0.0;

	if (shape == 2) {
		float lateral = p.x * quad_size.x * 0.5;
		along = (1.0 - uv.y) * quad_size.y - back_margin;
		float limit = logic_length + LATERAL_MARGIN;
		depth_in = min(draw_half_width - abs(lateral), min(limit - along, along + back_margin));
		reach = clamp(along / max(logic_length, 0.001), 0.0, 1.0);
		if (tooth_count > 0.0 && along > limit && along - limit <= tooth_length * (1.0 - abs(2.0 * fract((lateral + draw_half_width) / (2.0 * draw_half_width) * tooth_count) - 1.0)) && abs(lateral) < draw_half_width) {
			tooth = true;
		}
		metric = vec2(lateral, along);
	} else {
		float half_size = quad_size.x * 0.5;
		metric = vec2(p.x, -p.y) * half_size;
		radius = length(metric);
		theta = atan(metric.x, metric.y);
		reach = clamp(radius / draw_radius, 0.0, 1.0);
		depth_in = draw_radius - radius;
		float span = PI;
		float center_angle = 0.0;
		if (shape == 1) {
			float a = abs(theta);
			float lateral_depth;
			if (a > half_angle) {
				float over = a - half_angle;
				float distance_out = over < PI * 0.5 ? radius * sin(over) : radius;
				lateral_depth = LATERAL_MARGIN - distance_out;
			} else {
				lateral_depth = LATERAL_MARGIN + radius * sin(min(half_angle - a, PI * 0.5));
			}
			depth_in = min(depth_in, lateral_depth);
			span = half_angle + LATERAL_MARGIN / draw_radius;
		}
		if (tooth_count > 0.0 && radius > draw_radius && abs(theta) <= span) {
			float u = fract((theta + span) / (2.0 * span) * tooth_count);
			if (radius - draw_radius <= tooth_length * (1.0 - abs(2.0 * u - 1.0))) {
				tooth = true;
			}
		}
	}

	bool inside = depth_in >= 0.0;
	if (!inside && !tooth) {
		color = vec3(0.0);
		alpha = 0.0;
		added = vec3(0.0);
		return;
	}

	bool filled = reach <= progress;
	alpha = (filled ? 0.55 : 0.22) + 0.08 * reach;
	color = fill_color;
	if (inside && depth_in < BAND_WIDTH) {
		color = band_color;
		alpha = 0.65;
	}

	added = vec3(0.0);
	float pulse = 0.75 + 0.25 * sin(TIME * mix(6.0, 20.0, progress));
	if ((inside && depth_in < EDGE_WIDTH) || tooth) {
		added += edge_color * 1.3 * pulse;
	}

	if (cracks > 0 && shape != 2 && radius <= progress * draw_radius && radius > 0.2) {
		float sector = TAU / float(cracks);
		float angle = theta - crack_phase;
		float index = round(angle / sector);
		float offset_angle = angle - index * sector;
		float wobble = (triangle_wave(radius * 0.55 + index * 0.37) - 0.5) * 0.7 * min(radius * 0.5, 1.0);
		float line = abs(radius * sin(offset_angle) - wobble);
		if (line < CRACK_HALF) {
			color = crack_color;
			alpha = 0.8;
			if (line < CRACK_THREAD) {
				added += edge_color;
			}
		}
	}

	if (rings && shape != 2) {
		for (int k = 0; k < 3; k++) {
			float t = fract((TIME - float(k) * 0.8) / 2.4);
			float ring_radius = draw_radius * (1.0 - t);
			if (abs(radius - ring_radius) < 0.12 && depth_in > BAND_WIDTH) {
				added += edge_color * 0.9 * (1.0 - t);
			}
		}
	}

	if (chevrons && shape == 2 && along > 0.0 && depth_in > BAND_WIDTH) {
		float k = fract((along + abs(metric.x) * 0.9 - TIME * 4.0) / 2.0);
		float band = smoothstep(0.0, 0.04, k) * (1.0 - smoothstep(0.08, 0.12, k));
		added += edge_color * 0.8 * band;
	}

	added += warn_color * 0.25 * (0.5 + 0.5 * sin(TIME * 24.0)) * smoothstep(0.85, 0.87, progress);
}

void fragment() {
	if (hostile) {
		vec3 color;
		float alpha;
		vec3 added;
		hostile_mark(UV, color, alpha, added);
		ALBEDO = color * alpha + added * step(0.001, alpha);
		ALPHA = alpha;
	} else {
		vec2 p = UV * 2.0 - 1.0;
		float mask = 0.0;
		float fill = 0.0;
		float edge = 0.0;
		if (shape == 2) {
			float x = abs(p.x);
			float y = UV.y;
			mask = step(x, 1.0);
			edge = smoothstep(0.9, 1.0, x) + smoothstep(0.03, 0.0, y) + smoothstep(0.97, 1.0, y);
			fill = step(1.0 - y, progress);
		} else {
			float r = length(p);
			mask = step(r, 1.0);
			edge = smoothstep(0.93, 0.985, r);
			fill = step(r, progress);
			if (shape == 1) {
				float a = abs(atan(p.x, -p.y));
				float inside = step(a, half_angle);
				mask *= inside;
				edge = max(edge, smoothstep(half_angle - 0.05, half_angle, a));
			}
		}
		float wave = 0.5 + 0.5 * sin(TIME * 12.0);
		float strength = mask * (0.07 + fill * 0.16 + edge * (0.5 + wave * 0.3));
		ALBEDO = tint * 1.1 * clamp(strength, 0.0, 1.0);
		ALPHA = 0.0;
	}
}
