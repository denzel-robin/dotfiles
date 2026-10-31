# ❯ colour: red after a failed command, otherwise the accent (terminal blue = wallpaper primary)
function __rice_symbol_color
    test "$argv[1]" = 0; and echo blue; or echo red
end
