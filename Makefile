# Customised Lua makefile
#  - statically link additional modules
#  -- luafilesystem
#  -- luasockets
#  -- lua-zlib
#
# This makefile builds objects into a separate directory, keeping the
# source directories 'clean'

# luaconf.h processes:
#  -DLUA_USE_LINUX  ->  LUA_USE_POSIX  LUA_USE_DLOPEN   + library -ldl
# By default, the standard LuaLau distribution disables LUA_USE_DLOPEN
# and removes package.loadlibrary()
USE_DLOPEN= -DLUA_NO_DYNAMIC_LOAD
LIB_DLOPEN=
#USE_DLOPEN= -DLUA_USE_DLOPEN
#LIB_DLOPEN= -ldl

# By default, use linenoise in preference to readline

# libsocket needs to know the Lua version
# XXX or maybe not - only used for establishing include path?
LUA_VERSION= 5.4


# == CHANGE THE SETTINGS BELOW TO SUIT YOUR ENVIRONMENT =======================
# See lua-<version>/doc/readme.html for installation and customization instructions.

# Your platform. See PLATS for possible values.
PLAT= guess

CC= gcc -std=gnu99
#CFLAGS= -O2 -Wall -Wextra -DLUA_COMPAT_5_3 $(SYSCFLAGS)
CFLAGS= -O2 -Wall -Wextra $(SYSCFLAGS)
LDFLAGS= $(SYSLDFLAGS)
LIBS= -lm $(SYSLIBS)

RM= rm -f
UNAME= uname

SYSCFLAGS=
SYSLDFLAGS=
SYSLIBS=

# Special flags for compiler modules (Lua core); -Os reduces code size.
CMCFLAGS= 

# Special flags for Zlib
ZLIBFLAGS= -D_LARGEFILE64_SOURCE=1 -DHAVE_HIDDEN

# Highlevel directories
O= obj
A= lau
L= lua-5.4.4/src
N= linenoise-1.0
F= luafilesystem-1_8_0/src
S= luasocket-3.0.0/src
Y= lua-zlib-1.2
Z= zlib-1.2.12

# == END OF USER SETTINGS -- NO NEED TO CHANGE ANYTHING BELOW THIS LINE =======

PLATS= guess aix bsd c89 freebsd generic linux linux-readline line-linenoise macosx mingw posix solaris

#LUA_A=	$O/liblua.a
CORE_O=	$O/lapi.o $O/lcode.o $O/lctype.o $O/ldebug.o $O/ldo.o $O/ldump.o $O/lfunc.o $O/lgc.o $O/llex.o $O/lmem.o $O/lobject.o $O/lopcodes.o $O/lparser.o $O/lstate.o $O/lstring.o $O/ltable.o $O/ltm.o $O/lundump.o $O/lvm.o $O/lzio.o $O/linenoise.o
LIB_O=	$O/lauxlib.o $O/lbaselib.o $O/lcorolib.o $O/ldblib.o $O/liolib.o $O/lmathlib.o $O/loadlib.o $O/loslib.o $O/lstrlib.o $O/ltablib.o $O/lutf8lib.o $O/linit.o
LFS_O=	$O/lfs.o
SOCK_O=	$O/luasocket.o $O/timeout.o $O/buffer.o $O/io.o $O/auxiliar.o $O/compat.o $O/options.o $O/inet.o $O/usocket.o $O/except.o $O/select.o $O/tcp.o $O/udp.o $O/mime.o
UNIXSOCK_O= $O/unixstream.o $O/unixdgram.o $O/unix.o $O/serial.o
ZLIB_O=	$O/adler32.o $O/crc32.o $O/deflate.o $O/infback.o $O/inffast.o $O/inflate.o $O/inftrees.o $O/trees.o $O/zutil.o $O/compress.o $O/uncompr.o $O/gzclose.o $O/gzlib.o $O/gzread.o $O/gzwrite.o
LUAZ_O=	$O/lua_zlib.o
BASE_O= $(CORE_O) $(LIB_O) $(LFS_O) $(SOCK_O) $(UNIXSOCK_O) $(ZLIB_O) $(LUAZ_O)

LUA_T=	lua
LUA_O=	$O/lua.o

LUAC_T=	luac
LUAC_O=	$O/luac.o

ALL_O= $(BASE_O) $(LUA_O) $(LUAC_O)
ALL_T= $(LUA_T) $(LUAC_T)

# Targets start here.
default: objdir $(PLAT)

all:	$(ALL_T)

o:	$(ALL_O)

$(LUA_T): $(LUA_O) $(BASE_O)
	$(CC) -o $@ $(LDFLAGS) $(LUA_O) $(BASE_O) $(LIBS)

$(LUAC_T): $(LUAC_O) $(BASE_O)
	$(CC) -o $@ $(LDFLAGS) $(LUAC_O) $(BASE_O) $(LIBS)

test:
	./$(LUA_T) -v

clean:
	$(RM) $(ALL_T) $(ALL_O)

objdir:
	[ -d $O ] || mkdir -p $O

