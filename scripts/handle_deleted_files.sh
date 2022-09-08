"""
Functionality for handling deleted files from the repository. Once a file is deleted, the csvcubed build and inspect command outputs generated for that file will also be deleted.
"""

echo "::set-output name=has_outputs::false"

echo "Input argument: $1"
IFS=', ' read -r -a deleted_files <<<"$1"
echo "deleted_files: ${deleted_files[@]}"

for file in "${deleted_files[@]}"; do
  file_path="${file%.*}"
  file_name="${file_path##*/}"
  file_extension="${file##*.}"

  if [[ $file_extension == "csv" && "${file_path}" != *"out/"* ]]; then
    echo $'\n'
    echo "Handling deletions for file ${file}"
    config_file="${file_path}.${file_extension}.json"
    out_folder="out/${file_path}/"

    if [[ -f $config_file ]]; then
      git rm $config_file
      git commit -m "Deleted out folder for file ${file} - $(date +'%d-%m-%Y at %H:%M:%S')"
    fi

    if [[ -d $out_folder ]]; then
      git rm -r $out_folder
      git commit -m "Deleted out folder for file ${file} - $(date +'%d-%m-%Y at %H:%M:%S')"
    fi

    git push

    echo "Finished handling deletions for file ${file}"
    echo "::set-output name=has_outputs::true"
  fi
done
