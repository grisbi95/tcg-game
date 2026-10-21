class_name JsonValues
extends RefCounted
## Lecture des valeurs JSON du journal (décision 0022) : le JSON lit tout nombre en flottant.


static func is_number(value: Variant) -> bool:
	return value is int or value is float


## Suppose `is_number(number)`.
static func to_int(number: Variant) -> int:
	var value: float = number
	return int(value)
