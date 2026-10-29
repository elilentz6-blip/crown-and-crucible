/// @description Stonecross UI Kit - Sprite-Font Typography Engine & Word-Wrap Routines
/// @module ui_text
///
/// PURPOSE:
///   Draws custom bitmap sprite-font typography without OS font dependencies:
///   1. Font Styles: "body", "small", and "title", with "_shadow", "_outline", or "_bold" style suffixes.
///   2. Glyph Normalization: Maps UTF-8 typographic punctuation (quotes, en-dash, ellipsis) to ASCII glyph indices.
///   3. Word Wrapping: Splits strings into pixel-accurate multi-line wrapped arrays preserving character counts.
///   4. String Measurement: Computes pixel text widths and vertical cap-height centering offsets.
///   5. Typewriter Rendering: Supports progressive char count truncation (_max_chars) for animated dialogue.
///
/// STATE OWNERSHIP:
///   - Pure visual rendering library.

function ui_text_font(_style) {
    var _fonts = ui_kit_data().fonts;
    return _fonts[$ _style] ?? _fonts.body;
}

/// Map a character to its ASCII glyph code (typographic punctuation folds to ASCII; unknown -> '?').
function ui_text_code(_ch) {
    var _c = ord(_ch);
    if (_c >= 32 && _c <= 126) return _c;
    switch (_c) {
        case 8216: case 8217: return 39;   // ' '
        case 8220: case 8221: return 34;   // " "
        case 8211: case 8212: return 45;   // - -
        case 8226: return 42;              // bullet
        case 8230: return 46;              // ellipsis
        case 160:  return 32;              // nbsp
    }
    return 63;
}

/// Split _str into lines no wider than _maxw (-1 = no wrapping).
/// Wrapped lines keep their trailing space and explicit breaks keep their "\n",
/// so the characters across all lines add up to the source string (typewriter counts stay exact).
function ui_text_wrap(_str, _style, _maxw = -1) {
    var _f = ui_text_font(_style);
    var _lines = [];
    var _line = "", _lw = 0, _word = "", _ww = 0;
    var _n = string_length(_str);
    for (var _i = 1; _i <= _n; _i++) {
        var _ch = string_char_at(_str, _i);
        if (_ch == "\n") {
            array_push(_lines, _line + _word + "\n");
            _line = ""; _lw = 0; _word = ""; _ww = 0;
            continue;
        }
        var _a = _f.adv[ui_text_code(_ch) - 32];
        if (_ch == " ") {
            _line += _word + " ";
            _lw += _ww + _a;
            _word = ""; _ww = 0;
            continue;
        }
        _word += _ch;
        _ww += _a;
        if (_maxw > 0 && _lw > 0 && _lw + _ww > _maxw) {
            array_push(_lines, _line);
            _line = ""; _lw = 0;
        }
    }
    array_push(_lines, _line + _word);
    return _lines;
}

/// Y to pass to ui_text_draw so capital letters are vertically centred on _cy.
function ui_text_center_y(_cy, _style = "body") {
    var _p = string_pos("_", _style);
    if (_p > 0) _style = string_copy(_style, 1, _p - 1);
    var _f = ui_text_font(_style);
    return round(_cy - _f.cap_top - _f.cap_h / 2);
}

/// Width in px of the widest line of _str (no wrapping).
function ui_text_width(_str, _style = "body") {
    var _p = string_pos("_", _style);
    if (_p > 0) _style = string_copy(_style, 1, _p - 1);
    var _f = ui_text_font(_style);
    _str = string(_str);
    var _best = 0, _w = 0;
    var _n = string_length(_str);
    for (var _i = 1; _i <= _n; _i++) {
        var _ch = string_char_at(_str, _i);
        if (_ch == "\n") { _best = max(_best, _w); _w = 0; continue; }
        _w += _f.adv[ui_text_code(_ch) - 32];
    }
    return max(_best, _w);
}

/// Draw text; returns the height of the whole (wrapped) block so layouts stay stable while typing.
/// _max_chars limits how many source characters are shown (-1 = all) for typewriter reveals.
/// _tracking adds px between glyphs (negative to squeeze a long name into a fixed band).
function ui_text_draw(_x, _y, _str, _style = "body", _col = c_white, _max_width = -1, _max_chars = -1, _tracking = 0) {
    _str = string(_str);
    var _fx = "";
    var _p = string_pos("_", _style);
    if (_p > 0) {
        _fx = string_delete(_style, 1, _p);
        _style = string_copy(_style, 1, _p - 1);
    }
    var _f = ui_text_font(_style);
    var _spr = ui_spr(_f.sprite);
    var _lines = ui_text_wrap(_str, _style, _max_width);
    var _height = array_length(_lines) * _f.line_h;
    if (_spr < 0) return _height;

    var _alpha = draw_get_alpha();
    var _o = _f.scale;                      // shadow/outline offset = one font pixel
    var _limit = (_max_chars < 0) ? infinity : _max_chars;
    var _count = 0;
    _x = floor(_x); _y = floor(_y);

    for (var _li = 0; _li < array_length(_lines); _li++) {
        var _ln = _lines[_li];
        var _cx = _x;
        var _cy = _y + _li * _f.line_h;
        var _n = string_length(_ln);
        for (var _i = 1; _i <= _n; _i++) {
            if (_count >= _limit) return _height;
            var _ch = string_char_at(_ln, _i);
            _count++;
            if (_ch == "\n") continue;
            var _fr = ui_text_code(_ch) - 32;
            if (_fr > 0) {
                var _gx = _cx - _f.pen_x;
                if (_fx == "shadow") {
                    draw_sprite_ext(_spr, _fr, _gx + _o, _cy + _o, 1, 1, 0, UI_COL_SHADOW, _alpha);
                } else if (_fx == "outline") {
                    for (var _dx = -1; _dx <= 1; _dx++) {
                        for (var _dy = -1; _dy <= 1; _dy++) {
                            if (_dx != 0 || _dy != 0) draw_sprite_ext(_spr, _fr, _gx + _dx * _o, _cy + _dy * _o, 1, 1, 0, UI_COL_SHADOW, _alpha);
                        }
                    }
                } else if (_fx == "bold") {
                    draw_sprite_ext(_spr, _fr, _gx + 1, _cy, 1, 1, 0, _col, _alpha);
                }
                draw_sprite_ext(_spr, _fr, _gx, _cy, 1, 1, 0, _col, _alpha);
            }
            _cx += _f.adv[_fr] + _tracking;
        }
    }
    return _height;
}
