/// @description Stonecross UI Kit - Narrative Dialogue Frame & Speaker Presentation
/// @module ui_dialogue
///
/// PURPOSE:
///   Renders bottom narrative typewriter dialogue boxes in 1366x768 GUI coordinates (y: 616..756):
///   1. Gilded parchment 9-slice backing panel with text-calming backing rectangle.
///   2. Framed 2x speaker portrait badge with background crests.
///   3. Styled speaker nameplate header.
///   4. Typewriter text stream with animated prompt indicator ("Z / Enter").
///
/// STATE OWNERSHIP:
///   - Pure UI presentation routine.

#macro UI_COL_DIALOGUE_INK make_color_rgb(34, 20, 24)

/// _portrait: a 64x64 portrait sprite (drawn 2x) or -1. _visible_chars: typewriter count (-1 = all).
function ui_dialogue_draw(_text, _speaker_name, _portrait, _visible_chars = -1, _alpha = 1) {
    var _old_alpha = draw_get_alpha();
    draw_set_alpha(_old_alpha * clamp(_alpha, 0, 1));
    var _a = draw_get_alpha();
    _text = string(_text);

    var _bx = 183, _by = 616, _bw = 1000, _bh = 140;
    var _slide = round((1 - clamp(_alpha, 0, 1)) * 24);   // eases up as it fades in
    _by += _slide;
    ui_panel("gilded", _bx, _by, _bw, _bh);
    // calm the parchment grain behind the text so the thin pixel font reads cleanly
    draw_set_color(UI_COL_PARCHMENT);
    draw_set_alpha(_a * 0.7);
    draw_rectangle(_bx + 14, _by + 14, _bx + _bw - 15, _by + _bh - 15, false);
    draw_set_alpha(_a);
    draw_set_color(c_white);

    var _tx = _bx + 30;
    var _has_portrait = (_portrait != -1 && sprite_exists(_portrait));
    if (_has_portrait) {
        var _px = _bx + 14, _py = _by - 12;
        var _bg = ui_spr("spr_ui_portrait_bg");
        if (_bg >= 0) draw_sprite_ext(_bg, 0, _px + 8, _py + 8, 1, 1, 0, c_white, _a);
        draw_sprite_ext(_portrait, 0,
            _px + 8 + sprite_get_xoffset(_portrait) * 2 * (64 / max(1, sprite_get_width(_portrait))),
            _py + 8 + sprite_get_yoffset(_portrait) * 2 * (64 / max(1, sprite_get_height(_portrait))),
            128 / max(1, sprite_get_width(_portrait)), 128 / max(1, sprite_get_height(_portrait)), 0, c_white, _a);
        var _fr = ui_spr("spr_ui_portrait_frame");
        if (_fr >= 0) draw_sprite_ext(_fr, 0, _px, _py, 1, 1, 0, c_white, _a);
        _tx = _px + 144 + 18;
    }

    if (_speaker_name != "") {
        var _nw = ui_text_width(_speaker_name, "body") + 48;
        ui_nine("spr_ui_nameplate", 0, _tx - 14, _by - 18, _nw, 36);
        ui_text_draw(_tx + 10, ui_text_center_y(_by, "body"), _speaker_name, "body_shadow", UI_COL_PARCHMENT);
    }

    var _tw = _bx + _bw - 34 - _tx;
    ui_text_draw(_tx, _by + 26, _text, "body_bold", UI_COL_DIALOGUE_INK, _tw, _visible_chars);

    if (_visible_chars < 0 || _visible_chars >= string_length(_text)) {
        var _arrow = ui_spr("spr_ui_next_arrow");
        if (_arrow >= 0) draw_sprite_ext(_arrow, (current_time div 400) mod 2, _bx + _bw - 44, _by + _bh - 36, 1, 1, 0, c_white, _a);
    }
    draw_set_alpha(_old_alpha);
}
