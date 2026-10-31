class_name WindowFrame
extends PanelContainer
## Janela com título e botão de fechar. O conteúdo é uma view independente.

signal closed


static func wrap(title: String, content: Control, window_size: Vector2, system_style: bool = false) -> WindowFrame:
	var window := WindowFrame.new()
	window.add_theme_stylebox_override(&"panel", UiKit.system_style(14) if system_style else UiKit.panel_style(14))
	window.custom_minimum_size = window_size
	var column := UiKit.vbox(10)
	window.add_child(column)
	var header := UiKit.hbox(8)
	column.add_child(header)
	var color: Color = UiKit.SYSTEM_LINE if system_style else UiKit.GOLD
	var heading := UiKit.label(title, 22, color, UiKit.title_font())
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(heading)
	header.add_child(UiKit.button("✕", func() -> void: window.closed.emit()))
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(content)
	UiKit.fit_rect(window, 0.5, 0.5, 0.5, 0.5, Rect2(-window_size.x * 0.5, -window_size.y * 0.5, window_size.x * 0.5, window_size.y * 0.5))
	return window
