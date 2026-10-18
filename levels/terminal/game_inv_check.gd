extends GamePlace

@export var inv_check: GameInteraction
@export var state_check: String

@export var passes: Array[GameBit]
@export var passes_description: int
@export var fails: Array[GameBit]
@export var fails_description: int


func sync(game: TerminalGame) -> void:
    if (inv_check == null || game.carried.has(inv_check)) && (state_check.is_empty() || game.state.has(state_check)):
        for p: GameBit in passes:
            p.blocked = false
        for f: GameBit in fails:
            f.blocked = true
        if passes_description >= 0:
            active_description = passes_description
    else:
        for p: GameBit in passes:
            p.blocked = true
        for f: GameBit in fails:
            f.blocked = false
        if fails_description >= 0:
            active_description = fails_description
