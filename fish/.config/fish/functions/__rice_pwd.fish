# Current folder for the header: ~ for home, shortened from the left to ~40 characters
function __rice_pwd
    set -l max 40
    set -l p (string replace -r "^$HOME(?=/|\$)" "~" -- $PWD)
    if test (string length -- $p) -gt $max
        set -l parts (string split / -- $p)
        set -l out
        for i in (seq (count $parts) -1 1)
            set -l candidate (string join / $parts[$i] $out)
            test (string length -- "…/$candidate") -gt $max; and break
            set out $parts[$i] $out
        end
        set p "…/"(string join / $out)
    end
    echo -n $p
end
