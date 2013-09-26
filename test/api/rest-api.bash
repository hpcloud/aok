api-get() { api-call GET "$@"; }
api-post() { api-call POST "$@"; }
api-put() { api-call PUT "$@"; }
api-patch() { api-call PUT "$@"; }
api-call() {
    local action="$1" url="$2" data="$3"
    format-curl-command
    "${curl_command[@]}" |
        perl -pe '$h="[0-9a-f]";s/$h{8}-($h{4}-){3}$h{12}/11111111-2222-3333-4444-555555555555/g'
}
format-curl-command() {
    curl_command=(
        curl
            --silent
            --request $action
            "$AOK_API_URL$url"
    )
}
