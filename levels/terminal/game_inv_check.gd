extends GamePlace

@export var inv_check: GameInteraction
@export var state_check: String

@export var passes: GameBit
@export var passes_description: int
@export var fails: GameBit
@export var fails_description: int


func sync(game: TerminalGame) -> void:
    if (inv_check == null || game.carried.has(inv_check)) && (state_check.is_empty() || game.state.has(state_check)):
        if passes:
            passes.blocked = false
        if fails:
            fails.blocked = true
        active_description = passes_description
    else:
        if passes:
            passes.blocked = true
        if fails:
            fails.blocked = false
        active_description = fails_description
