#!/bin/sh

set -eu
umask 0022
export LC_ALL=C
if type command && type getconf && POSIXPATH="$(command -p getconf PATH)"; then
  PATH="$POSIXPATH:$PATH"
fi >/dev/null 2>&1
