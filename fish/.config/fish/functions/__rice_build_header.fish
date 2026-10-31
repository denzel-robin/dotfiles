# Build (once per block) the header line:  ╭─  ~/folder   
# A blank line separates it from the previous block.
# (Quoted "$(…)" matters: an unquoted empty substitution would blank the whole string.)
function __rice_build_header
    set -l gap ""
    test -n "$__rice_block_dir"; and set gap \n
    set -g __rice_header_text "$gap$(set_color brblack)╭─ $(set_color blue) $(set_color --bold brwhite)$(__rice_pwd)$(set_color normal)$(__rice_env)$(set_color normal)"\n
end
