class_name ManualClock
extends MonotonicClock
## Horloge des tests (décision 0021) : le temps n'avance que par `advance()`.

var _now_msec: int = 0


func now_msec() -> int:
	return _now_msec


func advance(elapsed_msec: int) -> void:
	_now_msec += elapsed_msec
