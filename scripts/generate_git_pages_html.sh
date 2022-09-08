"""
Functionality for generating the html page which will be published to GitHub Pages.
"""

echo "Input argument: $1"
echo "Input argument: $2"
echo "Input argument: $3"
echo "Input argument: $4"

username=$1
repo_name=$2
commit_id=$3
processed_out_files=$4

touch .nojekyll
touch index.html

cat >index.html <<EOL
<!doctype html>
<html>
  <head>
  </head>
  <body>
    <h3>CSV-Ws generated are as below. The latest commit id is ${commit_id}.</h3>
    <div id="files-container"></div>
    <script type="text/javascript">
      var html_str = "<ul>";
      var files = "${processed_out_files}".split(',');
      files.shift()
      files.sort()
      files.forEach(function(file) {
        file = file.replace("./","")
        link = "https://${username}.github.io/${repo_name}/"+file
        html_str += "<li>"+"<a href='"+ link + "'>"+file+"</a></li>";
      });
      html_str += "</ul>";
      document.getElementById("files-container").innerHTML = html_str;
    </script>
  </body>
</html>
EOL
