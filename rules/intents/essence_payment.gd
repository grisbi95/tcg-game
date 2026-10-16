class_name EssencePayment
extends RefCounted
## Paiement porté par une intention qui paie un coût (décision 0003 ; 203.2, 203.3).
##
## Les Sources sont fongibles : deux nombres suffisent. Les Sources s'inclinent d'abord, puis
## se recyclent ; une Source inclinée par ce paiement peut y être recyclée (203.2.6).

## 203.2.1 : Sources redressées à incliner.
var incline_count: int = 0
## 203.2.2 : Sources inclinées à recycler.
var recycle_count: int = 0


func _init(sources_to_incline: int = 0, sources_to_recycle: int = 0) -> void:
	incline_count = sources_to_incline
	recycle_count = sources_to_recycle


## 203.2.1, 203.2.2 : Essence produite, 1 par Source inclinée et 1 par Source recyclée.
func essence_produced() -> int:
	return incline_count + recycle_count
