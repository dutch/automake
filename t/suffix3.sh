#! /bin/sh
# Copyright (C) 1999-2012 Free Software Foundation, Inc.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Test to make sure that suffix rules chain.

required=c++
. ./defs || Exit 1

cat >> configure.ac << 'END'
AC_PROG_CXX
AC_OUTPUT
END

cat > Makefile.am << 'END'
%.cc: %.zoo
	sed 's/INTEGER/int/g' $< >$@
bin_PROGRAMS = foo
foo_SOURCES = foo.zoo
# This is required by "make distcheck".  The useless indirection is
# reequired to avoid false positives by the grepping checks below.
FOO = foo
CLEANFILES = $(FOO).cc
END

$ACLOCAL
$AUTOMAKE

# The foo.cc intermediate step is implicit, it's a mistake if
# Automake requires this file somewhere.  Also, Automake should
# not require the file 'foo.c' anywhere.
$FGREP foo.c Makefile.in && Exit 1
# However Automake must figure that foo.zoo is eventually
# transformed into foo.o, and use this latter file (to link foo).
$FGREP 'foo.$(OBJEXT)' Makefile.in
# Finally, our dummy package doesn't use C in any way, so it the
# Makefile shouldn't contain stuff related to the C compiler.
$FGREP '$(LINK)'   Makefile.in && Exit 1
$FGREP 'AM_CFLAGS' Makefile.in && Exit 1
$FGREP '$(CFLAGS)' Makefile.in && Exit 1
$FGREP '$(CC)'     Makefile.in && Exit 1


$AUTOCONF
./configure

# This is deliberately valid C++, but invalid C.
cat > foo.zoo <<'END'
using namespace std;
INTEGER main (void)
{
  return 0;
}
END

$MAKE all
$MAKE distcheck

# TODO: should we check that intermediate file 'foo.cc' has
# been removed?  Or is this requiring too much from the make
# implementation?

# Intermediate files should not be distributed.
$MAKE distdir
test ! -r $me-1.0/foo.cc

: