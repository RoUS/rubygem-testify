dnl ====================================================================
dnl Copyright 2005 Ken Coar
dnl All rights reserved.
dnl
dnl The use and distribution of this code or document is
dnl governed by version 2.0 of the Apache licence, which may
dnl be found online at
dnl  <URL:http://www.apache.org/licenses/LICENSE-2.0>.
dnl There should also be a copy accompanying this package, in
dnl a file named LICENCE.
dnl
dnl $Id: acinclude.m4,v 1.1 2005/06/01 23:36:45 coar Exp $
dnl

dnl MP_PERL_MODULE(cpan::module [...])
dnl
dnl See if the specified module is available on the system in Perl's
dnl @INC path.  Perl must be installed (and have been checked for)
dnl or this will regard all as being unavailable.  Each module is
dnl checked separately, even if a list is provided.  The envariable
dnl 'mp_missing_pm' is updated if any modules are not found.
dnl
AC_DEFUN(MP_PERL_MODULE, [
    if test "x${mp_x_perl_was}" = "x" ; then
        AC_PATH_PROG(PERL, perl, "NOT-FOUND")
        mp_x_perl_was=${ac_cv_path_PERL}
    fi
    if test "x${mp_x_perl_was}" = "xNOT-FOUND" ; then
        mp_missing_pm="${mp_missing_pm} $*"
        mp_missing_pm=`eval echo ${mp_missing_pm}`
    else
        for mp_x_module in $* ; do
            AC_MSG_CHECKING(for Perl module ${mp_x_module})
            if ${mp_x_perl_was} -e "use ${mp_x_module};" 2> /dev/null ; then
                AC_MSG_RESULT(found)
            else
                AC_MSG_RESULT(not found)
                mp_missing_pm="${mp_missing_pm} ${mp_x_module}"
                mp_missing_pm=`eval echo ${mp_missing_pm}`
            fi
        done
    fi
])

dnl MP_CONFIGURE_COMMAND(envar-name)
dnl
dnl Store the ./configure command line in the specified environment variable.
dnl
AC_DEFUN(MP_CONFIGURE_COMMAND, [
    mp_private_string=[$]0
    for arg in "[$]@" ; do
        mp_private_string="$mp_private_string \"[$]arg\""
    done
    $1="$mp_private_string"
    export $1
])dnl

dnl MP_CONFIG_NICE(file)
dnl
dnl Store the ./configure command in the specified file for easy
dnl re-execution with the same options.
dnl
AC_DEFUN(MP_CONFIG_NICE, [
    rm -f $1
    echo '#! /bin/sh'			>> $1
    echo '#'				>> $1
    echo -n "# Created by "             >> $1
    echo "[$]0"         		>> $1
    echo '#'				>> $1
    echo "[$]0 \\"			>> $1
    for arg in "[$]@" ; do
        echo "    '[$]arg' \\"		>> $1
    done
    echo '    "[$]@"'			>> $1
    chmod +x $1
])dnl
