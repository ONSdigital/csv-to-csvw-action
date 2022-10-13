get_paths_for_pattern() {

    local files_matching_pattern=($1)
    local absolute_paths_matching_pattern=()

    for file_matching_pattern in "${files_matching_pattern[@]}"
    do
        absolute_paths_matching_pattern+=($(readlink -f $file_matching_pattern))
    done

    # (Kind of) return the array
    echo "${absolute_paths_matching_pattern[@]}"
}

function get_files_matching_glob_pattern {
    shopt -s globstar # Enable the globstar (**) functionality

    local path_patterns=($1)
    local absolute_paths=()
    for path_pattern in "${path_patterns[@]}"
    do
        absolute_paths+=( $(get_paths_for_pattern "$path_pattern"))
    done

    shopt -u globstar # Disable the globstar (**) functionality

    # (Kind of) return the array
    echo "${absolute_paths[@]}"
}