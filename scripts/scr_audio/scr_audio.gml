/// @description Crown & Crucible - Lightweight Audio Feedback Architecture
/// @module scr_audio
///
/// PURPOSE:
///   Provides defensive, lightweight audio playback routines across UI, dialogue, and combat:
///   1. Safe Playback: cc_sfx_play(snd, pitch, gain) verifies audio system availability and asset existence.
///   2. Graceful Fallback: Returns -1 safely if audio hardware is unavailable (e.g. headless CI, VMs).
///   3. Asset Resolution: Resolves sound assets by resource index or asset name string.
///
/// STATE OWNERSHIP:
///   - Pure stateless utility module. Does not mutate gameplay or combat variables.

/// Safe sound effect playback with pitch and gain control.
/// Returns sound instance ID or -1 if audio system or asset is unavailable.
function cc_sfx_play(_snd, _pitch = 1.0, _gain = 1.0) {
    if (is_undefined(_snd) || _snd == -4 || _snd == -1) return -1;
    if (!audio_system_is_available()) return -1;
    if (is_string(_snd)) {
        var _idx = asset_get_index(_snd);
        if (_idx < 0) return -1;
        _snd = _idx;
    }
    if (!audio_exists(_snd)) return -1;
    var _has_pitch = (_pitch != 1.0);
    var _has_gain = (_gain != 1.0);
    _pitch = clamp(_pitch, 0.1, 5.0);
    _gain = clamp(_gain, 0.0, 1.0);
    var _inst = audio_play_sound(_snd, 10, false);
    if (_inst != -1 && !is_undefined(_inst)) {
        if (_has_pitch) audio_sound_pitch(_inst, _pitch);
        if (_has_gain) audio_sound_gain(_inst, _gain, 0);
    }
    return _inst;
}
