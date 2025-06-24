/*
 * @File	  : utils.hpp
 * @Coding	  : utf-8
 * @Author    : Bing
 * @Time      : 2023/05/28 14:11
 * @Introduce : 各种工具
*/

#pragma once

#include <vector>
#include <unistd.h>
#include <thread>
#include <list>
#include <unordered_map>
#include <random>
#include <chrono>
#include <functional>
#include <snowflake.hpp>

#include <configuration/define.hpp>
#include "opencv2/opencv.hpp"
#include "Poco/UUID.h"
#include "Poco/UUIDGenerator.h"
#include "Poco/DigestEngine.h"
#include "Poco/SHA2Engine.h"
#include "Poco/SHA1Engine.h"
#include "http_util.hpp"
#include "self_exception.hpp"

#ifndef UTILS_HPP
#define UTILS_HPP

namespace self {
	namespace Tools {
		/// <summary>
		/// 分割字符串为std::string
		/// </summary>
		/// <param name="str">需要分割的字符串</param>
		/// <param name="pattern">分割的字符</param>
		/// <returns>返回分割的std::string</returns>
		inline static std::vector<std::string> split(std::string str, std::string pattern)
		{
			std::string::size_type pos;
			std::vector<std::string> result;
			str += pattern;//扩展字符串以方便操作
			int size = str.size();
			for (int i = 0; i < size; i++)
			{
				pos = str.find(pattern, i);
				if (pos < size)
				{
					std::string s = str.substr(i, pos - i);
					result.emplace_back(s);
					i = pos + pattern.size() - 1;
				}
			}
			return result;
		}


		inline void HexDebug(const auto& content) {
			for (const auto& data : content)
			{
				std::cout << std::format("{:02X}", data);
			};
			std::cout << std::endl;
		}

		inline bool exec_simple(const char* cmd) {
			FILE* pipe{ popen(cmd, "r") };
			if (!pipe) {
				pclose(pipe);
				return false;
			}
			pclose(pipe);
			return true;
		}

		// 运行shell脚本并获取字符串
		inline const std::string exec(const char* cmd) {
			FILE* pipe = popen(cmd, "r");
			if (!pipe) {
				pclose(pipe);
				return "ERROR";
			}
			char buffer[128];
			std::string result = "";
			while (!feof(pipe)) {
				if (fgets(buffer, 128, pipe) != NULL)
					result += buffer;
			}
			pclose(pipe);
			return result;
		}

		// 生成随机字符串
		inline std::string generateRandom(size_t length = 32, const std::string& charset = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz") {
			std::random_device seeder; // 用于生成随机种子    mt19937 gen(rd()); // 以随机种子初始化随机数生成器

			const auto seed{ seeder.entropy() ? seeder() : time(nullptr) };

			std::mt19937 engine{ static_cast<std::mt19937::result_type>(seed) };

			std::uniform_int_distribution<size_t> distribution{ 0, charset.length() - 1 }; // 均匀分布

			std::string randomStr;
			for (size_t i = 0; i < length; i++) {
				randomStr += charset[distribution(engine)]; // 从字符集中随机选择一个字符    
			}
			return randomStr;
		}
	
		/// <summary>
		/// 判断vector<string>是否存在特定值
		/// </summary>
		/// <param name="keys">crow param的列表</param>
		/// <param name="val">是否含有特定字符串</param>
		/// <returns>true为存在,false为不存在</returns>
		inline bool hasParam(const std::vector<std::string>& keys, std::string_view val) {
			return std::find(keys.cbegin(), keys.cend(), val) != keys.cend();
		}

		/// <summary>
		/// 效验request参数
		/// </summary>
		/// <param name="req">req丢进去就完事了</param>
		/// <param name="val">是否存在的字符串</param>
		/// <returns>true返回长度不为0的内容</returns>
		inline bool verifyParam(const crow::request& req, std::string_view val) {
			bool has_value{ hasParam(req.url_params.keys(), val) };
			if (has_value)
			{
				return !std::string(req.url_params.get(val.data())).empty();
			}
			else return false;
		}

		inline std::string UUIDGenerator(snowflake_t& sf = Global::snowflake_uuid) {
			auto id{ sf.nextid() };

			Poco::UUIDGenerator uuid_generator{};
			std::unique_ptr<Poco::DigestEngine> engine{ new Poco::SHA1Engine() };
			Poco::UUID uuid{ uuid_generator.createFromName(Poco::UUID(Global::uuid_info.uuid_namespace), std::to_string(id), *engine, Poco::UUID::UUID_NAME_BASED_SHA1) };
			engine.reset();

			return uuid.toString();
		};

		// base64解码的工具
		inline static std::vector<uint8_t> base64Decode(const std::string& base64Str) {
			static const std::string base64Chars =
				"ABCDEFGHIJKLMNOPQRSTUVWXYZ"
				"abcdefghijklmnopqrstuvwxyz"
				"0123456789+/";

			std::vector<uint8_t> data;
			size_t i = 0;
			uint32_t n = 0;
			int padding = 0;

			while (i < base64Str.length()) {
				char c = base64Str[i++];
				if (c == '=') {
					padding++;
					continue;
				}
				size_t index = base64Chars.find(c);
				if (index == std::string::npos) {
					continue;
				}
				n = (n << 6) | index;
				if (i % 4 == 0) {
					data.push_back((n >> 16) & 0xFF);
					data.push_back((n >> 8) & 0xFF);
					data.push_back(n & 0xFF);
					n = 0;
				}
			}
			if (padding > 0) {
				n <<= padding * 6;
				data.push_back((n >> 16) & 0xFF);
				if (padding == 1) {
					data.push_back((n >> 8) & 0xFF);
				}
			}
			return data;
		}

		inline void saveBase64Image(std::string_view base64_data, std::string_view filename) {
			cv::Mat save_image{};
			try {
				// 将base64编码的图像数据解码为二进制数据
				auto binary_data{ base64Decode(base64_data.data()) };

				// 从内存中解码图像数据
				save_image = cv::imdecode(binary_data, cv::IMREAD_UNCHANGED);

				// 将图像保存为PNG格式文件
				cv::imwrite(filename.data(), save_image);
			}
			catch (...) {
				save_image.release();
				throw;
			}
			save_image.release();
		}
	};

	inline crow::response HandleResponseBody(std::function<std::string(void)> f, const std::string& content_type = "application/json") {
		crow::response response;
		response.set_header("Content-Type", content_type);
		try {
			response.write(f());
			response.code = 200;
			return response;
		} catch (const self::HTTPException& except) {
			response.write(HTTPUtil::StatusCodeHandle::getSimpleJsonResult(except.getCode(), except.getMessage(), except.getJson(), except.getStatus()).dump(2));
			response.code = except.getCode();
		} catch (const json::out_of_range& except) {
			response.write(HTTPUtil::StatusCodeHandle::getSimpleJsonResult(400, except.what()).dump(2));
			response.code = 400;
		} catch (const std::exception& except) {
			response.write(HTTPUtil::StatusCodeHandle::getSimpleJsonResult(500, except.what()).dump(2));
			response.code = 500;
		}
		response.set_header("Content-Type", "application/json");
		return response;
	}
}

#endif // !UTILS_HPP