echo:
	@echo "PLAT= $(PLAT)"
	@echo "CC= $(CC)"
	@echo "CFLAGS= $(CFLAGS)"
	@echo "LDFLAGS= $(LDFLAGS)"
	@echo "LIBS= $(LIBS)"
	@echo "RM= $(RM)"
	@echo "UNAME= $(UNAME)"

# Convenience targets for popular platforms.
ALL= all

help:
	@echo "Do 'make PLATFORM' where PLATFORM is one of these:"
	@echo "   $(PLATS)"
	@echo "See lau-<version>/doc/readme.html for complete instructions."

guess:
	@echo Guessing `$(UNAME)`
	@$(MAKE) `$(UNAME)`

AIX aix:
	$(MAKE) $(ALL) CC="xlc" CFLAGS="-O2 -DLUA_USE_POSIX $(USE_DLOPEN)" SYSLIBS="$(LIB_DLOPEN)" SYSLDFLAGS="-brtl -bexpall"

bsd:
	$(MAKE) $(ALL) SYSCFLAGS="-DLUA_USE_POSIX $(USE_DLOPEN)" SYSLIBS="-Wl,-E"

c89:
	$(MAKE) $(ALL) SYSCFLAGS="-DLUA_USE_C89" CC="gcc -std=c89"
	@echo ''
	@echo '*** C89 does not guarantee 64-bit integers for Lua.'
	@echo '*** Make sure to compile all external Lua libraries'
	@echo '*** with LUA_USE_C89 to ensure consistency'
	@echo ''

FreeBSD NetBSD OpenBSD freebsd:
	$(MAKE) $(ALL) SYSCFLAGS="-DLUA_USE_POSIX $(USE_DLOPEN) -DLUA_USE_READLINE -I/usr/include/edit" SYSLIBS="-Wl,-E -ledit" CC="cc"

generic: $(ALL)

Linux linux:	linux-linenoise

linux-noreadline:
	$(MAKE) $(ALL) SYSCFLAGS="-DLUA_USE_POSIX $(USE_DLOPEN)" SYSLIBS="-Wl,-E $(LIB_DLOPEN)"

linux-readline:
	$(MAKE) $(ALL) SYSCFLAGS="-DLUA_USE_POSIX $(USE_DLOPEN) -DLUA_USE_READLINE" SYSLIBS="-Wl,-E $(LIB_DLOPEN) -lreadline"

linux-linenoise:
	$(MAKE) $(ALL) SYSCFLAGS="-DLUA_USE_POSIX $(USE_DLOPEN) -DLUA_USE_LINENOISE" SYSLIBS="-Wl,-E $(LIB_DLOPEN)"

Darwin macos macosx:
	$(MAKE) $(ALL) SYSCFLAGS="-DLUA_USE_MACOSX -DLUA_USE_READLINE" SYSLIBS="-lreadline"

mingw:
	$(MAKE) "LUA_A=lua54.dll" "LUA_T=lua.exe" \
	"AR=$(CC) -shared -o" "RANLIB=strip --strip-unneeded" \
	"SYSCFLAGS=-DLUA_BUILD_AS_DLL" "SYSLIBS=" "SYSLDFLAGS=-s" lua.exe
	$(MAKE) "LUAC_T=luac.exe" luac.exe

posix:
	$(MAKE) $(ALL) SYSCFLAGS="-DLUA_USE_POSIX"

SunOS solaris:
	$(MAKE) $(ALL) SYSCFLAGS="-DLUA_USE_POSIX $(USE_DLOPEN) -D_REENTRANT" SYSLIBS="$(LIB_DLOPEN)"

# Targets that do not create files (not all makes understand .PHONY).
.PHONY: all $(PLATS) help test clean default o a depend echo objdir

# Compiler modules may use special flags $(CMCFLAGS)
# llex.o lparser.o lcode.o

# (Utility)

# This is ugly, and prone to errors - CSRC must be manually updated
# whenever new source files are added; and the dependencies must also
# be manually update. Yuk!
CSRC= $S/ftp.lua $L/lapi.c $L/lauxlib.c $L/lbaselib.c $L/lcode.c \
	$L/lcorolib.c $L/lctype.c $L/ldblib.c $L/ldebug.c $L/ldo.c \
	$L/ldump.c $L/lfunc.c $L/lgc.c $A/linit.c $L/liolib.c $L/llex.c \
	$L/lmathlib.c $L/lmem.c $A/loadlib.c $L/lobject.c $L/lopcodes.c \
	$L/loslib.c $L/lparser.c $L/lstate.c $L/lstring.c $L/lstrlib.c \
	$L/ltable.c $L/ltablib.c $L/ltm.c $A/lua.c $L/luac.c $L/lundump.c \
	$L/lutf8lib.c $L/lvm.c $L/lzio.c $N/linenoise.c $F/lfs.c \
	$S/luasocket.c $S/timeout.c $S/buffer.c $S/io.c $S/auxiliar.c \
	$S/compat.c $S/options.c $S/inet.c $S/usocket.c $S/except.c \
	$S/select.c $S/tcp.c $S/udp.c $S/mime.c $S/unixstream.c \
	$S/unixdgram.c $S/unix.c $S/serial.c $Z/adler32.c $Z/crc32.c \
	$Z/deflate.c $Z/infback.c $Z/inffast.c $Z/inflate.c $Z/inftrees.c \
	$Z/trees.c $Z/zutil.c $Z/compress.c $Z/uncompr.c $Z/gzclose.c \
	$Z/gzlib.c $Z/gzread.c $Z/gzwrite.c $Y/lua_zlib.c

