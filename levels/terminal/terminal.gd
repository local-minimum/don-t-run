extends Control
class_name Terminal

@warning_ignore_start("unused_signal")
signal mist(on: bool)
@warning_ignore_restore("unused_signal")

@export var os: TerminalOS
@export var game: TerminalGame

@export var _music_players: Array[AudioStreamPlayer]

var _fader: Tween

func play_music(stream: AudioStream, cross_fade: float = 1.0) -> void:
    if _fader && _fader.is_running():
        _fader.kill()

    var play_on: int = 1 if _music_players[0].playing else 0
    if cross_fade == 0:
        _music_players[(play_on + 1) % 2].stop()
        _music_players[play_on].stream = stream
        _music_players[play_on].play()
    else:
        _fader = create_tween()
        var new: AudioStreamPlayer = _music_players[play_on]
        var old: AudioStreamPlayer = _music_players[(play_on + 1) % 2]
        new.volume_linear = 0
        new.stream = stream
        new.play()
        _fader.tween_property(new, "volume_linear", 1.0, cross_fade)
        _fader.tween_property(old, "volume_linear", 0.0, cross_fade)
        _fader.finished.connect(
            func () -> void:
                old.stop()
                ,
        )
