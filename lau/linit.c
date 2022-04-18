/*
** $Id: linit.c $
** Initialization of libraries for lua.c and other clients
** See Copyright Notice in lua.h
*/


#define linit_c
#define LUA_LIB

/*
** If you embed Lua in your program and need to open the standard
** libraries, call luaL_openlibs in your program. If you need a
** different set of libraries, copy this file to your project and edit
** it to suit your needs.
**
** You can also *preload* libraries, so that a later 'require' can
** open the library, which is already linked to the application.
** For that, do the following code:
**
**  luaL_getsubtable(L, LUA_REGISTRYINDEX, LUA_PRELOAD_TABLE);
**  lua_pushcfunction(L, luaopen_modname);
**  lua_setfield(L, -2, modname);
**  lua_pop(L, 1);  // remove PRELOAD table
*/

#include "lprefix.h"


#include <stddef.h>

#include "lua.h"

#include "lualib.h"
#include "lauxlib.h"


/*
** these libs are loaded by lua.c and are readily available to any Lua
** program
*/
static const luaL_Reg loadedlibs[] = {
  {LUA_GNAME, luaopen_base},
  {LUA_LOADLIBNAME, luaopen_package},
  {LUA_COLIBNAME, luaopen_coroutine},
  {LUA_TABLIBNAME, luaopen_table},
  {LUA_IOLIBNAME, luaopen_io},
  {LUA_OSLIBNAME, luaopen_os},
  {LUA_STRLIBNAME, luaopen_string},
  {LUA_MATHLIBNAME, luaopen_math},
  {LUA_UTF8LIBNAME, luaopen_utf8},
  {LUA_DBLIBNAME, luaopen_debug},
  {NULL, NULL}
};

/*
** these libs are linked into the static Lua binary but still
** must be require()'d
*/
#include "lfs.h"
#include "luasocket.h"
#include "mime.h"

static const luaL_Reg linkedlibs[] = {
  {"lfs", luaopen_lfs},
  {"socket.core", luaopen_socket_core},
  {"mime.core", luaopen_mime_core},
  {NULL, NULL}
};

static void lualL_linked (lua_State *L, const char *modname, int (*luaopen_modname)(lua_State *)) {
  luaL_getsubtable(L, LUA_REGISTRYINDEX, LUA_PRELOAD_TABLE);
  lua_pushcfunction(L, luaopen_modname);
  lua_setfield(L, -2, modname);
  lua_pop(L, 1);  // remove PRELOAD table
}

/* Import statically loaded .lua modules */
#include "linit_src.ci"

LUALIB_API void luaL_openlibs (lua_State *L) {
  const luaL_Reg *lib;
  /* "require" functions from 'loadedlibs' and set results to global table */
  for (lib = loadedlibs; lib->func; lib++) {
    luaL_requiref(L, lib->name, lib->func, 1);
    lua_pop(L, 1);  /* remove lib */
  }
  /* prelinked C modules */
  for (lib = linkedlibs; lib->func; lib++) {
    lualL_linked(L, lib->name, lib->func);
  }
  /* prelinked Lua modules */
  for (lib = lau__strings; lib->func; lib++) {
    lualL_linked(L, lib->name, lib->func);
  }
}