# Clean the generated makefile dependency rule, substituting variables for
# the paths, removing the .c file, and adding a $O prefix to the object file.
#
# *** Assumptions:
#       - All object files are placed into $O
#       - Include file paths are $L $F $S $Z   *** Extend as required
#       - Dependency rules generated by gcc are well-formed (rules start
#         with a graphical character in column 1; subsequent lines start
#         with a space; the C source file is the first dependency)
depend:
	gcc -c -MM $(CFLAGS) $(CSRC) -I$L -I$F -I$S -I$Z | \
	( echo "# Automatically generated `date`" ; \
	  sed -E -e s%$L%\$$L%g -e s%$F%\$$F%g -e s%$S%\$$S%g -e s%$Z%\$$Z%g \
		-e "s%: [^ ]*%:%" -e "s%^([[:graph:]])%\$$O/\\1%" ) > Makefile.dep

# Statically linked Lua code (from core LuaLau libraries) is currently
# embedded as raw strings. Each module has a name that is not necessarily
# the same as the file. For example, there is an implicit directory search
# when the module name contains a dot '.'. Since the embedding of the .lua
# code strips away the directory structure normally set by installing a
# library there must be another way of mapping file names to module names.
# Cannot rely on the shell supporting associative arrays, so kludge it:
#  - define variables lau_<basename>=<lua module name>
# This is ugly, but explicit.

