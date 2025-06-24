#pragma once

#include <common.hpp>
#include <codecvt>
#include <memory>
#include "lua5.4/lua.hpp"
#include <opencv2/freetype.hpp>
#include <ft2build.h>
#include <bits/locale_conv.h>

using namespace std::string_literals;

# if 0
/* 定义C++的Average 函数 */
int average(lua_State* L)
{
	int num = lua_gettop(L);  //获取参数个数

	double sum = 0;
	double avg = 0;

	for (int i = 1; i <= num; i++)   //注意Lua栈下标从1开始
	{
		sum += lua_tonumber(L, i);  //求和
	}

	avg = sum / num;   //求平均

	lua_pushnumber(L, avg);  //平均值入栈

	lua_pushnumber(L, sum);  //和入栈

	return 2;   //return 返回值个数
}

/* 定义C++的sub函数 */
int sub(lua_State* L)
{
	int num = lua_gettop(L);
	if (num != 2)
	{
		std::cout << "Input param number is not correct!" << std::endl;
		return 0;
	}

	int a = lua_tonumber(L, 1);   //获取第一个参数，被减数
	int b = lua_tonumber(L, 2);   //获取第二个参数，减数

	int diff = a - b;
	lua_pushnumber(L, diff);   //结果压入栈

	return 1;
}

/* 定义C++的add函数 */
int add(lua_State* L)
{
	int num = lua_gettop(L);
	if (num != 2)
	{
		std::cout << "Input param number is not correct!" << std::endl;
		return 0;
	}

	int a = lua_tonumber(L, 1);   //获取第一个参数，被减数
	int b = lua_tonumber(L, 2);   //获取第二个参数，减数

	int sum = a + b;
	lua_pushnumber(L, sum);   //结果压入栈

	return 1;
}
# endif

// 文本处理函数
int handle_text(lua_State* L)
{
	std::string text{}, fontPath{};
	lua_Integer fontSize{}, maxSize{}, maxLine{ 255 };
	bool isRows{ false };

	// 第1个参数为文本参数
	text = lua_tostring(L, 1);
	// 第2个参数为字体路径参数
	fontPath = lua_tostring(L, 2);
	// 第3个参数为字体大小
	fontSize = lua_tointeger(L, 3);
	// 第4个参数为最大尺寸限制
	maxSize = lua_tointeger(L, 4);

	if (!lua_isnoneornil(L, 5)) {
		// 第5个参数为是否开启多行处理模式
		isRows = lua_toboolean(L, 5);
	}

	if (!lua_isnoneornil(L, 6)) {
		// 第6个参数为多行处理最多为多少行
		maxLine = lua_tointeger(L, 6);
	}

	auto freetype2{ cv::freetype::createFreeType2() };
	freetype2->loadFontData(fontPath, 0);

	// 多行
	if (isRows) {
		// *开始*

		std::vector<std::string> texts{ };
		// 存在\n\r
		if (text.find("\r\n") != std::string::npos) {
			texts = utils::split(text, "\r\n");
		}// 存在\n\r
		else if (text.find("\n\r") != std::string::npos) {
			texts = utils::split(text, "\n\r");
		}// 存在\n
		else {
			texts = utils::split(text, "\n");
		}

		std::vector<std::string> texts_handled{ };

		// 存放std:string 与 位置
		std::vector<std::string>temps{};

		// 当前行
		uint8_t current_line{ 0 };

		// 字符串转换需要
		std::wstring_convert<std::codecvt_utf8<wchar_t>> converter;

		for (const auto& element : texts) {
			if (current_line >= maxLine) { break; }
			// 如果flag为true说明了多行插入
			bool flag{ false };

			int offset_w{ freetype2->getTextSize(element, fontSize, -1, nullptr).width };

			std::wstring wstr{ converter.from_bytes(element) };

			for (int i = 0; i < wstr.length(); i++) {
				std::string temp = converter.to_bytes(wstr.substr(0, i + 1));
				cv::Size text_size = freetype2->getTextSize(temp, fontSize, -1, nullptr); // 获取文本的大小
				if (text_size.width > maxSize) { // 如果文本宽度超过最大宽度
					if (current_line >= maxLine) { break; }
					temps.emplace_back(converter.to_bytes(wstr.substr(0, i)));
					wstr = wstr.substr(i); // 剩余文本
					i = 0; // 重新开始计数
					flag = true;
					++current_line;
				}
			}

			if (current_line < maxLine and flag) {
				temps.emplace_back(converter.to_bytes(wstr));
				wstr.clear();
				++current_line;
			}

			// 一段vector多行分割
			if (flag) {
				for (const auto& str : temps) {
					texts_handled.emplace_back(str);
				}
				temps.clear();
			}
			// 一段vector一行分割
			else {
				texts_handled.emplace_back(element);
				++current_line;
			}
		}

		lua_newtable(L);//创建一个表格，放在栈顶
		
		int count{ 1 };
		for (const auto& text : texts_handled) {
			lua_pushnumber(L, count);
			lua_pushstring(L, text.c_str());//压入key
			lua_settable(L, -3);
			++count;
		}
		// *结束*
	}
	// 单行
	else {
		// *开始*

		int offset_w{ freetype2->getTextSize(text, fontSize, -1, nullptr).width };

		std::wstring_convert<std::codecvt_utf8<wchar_t>> converter;
		while (offset_w > maxSize) {
			std::wstring wtext{ converter.from_bytes(text) };

			wtext.pop_back();

			text = converter.to_bytes(wtext);
			std::string temp{ text + "..."s };
			offset_w = freetype2->getTextSize(temp, fontSize, -1, nullptr).width;

			if (offset_w <= maxSize) {
				text = temp;
				break;
			}
		}

		lua_pushstring(L, text.c_str());
		// *结束*
	}

	freetype2.release();

	return 1;
}

// 获取文本尺寸函数(width,height)
int get_text_size(lua_State* L) {
	std::string 
		// 第1个参数为文本参数
		text{ lua_tostring(L, 1) }, 
		// 第2个参数为字体路径参数
		fontPath{ lua_tostring(L, 2) };
	
	// 第3个参数为字体大小
	lua_Integer fontSize{ lua_tointeger(L, 3) };

	auto freetype2{ cv::freetype::createFreeType2() };
	freetype2->loadFontData(fontPath, 0);

	auto textSize{ freetype2->getTextSize(text, fontSize, -1, nullptr) };

	freetype2.release();

	lua_pushnumber(L, textSize.width);  //平均值入栈

	lua_pushnumber(L, textSize.height);  //和入栈

	return 2; // 返回2个参数
}

extern "C" int luaopen_libluadraw(lua_State * L);