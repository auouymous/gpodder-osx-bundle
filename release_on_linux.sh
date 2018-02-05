#!/bin/bash

usage="Usage: $0 /path/to/gpodder-x.y.z_w.deps.zip /path/to/gPodder/checkout"

if [ -z "$1" ] ; then
	echo "$usage"
	exit -1
elif [ ! -f "$1" ] ; then
	echo "$usage"
	echo
	echo "E: deps not found: $1 doesn't exist"
	echo "   get them from https://sourceforge.net/projects/gpodder/files/macosx/"
	exit -1
else
	deps="$1"
	shift
fi


if [ -z "$1" ] ; then
	echo "$usage"
	exit -1
elif [ ! -d "$1"/.git ] ; then
	echo "$usage"
	echo
	echo "E: gPodder checkout not found: $1/.git doesn't exist"
	echo "   git clone https://github.com/gpodder/gpodder.git \"${1}\""
	exit -1
else
	checkout="$1"
	shift
fi

set -x

me=$(readlink -e "$0")
mydir=$(dirname "$me")

# directory where the generated app and zip will end in
workspace="$mydir/_build"

app="$workspace"/gPodder.app

contents="$app"/Contents
resources="$contents"/Resources

mkdir -p "$workspace"
rm -Rf "$app"
cd "$workspace"
unzip "$deps"

if [ ! -e "$app" ] ; then
	echo "E: unzipping deps didn't generate $app"
	exit -1
fi

cd "$checkout"
export GPODDER_INSTALL_UIS="cli gtk"
make install DESTDIR="$resources/" PREFIX= PYTHON=python3

find "$app" -name '*.pyc' -delete
find "$app" -name '*.pyo' -delete
rm -Rf "$resources"/share/applications
rm -Rf "$resources"/share/dbus-1

# remove the check for DISPLAY variable since it's not used AND it's not
# available on Mavericks (see bug #1855)
(cd "$resources" && patch -p0 < "$mydir"/modulesets/patches/dont_check_display.patch)

# Command-XX shortcuts in gPodder menus 
/usr/bin/xsltproc -o menus.ui.tmp "$mydir"/misc/adjust-modifiers.xsl "$resources"/share/gpodder/ui/gtk/menus.ui
mv menus.ui.tmp "$resources"/share/gpodder/ui/gtk/menus.ui

# Set the version and copyright automatically
version=$(perl -ne "/__version__\\s*=\\s*'(.+)'/ && print \$1" "$checkout"/src/gpodder/__init__.py)
copyright=$(perl -ne "/__copyright__\\s*=\\s*'(.+)'/ && print \$1" "$checkout"/src/gpodder/__init__.py)
sed "s/@VERSION@/$version/g" "$mydir/misc/bundle/Info.plist" | sed "s/@COPYRIGHT@/$copyright/g" > "$contents"/Info.plist

# Copy the latest icons
cp "$checkout"/tools/mac-osx/icon.icns "$resources"/gPodder.icns

# release the thing
"$mydir"/release.sh "$app" "$version"