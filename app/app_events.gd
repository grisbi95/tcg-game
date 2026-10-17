extends Node
## Bus de l'application, autoload `AppEvents` (décision 0006) : signals seuls.
##
## Écrans, audio et réglages. Aucun fait de jeu : ceux-ci passent par `Array[DuelEvent]`.
## Aucune variable, aucune fonction, aucune référence ici.

@warning_ignore("unused_signal")
signal scene_requested(scene_path: String)
@warning_ignore("unused_signal")
signal audio_requested(sound_id: StringName)
@warning_ignore("unused_signal")
signal settings_changed
