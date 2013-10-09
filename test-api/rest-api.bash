api-get() { api-call GET "$@"; }
api-post() { api-call POST "$@"; }
api-put() { api-call PUT "$@"; }
api-patch() { api-call PATCH "$@"; }
api-delete() { api-call DELETE "$@"; }
api-call() {
    rm -f HEAD STDOUT STDERR
    local action="$1" url="$2" data="$3"
    url="$(url-encode "$url")"
    format-curl-command
    "${curl_command[@]}"
}
format-curl-command() {
    curl_command=(curl)
    curl_command+=(
        -H "accept: application/json"
        -H "content-type: application/json"
        --silent
        --request $action
        --dump-header HEAD
        --output STDOUT
        --stderr STDERR
        --silent
        --show-error
        "$AOK_API_URL$url"
    )
    if [ -n "$data" ]; then
        curl_command+=(-d "$data")
    fi
}

api-output() {
    [ ! -e STDOUT ] && return
    cat STDOUT
}

api-output-pretty() {
    [ ! -e STDOUT ] && return
    cat STDOUT | json_pp
}

api-output-linear() {
    [ ! -e STDOUT ] && return
    cat STDOUT | JSON.load
}

api-output-get() {
    [ ! -e STDOUT ] && return
    cat STDOUT | JSON.load | JSON.get -a "$1"
}

api-status() {
    if [[ -e HEAD ]] && [[ -s HEAD ]]; then
        local line=`head HEAD -n1`
        if [[ "$line" =~ ^HTTP/1.1\ ([0-9][0-9][0-9]) ]]; then
            echo ${BASH_REMATCH[1]}
        fi
    fi
}

# XXX finish encoding logic…
url-encode() {
    echo "${1// /+}"
}

# normalize() {
#     perl -p \
#         -e '$h="[0-9a-f]";' \
#         -e 's/$h{8}-($h{4}-){3}$h{12}/11111111-2222-3333-4444-555555555555/g'
# }
