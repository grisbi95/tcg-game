class_name RelayAddress
extends RefCounted
## Adresse du relais du duel à distance (décisions 0043 et 0049) : celle de la page Web si elle en
## donne une (`?relay=wss://…`), sinon le relais lancé sur cet ordinateur (`tools/relay/`).

const LOCAL_URL: String = "ws://localhost:8080"
const QUERY_KEY: String = "relay"


static func url() -> String:
	var page_url := _url_from_page()
	return page_url if not page_url.is_empty() else LOCAL_URL


# Contournement Web : la page qui héberge le jeu est lue par JavaScriptBridge, absent ailleurs.
static func _url_from_page() -> String:
	if not OS.has_feature("web"):
		return ""
	var script := "new URLSearchParams(window.location.search).get('%s') || ''" % QUERY_KEY
	var value: Variant = JavaScriptBridge.eval(script)
	return str(value) if value is String else ""
