# Customised Lua makefile
#  - statically link additional modules
#  -- luafilesystem
#  -- luasockets
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

AR= ar rcu
RANLIB= ranlib
RM= rm -f
UNAME= uname

SYSCFLAGS=
SYSLDFLAGS=
SYSLIBS=

# Special flags for compiler modules (Lua core); -Os reduces code size.
CMCFLAGS= 

# Highlevel directories
O= obj
L= lua-5.4.4/src
N= linenoise-1.0
F= luafilesystem-1_8_0/src
S= luasocket-3.0.0/src
Z= lau

# == END OF USER SETTINGS -- NO NEED TO CHANGE ANYTHING BELOW THIS LINE =======

PLATS= guess aix bsd c89 freebsd generic linux linux-readline line-linenoise macosx mingw posix solaris

LUA_A=	$O/liblua.a
CORE_O=	$O/lapi.o $O/lcode.o $O/lctype.o $O/ldebug.o $O/ldo.o $O/ldump.o $O/lfunc.o $O/lgc.o $O/llex.o $O/lmem.o $O/lobject.o $O/lopcodes.o $O/lparser.o $O/lstate.o $O/lstring.o $O/ltable.o $O/ltm.o $O/lundump.o $O/lvm.o $O/lzio.o $O/linenoise.o
LIB_O=	$O/lauxlib.o $O/lbaselib.o $O/lcorolib.o $O/ldblib.o $O/liolib.o $O/lmathlib.o $O/loadlib.o $O/loslib.o $O/lstrlib.o $O/ltablib.o $O/lutf8lib.o $O/linit.o
LFS_O=	$O/lfs.o
SOCK_O=	$O/luasocket.o $O/timeout.o $O/buffer.o $O/io.o $O/auxiliar.o $O/compat.o $O/options.o $O/inet.o $O/usocket.o $O/except.o $O/select.o $O/tcp.o $O/udp.o $O/mime.o $O/unixstream.o $O/unixdgram.o $O/unix.o $O/serial.o
UNIXSOCK_O= $O/unixstream.o $O/unixdgram.o $O/unix.o $O/serial.o
BASE_O= $(CORE_O) $(LIB_O) $(LFS_O) $(SOCK_O) $(UNIXSOCK_O)

LUA_T=	lua
LUA_O=	$O/lua.o

LUAC_T=	luac
LUAC_O=	$O/luac.o

ALL_O= $(BASE_O) $(LUA_O) $(LUAC_O)
ALL_T= $(LUA_A) $(LUA_T) $(LUAC_T)
ALL_A= $(LUA_A)

# Targets start here.
default: objdir $(PLAT)

all:	$(ALL_T)

o:	$(ALL_O)

a:	$(ALL_A)

$(LUA_A): $(BASE_O)
	$(AR) $@ $(BASE_O)
	$(RANLIB) $@

$(LUA_T): $(LUA_O) $(LUA_A)
	$(CC) -o $@ $(LDFLAGS) $(LUA_O) $(LUA_A) $(LIBS)

$(LUAC_T): $(LUAC_O) $(LUA_A)
	$(CC) -o $@ $(LDFLAGS) $(LUAC_O) $(LUA_A) $(LIBS)

test:
	./$(LUA_T) -v

clean:
	$(RM) $(ALL_T) $(ALL_O)

depend:
	@$(CC) $(CFLAGS) -MM l*.c

objdir:
	[ -d $O ] || mkdir -p $O

echo:
	@echo "PLAT= $(PLAT)"
	@echo "CC= $(CC)"
	@echo "CFLAGS= $(CFLAGS)"
	@echo "LDFLAGS= $(LDFLAGS)"
	@echo "LIBS= $(LIBS)"
	@echo "AR= $(AR)"
	@echo "RANLIB= $(RANLIB)"
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

# DO NOT DELETE

# Statically linked Lua code (from core LuaLau libraries) is currently
# embedded as raw strings. Each module has a name that is not necessarily
# the same as the file. For example, there is an implicit directory search
# when the module name contains a dot '.'. Since the embedding of the .lua
# code strips away the directory structure normally set by installing a
# library there must be another way of mapping file names to module names.
# Cannot rely on the shell supporting associative arrays, so kludge it:
#  - define variables lau_<basename>=<lua module name>
# This is ugly, but explicit.

