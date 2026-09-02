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
#   - saom_sim.c     nwsaom (SAOM) ministep/interval simulation kernel -
#                     see ../docs/SAOM_ROADMAP.md/ARCHITECTURE.md and
#                     saom_sim.c's own header. A separate initiative from
#                     nwergm/nwgraph above (see SAOM_ROADMAP.md's own
#                     coordination note) - added here as a third
#                     independent plugin target, touching neither of the
#                     other two targets below.
#   - dynam_sim.c    nwdynam (DyNAM) log-likelihood/gradient kernel -
#                     see ../docs/DYNAM_ROADMAP.md and dynam_sim.c's own
#                     header. A fourth independent plugin target,
#                     touching none of the three above - unlike
#                     ergm_mcmc.c/saom_sim.c (full sampling/simulation
#                     loops in C), this one accelerates only the hot
#                     inner likelihood/gradient evaluation Mata's own
#                     optimize() calls repeatedly; the optimizer itself
#                     stays in Mata.
#
# Output layout: ../lib/plugins/<platform>/<name>_<platform>.plugin - one
# subdirectory per platform (harmonisation unit 87) AND a platform suffix
# on every filename (harmonisation 2026-09-02, docs/CERTIFICATION.md).
# Both matter for a different reason: the per-platform subdirectory keeps
# this repo's own dev-mode lookup (a raw git checkout, `adopath ++
# <repo-root>`) working; the per-platform SUFFIX is what actually matters
# for a real `net install`, which flattens every package file into one
# shared PLUS folder by basename alone, discarding any subdirectory -
# without the suffix, macOS's and Windows's own binaries would both be
# named "<name>.plugin" and silently overwrite each other there (verified
# directly - see docs/CERTIFICATION.md's own account). Each plugin's own
# Mata-side dispatcher (unw_ergm.do's ErgmNativePluginPath(), unw_core.do's
# NativeGraphPluginPath(), etc.) tries `findfile()` on the platform-
# specific basename first (what a real net install needs), falling back to
# the subdirectory-relative path for the dev-checkout case, and gracefully
# falls back further to the pure-Mata implementation when a given
# platform's binary is absent altogether - so a platform this Makefile has
# not been run on (or cannot target) is simply not accelerated, never
# broken.
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
#   make macos-ergm_mcmc     make macos-nwgraph     make macos-saom_sim     make macos-dynam_sim     (build just one)
#
# --- Windows (built automatically by CI - see ../.github/workflows/
#     build-plugins.yml - once this repo lives on GitHub; NOT built or
#     verified directly in the environment this unit was authored in, no
#     Windows toolchain was available there) ---
#
#   From a Visual Studio "x64 Native Tools" command prompt, per plugin:
#     cl /LD /DSYSTEM=STWIN32 /I spi ergm_mcmc.c spi\stplugin.c ^
#        /Fe:..\lib\plugins\windows\ergm_mcmc_windows.plugin
#     cl /LD /DSYSTEM=STWIN32 /I spi nwgraph.c spi\stplugin.c ^
#        /Fe:..\lib\plugins\windows\nwgraph_windows.plugin
#     cl /LD /DSYSTEM=STWIN32 /I spi saom_sim.c spi\stplugin.c ^
#        /Fe:..\lib\plugins\windows\saom_sim_windows.plugin
#     cl /LD /DSYSTEM=STWIN32 /I spi dynam_sim.c spi\stplugin.c ^
#        /Fe:..\lib\plugins\windows\dynam_sim_windows.plugin
#
# --- Linux (built automatically by CI, same reason as Windows above -
#     no Linux toolchain/cross-compiler or Docker was available in the
#     environment this unit was authored in) ---
#
#   make unix                (builds every plugin)
#   make unix-ergm_mcmc        make unix-nwgraph      make unix-saom_sim      make unix-dynam_sim      (build just one)
#
#   (Stata expects a Unix plugin named "<progname>_unix.plugin"
#   specifically - unlike the Mac ".plugin" and Windows ".dll"/".plugin"
#   conventions, per Stata's own plugin-loading documentation at
#   stata.com/plugins/.)

CC = clang
CFLAGS = -O2 -Wall -Ispi

.PHONY: macos unix clean macos-ergm_mcmc macos-nwgraph macos-saom_sim macos-dynam_sim unix-ergm_mcmc unix-nwgraph unix-saom_sim unix-dynam_sim

macos: macos-ergm_mcmc macos-nwgraph macos-saom_sim macos-dynam_sim

