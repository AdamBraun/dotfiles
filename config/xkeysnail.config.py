from xkeysnail.transform import *
from string import ascii_lowercase, ascii_uppercase
import re

define_multipurpose_modmap({
    # Enter is enter when pressed and released. Control when held down.
    Key.ENTER: [Key.ENTER, Key.RIGHT_CTRL],

    # Capslock is escape when pressed and released. Control when held down.
    # Key.CAPSLOCK: [Key.ESC, Key.LEFT_CTRL],
    Key.LEFT_CTRL: [Key.ESC, Key.LEFT_CTRL]
})

define_keymap(re.compile("Tilix|Konsole"), {
    # copy/paste
    K("Super-c"): K("C-Shift-c"),
    K("Super-v"): K("C-Shift-v"),
    #new tab
    K("Super-t"): K("C-Shift-t"),
    #quit/close
    K("Super-q"): K("C-Shift-q"),
    K("Super-w"): K("C-Shift-w"),
    #zoom
    K("Super-EQUAL"): K("C-Shift-EQUAL"),
    K("Super-MINUS"): K("C-MINUS"),
    #find
    K("Super-f"): K("C-Shift-f")
}, "Copy paste in tilix terminal")

browserMap = {
    K("Super-Alt-i"): K("C-Shift-i"),
    K("Super-EQUAL"): K("C-EQUAL"),
    K("Super-MINUS"): K("C-MINUS"),
    K("Super-SLASH"): K("C-SLASH")
}
for c in ascii_lowercase:
    browserMap[K("Super-" + c)] = K("C-" + c)
    browserMap[K("Super-Shift-" + c)] = K("C-Shift-" + c)

define_keymap(lambda wm_class: wm_class not in ("Tilix"), browserMap, 'Cmd to Ctrl not in terminal')
define_keymap(None, {
    K("Super-LAlt-SLASH"): K("Super-SLASH")
}, "fix gnome not allowing toggle-maximize with Super-Alt-/")

# define_keymap(re.compile("firefox|Chrome"), browserMap, 'ha')
