# State for the block prompt (functions/fish_prompt.fish)
status is-interactive; or return

set -g fish_transient_prompt 1
set -g __rice_block_dir ""
set -g __rice_show_header 1
__rice_build_header

# After each command: start a new block if the folder changed or the block was closed
function __rice_after_command --on-event fish_postexec
    if test "$PWD" != "$__rice_block_dir"; or set -q __rice_block_closed
        set -e __rice_block_closed
        __rice_build_header
        set -g __rice_show_header 1
    end
end

# `clear` / Ctrl+L start a fresh block at the top (no blank line before it)
function __rice_fresh_block
    set -g __rice_block_dir ""
    set -e __rice_block_closed
    __rice_build_header
    set -g __rice_show_header 1
end

function clear --wraps clear --description 'Clear the screen and start a new prompt block'
    command clear $argv
    __rice_fresh_block
end

bind ctrl-l '__rice_fresh_block; commandline -f clear-screen'
