source file-patterns.sh
source utils.sh

if [[ -v $DEBUG && "$DEBUG" == true ]]
then
    set -x    
fi

function get_companion_json_file_for_csv {
    local csv_file="$1"
    potential_config_file=$(replace_extension "$csv_file" "json")
    if [[ -f $potential_config_file ]] && ! is_excluded_file "$potential_config_file"; then
        echo $potential_config_file
    fi
}

function get_companion_csv_file_for_json {
    local config_file="$1"

    potential_csv_file=$(replace_extension "$config_file" "csv")
    if [[ -f $potential_csv_file ]] && ! is_excluded_file "$potential_csv_file"; then
        echo "$potential_csv_file"
    fi
}

function get_out_path {
    local csv_file="$1"

    local csv_file_without_extension="${csv_file%.*}"
    local csv_file_name="${csv_file_without_extension##*/}"
    # Creating the out path to store outputs.
    if is_in_root_directory "$csv_file"; then
        echo "out/${csv_file_name}/"
    else
        parent_directory=$(get_parent_directory_for_file "$csv_file")
        echo "out/${parent_directory}/${csv_file_name}/"
    fi
}

function build_and_inspect_csvw {
    local csv_file="$1"
    local json_file="$2"

    local out_dir="$RUNNER_TEMP/$(get_out_path "$csv_file")"

    echo "---Building CSV-W for $csv_file"
    echo "Building CSV-W"
    if [[ -f $json_file ]]; then
        echo "Config for ${csv_file} is available: ${json_file}"
        csvcubed build "$csv_file" -c "$json_file" --out "$out_dir" --validation-errors-to-file
    else
        echo "Config for ${csv_file} is not available"
        csvcubed build "$csv_file" --out "$out_dir" --validation-errors-to-file
    fi
    
    echo "---Inspecting CSV-Ws for $csv_file"
    mapfile -d $'\0' inspectable_files < <(find "$out_dir" -name "*.csv-metadata.json" -type f -print0)
    for inspect_file in "${inspectable_files[@]}"; do
        echo "Inspecting file: ${inspect_file}"
        inspect_file_path="${inspect_file%/*}"
        inspect_file_name="${inspect_file##*/}"                  
        inspect_output_file="${out_dir}${inspect_file_name}_inspect_output.txt"

        csvcubed inspect "$inspect_file" > "$inspect_output_file"
    done
}

# Main logic starts here
echo "::set-output name=has_outputs::false"

mapfile -d ',' -t detected_files < <(printf '%s,' "$FILES_ADDED_MODIFIED")
mapfile -d ',' -t renamed_files < <(printf '%s,' "$FILES_RENAMED")
detected_files+=(${renamed_files[@]})
echo "detected_files: ${detected_files[@]}"

processed_files=()
for file in "${detected_files[@]}"; do
    echo $'\n'
    echo "======================"
    echo "Detected file: ${file}"

    file_extension="${file##*.}"

    # If the file is already processed, it will be ignored.
    if [[ " ${processed_files[@]} " =~ " ${file} " ]]; then
        continue
    elif [[ $(get_top_level_folder_name "$file") == "out" ]]
    then
        echo "File is in 'out' directory, ignoring it."
        continue
    elif is_excluded_file "$file"
    then
        echo "File is to be excluded, ignoring it."
        continue
    elif [[ $file_extension != "csv" && $file_extension != "json" ]]
    then
        echo "This is not the file we're looking for. Neither JSON nor CSV."
        continue
    fi

    csv_file=""
    config_file=""
    if [[ $file_extension == "csv" ]]; then
        csv_file="$file"
        config_file=$(get_companion_json_file_for_csv "$file")
        if [[ "$JSON_CONFIG_REQUIRED" == true && ! -f "$config_file" ]]
        then
            echo "Could not find JSON config for $csv_file whilst `config-required` is true"
            continue
        fi
    elif [[ $file_extension == "json" ]]; then
        config_file="$file"
        csv_file=$(get_companion_csv_file_for_json "$file")
        if [[ ! -f "$csv_file" ]]
        then
            # If a JSON file exists without a companion CSV file, we can't run csvcubed build at all for this file.
            continue
        fi
    else 
        # The file extension is not CSV or JSON, we can't process this file with csvcubed build.
        continue
    fi
    
    build_and_inspect_csvw "$csv_file" "$config_file"
    
    processed_files+=($csv_file)
    processed_files+=($config_file)
    
    echo "::set-output name=has_outputs::true"
    
    echo "---Finished Processing File: ${file}"
    echo "======================"                
done