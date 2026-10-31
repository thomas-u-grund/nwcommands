nwcommands: C source of the native plugin and of the viewer launcher
=====================================================================

The core package runs the heavy graph algorithms (betweenness, motif and clique
counts, Burt's constraint and others) in a compiled Stata plugin (nwgraph), and the
network editor window is started by a small launcher (nwedit_viewer). The package
installs the compiled files for macOS, Linux and Windows; this file comes with the C
source they were built from. nwcommands is free software under the GNU General
Public License, version 3 (file LICENSE in the repository).

Where to get the source
  * In Stata:  net get nwcommands, from(https://nwcommands.org/net/)
    copies the files into the current directory. net get puts all files of a
    package into one folder; the build needs the layout of the repository (below).
  * On GitHub: https://github.com/thomas-u-grund/nwcommands, folder native/.

Files
  nwgraph.c                 the plugin; it includes the headers nwtypes.h, nwcomb.h, nwcomb2.h,
                            nwfast.h, nwfast2.h, nwburtw.h, nwbrokerage.h, nwbmotif_dict.h,
                            nwnative370.h, nwnative380.h and nwnative390.h
  nwedit_viewer.mm, nwedit_viewer_linux.c, nwedit_viewer_win.cpp   the viewer launcher (macOS, Linux, Windows)
  stplugin.c, stplugin.h    StataCorp's Stata Plugin Interface 3.0 (https://www.stata.com/plugins/),
                            redistributed unchanged; not part of nwcommands' own code
  makefile                  the build rules (Makefile in the repository; net get writes lower case names)

Layout needed for the build (as in the repository)
  native/nwgraph.c and the headers, native/Makefile
  native/spi/stplugin.c  native/spi/stplugin.h

Build the plugin
  The easiest way is  nwinstall, buildplugin(nwcommands)  in Stata (macOS and Linux): it fetches the
  source, compiles it on this computer and installs the plugin.
  By hand:
  macOS (universal binary):  cd native && make macos
  Linux:                     cd native && make unix
  Windows (Visual Studio x64 prompt, in native/):
      cl /LD /O2 /DSYSTEM=STWIN32 /I spi nwgraph.c spi\stplugin.c /Fe:..\lib\plugins\windows\nwgraph_windows.plugin
  The binaries are written to lib/plugins/<platform>/ next to the .ado files.
  The viewer launcher is built by the workflow .github/workflows/build-plugins.yml of the repository.
