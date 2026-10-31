# Right side of the typing line: active venv, how long the last command took (>3 s)
# and its exit code if it failed. Left out of the scrollback to keep history clean.
function fish_right_prompt
    set -l last_status $status
    contains -- --final-rendering $argv; and return

    set -l parts
    if set -q VIRTUAL_ENV
        set -a parts (set_color yellow)" "(basename (dirname $VIRTUAL_ENV))/(basename $VIRTUAL_ENV)
    end
    if test "$CMD_DURATION" -gt 3000 2>/dev/null
        set -l s (math --scale=0 $CMD_DURATION / 1000)
        set -l text (test $s -ge 60; and echo (math --scale=0 $s / 60)"m "(math $s % 60)"s"; or echo $s"s")
        set -a parts (set_color brblack)"took $text"
    end
    if test $last_status -ne 0
        set -a parts (set_color red)"✗ $last_status"
    end
    test (count $parts) -gt 0; and echo -n (string join "  " $parts)(set_color normal)
end
