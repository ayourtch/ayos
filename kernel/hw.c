#define LUA_LIB
#include <stdint.h>
#include "lua.h"
#include "lauxlib.h"



static int lua_fn_poke(lua_State *L) {
  int n = lua_gettop(L);
  int iaddr = lua_tointeger(L, 1);
  int ival = lua_tointeger(L, 2);
  char *ptr = ((char *)0) + iaddr;
  int ret = (uint8_t)*ptr;
  *ptr = ival;
  lua_pushinteger(L, ret);
  return 1;
}

static int lua_fn_peek(lua_State *L) {
  int iaddr = lua_tointeger(L, 1);
  char *ptr = ((char *)0) + iaddr;
  int ret = (uint8_t)*ptr;
  lua_pushinteger(L, ret);
  return 1;
}

static inline void outb(uint16_t port, uint8_t val)
{
    asm volatile ( "outb %0, %1" : : "a"(val), "Nd"(port) );
}

static inline uint8_t inb(uint16_t port)
{
    uint8_t ret;
    asm volatile ( "inb %1, %0" : "=a"(ret) : "Nd"(port) );
    return ret;
}

static inline void outw(uint16_t port, uint16_t val)
{
    asm volatile ( "outw %0, %1" : : "a"(val), "Nd"(port) );
}

static inline uint16_t inw(uint16_t port)
{
    uint16_t ret;
    asm volatile ( "inw %1, %0" : "=a"(ret) : "Nd"(port) );
    return ret;
}

static inline void outl(uint16_t port, uint32_t val)
{
    asm volatile ( "outl %0, %1" : : "a"(val), "Nd"(port) );
}

static inline uint32_t inl(uint16_t port)
{
    uint32_t ret;
    asm volatile ( "inl %1, %0" : "=a"(ret) : "Nd"(port) );
    return ret;
}

static int lua_fn_outb(lua_State *L) {
  int n = lua_gettop(L);
  int iaddr = lua_tointeger(L, 1);
  int ival = lua_tointeger(L, 2);
  outb(iaddr, ival);
  return 0;
}

static int lua_fn_inb(lua_State *L) {
  int iaddr = lua_tointeger(L, 1);
  int ret = inb(iaddr);
  lua_pushinteger(L, ret);
  return 1;
}

static int lua_fn_outw(lua_State *L) {
  int n = lua_gettop(L);
  int iaddr = lua_tointeger(L, 1);
  int ival = lua_tointeger(L, 2);
  outw(iaddr, ival);
  return 0;
}

static int lua_fn_inw(lua_State *L) {
  int iaddr = lua_tointeger(L, 1);
  int ret = inw(iaddr);
  lua_pushinteger(L, ret);
  return 1;
}

static int lua_fn_outl(lua_State *L) {
  int n = lua_gettop(L);
  int iaddr = lua_tointeger(L, 1);
  int ival = lua_tointeger(L, 2);
  outl(iaddr, ival);
  return 0;
}

static int lua_fn_inl(lua_State *L) {
  int iaddr = lua_tointeger(L, 1);
  int ret = inl(iaddr);
  lua_pushinteger(L, ret);
  return 1;
}

static const struct luaL_Reg hw_funcs[] = {
  { "peek",    lua_fn_peek },
  { "poke",    lua_fn_poke },
  { "inb",     lua_fn_inb },
  { "inw",     lua_fn_inw },
  { "inl",     lua_fn_inl },
  { "outb",    lua_fn_outb },
  { "outw",    lua_fn_outw },
  { "outl",    lua_fn_outl },
  { NULL, NULL }
};

LUALIB_API int luaopen_hw(lua_State *L)
{
#if LUA_VERSION_NUM < 502
  luaL_register(L, "hw", hw_funcs);
#else
  luaL_newlib(L, hw_funcs);
#endif
  return 1;
}

