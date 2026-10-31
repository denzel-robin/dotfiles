# Block prompt: one header per folder, a line down the left through every command,
# `cd` closes the block and the next folder starts a new one.
#
#   ╭─  ~/dotfiles   
#   ├─❯ git status        <- after Enter the corner becomes ├ (block continues)
#   ╰─❯ cd ~/Pictures     <- folder-changing commands keep ╰ (block closes)
#
# Needs fish_transient_prompt (set in conf.d/rice-prompt.fish): fish re-runs this
# with --final-rendering when you press Enter, which is when the corner is decided.
function fish_prompt
    set -l last_status $status
    set -l line (set_color brblack)
    set -l reset (set_color normal)

    if contains -- --final-rendering $argv
        # What goes into the scrollback for the command that's about to run
        set -l cmd (string trim -- (commandline))
        set -l corner ├─
        if string match -qr '^(cd|z|zi|y|pushd|popd|prevd|nextd|exit)(\s|$)' -- $cmd
            set corner ╰─
            set -g __rice_block_closed 1
        end
        test "$__rice_show_header" = 1; and printf '%s' $__rice_header_text
        printf '%s%s%s❯%s ' $line $corner (set_color (__rice_symbol_color $last_status)) $reset
        set -g __rice_show_header 0          # the header is in the scrollback now
        set -g __rice_block_dir $PWD
        return
    end

    # Live prompt (redrawn on every repaint, so its state is decided elsewhere)
    test "$__rice_show_header" = 1; and printf '%s' $__rice_header_text
    printf '%s╰─%s❯%s ' $line (set_color (__rice_symbol_color $last_status)) $reset
end
