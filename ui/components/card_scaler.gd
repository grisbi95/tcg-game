class_name CardScaler
extends RefCounted
## Échelle d'une `CardView` (décision 0028) : les tailles du thème valent pour l'échelle 1, la carte
## agrandie les multiplie. Ajuste aussi la taille de police du texte pour qu'il tienne dans la place
## restante, jusqu'à un minimum, puis le coupe. Aucune règle ici.

const COST_BADGE_SIZE: float = 32.0
const STAT_BADGE_SIZE: float = 34.0
## Marge des pastilles contre le coin de l'illustration.
const BADGE_INSET: float = 4.0
const ART_ICON_SIZE: float = 50.0
## Côté de la zone d'illustration carrée : la largeur intérieure de la carte, à l'échelle 1.
const ART_SIDE: float = 142.0
const TEXT_HEIGHT: float = 40.0
const TEXT_MARGIN: float = 1.0
## Taille de police la plus petite du texte, à l'échelle 1.
const TEXT_MIN_FONT_SIZE: int = 9
const HIGHLIGHT_PADDING_NAMES: Array[StringName] = [
	&"text_highlight_h_padding", &"text_highlight_v_padding"
]
## Le Layout compte deux rangées : l'illustration et le texte.
const LAYOUT_GAP_COUNT: int = 1

var _card: PanelContainer
var _parts: Parts
var _card_size: Vector2
var _scale: float = 1.0
var _fitted_text_width: float = -1.0
var _is_text_fit_pending: bool = false


## Les nœuds de la carte que l'échelle touche ; la carte les donne une fois à `setup`.
class Parts:
	extends RefCounted
	var layout: VBoxContainer
	var art_frame: Control
	var art_icon: Control
	var art: PanelContainer
	var cost_badge: Control
	var stat_badge: Control
	var name_banner: PanelContainer
	var text_panel: PanelContainer
	var text_label: RichTextLabel
	var cost_label: Label
	var stat_label: Label
	var name_label: Label


## `card` est la carte mise à l'échelle, de taille `card_size` à l'échelle 1.
func setup(card: PanelContainer, parts: Parts, card_size: Vector2) -> void:
	_card = card
	_parts = parts
	_card_size = card_size
	_parts.text_label.resized.connect(_on_text_label_resized)


## Applique l'échelle `card_scale` aux textes, formes et marges, puis redemande l'ajustement du
## texte. Le cadre de la carte, de son bandeau de nom, de son illustration et de son texte suit
## l'échelle dans `CardView`, qui connaît la teinte.
func apply_scale(card_scale: float) -> void:
	_scale = card_scale
	_card.custom_minimum_size = _card_size * _scale
	_scale_constant(_parts.layout, &"CardTightColumn", &"separation")
	for label: Label in [_parts.cost_label, _parts.stat_label]:
		_scale_font(label, &"CardPillLabel", &"font_size")
	_scale_font(_parts.name_label, &"CardNameLabel", &"font_size")
	_parts.text_label.theme_type_variation = &"CardBodyText"
	_parts.art_frame.custom_minimum_size = Vector2.ONE * ART_SIDE * _scale
	_parts.art_icon.custom_minimum_size = Vector2.ONE * ART_ICON_SIZE * _scale
	_place_badge(_parts.cost_badge, COST_BADGE_SIZE, false)
	_place_badge(_parts.stat_badge, STAT_BADGE_SIZE, true)
	_parts.text_panel.custom_minimum_size.y = TEXT_HEIGHT * _scale
	_request_text_fit()


# Contournement : la largeur du texte n'est connue qu'après la mise en page des conteneurs, d'où
# l'appel différé, repris par `resized` tant que la largeur n'a pas été donnée.
func _request_text_fit() -> void:
	if _is_text_fit_pending:
		return
	_is_text_fit_pending = true
	_fit_text.call_deferred()


# Pastille dans un coin haut de l'illustration : à gauche, ou à droite si `is_right`.
func _place_badge(badge: Control, badge_size: float, is_right: bool) -> void:
	var side := badge_size * _scale
	var inset := BADGE_INSET * _scale
	badge.custom_minimum_size = Vector2.ONE * side
	badge.offset_top = inset
	badge.offset_bottom = inset + side
	badge.offset_left = -inset - side if is_right else inset
	badge.offset_right = -inset if is_right else inset + side


func _scale_font(control: Control, variation: StringName, font_size_name: StringName) -> void:
	control.theme_type_variation = variation
	control.remove_theme_font_size_override(font_size_name)
	var base_size := control.get_theme_font_size(font_size_name)
	control.add_theme_font_size_override(font_size_name, roundi(base_size * _scale))


func _scale_constant(
	container: Container, variation: StringName, constant_name: StringName
) -> void:
	container.theme_type_variation = variation
	container.remove_theme_constant_override(constant_name)
	var base_value := container.get_theme_constant(constant_name)
	container.add_theme_constant_override(constant_name, roundi(base_value * _scale))


# Le surlignage d'une étiquette déborde de sa ligne de la marge `text_highlight_*_padding`, valable
# pour la taille de police du thème : elle suit la taille effective du texte.
func _follow_highlight_padding(font_size: int, theme_font_size: int) -> void:
	var text_label := _parts.text_label
	for padding_name: StringName in HIGHLIGHT_PADDING_NAMES:
		text_label.remove_theme_constant_override(padding_name)
		var base_padding := text_label.get_theme_constant(padding_name)
		var padding := roundi(base_padding * float(font_size) / theme_font_size)
		text_label.add_theme_constant_override(padding_name, padding)


func _on_text_label_resized() -> void:
	if not is_equal_approx(_parts.text_label.size.x, _fitted_text_width):
		_request_text_fit()


# Seuls le texte, la largeur et l'échelle décident de la taille : la mesure est déterministe.
func _fit_text() -> void:
	_is_text_fit_pending = false
	var text_label := _parts.text_label
	if text_label.size.x <= 0.0:
		return
	_fitted_text_width = text_label.size.x
	var panel_margin := _parts.text_panel.get_theme_stylebox(&"panel").get_minimum_size().y
	var max_text_height := _max_text_panel_height() - panel_margin
	text_label.remove_theme_font_size_override(&"normal_font_size")
	var theme_font_size := text_label.get_theme_font_size(&"normal_font_size")
	var font_size := roundi(theme_font_size * _scale)
	var min_font_size := roundi(TEXT_MIN_FONT_SIZE * _scale)
	text_label.add_theme_font_size_override(&"normal_font_size", font_size)
	while font_size > min_font_size and text_label.get_content_height() > max_text_height:
		font_size -= 1
		text_label.add_theme_font_size_override(&"normal_font_size", font_size)
	_follow_highlight_padding(font_size, theme_font_size)
	var text_height := minf(text_label.get_content_height(), max_text_height)
	var content_height := text_height + panel_margin
	_parts.text_panel.custom_minimum_size.y = maxf(TEXT_HEIGHT * _scale, content_height)


# Place laissée au texte : la carte moins le cadre, l'illustration et l'écart.
func _max_text_panel_height() -> float:
	var frame_height := _card.get_theme_stylebox(&"panel").get_minimum_size().y
	var gaps_height := _parts.layout.get_theme_constant(&"separation") * LAYOUT_GAP_COUNT
	return (
		_card_size.y * _scale - frame_height - _parts.art_frame.custom_minimum_size.y - gaps_height
	)
