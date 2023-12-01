azure_login() {
    if ! az account show &>/dev/null; then
        az login
    fi
}
