# Builds the native (C) ERGM MCMC kernel (harmonisation unit 83,
# docs/CERTIFICATION.md) as a Stata plugin. See ../docs/ERGM_ARCHITECTURE.md's
# "Native (C) MCMC backend" section for the full design and
# ergm_mcmc.c's own header comment for the evidence behind it.
#
# Output: ../lib/plugins/ergm_mcmc.plugin - unw_ergm.do's own
# ErgmNativeAvailable()/ErgmNativePluginPath() look for exactly this
# path (relative to the installed nwergm.ado's own directory), and
# gracefully fall back to the pure-Mata backend when it is absent - so
# a platform this Makefile has not been run on (or cannot target) is
# simply not accelerated, never broken.
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
# --- Windows (NOT built or verified in this repository - no Windows
#     toolchain was available in the environment this unit was built
#     in; documented here, per this unit's own explicit cross-platform
#     requirement, so a Windows-side build is a single documented
#     command away rather than an unknown gap) ---
#
#   From a Visual Studio "x64 Native Tools" command prompt:
#     cl /LD /DSYSTEM=STWIN32 /I spi ergm_mcmc.c spi\stplugin.c ^
#        /Fe:..\lib\plugins\ergm_mcmc.plugin
#
# --- Linux (NOT built or verified in this repository - same reason as
#     Windows above) ---
#
#   gcc -shared -fPIC -DSYSTEM=OPUNIX -Ispi -O2 -o \
#       ../lib/plugins/ergm_mcmc_unix.plugin ergm_mcmc.c spi/stplugin.c -ldl
#
#   (Stata expects a Unix plugin named "<progname>_unix.plugin" specifically
#   - unlike the Mac ".plugin" and Windows ".dll" conventions, per Stata's
#   own plugin-loading documentation at stata.com/plugins/.)

CC = clang
CFLAGS = -O2 -Wall -Ispi
OUT = ../lib/plugins/ergm_mcmc.plugin

.PHONY: macos clean

macos:
	$(CC) -bundle -o ergm_mcmc.x86_64 ergm_mcmc.c spi/stplugin.c \
		-DSYSTEM=APPLEMAC -target x86_64-apple-macos10.11 $(CFLAGS)
	$(CC) -bundle -o ergm_mcmc.arm64 ergm_mcmc.c spi/stplugin.c \
		-DSYSTEM=APPLEMAC -target arm64-apple-macos11 $(CFLAGS)
	lipo -create -output $(OUT) ergm_mcmc.x86_64 ergm_mcmc.arm64
	codesign -s - $(OUT)
	rm -f ergm_mcmc.x86_64 ergm_mcmc.arm64
	@echo "Built $(OUT)"
	@file $(OUT)

clean:
	rm -f ergm_mcmc.x86_64 ergm_mcmc.arm64 $(OUT)
