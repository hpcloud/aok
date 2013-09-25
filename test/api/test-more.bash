is() {
    local got="$1" want="$2" label="$3"
    ok [ "$got" == "$want" ] $label || true
    if [ "$got" != "$want" ]; then
        echo "$got" > /tmp/got-$$
        echo "$want" > /tmp/want-$$
        diff -u /tmp/{want,got}-$$ >&2
        wc /tmp/{want,got}-$$ >&2
        rm -f /tmp/{got,want}-$$
    fi
}
