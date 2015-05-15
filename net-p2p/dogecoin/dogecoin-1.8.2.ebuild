# Distributed under the terms of the GNU General Public License v2

EAPI=5

DB_VER="5.1"

LANGS="ach af_ZA ar be_BY bg bs ca ca@valencia ca_ES cmn cs cy da de de_AT el_GR en eo es es_CL es_DO es_MX es_UY et eu_ES fa fa_IR fi fr fr_CA gl gu_IN he hi_IN hr hu id_ID it ja ka kk_KZ ko_KR ky la lt lv_LV ms_MY nb nl pam pl pt_BR pt_PT ro_RO ru sah sk sl_SI sq sr sv th_TH tr uk ur_PK uz@Cyrl vi vi_VN zh_CN zh_HK zh_TW"

inherit db-use eutils fdo-mime gnome2-utils kde4-functions qt4-r2

MyPV="${PV/_/-}"
MyPN="dogecoin"
MyP="${MyPN}-${MyPV}"

DESCRIPTION="P2P Internet currency favored by Shiba Inus worldwide"
HOMEPAGE="https://dogecoin.com/"
SRC_URI="https://github.com/${MyPN}/${MyPN}/archive/v${MyPV}.tar.gz -> ${MyP}.tar.gz"

LICENSE="MIT ISC GPL-3 LGPL-2.1 public-domain || ( CC-BY-SA-3.0 LGPL-2.1 )"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="$IUSE dbus cli daemon +hardened kde +qrcode qt4 qt5 test upnp wallet"

REQUIRED_USE="
	|| ( cli daemon qt4 qt5 )
	?? ( qt4 qt5 )
"

RDEPEND="
	>=dev-libs/boost-1.55[threads(+)]
	dev-libs/openssl:0[-bindist]
	dev-libs/protobuf
	qrcode? (
		media-gfx/qrencode
	)
	upnp? (
		net-libs/miniupnpc
	)
	wallet? (
		sys-libs/db:$(db_ver_to_slot "${DB_VER}")[cxx]
	)
	<=dev-libs/leveldb-1.16.0[-snappy]
	qt4? (
		dev-qt/qtgui:4
	)
	qt5? (
		dev-qt/qtgui:5
	)
	dbus? (
		qt4? (
			dev-qt/qtdbus:4
		)
		qt5? (
			dev-qt/qtdbus:5
		)
	)
"
DEPEND="${RDEPEND}
	>=app-shells/bash-4.1
"

DOCS="doc/README.md doc/release-notes.md"

S="${WORKDIR}/${MyP}"

src_prepare() {
	epatch "${FILESDIR}/0.9.0-sys_leveldb.patch"
	rm -rf src/leveldb

	local filt= yeslang= nolang=

	for ts in $(ls src/qt/locale/*.ts)
	do
		x="${ts/*bitcoin_/}"
		x="${x/.ts/}"
		if ! use "linguas_$x"; then
			nolang="$nolang $x"
			rm "$ts"
			filt="$filt\\|$x"
		else
			yeslang="$yeslang $x"
		fi
	done

	filt="bitcoin_\\(${filt:2}\\)\\.\(qm\|ts\)"
	sed "/${filt}/d" -i 'src/qt/dogecoin.qrc' || die
	sed "s/locale\/${filt}/dogecoin.qrc/" -i 'src/qt/Makefile.am' || die
	einfo "Languages -- Enabled:$yeslang -- Disabled:$nolang"

	./autogen.sh
}

src_configure() {
	OPTS=();
	
	if use qt5; then
		OPTS+=" --with-gui=qt5"
	elif use qt4; then
		OPTS+=" --with-gui"
	else
		OPTS+=" --without-gui"
	fi

	econf \
			--disable-ccache \
			--with-system-leveldb \
			$(use_with dbus qtdbus) \
			$(use_with upnp miniupnpc) $(use_enable upnp upnp-default) \
			$(use_with qrcode qrencode) \
			$(use_enable hardened hardening) \
			$(use_enable wallet) \
			$(use_enable test tests) \
			$(use_with cli) \
			$(use_with daemon) \
			${OPTS[@]}
}

src_test() {
        emake check
}


src_install() {
	emake DESTDIR="${D}" install

	insinto /usr/share/pixmaps
	newins "share/pixmaps/bitcoin.ico" "${PN}.ico"

	make_desktop_entry "${PN} %u" "dogecoin-qt" "/usr/share/pixmaps/${PN}.ico" "Qt;Network;P2P;Office;Finance;" "MimeType=x-scheme-handler/dogecoin;\nTerminal=false"

    dodoc doc/README.md
    dodoc doc/assets-attribution.md doc/tor.md

	if use qt4 || use qt5; then
		mv contrib/debian/manpages/bitcoin-qt.1 contrib/debian/manpages/dogecoin-qt.1
	    doman contrib/debian/manpages/dogecoin-qt.1
	fi
	if use daemon; then
		mv contrib/debian/manpages/bitcoind.1 contrib/debian/manpages/dogecoind.1
		doman contrib/debian/manpages/dogecoind.1
	fi

	mv contrib/debian/manpages/bitcoin.conf.5 contrib/debian/manpages/dogecoin.conf.5
	doman contrib/debian/manpages/dogecoin.conf.5

	if use kde; then
    	insinto /usr/share/kde4/services
	    doins contrib/debian/dogecoin-qt.protocol
	fi
}

update_caches() {
	gnome2_icon_cache_update
	fdo-mime_desktop_database_update
	buildsycoca
}

pkg_postinst() {
	update_caches
}

pkg_postrm() {
	update_caches
}
