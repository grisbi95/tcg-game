class_name DuelAssets
extends RefCounted
## Assets du jeu (décision 0051) : rangés par sorte dans `res://assets/`, retrouvés par leur nom.
## Un asset absent rend `null` et l'appelant garde son repli : l'icône du type pour une
## illustration (0027), le dessin de `DuelIcons` pour une icône. Les cadres et fonds entrent par
## `duel_theme.tres`, pas par cet utilitaire. Le moteur et `data/` ne connaissent aucune image.

const ROOT_DIRECTORY: String = "res://assets/"
const CARD_ART_DIRECTORY: String = ROOT_DIRECTORY + "cards/art/"
const ICON_DIRECTORY: String = ROOT_DIRECTORY + "icons/"
const CARD_ART_EXTENSION: String = ".webp"
const ICON_EXTENSION: String = ".svg"

## Chemin cherché → texture, `null` compris : un asset absent ne se recherche qu'une fois.
static var _textures: Dictionary[String, Texture2D] = {}


## Illustration de la carte ou du Hero d'identifiant `definition_id`, ou `null` sans fichier.
static func card_art(definition_id: StringName) -> Texture2D:
	if definition_id.is_empty():
		return null
	return _texture(card_art_path(definition_id))


## Chemin de l'illustration de `definition_id` : son identifiant dans `data/cards/`.
static func card_art_path(definition_id: StringName) -> String:
	return CARD_ART_DIRECTORY + String(definition_id) + CARD_ART_EXTENSION


## Icône `icon_name`, nom rendu par `DuelIcons.asset_name`, dessinée en blanc et teintée au
## dessin, ou `null` sans fichier.
static func icon(icon_name: String) -> Texture2D:
	return _texture(ICON_DIRECTORY + icon_name + ICON_EXTENSION)


## Montre dans `image` l'illustration de `definition_id` ; sans elle, l'icône `fallback_icon`.
static func show_card_art(
	image: TextureRect, fallback_icon: Control, definition_id: StringName
) -> void:
	_show_art(image, fallback_icon, card_art(definition_id))


## Un jeton n'a pas d'illustration : `image` est vidée, `fallback_icon` montrée.
static func show_no_art(image: TextureRect, fallback_icon: Control) -> void:
	_show_art(image, fallback_icon, null)


static func _show_art(image: TextureRect, fallback_icon: Control, texture: Texture2D) -> void:
	image.texture = texture
	image.visible = texture != null
	fallback_icon.visible = texture == null


static func _texture(path: String) -> Texture2D:
	if not _textures.has(path):
		_textures[path] = load(path) as Texture2D if ResourceLoader.exists(path) else null
	return _textures[path]
