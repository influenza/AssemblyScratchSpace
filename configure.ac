dnl Initialization
AC_PREREQ([2.69])
AC_INIT([ASM Learning], [1], [ron@red83.net],, [])
dnl AC_USE_SYSTEM_EXTENSIONS must be called prior to any macros that use the
dnl C compile (such as AX_CHECK_COMPILE_FLAG below, or the CHECK_LIB calls)
AC_USE_SYSTEM_EXTENSIONS
AC_CONFIG_SRCDIR([src/hello-world/hello.asm])
AC_CONFIG_MACRO_DIR([m4/])

AM_INIT_AUTOMAKE([foreign no-exeext -Wall -Wno-override -Wno-extra-portability])
AM_SILENT_RULES([no])
AM_MAKEFLAGS="--jobs=8"
dnl Shopping List
AC_PROG_CC([gcc])
AC_PROG_INSTALL
AX_PROG_NASM
PKG_PROG_PKG_CONFIG

dnl AR warnings (see https://bugzilla.redhat.com/show_bug.cgi?id=1155273)
m4_divert_text([DEFAULTS], [: "${ARFLAGS=cr} ${AR_FLAGS=cr}"])

dnl Output
AC_CONFIG_FILES([Makefile
                 README.md
                 src/hello-world/Makefile])
AC_OUTPUT
