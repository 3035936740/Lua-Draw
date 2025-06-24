#include <main.h>

//使用luaL_Reg注册新的C函数到Lua中
static luaL_Reg lua_draw_functions[] =
{
	{"handle_text", handle_text},
	{"get_text_size", get_text_size},
	{NULL, NULL}  // 数组中最后一对必须是{NULL, NULL}，用来表示结束
};


/* luaopen_XXX，XXX为库名称，若库名称为testlib.so，XXX即为testlib */
int luaopen_libluadraw(lua_State* L)
{
	luaL_newlib(L, lua_draw_functions);  //Lua 5.2之后用luaL_newlib代替了luaL_register
	return 1;
}