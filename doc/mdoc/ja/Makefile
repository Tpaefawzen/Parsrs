.POSIX:

################################################################################
#
# doc/mdoc/ja/Makefile
#
# Copyright (C) 2023 Tpaefawzen
#
# Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted, provided that the above copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED “AS IS” AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
#
################################################################################

.SUFFIXES:

TARGET = Parsrs.1

all: $(TARGET)

shutup:
	rm -f $(TARGET)

install: _unimplemented

uninstall: _unimplemented

mostlyclean: _unimplemented

distclean: _unimplemented

test: _unimplemented

check: _unimplemented

dist: $(TARGET)
	mkdir -p dist/
	mv $(TARGET) dist/

clean: _unimplemented
	rm -Rf *.sh~ *[!.]~ *.1~

_unimplemented:
	@ ! echo unimplemented 1>&2

.SUFFIXES: .in.1 .1
.in.1.1:
	sh ./eliminate-atmarks.sh <$< >$@
