* Tutorial 1: Installation & Setup
* The installation commands from the tutorial. They download from GitHub
* and change your Stata installation, so run them once, on purpose.

net from "https://raw.githubusercontent.com/thomas-u-grund/nwcommands/main"
net install nwcommands
nwinstall, all

* Check what is installed
nwversion
