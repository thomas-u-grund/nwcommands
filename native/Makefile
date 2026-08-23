# Builds the native (C) ERGM MCMC kernel (harmonisation unit 83,
# docs/CERTIFICATION.md) as a Stata plugin. See ../docs/ERGM_ARCHITECTURE.md's
# "Native (C) MCMC backend" section for the full design and
# ergm_mcmc.c's own header comment for the evidence behind it.
#
# Output layout: ../lib/plugins/<platform>/ergm_mcmc*.plugin - one
# subdirectory per platform (harmonisation unit 87), not a single shared
# path, because macOS's and Windows's own plugins would otherwise both be
# named "ergm_mcmc.plugin" and collide at the same location once all three
# platforms' binaries ship from the same commit (built by separate CI
# runners - see ../.github/workflows/build-plugins.yml - not chosen
# one-at-a-time by a single developer's own machine). unw_ergm.do's own
# ErgmNativePluginPath()/ErgmNativePluginSubdir() pick the right
# subdirectory/filename for the running platform via c(os), and
# ErgmNativeAvailable() gracefully falls back to the pure-Mata backend when
# a given platform's binary is absent - so a platform this Makefile has not
# been run on (or cannot target) is simply not accelerated, never broken.
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
#   make macos
#
# --- Windows (built automatically by CI - see ../.github/workflows/
#     build-plugins.yml - once this repo lives on GitHub; NOT built or
#     verified directly in the environment this unit was authored in, no
#     Windows toolchain was available there) ---
#
#   From a Visual Studio "x64 Native Tools" command prompt:
#     cl /LD /DSYSTEM=STWIN32 /I spi ergm_mcmc.c spi\stplugin.c ^
#        /Fe:..\lib\plugins\windows\ergm_mcmc.plugin
#
# --- Linux (built automatically by CI, same reason as Windows above -
#     no Linux toolchain/cross-compiler or Docker was available in the
#     environment this unit was authored in) ---
#
#   make unix
#
#   (Stata expects a Unix plugin named "<progname>_unix.plugin"
#   specifically - unlike the Mac ".plugin" and Windows ".dll"/".plugin"
#   conventions, per Stata's own plugin-loading documentation at
#   stata.com/plugins/.)

CC = clang
CFLAGS = -O2 -Wall -Ispi
OUT = ../lib/plugins/macos/ergm_mcmc.plugin
OUT_UNIX = ../lib/plugins/unix/ergm_mcmc_unix.plugin

.PHONY: macos unix clean

macos:
	mkdir -p ../lib/plugins/macos
	$(CC) -bundle -o ergm_mcmc.x86_64 ergm_mcmc.c spi/stplugin.c \
		-DSYSTEM=APPLEMAC -target x86_64-apple-macos10.11 $(CFLAGS)
	$(CC) -bundle -o ergm_mcmc.arm64 ergm_mcmc.c spi/stplugin.c \
		-DSYSTEM=APPLEMAC -target arm64-apple-macos11 $(CFLAGS)
	lipo -create -output $(OUT) ergm_mcmc.x86_64 ergm_mcmc.arm64
	codesign -s - $(OUT)
	rm -f ergm_mcmc.x86_64 ergm_mcmc.arm64
	@echo "Built $(OUT)"
	@file $(OUT)

# Run only on an actual Linux host (or Linux CI runner) - `gcc -shared`
# targeting OPUNIX is meaningless cross-compiled from macOS without a
# genuine Linux sysroot/toolchain, which this development environment did
# not have.
unix:
	mkdir -p ../lib/plugins/unix
	gcc -shared -fPIC -DSYSTEM=OPUNIX $(CFLAGS) -o $(OUT_UNIX) \
		ergm_mcmc.c spi/stplugin.c -ldl
	@echo "Built $(OUT_UNIX)"
	@file $(OUT_UNIX)

clean:
	rm -f ergm_mcmc.x86_64 ergm_mcmc.arm64 $(OUT) $(OUT_UNIX)
