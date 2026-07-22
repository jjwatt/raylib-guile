
GUILE_EXTENSIONDIR ?= $(shell pkg-config --variable=extensiondir guile-3.0 2>/dev/null)
GUILE_SITEDIR ?= $(shell pkg-config --variable=sitedir guile-3.0 2>/dev/null)

PREFIX ?= /usr/local
GUILE_EXTENSIONDIR := $(if $(GUILE_EXTENSIONDIR),$(GUILE_EXTENSIONDIR),$(PREFIX)/lib/guile/3.0/extensions)
GUILE_SITEDIR := $(if $(GUILE_SITEDIR),$(GUILE_SITEDIR),$(PREFIX)/share/guile/site/3.0)

all: libraylib-guile.so raylib.scm

install: all
	install -d $(DESTDIR)$(GUILE_EXTENSIONDIR)
	install -m 755 libraylib-guile.so $(DESTDIR)$(GUILE_EXTENSIONDIR)
	install -d $(DESTDIR)$(GUILE_SITEDIR)
	install -m 644 raylib.scm $(DESTDIR)$(GUILE_SITEDIR)

libraylib-guile.so: raylib-guile.c
	$(CC) $(CFLAGS) `pkg-config --cflags guile-3.0 raylib` -shared -o $@ -fPIC $^ `pkg-config --libs raylib` $(LDFLAGS)

raylib.scm raylib-guile.c: raylib_api.xml generate-bindings.scm
	guile ./generate-bindings.scm $<

raylib_api.xml:
	wget "https://raw.githubusercontent.com/raysan5/raylib/`cat VERSION`/parser/output/raylib_api.xml"

clean:
	rm raylib-guile.c libraylib-guile.so raylib.scm -f

.PHONY: clean all install
