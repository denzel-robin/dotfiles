# Read at login by greetd (and login shells): environment for the whole session.
# Without this, the shell/Hyprland can't find the rice scripts in ~/.local/bin.
case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) export PATH="$HOME/.local/bin:$PATH" ;;
esac