$Z/linit_src.ci: $S/ftp.lua $S/headers.lua $S/http.lua $S/ltn12.lua \
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


$O/lapi.o: $L/lapi.c $L/lprefix.h $L/lua.h $L/luaconf.h $L/lapi.h $L/llimits.h $L/lstate.h \
 $L/lobject.h $L/ltm.h $L/lzio.h $L/lmem.h $L/ldebug.h $L/ldo.h $L/lfunc.h $L/lgc.h $L/lstring.h \
 $L/ltable.h $L/lundump.h $L/lvm.h
	$(CC) $(CFLAGS) -c -o $@ $<
$O/lauxlib.o: $L/lauxlib.c $L/lprefix.h $L/lua.h $L/luaconf.h $L/lauxlib.h
	$(CC) $(CFLAGS) -c -o $@ $<
$O/lbaselib.o: $L/lbaselib.c $L/lprefix.h $L/lua.h $L/luaconf.h $L/lauxlib.h $L/lualib.h
	$(CC) $(CFLAGS) -c -o $@ $<
$O/lcode.o: $L/lcode.c $L/lprefix.h $L/lua.h $L/luaconf.h $L/lcode.h $L/llex.h $L/lobject.h \
 $L/llimits.h $L/lzio.h $L/lmem.h $L/lopcodes.h $L/lparser.h $L/ldebug.h $L/lstate.h $L/ltm.h \
 $L/ldo.h $L/lgc.h $L/lstring.h $L/ltable.h $L/lvm.h
	$(CC) $(CFLAGS) $(CMCFLAGS) -c -o $@ $<
$O/lcorolib.o: $L/lcorolib.c $L/lprefix.h $L/lua.h $L/luaconf.h $L/lauxlib.h $L/lualib.h
	$(CC) $(CFLAGS) -c -o $@ $<
$O/lctype.o: $L/lctype.c $L/lprefix.h $L/lctype.h $L/lua.h $L/luaconf.h $L/llimits.h
	$(CC) $(CFLAGS) -c -o $@ $<
$O/ldblib.o: $L/ldblib.c $L/lprefix.h $L/lua.h $L/luaconf.h $L/lauxlib.h $L/lualib.h
	$(CC) $(CFLAGS) -c -o $@ $<
$O/ldebug.o: $L/ldebug.c $L/lprefix.h $L/lua.h $L/luaconf.h $L/lapi.h $L/llimits.h $L/lstate.h \
 $L/lobject.h $L/ltm.h $L/lzio.h $L/lmem.h $L/lcode.h $L/llex.h $L/lopcodes.h $L/lparser.h \
 $L/ldebug.h $L/ldo.h $L/lfunc.h $L/lstring.h $L/lgc.h $L/ltable.h $L/lvm.h
	$(CC) $(CFLAGS) -c -o $@ $<
$O/ldo.o: $L/ldo.c $L/lprefix.h $L/lua.h $L/luaconf.h $L/lapi.h $L/llimits.h $L/lstate.h \
 $L/lobject.h $L/ltm.h $L/lzio.h $L/lmem.h $L/ldebug.h $L/ldo.h $L/lfunc.h $L/lgc.h $L/lopcodes.h \
 $L/lparser.h $L/lstring.h $L/ltable.h $L/lundump.h $L/lvm.h
	$(CC) $(CFLAGS) -c -o $@ $<
$O/ldump.o: $L/ldump.c $L/lprefix.h $L/lua.h $L/luaconf.h $L/lobject.h $L/llimits.h $L/lstate.h \
 $L/ltm.h $L/lzio.h $L/lmem.h $L/lundump.h
	$(CC) $(CFLAGS) -c -o $@ $<
$O/lfunc.o: $L/lfunc.c $L/lprefix.h $L/lua.h $L/luaconf.h $L/ldebug.h $L/lstate.h $L/lobject.h \
 $L/llimits.h $L/ltm.h $L/lzio.h $L/lmem.h $L/ldo.h $L/lfunc.h $L/lgc.h
	$(CC) $(CFLAGS) -c -o $@ $<
