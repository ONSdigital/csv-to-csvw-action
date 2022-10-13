echo "::set-output name=has_outputs::false"
mapfile -d ',' -t deleted_files < <(printf '%s,' "$FILES_REMOVED")
for file in "${deleted_files[@]}"; do
    echo $'\n'
    echo "---Handling Deletions for File: ${file}"            
    root_file=false
    file_path="${file%/*}"
    if [[ $file_path == $file ]]; then
    file_path=""
    root_file=true
    fi
    file_without_extension="${file%.*}"
    file_name="${file_without_extension##*/}"
    file_extension="${file##*.}"

    # Detecting the top folder from the file path. E.g. csv/ is the top folder when the path is csv/sub-folder/my-data.csv
    if [[ $root_file == true ]]; then
    top_folder=""
    else
    top_folder=$(echo "$file_path" | cut -d "/" -f1)
    fi

    echo "---Extracting Delete File Info"
    echo "file_path: ${file_path}"
    echo "file_without_extension: ${file_without_extension}"
    echo "file_name: ${file_name}"
    echo "file_extension: ${file_extension}"
    echo "top_folder: ${top_folder}"

    # Delete config and outputs when a csv outside the out folder is deleted.
    if [[ $file_extension != "csv" || $top_folder == "out" ]]; then
    echo "File is not a csv or a it is a file inside out folder, hence ignoring it."
    continue
    fi
    
    config_file="${file_without_extension}.json"

    if [[ $root_file == true ]]; then
    out_folder="out/${file_name}/"
    else
    out_folder="out/${file_path}/${file_name}/"
    fi
    
    echo "config_file: ${config_file}"
    echo "out_folder: ${out_folder}"
    
    if [[ -f $config_file ]]; then
    echo "config file exists, hence deleting."
    git rm "$config_file"
    git commit -m "Deleted config file for file ${file} - $(date +'%d-%m-%Y at %H:%M:%S')"
    fi

    if [[ -d $out_folder ]]; then
    echo "outputs exist, hence deleting."
    git rm -r "$out_folder"
    git commit -m "Deleted outputs for file ${file} - $(date +'%d-%m-%Y at %H:%M:%S')"
    fi
    
    git push
    
    echo "::set-output name=has_outputs::true"
    echo "---Finished Handling Deletions for File: ${file}"
done