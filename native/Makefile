# Builds the core package's native (C) Stata plugin nwgraph.c (shared native
# graph-algorithm kernels, currently betweenness centrality) and documents how
# the nwedit_viewer launcher is built (see .github/workflows/build-plugins.yml).
# The model packages (nwergm, nwsaom, nwdynam, nwrem) build their own plugins in
# their own repositories.
#
# Output layout: ../lib/plugins/<platform>/<name>_<platform>.plugin. The platform
# suffix on every filename matters for a real `net install`, which flattens all
# package files into one PLUS folder by basename; the per-platform subdirectory
# keeps a raw git checkout (`adopath ++ <repo-root>`) working. The Mata-side
# dispatcher (unw_core.do's NativeGraphPluginPath()) tries findfile() on the
# platform-specific basename first, then the subdirectory path, then falls back
# to the pure-Mata implementation, so a platform without a binary is simply not
# accelerated, never broken.
#
# spi/stplugin.h and spi/stplugin.c are StataCorp's official Stata Plugin
# Interface (SPI) version 3.0 files, redistributed unchanged from
# https://www.stata.com/plugins/ - not this project's own code.
#
# macOS (universal binary, as in Stata's documented recipe):  make macos
# Linux (run on a Linux host or CI runner):                   make unix
# Windows (Visual Studio x64 Native Tools prompt):
#     cl /LD /DSYSTEM=STWIN32 /I spi nwgraph.c spi\stplugin.c ^
#        /Fe:..\lib\plugins\windows\nwgraph_windows.plugin

CC = clang
CFLAGS = -O2 -Wall -Ispi

.PHONY: macos unix clean macos-nwgraph unix-nwgraph

macos: macos-nwgraph

macos-nwgraph:
	mkdir -p ../lib/plugins/macos
	$(CC) -bundle -o nwgraph.x86_64 nwgraph.c spi/stplugin.c \
		-DSYSTEM=APPLEMAC -target x86_64-apple-macos10.11 $(CFLAGS)
	$(CC) -bundle -o nwgraph.arm64 nwgraph.c spi/stplugin.c \
		-DSYSTEM=APPLEMAC -target arm64-apple-macos11 $(CFLAGS)
	lipo -create -output ../lib/plugins/macos/nwgraph_macos.plugin nwgraph.x86_64 nwgraph.arm64
	codesign -s - ../lib/plugins/macos/nwgraph_macos.plugin
	rm -f nwgraph.x86_64 nwgraph.arm64
	@echo "Built ../lib/plugins/macos/nwgraph_macos.plugin"
	@file ../lib/plugins/macos/nwgraph_macos.plugin

unix: unix-nwgraph

unix-nwgraph:
	mkdir -p ../lib/plugins/unix
	gcc -shared -fPIC -DSYSTEM=OPUNIX $(CFLAGS) -o ../lib/plugins/unix/nwgraph_unix.plugin \
		nwgraph.c spi/stplugin.c -ldl
	@echo "Built ../lib/plugins/unix/nwgraph_unix.plugin"
	@file ../lib/plugins/unix/nwgraph_unix.plugin

clean:
	rm -f nwgraph.x86_64 nwgraph.arm64 \
		../lib/plugins/macos/nwgraph_macos.plugin ../lib/plugins/unix/nwgraph_unix.plugin