macos-ergm_mcmc:
	mkdir -p ../lib/plugins/macos
	$(CC) -bundle -o ergm_mcmc.x86_64 ergm_mcmc.c spi/stplugin.c \
		-DSYSTEM=APPLEMAC -target x86_64-apple-macos10.11 $(CFLAGS)
	$(CC) -bundle -o ergm_mcmc.arm64 ergm_mcmc.c spi/stplugin.c \
		-DSYSTEM=APPLEMAC -target arm64-apple-macos11 $(CFLAGS)
	lipo -create -output ../lib/plugins/macos/ergm_mcmc_macos.plugin ergm_mcmc.x86_64 ergm_mcmc.arm64
	codesign -s - ../lib/plugins/macos/ergm_mcmc_macos.plugin
	rm -f ergm_mcmc.x86_64 ergm_mcmc.arm64
	@echo "Built ../lib/plugins/macos/ergm_mcmc_macos.plugin"
	@file ../lib/plugins/macos/ergm_mcmc_macos.plugin

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

macos-saom_sim:
	mkdir -p ../lib/plugins/macos
	$(CC) -bundle -o saom_sim.x86_64 saom_sim.c spi/stplugin.c \
		-DSYSTEM=APPLEMAC -target x86_64-apple-macos10.11 $(CFLAGS)
	$(CC) -bundle -o saom_sim.arm64 saom_sim.c spi/stplugin.c \
		-DSYSTEM=APPLEMAC -target arm64-apple-macos11 $(CFLAGS)
	lipo -create -output ../lib/plugins/macos/saom_sim_macos.plugin saom_sim.x86_64 saom_sim.arm64
	codesign -s - ../lib/plugins/macos/saom_sim_macos.plugin
	rm -f saom_sim.x86_64 saom_sim.arm64
	@echo "Built ../lib/plugins/macos/saom_sim_macos.plugin"
	@file ../lib/plugins/macos/saom_sim_macos.plugin

macos-dynam_sim:
	mkdir -p ../lib/plugins/macos
	$(CC) -bundle -o dynam_sim.x86_64 dynam_sim.c spi/stplugin.c \
		-DSYSTEM=APPLEMAC -target x86_64-apple-macos10.11 $(CFLAGS)
	$(CC) -bundle -o dynam_sim.arm64 dynam_sim.c spi/stplugin.c \
		-DSYSTEM=APPLEMAC -target arm64-apple-macos11 $(CFLAGS)
	lipo -create -output ../lib/plugins/macos/dynam_sim_macos.plugin dynam_sim.x86_64 dynam_sim.arm64
	codesign -s - ../lib/plugins/macos/dynam_sim_macos.plugin
	rm -f dynam_sim.x86_64 dynam_sim.arm64
	@echo "Built ../lib/plugins/macos/dynam_sim_macos.plugin"
	@file ../lib/plugins/macos/dynam_sim_macos.plugin

# Run only on an actual Linux host (or Linux CI runner) - `gcc -shared`
# targeting OPUNIX is meaningless cross-compiled from macOS without a
# genuine Linux sysroot/toolchain, which this development environment did
# not have.
unix: unix-ergm_mcmc unix-nwgraph unix-saom_sim unix-dynam_sim

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

unix-saom_sim:
	mkdir -p ../lib/plugins/unix
	gcc -shared -fPIC -DSYSTEM=OPUNIX $(CFLAGS) -o ../lib/plugins/unix/saom_sim_unix.plugin \
		saom_sim.c spi/stplugin.c -ldl
	@echo "Built ../lib/plugins/unix/saom_sim_unix.plugin"
	@file ../lib/plugins/unix/saom_sim_unix.plugin

unix-dynam_sim:
	mkdir -p ../lib/plugins/unix
	gcc -shared -fPIC -DSYSTEM=OPUNIX $(CFLAGS) -o ../lib/plugins/unix/dynam_sim_unix.plugin \
		dynam_sim.c spi/stplugin.c -ldl
	@echo "Built ../lib/plugins/unix/dynam_sim_unix.plugin"
	@file ../lib/plugins/unix/dynam_sim_unix.plugin

clean:
	rm -f ergm_mcmc.x86_64 ergm_mcmc.arm64 nwgraph.x86_64 nwgraph.arm64 saom_sim.x86_64 saom_sim.arm64 \
		dynam_sim.x86_64 dynam_sim.arm64 \
		../lib/plugins/macos/ergm_mcmc_macos.plugin ../lib/plugins/unix/ergm_mcmc_unix.plugin \
		../lib/plugins/macos/nwgraph_macos.plugin ../lib/plugins/unix/nwgraph_unix.plugin \
		../lib/plugins/macos/saom_sim_macos.plugin ../lib/plugins/unix/saom_sim_unix.plugin \
		../lib/plugins/macos/dynam_sim_macos.plugin ../lib/plugins/unix/dynam_sim_unix.plugin