$O/lgc.o: $L/lgc.c $L/lprefix.h $L/lua.h $L/luaconf.h $L/ldebug.h $L/lstate.h $L/lobject.h \
 $L/llimits.h $L/ltm.h $L/lzio.h $L/lmem.h $L/ldo.h $L/lfunc.h $L/lgc.h $L/lstring.h $L/ltable.h
	$(CC) $(CFLAGS) -c -o $@ $<
$O/linit.o: $Z/linit.c $Z/linit_src.ci $L/lprefix.h $L/lua.h $L/luaconf.h $L/lualib.h $L/lauxlib.h
	$(CC) $(CFLAGS) -I$L -I$F -I$S -c -o $@ $<
$O/liolib.o: $L/liolib.c $L/lprefix.h $L/lua.h $L/luaconf.h $L/lauxlib.h $L/lualib.h
	$(CC) $(CFLAGS) -c -o $@ $<
$O/llex.o: $L/llex.c $L/lprefix.h $L/lua.h $L/luaconf.h $L/lctype.h $L/llimits.h $L/ldebug.h \
 $L/lstate.h $L/lobject.h $L/ltm.h $L/lzio.h $L/lmem.h $L/ldo.h $L/lgc.h $L/llex.h $L/lparser.h \
 $L/lstring.h $L/ltable.h
	$(CC) $(CFLAGS) $(CMCFLAGS) -c -o $@ $<
$O/lmathlib.o: $L/lmathlib.c $L/lprefix.h $L/lua.h $L/luaconf.h $L/lauxlib.h $L/lualib.h
	$(CC) $(CFLAGS) -c -o $@ $<
$O/lmem.o: $L/lmem.c $L/lprefix.h $L/lua.h $L/luaconf.h $L/ldebug.h $L/lstate.h $L/lobject.h \
 $L/llimits.h $L/ltm.h $L/lzio.h $L/lmem.h $L/ldo.h $L/lgc.h
	$(CC) $(CFLAGS) -c -o $@ $<
$O/loadlib.o: $Z/loadlib.c $L/lprefix.h $L/lua.h $L/luaconf.h $L/lauxlib.h $L/lualib.h
	$(CC) $(CFLAGS) -I$L -c -o $@ $<
$O/lobject.o: $L/lobject.c $L/lprefix.h $L/lua.h $L/luaconf.h $L/lctype.h $L/llimits.h \
 $L/ldebug.h $L/lstate.h $L/lobject.h $L/ltm.h $L/lzio.h $L/lmem.h $L/ldo.h $L/lstring.h $L/lgc.h \
 $L/lvm.h
	$(CC) $(CFLAGS) -c -o $@ $<
$O/lopcodes.o: $L/lopcodes.c $L/lprefix.h $L/lopcodes.h $L/llimits.h $L/lua.h $L/luaconf.h
	$(CC) $(CFLAGS) -c -o $@ $<
$O/loslib.o: $L/loslib.c $L/lprefix.h $L/lua.h $L/luaconf.h $L/lauxlib.h $L/lualib.h
	$(CC) $(CFLAGS) -c -o $@ $<
$O/lparser.o: $L/lparser.c $L/lprefix.h $L/lua.h $L/luaconf.h $L/lcode.h $L/llex.h $L/lobject.h \
 $L/llimits.h $L/lzio.h $L/lmem.h $L/lopcodes.h $L/lparser.h $L/ldebug.h $L/lstate.h $L/ltm.h \
 $L/ldo.h $L/lfunc.h $L/lstring.h $L/lgc.h $L/ltable.h
	$(CC) $(CFLAGS) $(CMCFLAGS) -c -o $@ $<
$O/lstate.o: $L/lstate.c $L/lprefix.h $L/lua.h $L/luaconf.h $L/lapi.h $L/llimits.h $L/lstate.h \
 $L/lobject.h $L/ltm.h $L/lzio.h $L/lmem.h $L/ldebug.h $L/ldo.h $L/lfunc.h $L/lgc.h $L/llex.h \
 $L/lstring.h $L/ltable.h
	$(CC) $(CFLAGS) -c -o $@ $<
