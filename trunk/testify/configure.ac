# ====================================================================
# Copyright 2005 Ken Coar
# All rights reserved.
#
# The use and distribution of this code or document is
# governed by version 2.0 of the Apache licence, which may
# be found online at
#  <URL:http://www.apache.org/licenses/LICENSE-2.0>.
# There should also be a copy accompanying this package, in
# a file named LICENCE.
#
# $Id: configure.ac,v 1.1 2005/06/01 23:36:45 coar Exp $
#

AC_INIT(testify,0.1)
AC_CONFIG_AUX_DIR(buildtools/)

#
# Our own macros.
#
sinclude(acinclude.m4)

MP_CONFIGURE_COMMAND(CONFIGURE_CMDLINE)
AC_SUBST(CONFIGURE_CMDLINE)
MP_CONFIG_NICE(config.nice)

#
# Checks for strings.
#
AC_MSG_CHECKING(package version)
PACKAGE_VERSION=`grep -i 'Package version:' MANIFEST | cut -d: -f2 | sed -e 's,[ \t],,g;'`
PACKAGE_VERSION=`eval echo ${PACKAGE_VERSION}`
AC_MSG_RESULT(${PACKAGE_VERSION})
AC_SUBST(PACKAGE_VERSION)

#
# Figure out the files that are part of the distribution.
#
PACKAGE_FILES=`sed -e '1,/Package files:/d ; /^#$/,$d' < MANIFEST | sed -e 's/^# *//g;'`
PACKAGE_FILES=`eval echo ${PACKAGE_FILES}`
AC_SUBST(PACKAGE_FILES)

#
# Checks for programs.
#
AC_PROG_INSTALL
AC_PATH_PROG(PERL, perl, "NOT-FOUND")
if test "x${ac_cv_path_PERL}" = "xNOT-FOUND" ; then
        AC_MSG_ERROR(Perl interpreter not found; unable to continue)
fi
AC_SUBST(PERL)

#
# Check options
#
AC_ARG_WITH(cms,
[  --with-cms=engine        Back-end content management system to use to
                           store results.  CVS, SVN, or SUBVERSION (case-
                           insensitive.],
[
    if test "$with_val" = "no" ; then
       AC_MSG_RESULT(none)
       AC_MSG_ERROR(You must specify a valid storage tool using --with-cms)
    fi
    CMSARG=`echo $withval | tr '[:upper:]' '[:lower:]'`
    case "$CMSARG" in
        cvs)
            CMS=cvs
            ;;
        svn|subversion)
            CMS=svn
            ;;
        *)
            AC_MSG_RESULT(none)
            AC_MSG_ERROR(Unrecognised storage engine $withval)
            ;;
    esac
    AC_MSG_RESULT($withval)
],
[
    AC_MSG_ERROR(You must specify a valid storage tool using --with-cms)
])
AC_SUBST(CMS)

##default="no"
##AC_ARG_ENABLE(history,
##[  --enable-history        Enable one-autoreply-per-time-t handling],
##[
##    if test "$enableval" = "no" ; then
##        AC_MSG_RESULT(no)
##    else
##        AC_MSG_RESULT(yes)
##    fi
##],
##[
##    AC_MSG_RESULT($default)
##    enableval=$default
##])
##ENABLE_HISTORY=$enableval
##if test "$ENABLE_HISTORY" = "yes" ; then
##    OPTION_HISTORY="1"
##else
##    OPTION_HISTORY="0"
##fi
##AC_SUBST(OPTION_HISTORY)
##
#
# Check for necessary Perl modules.
#
MP_REQUIRED_MODULES="Carp Data::Dumper Expect Fcntl Getopt::Long"
MP_REQUIRED_MODULES="$MP_REQUIRED_MODULES IO::Handle IO::Stty IPC::Open2"
MP_REQUIRED_MODULES="$MP_REQUIRED_MODULES MIME::Base64 POSIX Symbol"
MP_REQUIRED_MODULES="$MP_REQUIRED_MODULES Text::Abbrev"
#if test "$ENABLE_HISTORY" = "yes" ; then
#    MP_REQUIRED_MODULES="$MP_REQUIRED_MODULES SDBM_File Mail::Address"
#fi
MP_PERL_MODULE(${MP_REQUIRED_MODULES})
if test "x${mp_missing_pm}" != "x" ; then
        AC_MSG_WARN(Missing required Perl module(s): ${mp_missing_pm})
fi

AC_OUTPUT(testify Makefile)

#
# All done, say what we did.
#
##B=`eval echo ${bindir}` ; B=`eval echo ${B}`
##M=`eval echo ${mandir}` ; M=`eval echo ${M}`
##S=`eval echo ${ac_cv_path_SENDMAIL}` ; S=`eval echo ${S}`
##echo ""
##echo "autoresponder has been configured with the following options."
##echo ""
##echo "                 User binaries: ${B}"
##echo "                     Man pages: ${M}"
##echo "                      sendmail: ${S}"
##echo "     Perl interpreter location: ${ac_cv_path_PERL}"
##FL=
##for file in ${PACKAGE_FILES} ; do
##    if test -z "$FL" ; then
##        echo "         Files in distribution: ${file}"
##    else
##        echo "                                ${file}"
##    fi
##    FL="${FL} ${file}"
##done
##echo ""
##if test "x${mp_missing_pm}" != "x" ; then
##        echo "autoresponder requires the following Perl module(s):"
##        echo ""
##        echo "	${MP_REQUIRED_MODULES}"
##        echo ""
##        echo "configure was unable to find the following on your system:"
##        echo ""
##        echo "	${mp_missing_pm}"
##        echo ""
##        echo "You will need to install the missing module(s) before the"
##        echo "package will run."
##        echo ""
##fi
echo "Now run 'make install'."
