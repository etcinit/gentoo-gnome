# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI="5"

inherit eutils multilib libtool flag-o-matic toolchain-funcs multilib-minimal

DESCRIPTION="Perl-compatible regular expression library"
HOMEPAGE="http://www.pcre.org/"
MY_P="pcre2-${PV/_rc/-RC}"
SRC_URI="ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/${MY_P}.tar.bz2"

LICENSE="BSD"
SLOT="3"
KEYWORDS="~alpha amd64 ~arm ~arm64 hppa ~ia64 ~m68k ~mips ~ppc ppc64 ~s390 ~sh ~sparc ~x86 ~ppc-aix ~amd64-fbsd ~sparc-fbsd ~x86-fbsd ~x64-freebsd ~x86-freebsd ~x86-interix ~amd64-linux ~arm-linux ~ia64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~m68k-mint ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris"
IUSE="bzip2 +cxx +jit libedit pcre16 pcre32 +readline +recursion-limit static-libs unicode zlib"
REQUIRED_USE="readline? ( !libedit )
	libedit? ( !readline )"

RDEPEND="bzip2? ( app-arch/bzip2 )
	zlib? ( sys-libs/zlib )
	libedit? ( dev-libs/libedit )
	readline? ( sys-libs/readline:0= )"
DEPEND="${RDEPEND}
	virtual/pkgconfig
	userland_GNU? ( >=sys-apps/findutils-4.4.0 )"
RDEPEND="${RDEPEND}
	abi_x86_32? (
		!<=app-emulation/emul-linux-x86-baselibs-20131008-r2
		!app-emulation/emul-linux-x86-baselibs[-abi_x86_32(-)]
	)"

S=${WORKDIR}/${MY_P}

MULTILIB_CHOST_TOOLS=(
	/usr/bin/pcre2-config
)

src_prepare() {
	local pc
	for pc in *.pc.in ; do
		echo "Libs.private: @PTHREAD_CFLAGS@" >> ${pc} #454478
	done
	elibtoolize
}

multilib_src_configure() {
	ECONF_SOURCE="${S}" econf \
		--with-match-limit-recursion=$(usex recursion-limit 8192 MATCH_LIMIT) \
		$(multilib_native_use_enable bzip2 pcre2grep-libbz2) \
		$(use_enable cxx cpp) \
		$(use_enable jit) $(use_enable jit pcre2grep-jit) \
		$(use_enable pcre16 pcre2-16) \
		$(use_enable pcre32 pcre2-32) \
		$(multilib_native_use_enable libedit pcre2test-libedit) \
		$(multilib_native_use_enable readline pcre2test-libreadline) \
		$(use_enable static-libs static) \
		$(use_enable unicode utf) $(use_enable unicode unicode-properties) \
		$(multilib_native_use_enable zlib pcre2grep-libz) \
		--enable-pcre2-8 \
		--enable-shared \
		--htmldir="${EPREFIX}"/usr/share/doc/${PF}/html \
		--docdir="${EPREFIX}"/usr/share/doc/${PF}
}

multilib_src_compile() {
	emake V=1 $(multilib_is_native_abi || echo "bin_PROGRAMS=")
}

multilib_src_install() {
	emake \
		DESTDIR="${D}" \
		$(multilib_is_native_abi || echo "bin_PROGRAMS= dist_html_DATA=") \
		install
	multilib_is_native_abi && gen_usr_ldscript -a pcre2-posix
}

multilib_src_install_all() {
	prune_libtool_files
}

pkg_preinst() {
	preserve_old_lib /$(get_libdir)/libpcre.so.0
}

pkg_postinst() {
	preserve_old_lib_notify /$(get_libdir)/libpcre.so.0
}
