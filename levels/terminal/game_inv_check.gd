extends GamePlace

@export var inv_check: GameInteraction

@export var has_inv: GameBit
@export var has_inv_description: int
@export var lacks_inv: GameBit
@export var lacks_inv_description: int


func sync(game: TerminalGame) -> void:
    if game.carried.has(inv_check):
        has_inv.blocked = false
        lacks_inv.blocked = true
        active_description = has_inv_description
    else:
        has_inv.blocked = true
        lacks_inv.blocked = false
        active_description = lacks_inv_description
