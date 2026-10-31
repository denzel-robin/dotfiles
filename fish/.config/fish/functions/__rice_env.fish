# Environment of the current folder, as coloured logos (+ Python version / venv).
# Only looks at files in this folder, and never runs interpreters except a quick
# `python3 -V` when there's no venv to read the version from.
function __rice_env
    set -l out
    set -l has (path filter -- * .venv venv .python-version)

    # Python
    set -l py
    if set -q VIRTUAL_ENV; and test -f $VIRTUAL_ENV/pyvenv.cfg
        set py (string match -rg '^version(?:_info)?\s*=\s*(\d+\.\d+)' < $VIRTUAL_ENV/pyvenv.cfg)" ("(basename $VIRTUAL_ENV)")"
    else
        for v in .venv venv
            if test -f $v/pyvenv.cfg
                set py (string match -rg '^version(?:_info)?\s*=\s*(\d+\.\d+)' < $v/pyvenv.cfg)" ($v)"
                break
            end
        end
        if test -z "$py"; and path filter -q -- pyproject.toml requirements.txt setup.py Pipfile .python-version *.py
            set py (python3 -V 2>/dev/null | string match -rg '(\d+\.\d+)')
        end
    end
    test -n "$py"; and set -a out (set_color yellow)" $py"

    path filter -q -- *.ipynb; and set -a out (set_color yellow)"󰠮"
    path filter -q -- package.json; and set -a out (set_color green)""
    path filter -q -- Cargo.toml; and set -a out (set_color red)""
    path filter -q -- go.mod; and set -a out (set_color cyan)"󰟓"
    path filter -q -- pom.xml build.gradle build.gradle.kts *.java; and set -a out (set_color red)""
    path filter -q -- *.cpp *.cc *.hpp; and set -a out (set_color blue)""
    or path filter -q -- *.c *.h CMakeLists.txt Makefile; and set -a out (set_color blue)""
    path filter -q -- *.lua; and set -a out (set_color blue)""
    path filter -q -- *.qml; and set -a out (set_color green)"󰫾"
    path filter -q -- Dockerfile compose.yml compose.yaml docker-compose.yml docker-compose.yaml; and set -a out (set_color cyan)""
    path filter -q -- *.R *.Rproj DESCRIPTION; and set -a out (set_color blue)"󰟔"
    path filter -q -- project.godot; and set -a out (set_color cyan)""
    path filter -q -- *.tex; and set -a out (set_color green)""
    path filter -q -- *.sh *.fish; and set -a out (set_color green)""

    test (count $out) -gt 0; and echo -n "   "(string join "  " $out)
end
