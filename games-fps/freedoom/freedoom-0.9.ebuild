# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5

PYTHON_COMPAT=( python2_7 )
inherit eutils python-any-r1

DESCRIPTION="Freedoom - Open Source Doom resources"
HOMEPAGE="http://www.nongnu.org/freedoom/"
SRC_URI="https://github.com/freedoom/freedoom/archive/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64 ~ppc ~x86"
IUSE=""

DEPEND="${PYTHON_DEPS}
	media-gfx/imagemagick
	games-util/deutex
"

src_install() {
	insinto /usr/share/doom-data/${PN}
	doins wads/*.wad
	einstalldocs
}

pkg_postinst() {
	elog "A Doom engine is required to play the wad"
	elog "but games-fps/doomsday doesn't count since it doesn't"
	elog "have the necessary features."
	echo
	ewarn "To play freedoom with Doom engines which do not support"
	ewarn "subdirectories, create symlinks by running the following:"
	ewarn "(Be careful of overwriting existing wads.)"
	ewarn
	ewarn "   cd /usr/share/doom-data"
	ewarn "   for f in doom{1,2} freedm ; do"
	ewarn "       ln -sn freedoom/\${f}.wad"
	ewarn "   done"
}
