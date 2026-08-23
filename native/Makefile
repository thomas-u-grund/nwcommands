# Builds this package's native (C) Stata plugins:
#   - ergm_mcmc.c   the nwergm MCMC kernel (harmonisation unit 83,
#                    docs/CERTIFICATION.md). See
#                    ../docs/ERGM_ARCHITECTURE.md's "Native (C) MCMC
#                    backend" section and ergm_mcmc.c's own header.
#   - nwgraph.c      shared native graph-algorithm kernels (harmonisation
#                     unit 95, docs/CERTIFICATION.md; feasibility
#                     background in ../docs/NATIVE_GRAPH_LIBRARIES.md).
#                     Currently: betweenness centrality. See nwgraph.c's
#                     own header for scope and the evidence behind it.
#
# Output layout: ../lib/plugins/<platform>/<name>*.plugin - one
# subdirectory per platform (harmonisation unit 87), not a single shared
# path, because macOS's and Windows's own plugins would otherwise both be
# named "<name>.plugin" and collide at the same location once all three
# platforms' binaries ship from the same commit (built by separate CI
# runners - see ../.github/workflows/build-plugins.yml - not chosen
# one-at-a-time by a single developer's own machine). Each plugin's own
# Mata-side dispatcher (unw_ergm.do's ErgmNativePluginPath(), unw_core.do's
# NativeGraphPluginPath()) picks the right subdirectory/filename for the
# running platform via c(os), and gracefully falls back to the pure-Mata
# implementation when a given platform's binary is absent - so a platform
# this Makefile has not been run on (or cannot target) is simply not
# accelerated, never broken.
#
# spi/stplugin.h and spi/stplugin.c are StataCorp's own official Stata
# Plugin Interface (SPI) version 3.0 files, redistributed here exactly
# as published at https://www.stata.com/plugins/ for this purpose
# (StataCorp explicitly distributes them for third-party plugin
# developers to build against) - not this project's own code.
#
# --- macOS (built and verified on this development machine: Apple
#     Silicon; the -target flags below also produce an Intel slice,
#     combined into one universal binary via lipo, matching Stata's own
#     documented macOS plugin build recipe at stata.com/plugins/) ---
#
#   make macos              (builds every plugin)
#   make macos-ergm_mcmc     make macos-nwgraph     (build just one)
#
# --- Windows (built automatically by CI - see ../.github/workflows/
#     build-plugins.yml - once this repo lives on GitHub; NOT built or
#     verified directly in the environment this unit was authored in, no
#     Windows toolchain was available there) ---
#
#   From a Visual Studio "x64 Native Tools" command prompt, per plugin:
#     cl /LD /DSYSTEM=STWIN32 /I spi ergm_mcmc.c spi\stplugin.c ^
#        /Fe:..\lib\plugins\windows\ergm_mcmc.plugin
#     cl /LD /DSYSTEM=STWIN32 /I spi nwgraph.c spi\stplugin.c ^
#        /Fe:..\lib\plugins\windows\nwgraph.plugin
#
# --- Linux (built automatically by CI, same reason as Windows above -
#     no Linux toolchain/cross-compiler or Docker was available in the
#     environment this unit was authored in) ---
#
#   make unix                (builds every plugin)
#   make unix-ergm_mcmc        make unix-nwgraph      (build just one)
#
#   (Stata expects a Unix plugin named "<progname>_unix.plugin"
#   specifically - unlike the Mac ".plugin" and Windows ".dll"/".plugin"
#   conventions, per Stata's own plugin-loading documentation at
#   stata.com/plugins/.)

CC = clang
CFLAGS = -O2 -Wall -Ispi

.PHONY: macos unix clean macos-ergm_mcmc macos-nwgraph unix-ergm_mcmc unix-nwgraph

macos: macos-ergm_mcmc macos-nwgraph

macos-ergm_mcmc:
	mkdir -p ../lib/plugins/macos
	$(CC) -bundle -o ergm_mcmc.x86_64 ergm_mcmc.c spi/stplugin.c \
		-DSYSTEM=APPLEMAC -target x86_64-apple-macos10.11 $(CFLAGS)
	$(CC) -bundle -o ergm_mcmc.arm64 ergm_mcmc.c spi/stplugin.c \
		-DSYSTEM=APPLEMAC -target arm64-apple-macos11 $(CFLAGS)
	lipo -create -output ../lib/plugins/macos/ergm_mcmc.plugin ergm_mcmc.x86_64 ergm_mcmc.arm64
	codesign -s - ../lib/plugins/macos/ergm_mcmc.plugin
	rm -f ergm_mcmc.x86_64 ergm_mcmc.arm64
	@echo "Built ../lib/plugins/macos/ergm_mcmc.plugin"
	@file ../lib/plugins/macos/ergm_mcmc.plugin

macos-nwgraph:
	mkdir -p ../lib/plugins/macos
	$(CC) -bundle -o nwgraph.x86_64 nwgraph.c spi/stplugin.c \
		-DSYSTEM=APPLEMAC -target x86_64-apple-macos10.11 $(CFLAGS)
	$(CC) -bundle -o nwgraph.arm64 nwgraph.c spi/stplugin.c \
		-DSYSTEM=APPLEMAC -target arm64-apple-macos11 $(CFLAGS)
	lipo -create -output ../lib/plugins/macos/nwgraph.plugin nwgraph.x86_64 nwgraph.arm64
	codesign -s - ../lib/plugins/macos/nwgraph.plugin
	rm -f nwgraph.x86_64 nwgraph.arm64
	@echo "Built ../lib/plugins/macos/nwgraph.plugin"
	@file ../lib/plugins/macos/nwgraph.plugin

# Run only on an actual Linux host (or Linux CI runner) - `gcc -shared`
# targeting OPUNIX is meaningless cross-compiled from macOS without a
# genuine Linux sysroot/toolchain, which this development environment did
# not have.
unix: unix-ergm_mcmc unix-nwgraph

unix-ergm_mcmc:
	mkdir -p ../lib/plugins/unix
	gcc -shared -fPIC -DSYSTEM=OPUNIX $(CFLAGS) -o ../lib/plugins/unix/ergm_mcmc_unix.plugin \
		ergm_mcmc.c spi/stplugin.c -ldl
	@echo "Built ../lib/plugins/unix/ergm_mcmc_unix.plugin"
	@file ../lib/plugins/unix/ergm_mcmc_unix.plugin

unix-nwgraph:
	mkdir -p ../lib/plugins/unix
	gcc -shared -fPIC -DSYSTEM=OPUNIX $(CFLAGS) -o ../lib/plugins/unix/nwgraph_unix.plugin \
		nwgraph.c spi/stplugin.c -ldl
	@echo "Built ../lib/plugins/unix/nwgraph_unix.plugin"
	@file ../lib/plugins/unix/nwgraph_unix.plugin

clean:
	rm -f ergm_mcmc.x86_64 ergm_mcmc.arm64 nwgraph.x86_64 nwgraph.arm64 \
		../lib/plugins/macos/ergm_mcmc.plugin ../lib/plugins/unix/ergm_mcmc_unix.plugin \
		../lib/plugins/macos/nwgraph.plugin ../lib/plugins/unix/nwgraph_unix.plugin
