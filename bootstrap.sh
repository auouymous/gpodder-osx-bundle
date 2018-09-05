#!/bin/sh

set -e

source env.sh

# to allow bootstrapping again, try to delete everything first
rm -Rf "_jhbuild"
rm -Rf "_bundler"
rm -Rf "$HOME/.local"
rm -f "$HOME/.jhbuildrc"
rm -f "$HOME/.jhbuildrc-custom"

# https://git.gnome.org/browse/gtk-osx/tree/jhbuild-revision
JHBUILD_REVISION="7c8d34736c3804"

mkdir -p "$HOME"
git clone  https://gitlab.gnome.org/GNOME/jhbuild.git _jhbuild
# https://bugzilla.gnome.org/show_bug.cgi?id=766444
(cd _jhbuild && git checkout "$JHBUILD_REVISION" && \
	git am ../modulesets/patches/01_27891.patch ../modulesets/patches/02_327933.patch && \
	./autogen.sh && make -f Makefile.plain DISABLE_GETTEXT=1 install >/dev/null)
ln misc/gtk-osx-jhbuildrc "$HOME/.jhbuildrc"
ln misc/jhbuildrc-custom "$HOME/.jhbuildrc-custom"
git clone https://gitlab.gnome.org/GNOME/gtk-mac-bundler.git _bundler
(cd _bundler && make install)
