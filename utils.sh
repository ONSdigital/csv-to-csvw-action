function get_parent_directory_for_file {
    local file="$1"

    if is_in_root_directory "$file"
    then
        echo ""
    else
        echo "${file%/*}" 
    fi
}

function is_in_root_directory {
    local file="$1"
    if [[ "${file%/*}" == "$file" ]] 
    then
        return 0
    else
        return 1
    fi
}

function get_top_level_folder_name {
    local file="$1"
    if is_in_root_directory "$file"
    then
        echo ""
    else
        echo $(echo "$file" | cut -d "/" -f1)
    fi
}

function replace_extension {
    local file="$1"
    new_extension="$2"

    file_without_extension="${file%.*}"

    echo "$file_without_extension.$new_extension"
}
