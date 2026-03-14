# ── Completion ────────────────────────────────────────────────
[ -f /usr/share/bash-completion/bash_completion ] && . /usr/share/bash-completion/bash_completion
[ -f /etc/bash_completion ] && . /etc/bash_completion

bind 'set show-all-if-ambiguous on'
bind 'set menu-complete-display-prefix on'
bind 'TAB:menu-complete'
bind '"\e[Z":menu-complete-backward'
bind 'set completion-ignore-case on'
bind 'set colored-stats on'

# ── Prompt ────────────────────────────────────────────────────
_collapsed_pwd() {
    pwd | perl -pe '
        BEGIN {
            binmode STDIN,  ":encoding(UTF-8)";
            binmode STDOUT, ":encoding(UTF-8)";
        };
        s|^$ENV{HOME}|~|g;
        s|/([^/.])[^/]*(?=/)|/$1|g;
        s|/\\.([^/])[^/]*(?=/)|/.$1|g
    '
}

PS1='\[\e[32m\]\u\[\e[0m\]@\h:[\[\e[32m\]$(_collapsed_pwd)\[\e[0m\]]: '

# ── Ctrl+W: kill back to delimiter ───────────────────────────
stty werase undef
_kill_back_to_delim() {
    local l="${READLINE_LINE:0:$READLINE_POINT}"
    local r="${READLINE_LINE:$READLINE_POINT}"
    # skip trailing delimiters
    while [ "${#l}" -gt 0 ]; do
        case "${l: -1}" in
            /|_|.|,|" "|"	") l="${l%?}" ;;
            *) break ;;
        esac
    done
    # eat until next delimiter or start
    while [ "${#l}" -gt 0 ]; do
        case "${l: -1}" in
            /|_|.|,|" "|"	") break ;;
            *) l="${l%?}" ;;
        esac
    done
    READLINE_LINE="${l}${r}"
    READLINE_POINT=${#l}
}
bind -x '"\027":_kill_back_to_delim'
