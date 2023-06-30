#!/bin/sh

################################################################################
#
# CONFIGURE.sh - Generate Makefile from Makefile.template
#
################################################################################

################################################################################
# Initial configuration
################################################################################

# === Boilerplate ==============================================================
set -eu
umask 0022
export LC_ALL=C
if _posix_path="$( command -p getconf PATH 2>/dev/null)"; then
	export PATH="$_posix_path:${PATH+:}${PATH:-}"
fi
export POSIXLY_CORRECT=1 # make GNU POSIX-compatible
export UNIX_STD=2003     # make HP-UX POSIX-compatible

# === Functions ================================================================
usage(){
	cat <<-USAGE 1>&2
	Usage: ${0##*/}
USAGE
	exit 1
}

error_exit(){
	${2+:} false && echo "${0##*/}: $2" 1>&2
	exit $1
}

################################################################################
# WHAT?
################################################################################

################################################################################
# Main routine
################################################################################

# === Goto current path ========================================================

# === List shell scripts to be installed =======================================
to_be_exported=''
for x in ./*; do
	# They have to be executable shell script
	([ -f "$x" ] && [ -x "$x" ]) || continue

	# Must not be myself
	case "${x##*/}" in "${0##*/}") continue;; esac

	# Finally it can be listed
	x="${x##*/}"
	to_be_exported="$to_be_exported $x"
done

# === Replace templates ========================================================
cat Makefile.template |
sed 's|@TARGET@|'"$to_be_exported"'|g' \
> Makefile.tmp

mv Makefile.tmp Makefile

################################################################################
# Finally
################################################################################
exit 0