$O/lstring.o: $L/lstring.c $L/lprefix.h $L/lua.h $L/luaconf.h $L/ldebug.h $L/lstate.h \
 $L/lobject.h $L/llimits.h $L/ltm.h $L/lzio.h $L/lmem.h $L/ldo.h $L/lstring.h $L/lgc.h
	$(CC) $(CFLAGS) -c -o $@ $<
$O/lstrlib.o: $L/lstrlib.c $L/lprefix.h $L/lua.h $L/luaconf.h $L/lauxlib.h $L/lualib.h
	$(CC) $(CFLAGS) -c -o $@ $<
$O/ltable.o: $L/ltable.c $L/lprefix.h $L/lua.h $L/luaconf.h $L/ldebug.h $L/lstate.h $L/lobject.h \
 $L/llimits.h $L/ltm.h $L/lzio.h $L/lmem.h $L/ldo.h $L/lgc.h $L/lstring.h $L/ltable.h $L/lvm.h
	$(CC) $(CFLAGS) -c -o $@ $<
$O/ltablib.o: $L/ltablib.c $L/lprefix.h $L/lua.h $L/luaconf.h $L/lauxlib.h $L/lualib.h
	$(CC) $(CFLAGS) -c -o $@ $<
$O/ltm.o: $L/ltm.c $L/lprefix.h $L/lua.h $L/luaconf.h $L/ldebug.h $L/lstate.h $L/lobject.h \
 $L/llimits.h $L/ltm.h $L/lzio.h $L/lmem.h $L/ldo.h $L/lgc.h $L/lstring.h $L/ltable.h $L/lvm.h
	$(CC) $(CFLAGS) -c -o $@ $<
$O/lua.o: $Z/lua.c $L/lprefix.h $L/lua.h $L/luaconf.h $L/lauxlib.h $L/lualib.h
	$(CC) $(CFLAGS) -I$L -I$N -c -o $@ $<
$O/luac.o: $L/luac.c $L/lprefix.h $L/lua.h $L/luaconf.h $L/lauxlib.h $L/ldebug.h $L/lstate.h \
 $L/lobject.h $L/llimits.h $L/ltm.h $L/lzio.h $L/lmem.h $L/lopcodes.h $L/lopnames.h $L/lundump.h
	$(CC) $(CFLAGS) -c -o $@ $<
$O/lundump.o: $L/lundump.c $L/lprefix.h $L/lua.h $L/luaconf.h $L/ldebug.h $L/lstate.h \
 $L/lobject.h $L/llimits.h $L/ltm.h $L/lzio.h $L/lmem.h $L/ldo.h $L/lfunc.h $L/lstring.h $L/lgc.h \
 $L/lundump.h
	$(CC) $(CFLAGS) -c -o $@ $<
$O/lutf8lib.o: $L/lutf8lib.c $L/lprefix.h $L/lua.h $L/luaconf.h $L/lauxlib.h $L/lualib.h
	$(CC) $(CFLAGS) -c -o $@ $<
$O/lvm.o: $L/lvm.c $L/lprefix.h $L/lua.h $L/luaconf.h $L/ldebug.h $L/lstate.h $L/lobject.h \
 $L/llimits.h $L/ltm.h $L/lzio.h $L/lmem.h $L/ldo.h $L/lfunc.h $L/lgc.h $L/lopcodes.h $L/lstring.h \
 $L/ltable.h $L/lvm.h $L/ljumptab.h
	$(CC) $(CFLAGS) -c -o $@ $<
$O/lzio.o: $L/lzio.c $L/lprefix.h $L/lua.h $L/luaconf.h $L/llimits.h $L/lmem.h $L/lstate.h \
 $L/lobject.h $L/ltm.h $L/lzio.h
	$(CC) $(CFLAGS) -c -o $@ $<

$O/linenoise.o: $N/linenoise.c
	$(CC) $(CFLAGS) -c -o $@ $<

$O/lfs.o: $F/lfs.c
	$(CC) $(CFLAGS) -I$L -c -o $@ $<

