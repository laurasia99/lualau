# lualau
Custom Lua build (static; removing dynamic loading)

The primary goal of this build is to create a minimal [lua](https://www.lua.org/home.html) distribution that can run with a single binary.
It includes the following libraries:
- [linenoise](https://github.com/antirez/linenoise) (adding command line history)
- [luafilesystem](https://github.com/keplerproject/luafilesystem) (supporting scripting)
- [luasockets](https://github.com/lunarmodules/luasocket) (supporting networking)

This build *removes* package.loadlib(), and all dynamic library support, as supporting dynamic
loading of binary modules is contrary to having a minimal lua distribution and a single binary.
It also reduces the risk of insecure code being inadvertently loaded.

The build process places intermediate object files into a separate directory (obj/).
Hence, cleaning a build is as simple as 'rm -rf obj'.

Modified source code is located in the lau/ subdirectory. Currently the only modifications
have been to the following core lua-5.4.4 files:
- linit.c (adding support for statically linking to luafilesystem and luasockets)
- loadlib.c (removing dynamic library support)
- lua.c (adding support for linenoise)

The script `fetch` downloads the original sources, and does a tiny bit of scrubbing to remove
build/distributions files from those packages. It runs on unix-like systems via `sh fetch`.
The provided Makefile is relatively simple; `make` should suffice to build the `lua` binary
(which is placed in the root directory, along with the `luac` binary).

***This build has not been extensively tested*** - use with caution.
It has currently only been built within WSL (Windows Subsystem for Linux).

## What makes a 1.0 release?

My goals are to use this build for 6-months (or at least until I'm comfortable with it),
to identify if there is any core functionality missing, and that I can't live without.
I might add libraries to support date and time operations and reading/writing CSV files
- but no guarantee. My preference is to minimise both the number of external dependencies
and the amount of C code.

As noted above I have only built this within WSL. I'll need to support a native Windows
build (using the command line version of Visual C++) before I tag this as a release.

## Infrequently asked questions

1. Why don't you support libfroz? I really need it...

As noted above, this is an *opinionated* lua build. The decisions I make might not be
approprate for what you want to do. However, you have my full blessing to take this
code and modify it to do whatever you want (subject to complying with all of the
licenses).

2. What software licenses are being used?

The licences of this software and the components are:
- MIT -- [lua](https://www.lua.org/license.html), luafilesystem, luasockets, lualau
- BSD 2 clause -- linenoise


