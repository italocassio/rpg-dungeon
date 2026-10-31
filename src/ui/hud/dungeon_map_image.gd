class_name DungeonMapImage
extends RefCounted
## Desenha o mapa a partir do campo da masmorra: escuro no minimapa, pergaminho no mapa aberto.

const SCALE := 2


static func dark(field: DungeonField) -> ImageTexture:
	var width: int = field.columns * SCALE
	var height: int = field.rows * SCALE
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	for y in height:
		for x in width:
			var point: Vector2 = field.origin + Vector2(x, y) / float(SCALE) * DungeonField.CELL
			var distance: float = field.distance_at(point)
			if distance > 1.2:
				continue
			if distance > 0.0:
				image.set_pixel(x, y, Color(0.72, 0.8, 0.95, 0.95))
			else:
				var tone: float = 0.24 + clampf(-distance * 0.03, 0.0, 0.1)
				image.set_pixel(x, y, Color(tone * 0.9, tone, tone * 1.25, 0.86))
	return ImageTexture.create_from_image(image)


static func parchment(field: DungeonField) -> ImageTexture:
	var width: int = field.columns * SCALE
	var height: int = field.rows * SCALE
	var noise := FastNoiseLite.new()
	noise.frequency = 0.012
	noise.fractal_octaves = 5
	var fine := FastNoiseLite.new()
	fine.frequency = 0.15
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	var paper := Color("c9a874")
	var aged := Color("8a6638")
	var path := Color("e8d4a8")
	var ink := Color("4a3218")
	for y in height:
		for x in width:
			var point: Vector2 = field.origin + Vector2(x, y) / float(SCALE) * DungeonField.CELL
			var distance: float = field.distance_at(point)
			var grain: float = noise.get_noise_2d(x, y) * 0.5 + 0.5
			var edge: float = minf(minf(float(x), float(width - x)), minf(float(y), float(height - y))) / 26.0
			var color: Color = paper.lerp(aged, clampf(grain * 0.8 + (1.0 - clampf(edge, 0.0, 1.0)) * 0.55, 0.0, 1.0))
			color = color.darkened(fine.get_noise_2d(x, y) * 0.04 + 0.02)
			if distance < 0.0:
				color = color.lerp(path, 0.8)
			elif distance < 1.0:
				color = color.lerp(ink, 0.75 * (1.0 - distance))
			elif distance < 3.5:
				color = color.darkened((3.5 - distance) * 0.05)
			image.set_pixel(x, y, color)
	return ImageTexture.create_from_image(image)
