class_name FileDownload
extends RefCounted
## Remise d'un fichier texte au joueur (étape 2.5) : téléchargé par le navigateur dans l'export
## Web, écrit dans le dossier utilisateur du jeu sur un poste de travail. Aucune règle ici.

const WEB_FEATURE: String = "web"
const USER_FOLDER: String = "user://playtest"


## Donne `text` au joueur sous le nom `file_name`. Renvoie où le fichier est allé : son nom quand
## le navigateur l'a téléchargé, le chemin absolu du fichier écrit sur un poste de travail, vide
## si l'écriture a échoué.
static func save_text(file_name: String, text: String, mime_type: String) -> String:
	if OS.has_feature(WEB_FEATURE):
		JavaScriptBridge.download_buffer(text.to_utf8_buffer(), file_name, mime_type)
		return file_name
	return _write_user_file(file_name, text)


static func _write_user_file(file_name: String, text: String) -> String:
	var path := USER_FOLDER.path_join(file_name)
	if DirAccess.make_dir_recursive_absolute(USER_FOLDER) != OK:
		push_error("FileDownload : dossier impossible à créer, %s" % USER_FOLDER)
		return ""
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("FileDownload : écriture impossible de %s" % path)
		return ""
	file.store_string(text)
	file.close()
	return ProjectSettings.globalize_path(path)
