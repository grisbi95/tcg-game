extends GdUnitTestSuite
## Remise d'un fichier texte au joueur, `FileDownload` (étape 2.5). Sur un poste de travail, le
## fichier s'écrit dans le dossier utilisateur du jeu ; le téléchargement du navigateur ne se
## teste pas ici, faute de navigateur.

const FILE_NAME: String = "essai.csv"
const MIME_TYPE: String = "text/csv"
const CONTENT: String = "a,b\n"
const REPLACING_CONTENT: String = "c,d\n"
const USER_FOLDER: String = FileDownload.USER_FOLDER


func after_test() -> void:
	DirAccess.remove_absolute(USER_FOLDER.path_join(FILE_NAME))
	DirAccess.remove_absolute(USER_FOLDER)  # sans effet si le dossier contient d'autres fiches


func test_file_download_writes_the_file_in_the_user_folder() -> void:
	var path := FileDownload.save_text(FILE_NAME, CONTENT, MIME_TYPE)
	var expected_path := ProjectSettings.globalize_path(USER_FOLDER.path_join(FILE_NAME))
	assert_str(path).is_equal(expected_path)
	assert_bool(path.is_absolute_path()).is_true()
	assert_bool(FileAccess.file_exists(path)).is_true()
	assert_str(FileAccess.get_file_as_string(path)).is_equal(CONTENT)


func test_file_download_replaces_the_content_of_an_existing_file() -> void:
	FileDownload.save_text(FILE_NAME, CONTENT, MIME_TYPE)
	var path := FileDownload.save_text(FILE_NAME, REPLACING_CONTENT, MIME_TYPE)
	assert_str(FileAccess.get_file_as_string(path)).is_equal(REPLACING_CONTENT)
