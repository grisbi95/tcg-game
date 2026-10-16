class_name DuelSetupRejected
extends DuelEvent
## Décision 0012 : le DuelSetup est invalide, le duel ne démarre pas.

var errors: PackedStringArray = PackedStringArray()


func _init(setup_errors: PackedStringArray = PackedStringArray()) -> void:
	errors = setup_errors
