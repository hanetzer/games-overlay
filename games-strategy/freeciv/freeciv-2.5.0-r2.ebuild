# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5
inherit eutils gnome2-utils

DESCRIPTION="multiplayer strategy game (Civilization Clone)"
HOMEPAGE="http://www.freeciv.org/"
SRC_URI="mirror://sourceforge/freeciv/${P}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~ppc ~ppc64 ~x86"
IUSE="auth aimodules dedicated +gtk ipv6 mapimg modpack mysql nls postgres qt5 readline sdl +server +sound sqlite"

RDEPEND="app-arch/bzip2
	app-arch/xz-utils
	net-misc/curl
	sys-libs/zlib
	auth? (
		mysql? ( virtual/mysql )
		postgres? ( virtual/postgresql )
		sqlite? ( dev-db/sqlite:3 )
		!mysql? ( !postgres? ( !sqlite? ( virtual/mysql ) ) )
	)
	readline? ( sys-libs/readline:0 )
	dedicated? ( aimodules? ( dev-libs/libltdl:0 ) )
	!dedicated? (
		media-libs/libpng:0
		gtk? ( x11-libs/gtk+:3 )
		mapimg? ( media-gfx/imagemagick )
		modpack? ( x11-libs/gtk+:3 )
		nls? ( virtual/libintl )
		qt5? (
			dev-qt/qtcore:5
			dev-qt/qtgui:5
			dev-qt/qtwidgets:5
		)
		sdl? (
			media-libs/libsdl[video]
			media-libs/sdl-gfx
			media-libs/sdl-image[png]
			media-libs/sdl-ttf
		)
		server? ( aimodules? ( sys-devel/libtool:2 ) )
		sound? (
			media-libs/libsdl[sound]
			media-libs/sdl-mixer[vorbis]
		)
		!sdl? ( !gtk? ( x11-libs/gtk+:3 ) )
	)"
DEPEND="${RDEPEND}
	virtual/pkgconfig
	!dedicated? (
		x11-proto/xextproto
		nls? ( sys-devel/gettext )
	)"

pkg_setup() {
	if use !dedicated && use !server ; then
		ewarn "Disabling server USE flag will make it impossible"
		ewarn "to start local games, but you will still be able to"
		ewarn "join multiplayer games."
	fi
}

src_prepare() {
	# install the .desktop in /usr/share/applications
	# install the icons in /usr/share/pixmaps
	sed -i \
		-e 's:^.*\(desktopfiledir = \).*:\1/usr/share/applications:' \
		-e 's:^\(icon[0-9]*dir = \)$(prefix)\(.*\):\1/usr\2:' \
		-e 's:^\(icon[0-9]*dir = \)$(datadir)\(.*\):\1/usr/share\2:' \
		client/Makefile.in \
		server/Makefile.in \
		tools/Makefile.in \
		data/Makefile.in \
		data/icons/Makefile.in || die
	sed -i -e 's/=SDL/=X-SDL/' bootstrap/freeciv-sdl.desktop.in || die
}

src_configure() {
	local myclient myopts mydatabase

	if use auth ; then
		if use !mysql && use !postgres && use !sqlite ; then
			einfo "No database backend chosen, defaulting"
			einfo "to mysql!"
			mydatabase=mysql
		else
			use mysql && mydatabase="${mydatabase} mysql"
			use postgres && mydatabase="${mydatabase} postgres"
			use sqlite && mydatabase="${mydatabase} sqlite3"
		fi
	else
		mydatabase=no
	fi

	if use dedicated ; then
		myclient="no"
		myopts="--enable-server"
	else
		if use !sdl && use !gtk && use !qt5 ; then
			einfo "No client backend given, defaulting to"
			einfo "gtk3 client!"
			myclient="gtk3"
		else
			use sdl && myclient="${myclient} sdl"
			use gtk && myclient="${myclient} gtk3"
			use qt5 && myclient="${myclient} qt"
		fi
		myopts="$(use_enable server) --without-ggz-client"
	fi

	# disabling shared libs will break aimodules USE flag
	econf \
		--docdir="/usr/share/doc/${P}" \
		--localedir=/usr/share/locale \
		$(use_enable ipv6) \
		$(use_enable mapimg) \
		--enable-aimodules="$(usex aimodules "yes" "no")" \
		--enable-shared \
		--enable-fcdb="${mydatabase}" \
		$(use_enable nls) \
		$(use_with readline) \
		$(use_enable sound sdl-mixer) \
		--enable-fcmp="$(usex modpack "gtk3" "no")" \
		--disable-sys-lua \
		${myopts} \
		--enable-client="${myclient}"
}

src_install() {
	emake DESTDIR="${D}" install

	if use dedicated ; then
		rm -rf "${D}/usr/share/pixmaps"
		rm -f "${D}"/usr/share/man/man6/freeciv-{client,gtk2,gtk3,qt,modpack,sdl,xaw}*
	else
		if use server ; then
			# Create and install the html manual. It can't be done for dedicated
			# servers, because the 'freeciv-manual' tool is then not built. Also
			# delete freeciv-manual from /usr/bin, because it's useless.
			# Note: to have it localized, it should be ran from _postinst, or
			# something like that, but then it's a PITA to avoid orphan files...
			./tools/freeciv-manual || die
			dohtml manual*.html
		fi
		if use sdl ; then
			make_desktop_entry freeciv-sdl "Freeciv (SDL)" freeciv-client
		else
			rm -f "${D}"/usr/share/man/man6/freeciv-sdl*
		fi
		rm -f "${D}"/usr/share/man/man6/freeciv-xaw*
	fi
	find "${D}" -name "freeciv-manual*" -delete

	prune_libtool_files
}

pkg_preinst() {
	gnome2_icon_savelist
}

pkg_postinst() {
	gnome2_icon_cache_update
}

pkg_postrm() {
	gnome2_icon_cache_update
}
