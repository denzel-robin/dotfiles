# Small greeting in the terminal's colours (which follow the wallpaper):
#   greeting + name / kernel · uptime · memory / the current palette as dots.
# Reads /proc directly — no fastfetch, so new terminals open instantly.
function fish_greeting
    set -l h (date +%H)
    set -l hello "good evening"
    test $h -lt 5; and set hello "good night"
    test $h -ge 5 -a $h -lt 12; and set hello "good morning"
    test $h -ge 12 -a $h -lt 17; and set hello "good afternoon"

    set -l up (string split . < /proc/uptime)[1]
    set -l d (math --scale=0 $up / 86400)
    set -l hr (math --scale=0 "$up % 86400 / 3600")
    set -l mi (math --scale=0 "$up % 3600 / 60")
    set -l uptime (test $d -gt 0; and echo "$d"d" $hr"h; or test $hr -gt 0; and echo "$hr"h" $mi"m; or echo "$mi"m)

    set -l total (string match -rg 'MemTotal:\s+(\d+)' < /proc/meminfo)
    set -l avail (string match -rg 'MemAvailable:\s+(\d+)' < /proc/meminfo)
    set -l used (math --scale=1 "($total - $avail) / 1048576")
    set -l all (math --scale=0 "$total / 1048576")

    set -l dim (set_color brblack)
    set -l sep "$dim  ·  "
    echo
    echo "  "(set_color blue)"󰣇  "(set_color normal)"$hello, "(set_color --bold blue)$USER(set_color normal)
    echo "  $dim   "\uf31a" "(uname -r | string replace -r -- '-.*' '')"$sep󰅐 up $uptime$sep󰍛 $used / $all GB"(set_color normal)
    echo -n "     "
    for c in red green yellow blue magenta cyan
        echo -n (set_color $c)"● "
    end
    echo (set_color normal)
end
