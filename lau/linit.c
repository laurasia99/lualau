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
#include "unix.h"

#ifdef LAU_SOCKET_SERIAL
/* Missing prototype */
LUASOCKET_API int luaopen_socket_serial(lua_State *L);
#endif

/* Missing prototype */
LUALIB_API int luaopen_zlib(lua_State *L);

static const luaL_Reg linkedlibs[] = {
  {"lfs", luaopen_lfs},
  {"socket.core", luaopen_socket_core},
  {"mime.core", luaopen_mime_core},
#ifdef LAU_SOCKET_SERIAL
  /* Invocation socket.serial(<path>) -- factory function
  ** Allows raw access to Unix serial devices
  */
  {"socket.serial", luaopen_socket_serial},
#endif
  {"socket.unix", luaopen_socket_unix},
  {"zlib", luaopen_zlib},
  {NULL, NULL}
};

static void lau_addpreload (lua_State *L, const char *modname, int (*luaopen_modname)(lua_State *)) {
  luaL_getsubtable(L, LUA_REGISTRYINDEX, LUA_PRELOAD_TABLE);
  lua_pushcfunction(L, luaopen_modname);
  lua_setfield(L, -2, modname);
  lua_pop(L, 1);  // remove PRELOAD table
}

#ifndef NO_PARANOIA
#include <assert.h>
#include <string.h>
#endif

static int lau_loadlua(lua_State *L, const char *b, size_t n, const char *m) {
  int status;

#ifndef NO_PARANOIA
  assert(0==strcmp(luaL_checkstring(L,1),m));
  assert(0==strcmp(luaL_checkstring(L,2),":preload:"));
#endif

  status = luaL_loadbuffer(L, b, n-1, m);		/* Load chunk */
  if (status == LUA_OK) {
    lua_rotate(L, 1, 1);				/* chunk name :preload: */

#ifndef NO_PARANOIA
    assert(0==strcmp(luaL_checkstring(L,2),m));
    assert(0==strcmp(luaL_checkstring(L,3),":preload:"));
    assert(lua_isfunction(L,1));
#endif

    /* Stack: chunk module-name :preload: */
    lua_call(L, 2, 1);					/* execute chunk */

#ifndef NO_PARANOIA
    assert(lua_istable(L, -1));
    assert(lua_gettop(L) == 1);
#endif
    return 1;
  }

  /* XXX else ??? how to raise an error? */
  /* XXX fail silently? What does the caller of luaopen_XXX do? */
  /* XXX -- look at loadlib:ll_require() -- return nil? */
  return 0;
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
    lau_addpreload(L, lib->name, lib->func);
  }
  /* prelinked Lua modules */
  for (lib = lau_luamodules; lib->func; lib++) {
    lau_addpreload(L, lib->name, lib->func);
  }
}

