#!/bin/sh

arg1="$1"

script_dir=$(cd $(dirname "$0"); pwd)
pkg_name="se3-wpkg"

cd "$script_dir" || {
    echo "Error, impossible to change directory to $script_dir."
    echo "End of the script."
    exit 1
}

# Remove old *.deb files.
rm -rf "$script_dir/"*.deb

cp -ra "$script_dir/../sources" "$script_dir/$pkg_name"

if [ "$arg1" = "update-version" ]
then
    # Update the version number.
    commit_id=$(git log --format="%H" -n 1 | sed -r 's/^(.{10}).*$/\1/')
    epoch=$(date '+%s')
    # It's better to prefix by "0." to have a version number
    # lower than the version numbers of the stable and
    # official releases.
    version="0.${epoch}~${commit_id}"
    sed -i -r "s/^Version:.*$/Version: ${version}/" "$script_dir/se3-wpkg/DEBIAN/control"
fi

cd  "$script_dir/$pkg_name"
find ./ \( -name *.sh -o -name *.pl -o -name *.py \) -exec chmod +x {} \;

dh_clean
debuild -uc -us -b
# Cleaning.
rm -r "$script_dir/$pkg_name"


