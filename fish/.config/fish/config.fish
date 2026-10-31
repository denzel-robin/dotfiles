if status is-interactive
    # Starship custom prompt
    starship init fish | source
end

fish_add_path ~/.local/bin
set -gx JAVA_HOME /usr/lib/jvm/java-17-openjdk

alias p='sudo pacman'