$A/linit_src.ci: $S/ftp.lua $S/headers.lua $S/http.lua $S/ltn12.lua \
 $S/mbox.lua $S/mime.lua $S/smtp.lua $S/socket.lua $S/tp.lua $S/url.lua
	( P="" ; echo "/* Automatically generated `date` */" ; \
	lau_ftp=socket.ftp lau_http=socket.http lau_smtp=socket.smtp \
	lau_headers=socket.headers lau_tp=socket.tp lau_url=socket.url ; \
	for i in $^ ; do { \
	  echo "/* $$i */" ; p=`basename $$i .lua` ; P="$$P $$p" ; m=$$p \
	  eval m="\$$lau_$$p" ; [ -z $$m ] && eval m=$$p ; \
	  echo static const char lau_$$p[] = \"\\ ; \
	  (cat $$i ; echo "" ) | sed -e's/\\/\\\\/g' -e's/"/\\"/g' -e's/$$/\\n\\/' - ; \
	  echo \"\; ; echo "LUAMOD_API int luaopen_$$p (lua_State *L) {" ; \
	  echo "  return lau_loadlua(L,lau_$$p,sizeof(lau_$$p),\"$$m\"); }" ; \
	  echo "" ; }; done ; \
	echo "static struct luaL_Reg lau_luamodules[] = {" ; \
	for p in $$P ; do { \
	  eval m="\$$lau_$$p" ; [ -z $$m ] && eval m=$$p ; \
	  echo " {\"$$m\",luaopen_$$p}," ; } ; done ; \
	echo " {NULL,NULL}};" ; echo "" ; ) > $@


$O/lapi.o: $L/lapi.c
	$(CC) $(CFLAGS) -c -o $@ $<
$O/lauxlib.o: $L/lauxlib.c
	$(CC) $(CFLAGS) -c -o $@ $<
$O/lbaselib.o: $L/lbaselib.c
	$(CC) $(CFLAGS) -c -o $@ $<
$O/lcode.o: $L/lcode.c
	$(CC) $(CFLAGS) $(CMCFLAGS) -c -o $@ $<
$O/lcorolib.o: $L/lcorolib.c
	$(CC) $(CFLAGS) -c -o $@ $<
$O/lctype.o: $L/lctype.c
	$(CC) $(CFLAGS) -c -o $@ $<
$O/ldblib.o: $L/ldblib.c
	$(CC) $(CFLAGS) -c -o $@ $<
$O/ldebug.o: $L/ldebug.c
	$(CC) $(CFLAGS) -c -o $@ $<
$O/ldo.o: $L/ldo.c
	$(CC) $(CFLAGS) -c -o $@ $<
$O/ldump.o: $L/ldump.c
	$(CC) $(CFLAGS) -c -o $@ $<
$O/lfunc.o: $L/lfunc.c
	$(CC) $(CFLAGS) -c -o $@ $<
$O/lgc.o: $L/lgc.c
	$(CC) $(CFLAGS) -c -o $@ $<
$O/linit.o: $A/linit.c
	$(CC) $(CFLAGS) -I$L -I$F -I$S -c -o $@ $<
$O/liolib.o: $L/liolib.c
	$(CC) $(CFLAGS) -c -o $@ $<
$O/llex.o: $L/llex.c
	$(CC) $(CFLAGS) $(CMCFLAGS) -c -o $@ $<
$O/lmathlib.o: $L/lmathlib.c
	$(CC) $(CFLAGS) -c -o $@ $<
$O/lmem.o: $L/lmem.c
	$(CC) $(CFLAGS) -c -o $@ $<
$O/loadlib.o: $A/loadlib.c
	$(CC) $(CFLAGS) -I$L -c -o $@ $<
$O/lobject.o: $L/lobject.c
	$(CC) $(CFLAGS) -c -o $@ $<
$O/lopcodes.o: $L/lopcodes.c
	$(CC) $(CFLAGS) -c -o $@ $<
$O/loslib.o: $L/loslib.c
	$(CC) $(CFLAGS) -c -o $@ $<
$O/lparser.o: $L/lparser.c
	$(CC) $(CFLAGS) $(CMCFLAGS) -c -o $@ $<
$O/lstate.o: $L/lstate.c
	$(CC) $(CFLAGS) -c -o $@ $<
$O/lstring.o: $L/lstring.c
	$(CC) $(CFLAGS) -c -o $@ $<
$O/lstrlib.o: $L/lstrlib.c
	$(CC) $(CFLAGS) -c -o $@ $<
$O/ltable.o: $L/ltable.c
	$(CC) $(CFLAGS) -c -o $@ $<
$O/ltablib.o: $L/ltablib.c
	$(CC) $(CFLAGS) -c -o $@ $<
$O/ltm.o: $L/ltm.c
	$(CC) $(CFLAGS) -c -o $@ $<
$O/lua.o: $A/lua.c
	$(CC) $(CFLAGS) -I$L -I$N -c -o $@ $<
$O/luac.o: $L/luac.c
	$(CC) $(CFLAGS) -c -o $@ $<
$O/lundump.o: $L/lundump.c
	$(CC) $(CFLAGS) -c -o $@ $<
$O/lutf8lib.o: $L/lutf8lib.c
	$(CC) $(CFLAGS) -c -o $@ $<
$O/lvm.o: $L/lvm.c
	$(CC) $(CFLAGS) -c -o $@ $<
$O/lzio.o: $L/lzio.c
	$(CC) $(CFLAGS) -c -o $@ $<

$O/linenoise.o: $N/linenoise.c
	$(CC) $(CFLAGS) -c -o $@ $<

$O/lfs.o: $F/lfs.c
	$(CC) $(CFLAGS) -I$L -c -o $@ $<

#SOCK_O=	$O/luasocket.o $O/timeout.o $O/buffer.o $O/io.o $O/auxiliar.o $O/compat.o $O/options.o $O/inet.o $O/usocket.o $O/except.o $O/select.o $O/tcp.o $O/udp.o $O/mime.o $O/unixstream.o $O/unixdgram.o $O/compat.o $O/unix.o $O/serial.o
$O/luasocket.o: $S/luasocket.c
	$(CC) $(CFLAGS) -I$L -I$S -c -o $@ $<
$O/timeout.o: $S/timeout.c
	$(CC) $(CFLAGS) -I$L -I$S -c -o $@ $<
$O/buffer.o: $S/buffer.c
	$(CC) $(CFLAGS) -I$L -I$S -c -o $@ $<
$O/io.o: $S/io.c
	$(CC) $(CFLAGS) -I$L -I$S -c -o $@ $<
$O/auxiliar.o: $S/auxiliar.c
	$(CC) $(CFLAGS) -I$L -I$S -c -o $@ $<
$O/compat.o: $S/compat.c
	$(CC) $(CFLAGS) -I$L -I$S -c -o $@ $<
$O/options.o: $S/options.c
	$(CC) $(CFLAGS) -I$L -I$S -c -o $@ $<
$O/inet.o: $S/inet.c
	$(CC) $(CFLAGS) -I$L -I$S -c -o $@ $<
$O/usocket.o: $S/usocket.c
	$(CC) $(CFLAGS) -I$L -I$S -c -o $@ $<
$O/except.o: $S/except.c
	$(CC) $(CFLAGS) -I$L -I$S -c -o $@ $<
$O/select.o: $S/select.c
	$(CC) $(CFLAGS) -I$L -I$S -c -o $@ $<
$O/tcp.o: $S/tcp.c
	$(CC) $(CFLAGS) -I$L -I$S -c -o $@ $<
$O/udp.o: $S/udp.c
	$(CC) $(CFLAGS) -I$L -I$S -c -o $@ $<
$O/mime.o: $S/mime.c
	$(CC) $(CFLAGS) -I$L -I$S -c -o $@ $<
$O/unixstream.o: $S/unixstream.c
	$(CC) $(CFLAGS) -I$L -I$S -c -o $@ $<
$O/unixdgram.o: $S/unixdgram.c
	$(CC) $(CFLAGS) -I$L -I$S -c -o $@ $<
$O/unix.o: $S/unix.c
	$(CC) $(CFLAGS) -I$L -I$S -c -o $@ $<
$O/serial.o: $S/serial.c
	$(CC) $(CFLAGS) -I$L -I$S -c -o $@ $<

$O/adler32.o: $Z/adler32.c
	$(CC) $(CFLAGS) $(ZLIBFLAGS) -c -o $@ $<
$O/crc32.o: $Z/crc32.c
	$(CC) $(CFLAGS) $(ZLIBFLAGS) -c -o $@ $<
$O/deflate.o: $Z/deflate.c
	$(CC) $(CFLAGS) $(ZLIBFLAGS) -c -o $@ $<
$O/infback.o: $Z/infback.c
	$(CC) $(CFLAGS) $(ZLIBFLAGS) -c -o $@ $<
$O/inffast.o: $Z/inffast.c
	$(CC) $(CFLAGS) $(ZLIBFLAGS) -c -o $@ $<
$O/inflate.o: $Z/inflate.c
	$(CC) $(CFLAGS) $(ZLIBFLAGS) -c -o $@ $<
$O/inftrees.o: $Z/inftrees.c
	$(CC) $(CFLAGS) $(ZLIBFLAGS) -c -o $@ $<
$O/trees.o: $Z/trees.c
	$(CC) $(CFLAGS) $(ZLIBFLAGS) -c -o $@ $<
$O/zutil.o: $Z/zutil.c
	$(CC) $(CFLAGS) $(ZLIBFLAGS) -c -o $@ $<
$O/compress.o: $Z/compress.c
	$(CC) $(CFLAGS) $(ZLIBFLAGS) -c -o $@ $<
$O/uncompr.o: $Z/uncompr.c
	$(CC) $(CFLAGS) $(ZLIBFLAGS) -c -o $@ $<
$O/gzclose.o: $Z/gzclose.c
	$(CC) $(CFLAGS) $(ZLIBFLAGS) -c -o $@ $<
$O/gzlib.o: $Z/gzlib.c
	$(CC) $(CFLAGS) $(ZLIBFLAGS) -c -o $@ $<
$O/gzread.o: $Z/gzread.c
	$(CC) $(CFLAGS) $(ZLIBFLAGS) -c -o $@ $<
$O/gzwrite.o: $Z/gzwrite.c
	$(CC) $(CFLAGS) $(ZLIBFLAGS) -c -o $@ $<

$O/lua_zlib.o: $Y/lua_zlib.c
	$(CC) $(CFLAGS) -I$L -I$Z -c -o $@ $<

# Header dependencies
#
# There are differences between GNU make and BSD make; consequently the
# approach taken here is to manually generate Makefile.dep and embed it
# directly into this file *** change as desired

# include Makefile.dep			#-- GNU make
# .include Makefile.dep			#-- BSD make

# (manually imported Makefile.dep)
# Automatically generated Sat Apr 23 21:38:32 AEST 2022
$O/lapi.o: $L/lprefix.h $L/lua.h \
 $L/luaconf.h $L/lapi.h $L/llimits.h \
 $L/lstate.h $L/lobject.h $L/ltm.h \
 $L/lzio.h $L/lmem.h $L/ldebug.h \
 $L/ldo.h $L/lfunc.h $L/lgc.h \
 $L/lstring.h $L/ltable.h $L/lundump.h \
 $L/lvm.h
$O/lauxlib.o: $L/lprefix.h \
 $L/lua.h $L/luaconf.h $L/lauxlib.h
$O/lbaselib.o: $L/lprefix.h \
 $L/lua.h $L/luaconf.h $L/lauxlib.h \
 $L/lualib.h
$O/lcode.o: $L/lprefix.h \
 $L/lua.h $L/luaconf.h $L/lcode.h \
 $L/llex.h $L/lobject.h $L/llimits.h \
 $L/lzio.h $L/lmem.h $L/lopcodes.h \
 $L/lparser.h $L/ldebug.h $L/lstate.h \
 $L/ltm.h $L/ldo.h $L/lgc.h \
 $L/lstring.h $L/ltable.h $L/lvm.h
$O/lcorolib.o: $L/lprefix.h \
 $L/lua.h $L/luaconf.h $L/lauxlib.h \
 $L/lualib.h
$O/lctype.o: $L/lprefix.h \
 $L/lctype.h $L/lua.h $L/luaconf.h \
 $L/llimits.h
$O/ldblib.o: $L/lprefix.h \
 $L/lua.h $L/luaconf.h $L/lauxlib.h \
 $L/lualib.h
$O/ldebug.o: $L/lprefix.h \
 $L/lua.h $L/luaconf.h $L/lapi.h \
 $L/llimits.h $L/lstate.h $L/lobject.h \
 $L/ltm.h $L/lzio.h $L/lmem.h \
 $L/lcode.h $L/llex.h $L/lopcodes.h \
 $L/lparser.h $L/ldebug.h $L/ldo.h \
 $L/lfunc.h $L/lstring.h $L/lgc.h \
 $L/ltable.h $L/lvm.h
$O/ldo.o: $L/lprefix.h $L/lua.h \
 $L/luaconf.h $L/lapi.h $L/llimits.h \
 $L/lstate.h $L/lobject.h $L/ltm.h \
 $L/lzio.h $L/lmem.h $L/ldebug.h \
 $L/ldo.h $L/lfunc.h $L/lgc.h \
 $L/lopcodes.h $L/lparser.h $L/lstring.h \
 $L/ltable.h $L/lundump.h $L/lvm.h
$O/ldump.o: $L/lprefix.h \
 $L/lua.h $L/luaconf.h $L/lobject.h \
 $L/llimits.h $L/lstate.h $L/ltm.h \
 $L/lzio.h $L/lmem.h $L/lundump.h
$O/lfunc.o: $L/lprefix.h \
 $L/lua.h $L/luaconf.h $L/ldebug.h \
 $L/lstate.h $L/lobject.h $L/llimits.h \
 $L/ltm.h $L/lzio.h $L/lmem.h \
 $L/ldo.h $L/lfunc.h $L/lgc.h
$O/lgc.o: $L/lprefix.h $L/lua.h \
 $L/luaconf.h $L/ldebug.h $L/lstate.h \
 $L/lobject.h $L/llimits.h $L/ltm.h \
 $L/lzio.h $L/lmem.h $L/ldo.h \
 $L/lfunc.h $L/lgc.h $L/lstring.h \
 $L/ltable.h
$O/linit.o: $L/lprefix.h $L/lua.h \
 $L/luaconf.h $L/lualib.h $L/lua.h \
 $L/lauxlib.h $F/lfs.h \
 $S/luasocket.h $S/compat.h \
 $S/mime.h $S/luasocket.h \
 $S/unix.h $S/buffer.h \
 $S/io.h $S/timeout.h \
 $S/socket.h $S/usocket.h \
 lau/linit_src.ci
$O/liolib.o: $L/lprefix.h \
 $L/lua.h $L/luaconf.h $L/lauxlib.h \
 $L/lualib.h
$O/llex.o: $L/lprefix.h $L/lua.h \
 $L/luaconf.h $L/lctype.h $L/llimits.h \
 $L/ldebug.h $L/lstate.h $L/lobject.h \
 $L/ltm.h $L/lzio.h $L/lmem.h \
 $L/ldo.h $L/lgc.h $L/llex.h \
 $L/lparser.h $L/lstring.h $L/ltable.h
$O/lmathlib.o: $L/lprefix.h \
 $L/lua.h $L/luaconf.h $L/lauxlib.h \
 $L/lualib.h
$O/lmem.o: $L/lprefix.h $L/lua.h \
 $L/luaconf.h $L/ldebug.h $L/lstate.h \
 $L/lobject.h $L/llimits.h $L/ltm.h \
 $L/lzio.h $L/lmem.h $L/ldo.h \
 $L/lgc.h
$O/loadlib.o: $L/lprefix.h $L/lua.h \
 $L/luaconf.h $L/lauxlib.h $L/lua.h \
 $L/lualib.h
$O/lobject.o: $L/lprefix.h \
 $L/lua.h $L/luaconf.h $L/lctype.h \
 $L/llimits.h $L/ldebug.h $L/lstate.h \
 $L/lobject.h $L/ltm.h $L/lzio.h \
 $L/lmem.h $L/ldo.h $L/lstring.h \
 $L/lgc.h $L/lvm.h
$O/lopcodes.o: $L/lprefix.h \
 $L/lopcodes.h $L/llimits.h $L/lua.h \
 $L/luaconf.h
$O/loslib.o: $L/lprefix.h \
 $L/lua.h $L/luaconf.h $L/lauxlib.h \
 $L/lualib.h
$O/lparser.o: $L/lprefix.h \
 $L/lua.h $L/luaconf.h $L/lcode.h \
 $L/llex.h $L/lobject.h $L/llimits.h \
 $L/lzio.h $L/lmem.h $L/lopcodes.h \
 $L/lparser.h $L/ldebug.h $L/lstate.h \
 $L/ltm.h $L/ldo.h $L/lfunc.h \
 $L/lstring.h $L/lgc.h $L/ltable.h
$O/lstate.o: $L/lprefix.h \
 $L/lua.h $L/luaconf.h $L/lapi.h \
 $L/llimits.h $L/lstate.h $L/lobject.h \
 $L/ltm.h $L/lzio.h $L/lmem.h \
 $L/ldebug.h $L/ldo.h $L/lfunc.h \
 $L/lgc.h $L/llex.h $L/lstring.h \
 $L/ltable.h
$O/lstring.o: $L/lprefix.h \
 $L/lua.h $L/luaconf.h $L/ldebug.h \
 $L/lstate.h $L/lobject.h $L/llimits.h \
 $L/ltm.h $L/lzio.h $L/lmem.h \
 $L/ldo.h $L/lstring.h $L/lgc.h
$O/lstrlib.o: $L/lprefix.h \
 $L/lua.h $L/luaconf.h $L/lauxlib.h \
 $L/lualib.h
$O/ltable.o: $L/lprefix.h \
 $L/lua.h $L/luaconf.h $L/ldebug.h \
 $L/lstate.h $L/lobject.h $L/llimits.h \
 $L/ltm.h $L/lzio.h $L/lmem.h \
 $L/ldo.h $L/lgc.h $L/lstring.h \
 $L/ltable.h $L/lvm.h
$O/ltablib.o: $L/lprefix.h \
 $L/lua.h $L/luaconf.h $L/lauxlib.h \
 $L/lualib.h
$O/ltm.o: $L/lprefix.h $L/lua.h \
 $L/luaconf.h $L/ldebug.h $L/lstate.h \
 $L/lobject.h $L/llimits.h $L/ltm.h \
 $L/lzio.h $L/lmem.h $L/ldo.h \
 $L/lgc.h $L/lstring.h $L/ltable.h \
 $L/lvm.h
$O/lua.o: $L/lprefix.h $L/lua.h \
 $L/luaconf.h $L/lauxlib.h $L/lua.h \
 $L/lualib.h
$O/luac.o: $L/lprefix.h $L/lua.h \
 $L/luaconf.h $L/lauxlib.h $L/ldebug.h \
 $L/lstate.h $L/lobject.h $L/llimits.h \
 $L/ltm.h $L/lzio.h $L/lmem.h \
 $L/lopcodes.h $L/lopnames.h \
 $L/lundump.h
$O/lundump.o: $L/lprefix.h \
 $L/lua.h $L/luaconf.h $L/ldebug.h \
 $L/lstate.h $L/lobject.h $L/llimits.h \
 $L/ltm.h $L/lzio.h $L/lmem.h \
 $L/ldo.h $L/lfunc.h $L/lstring.h \
 $L/lgc.h $L/lundump.h
$O/lutf8lib.o: $L/lprefix.h \
 $L/lua.h $L/luaconf.h $L/lauxlib.h \
 $L/lualib.h
$O/lvm.o: $L/lprefix.h $L/lua.h \
 $L/luaconf.h $L/ldebug.h $L/lstate.h \
 $L/lobject.h $L/llimits.h $L/ltm.h \
 $L/lzio.h $L/lmem.h $L/ldo.h \
 $L/lfunc.h $L/lgc.h $L/lopcodes.h \
 $L/lstring.h $L/ltable.h $L/lvm.h \
 $L/ljumptab.h
$O/lzio.o: $L/lprefix.h $L/lua.h \
 $L/luaconf.h $L/llimits.h $L/lmem.h \
 $L/lstate.h $L/lobject.h $L/ltm.h \
 $L/lzio.h
$O/linenoise.o: linenoise-1.0/linenoise.h
$O/lfs.o: $L/lua.h \
 $L/luaconf.h $L/lauxlib.h $L/lua.h \
 $L/lualib.h $F/lfs.h
$O/luasocket.o: \
 $S/luasocket.h $L/lua.h \
 $L/luaconf.h $L/lauxlib.h $L/lua.h \
 $S/compat.h $S/auxiliar.h \
 $S/except.h $S/timeout.h \
 $S/buffer.h $S/io.h \
 $S/inet.h $S/socket.h \
 $S/usocket.h $S/tcp.h \
 $S/udp.h $S/select.h
$O/timeout.o: $S/luasocket.h \
 $L/lua.h $L/luaconf.h $L/lauxlib.h \
 $L/lua.h $S/compat.h \
 $S/auxiliar.h $S/timeout.h
$O/buffer.o: $S/luasocket.h \
 $L/lua.h $L/luaconf.h $L/lauxlib.h \
 $L/lua.h $S/compat.h \
 $S/buffer.h $S/io.h \
 $S/timeout.h
$O/io.o: $S/luasocket.h \
 $L/lua.h $L/luaconf.h $L/lauxlib.h \
 $L/lua.h $S/compat.h \
 $S/io.h $S/timeout.h
$O/auxiliar.o: \
 $S/luasocket.h $L/lua.h \
 $L/luaconf.h $L/lauxlib.h $L/lua.h \
 $S/compat.h $S/auxiliar.h
$O/compat.o: $S/luasocket.h \
 $L/lua.h $L/luaconf.h $L/lauxlib.h \
 $L/lua.h $S/compat.h
$O/options.o: $S/luasocket.h \
 $L/lua.h $L/luaconf.h $L/lauxlib.h \
 $L/lua.h $S/compat.h \
 $S/auxiliar.h $S/options.h \
 $S/socket.h $S/io.h \
 $S/timeout.h $S/usocket.h \
 $S/inet.h
$O/inet.o: $S/luasocket.h \
 $L/lua.h $L/luaconf.h $L/lauxlib.h \
 $L/lua.h $S/compat.h \
 $S/inet.h $S/socket.h \
 $S/io.h $S/timeout.h \
 $S/usocket.h
$O/usocket.o: $S/luasocket.h \
 $L/lua.h $L/luaconf.h $L/lauxlib.h \
 $L/lua.h $S/compat.h \
 $S/socket.h $S/io.h \
 $S/timeout.h $S/usocket.h \
 $S/pierror.h
$O/except.o: $S/luasocket.h \
 $L/lua.h $L/luaconf.h $L/lauxlib.h \
 $L/lua.h $S/compat.h \
 $S/except.h
$O/select.o: $S/luasocket.h \
 $L/lua.h $L/luaconf.h $L/lauxlib.h \
 $L/lua.h $S/compat.h \
 $S/socket.h $S/io.h \
 $S/timeout.h $S/usocket.h \
 $S/select.h
$O/tcp.o: $S/luasocket.h \
 $L/lua.h $L/luaconf.h $L/lauxlib.h \
 $L/lua.h $S/compat.h \
 $S/auxiliar.h $S/socket.h \
 $S/io.h $S/timeout.h \
 $S/usocket.h $S/inet.h \
 $S/options.h $S/tcp.h \
 $S/buffer.h
$O/udp.o: $S/luasocket.h \
 $L/lua.h $L/luaconf.h $L/lauxlib.h \
 $L/lua.h $S/compat.h \
 $S/auxiliar.h $S/socket.h \
 $S/io.h $S/timeout.h \
 $S/usocket.h $S/inet.h \
 $S/options.h $S/udp.h
$O/mime.o: $S/luasocket.h \
 $L/lua.h $L/luaconf.h $L/lauxlib.h \
 $L/lua.h $S/compat.h \
 $S/mime.h
$O/unixstream.o: \
 $S/luasocket.h $L/lua.h \
 $L/luaconf.h $L/lauxlib.h $L/lua.h \
 $S/compat.h $S/auxiliar.h \
 $S/socket.h $S/io.h \
 $S/timeout.h $S/usocket.h \
 $S/options.h $S/unixstream.h \
 $S/unix.h $S/buffer.h
$O/unixdgram.o: \
 $S/luasocket.h $L/lua.h \
 $L/luaconf.h $L/lauxlib.h $L/lua.h \
 $S/compat.h $S/auxiliar.h \
 $S/socket.h $S/io.h \
 $S/timeout.h $S/usocket.h \
 $S/options.h $S/unix.h \
 $S/buffer.h
$O/unix.o: $S/luasocket.h \
 $L/lua.h $L/luaconf.h $L/lauxlib.h \
 $L/lua.h $S/compat.h \
 $S/unixstream.h $S/unix.h \
 $S/buffer.h $S/io.h \
 $S/timeout.h $S/socket.h \
 $S/usocket.h $S/unixdgram.h
$O/serial.o: $S/luasocket.h \
 $L/lua.h $L/luaconf.h $L/lauxlib.h \
 $L/lua.h $S/compat.h \
 $S/auxiliar.h $S/socket.h \
 $S/io.h $S/timeout.h \
 $S/usocket.h $S/options.h \
 $S/unix.h $S/buffer.h
$O/adler32.o: $Z/zutil.h $Z/zlib.h \
 $Z/zconf.h
$O/crc32.o: $Z/zutil.h $Z/zlib.h \
 $Z/zconf.h $Z/crc32.h
$O/deflate.o: $Z/deflate.h \
 $Z/zutil.h $Z/zlib.h $Z/zconf.h
$O/infback.o: $Z/zutil.h $Z/zlib.h \
 $Z/zconf.h $Z/inftrees.h $Z/inflate.h \
 $Z/inffast.h $Z/inffixed.h
$O/inffast.o: $Z/zutil.h $Z/zlib.h \
 $Z/zconf.h $Z/inftrees.h $Z/inflate.h \
 $Z/inffast.h
$O/inflate.o: $Z/zutil.h $Z/zlib.h \
 $Z/zconf.h $Z/inftrees.h $Z/inflate.h \
 $Z/inffast.h $Z/inffixed.h
$O/inftrees.o: $Z/zutil.h $Z/zlib.h \
 $Z/zconf.h $Z/inftrees.h
$O/trees.o: $Z/deflate.h $Z/zutil.h \
 $Z/zlib.h $Z/zconf.h $Z/trees.h
$O/zutil.o: $Z/zutil.h $Z/zlib.h \
 $Z/zconf.h $Z/gzguts.h
$O/compress.o: $Z/zlib.h $Z/zconf.h
$O/uncompr.o: $Z/zlib.h $Z/zconf.h
$O/gzclose.o: $Z/gzguts.h $Z/zlib.h \
 $Z/zconf.h
$O/gzlib.o: $Z/gzguts.h $Z/zlib.h \
 $Z/zconf.h
$O/gzread.o: $Z/gzguts.h $Z/zlib.h \
 $Z/zconf.h
$O/gzwrite.o: $Z/gzguts.h $Z/zlib.h \
 $Z/zconf.h
$O/lua_zlib.o: $L/lauxlib.h \
 $L/luaconf.h $L/lua.h $L/lua.h \
 $Z/zlib.h $Z/zconf.h

# (end of Makefile)

