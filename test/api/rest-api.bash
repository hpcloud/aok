api-get() { api-call GET "$@"; }
api-post() { api-call POST "$@"; }
api-put() { api-call PUT "$@"; }
api-patch() { api-call PUT "$@"; }
api-call() {
    local action="$1" url="$2" data="$3"
    format-curl-command
    "${curl_command[@]}"
}
format-curl-command() {
    curl_command=(
        curl
            --silent
            --request $action
            "$AOK_API_URL$url"
    )
}
