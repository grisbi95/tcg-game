class_name Piece
extends RefCounted
## Pièce du plateau : Hero, Unit, Building ou jeton (décision 0008).
##
## Une pièce qui revient sur le plateau est une nouvelle pièce, avec un nouveau `piece_id`.
## La Force actuelle et les auras se calculent par ForceRules, jamais ne se stockent (209.1.1).

enum PieceKind {
	HERO,  # 202.3.2
	UNIT,  # 202.2.2
	BUILDING,  # 202.2.3
}

var piece_id: int = DuelState.NO_ID
var kind: PieceKind = PieceKind.UNIT
## 201.5.2 : joueur qui contrôle la pièce ; pour un jeton, 201.5.4.
var owner: DuelState.PlayerSide = DuelState.PlayerSide.A
var cell: Vector2i = BoardGeometry.NO_CELL
## Carte qui a donné la pièce ; null pour un jeton (202.4.2). Le Hero est une carte (202.3.4).
var card: CardInstance
## PV du Hero (202.3.7, 204.1.8) ; sans objet pour les autres pièces.
var health: int = 0
## 209.1.1a : Force que l'effet créateur donne à un jeton ; sans objet pour une carte.
var token_force: int = 0
## 205.5.1, 205.5.2 : éveillée, la pièce peut faire une action normale (205.5.3) ; toute pièce
## naît endormie (205.5.4, 204.1.18). Sans objet pour un Building (205.5.6).
var is_awake: bool = false
## 202.2.8 : Gear porté, pour une Unit seulement.
var attached_gear: CardInstance


# 205.5.1, 205.5.2, 205.5.4, 205.5.6 : un Unit ou un Hero non éveillé dort ; un Building n'est
# ni endormi ni éveillé. Pur.
func is_asleep() -> bool:
	return kind != PieceKind.BUILDING and not is_awake


func is_token() -> bool:
	return card == null


func clone() -> Piece:
	var copy := Piece.new()
	copy.piece_id = piece_id
	copy.kind = kind
	copy.owner = owner
	copy.cell = cell
	copy.card = card.clone() if card != null else null
	copy.health = health
	copy.token_force = token_force
	copy.is_awake = is_awake
	copy.attached_gear = attached_gear.clone() if attached_gear != null else null
	return copy
