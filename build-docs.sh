#!/bin/bash

# Exit on error
set -eu -o pipefail
set -x

# Source: https://stackoverflow.com/questions/35800082/how-to-trap-err-when-using-set-e-in-bash
trap 'echo >&2 "Error - exited with status $? at line $LINENO.";' ERR

source ./env/bin/activate

nav_files=$(cat ./mkdocs.yml | yq -r '[.nav | .. | strings] | map(select(. | endswith(".md"))) | .[]')

target_en_dir="$(readlink -f "./site")/en"
pushd help/
  # Get all directories that contain two characters (language code)
  lang_dirs=??

  for lang in $lang_dirs; do
      echo "Building docs for $lang"
      target_dir="$(readlink -f "../site")/$lang"
      pushd $lang
        mkdocs build --clean --site-dir "$target_dir"
        # TODO: rather make a doc-not-localized.md doc and copy the html file
        # if [ "$lang" != "en" ]; then
        #   # suggest the user the en page if the page is not translated
        #   for nav_file in $nav_files; do
        #     if [ ! -f "$target_dir/$nav_file" ]; then
        #       mkdir -p "$(dirname "$target_dir/$nav_file")"
        #       echo -e "## Oops, this page is not translated yet.\n\nPlease read the [English version](/en/${nav_file/%\.md/}) instead." > "$target_dir/$nav_file"
        #     fi
        #   done
        # fi
      popd
  done
popd
echo "moving english site to root"
rsync -av --inplace "$target_en_dir"/* ./site/
echo "Copying assets"
rsync -av --inplace "./help/assets/"* "./site/"
