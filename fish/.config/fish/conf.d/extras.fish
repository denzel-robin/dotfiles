# Terminal extras. Each block only turns on if the tool is installed.
status is-interactive; or return

# eza: ls with icons and git status
if command -q eza
    alias ls 'eza --icons=auto --group-directories-first'
    alias ll 'eza -l --icons=auto --group-directories-first --git --time-style=relative'
    alias la 'eza -la --icons=auto --group-directories-first --git --time-style=relative'
    alias lt 'eza --tree --level=2 --icons=auto --group-directories-first'
end

# bat: cat with syntax highlighting, using the terminal's (wallpaper) colours
if command -q bat
    set -gx BAT_THEME ansi
    alias cat 'bat --paging=never --style=plain'
    set -gx MANPAGER "sh -c 'col -bx | bat -l man -p'"
    set -gx MANROFFOPT -c
end

# fzf: Ctrl+T find a file, Alt+C jump into a folder (Ctrl+R belongs to atuin)
if command -q fzf
    set -gx FZF_DEFAULT_OPTS "--height=45% --layout=reverse --border=rounded --info=inline --prompt='❯ ' --pointer='▌' --color=fg:-1,bg:-1,hl:4,fg+:15,bg+:0,hl+:4,info:8,prompt:4,pointer:4,marker:2,spinner:5,header:8,border:8"
    set -gx FZF_CTRL_T_OPTS "--preview 'bat --color=always --style=numbers --line-range=:200 {} 2>/dev/null || eza --tree --level=2 --icons=always --color=always {}'"
    set -gx FZF_ALT_C_OPTS "--preview 'eza --tree --level=2 --icons=always --color=always {}'"
    fzf --fish | source
end

# zoxide: z <part of a folder name>
command -q zoxide; and zoxide init fish | source

# atuin: Ctrl+R searchable history (loaded last so it owns Ctrl+R; Up arrow stays normal)
command -q atuin; and atuin init fish --disable-up-arrow | source
