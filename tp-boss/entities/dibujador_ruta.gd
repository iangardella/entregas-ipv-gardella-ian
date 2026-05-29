class_name DibujadorRuta

const DISTANCIA_NARANJA = CalculadorRuta.DISTANCIA_NARANJA
const DISTANCIA_CELESTE = CalculadorRuta.DISTANCIA_CELESTE

const COLOR_NARANJA_LINEA = Color(0.9, 0.45, 0.15, 0.9)
const COLOR_CELESTE_LINEA = Color(0.15, 0.85, 0.9, 0.9)
const COLOR_ROJO_LINEA = Color(0.85, 0.2, 0.2, 0.5)

const COLOR_DEST_NARANJA = Color(0.9, 0.45, 0.15, 0.85)
const COLOR_DEST_CELESTE = Color(0.15, 0.85, 0.9, 0.85)
const COLOR_DEST_ROJO = Color(0.85, 0.2, 0.2, 0.85)

static func dibujar_zonas(canvas: CanvasItem, puntos: Array[Dictionary]) -> void:
	for pt in puntos:
		var local_pos = pt.pos_local
		var color_pt = pt.color
		var color_glow = Color(color_pt.r, color_pt.g, color_pt.b, 0.12)
		canvas.draw_line(local_pos + Vector2(-12, 0), local_pos + Vector2(12, 0), color_glow, 10.0)
		canvas.draw_line(local_pos + Vector2(-10, 0), local_pos + Vector2(10, 0), color_pt, 4.0)

static func dibujar_ruta(canvas: CanvasItem, path: PackedVector2Array, distancia_total: float) -> void:
	if path.size() < 2:
		return
	var d_acum = 0.0
	for i in range(path.size() - 1):
		var A = path[i]
		var B = path[i + 1]
		_dibujar_segmento(canvas, A, B, d_acum)
		d_acum += A.distance_to(B)

static func dibujar_destino(canvas: CanvasItem, destino: Vector2, distancia: float) -> void:
	var color_dest = COLOR_DEST_NARANJA
	if distancia > DISTANCIA_CELESTE:
		color_dest = COLOR_DEST_ROJO
	elif distancia > DISTANCIA_NARANJA:
		color_dest = COLOR_DEST_CELESTE

	var local_dest = canvas.to_local(destino)
	if distancia <= DISTANCIA_CELESTE:
		canvas.draw_circle(local_dest, 6.0, color_dest)
		canvas.draw_arc(local_dest, 10.0, 0, TAU, 32, color_dest, 1.5)
	else:
		canvas.draw_circle(local_dest, 5.0, color_dest)

static func _dibujar_segmento(canvas: CanvasItem, A: Vector2, B: Vector2, d_start: float) -> void:
	var L = A.distance_to(B)
	if L <= 0.001:
		return

	var t_naranja = (DISTANCIA_NARANJA - d_start) / L
	var t_celeste = (DISTANCIA_CELESTE - d_start) / L

	var cortes = [0.0, 1.0]
	if t_naranja > 0.0 and t_naranja < 1.0:
		cortes.append(t_naranja)
	if t_celeste > 0.0 and t_celeste < 1.0:
		cortes.append(t_celeste)
	cortes.sort()

	for i in range(cortes.size() - 1):
		var t1 = cortes[i]
		var t2 = cortes[i + 1]
		var t_mid = (t1 + t2) / 2.0
		var d_mid = d_start + t_mid * L

		var color_actual = COLOR_NARANJA_LINEA
		var grosor = 3.0
		if d_mid > DISTANCIA_CELESTE:
			color_actual = COLOR_ROJO_LINEA
			grosor = 2.0
		elif d_mid > DISTANCIA_NARANJA:
			color_actual = COLOR_CELESTE_LINEA
			grosor = 3.0

		var p1 = canvas.to_local(A.lerp(B, t1)) + Vector2(0, -6)
		var p2 = canvas.to_local(A.lerp(B, t2)) + Vector2(0, -6)
		canvas.draw_line(p1, p2, color_actual, grosor)