#SOCK_O=	$O/luasocket.o $O/timeout.o $O/buffer.o $O/io.o $O/auxiliar.o $O/compat.o $O/options.o $O/inet.o $O/usocket.o $O/except.o $O/select.o $O/tcp.o $O/udp.o $O/mime.o $O/unixstream.o $O/unixdgram.o $O/compat.o $O/unix.o $O/serial.o
$O/luasocket.o: $S/luasocket.c $S/luasocket.h $S/auxiliar.h $S/except.h $S/timeout.h $S/buffer.h \
 $S/io.h $S/inet.h $S/socket.h $S/usocket.h $S/tcp.h $S/udp.h $S/select.h
	$(CC) $(CFLAGS) -I$L -I$S -c -o $@ $<
$O/timeout.o: $S/timeout.c $S/auxiliar.h $S/timeout.h
	$(CC) $(CFLAGS) -I$L -I$S -c -o $@ $<
$O/buffer.o: $S/buffer.c $S/buffer.h $S/io.h $S/timeout.h
	$(CC) $(CFLAGS) -I$L -I$S -c -o $@ $<
$O/io.o: $S/io.c $S/io.h $S/timeout.h
	$(CC) $(CFLAGS) -I$L -I$S -c -o $@ $<
$O/auxiliar.o: $S/auxiliar.c $S/auxiliar.h
	$(CC) $(CFLAGS) -I$L -I$S -c -o $@ $<
$O/compat.o: $S/compat.c $S/compat.h
	$(CC) $(CFLAGS) -I$L -I$S -c -o $@ $<
$O/options.o: $S/options.c $S/auxiliar.h $S/options.h $S/socket.h $S/io.h \
	$S/timeout.h $S/usocket.h $S/inet.h
	$(CC) $(CFLAGS) -I$L -I$S -c -o $@ $<
$O/inet.o: $S/inet.c $S/inet.h $S/socket.h $S/io.h $S/timeout.h $S/usocket.h
	$(CC) $(CFLAGS) -I$L -I$S -c -o $@ $<
$O/usocket.o: $S/usocket.c $S/socket.h $S/io.h $S/timeout.h $S/usocket.h
	$(CC) $(CFLAGS) -I$L -I$S -c -o $@ $<
$O/except.o: $S/except.c $S/except.h
	$(CC) $(CFLAGS) -I$L -I$S -c -o $@ $<
$O/select.o: $S/select.c $S/socket.h $S/io.h $S/timeout.h $S/usocket.h $S/select.h
	$(CC) $(CFLAGS) -I$L -I$S -c -o $@ $<
$O/tcp.o: $S/tcp.c $S/auxiliar.h $S/socket.h $S/io.h $S/timeout.h $S/usocket.h \
	$S/inet.h $S/options.h $S/tcp.h $S/buffer.h
	$(CC) $(CFLAGS) -I$L -I$S -c -o $@ $<
$O/udp.o: $S/udp.c $S/auxiliar.h $S/socket.h $S/io.h $S/timeout.h $S/usocket.h \
	$S/inet.h $S/options.h $S/udp.h
	$(CC) $(CFLAGS) -I$L -I$S -c -o $@ $<
$O/mime.o: $S/mime.c $S/mime.h
	$(CC) $(CFLAGS) -I$L -I$S -c -o $@ $<
$O/unixstream.o: $S/unixstream.c
	$(CC) $(CFLAGS) -I$L -I$S -c -o $@ $<
$O/unixdgram.o: $S/unixdgram.c
	$(CC) $(CFLAGS) -I$L -I$S -c -o $@ $<
$O/unix.o: $S/unix.c $S/auxiliar.h $S/socket.h $S/io.h $S/timeout.h $S/usocket.h \
	$S/options.h $S/unix.h $S/buffer.h
	$(CC) $(CFLAGS) -I$L -I$S -c -o $@ $<
$O/serial.o: $S/serial.c $S/auxiliar.h $S/socket.h $S/io.h $S/timeout.h $S/usocket.h \
  $S/options.h $S/unix.h $S/buffer.h
	$(CC) $(CFLAGS) -I$L -I$S -c -o $@ $<

# (end of Makefile)

