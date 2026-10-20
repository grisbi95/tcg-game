class_name JsonObjectFiles
extends RefCounted
## Lecture des fichiers JSON de `data/` (décisions 0002 et 0037), partagée par `CatalogLoader` et
## `DeckLoader` : chaque fonction ajoute ses erreurs à `errors` et ne lève jamais ; l'appelant
## sait qu'elle a échoué quand `errors` a grandi.

const FILE_EXTENSION: String = "json"


## Chemins des `.json` du dossier, par ordre alphabétique.
static func file_paths(directory_path: String, errors: PackedStringArray) -> PackedStringArray:
	var paths := PackedStringArray()
	if not DirAccess.dir_exists_absolute(directory_path):
		errors.append("%s : dossier introuvable" % directory_path)
		return paths
	var file_names := DirAccess.get_files_at(directory_path)
	file_names.sort()
	for file_name: String in file_names:
		if file_name.get_extension() == FILE_EXTENSION:
			paths.append(directory_path.path_join(file_name))
	return paths


## Texte du fichier ; vide si la lecture échoue.
static func read_text(path: String, errors: PackedStringArray) -> String:
	var json_text := FileAccess.get_file_as_string(path)
	if FileAccess.get_open_error() != OK:
		var reason := error_string(FileAccess.get_open_error())
		errors.append("%s : lecture impossible (%s)" % [path, reason])
		return ""
	return json_text


## Objet racine de `json_text` ; vide si le JSON est invalide ou n'est pas un objet. `source`
## nomme le fichier d'origine dans les messages.
static func parse_object(
	json_text: String, source: String, errors: PackedStringArray
) -> Dictionary:
	var json := JSON.new()
	if json.parse(json_text) != OK:
		errors.append(
			(
				"%s : JSON invalide, ligne %d : %s"
				% [source, json.get_error_line(), json.get_error_message()]
			)
		)
		return {}
	if typeof(json.data) != TYPE_DICTIONARY:
		errors.append("%s : l'objet racine est attendu" % source)
		return {}
	var data: Dictionary = json.data
	return data
