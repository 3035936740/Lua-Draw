/*
 * @File	  : log_system.hpp
 * @Coding	  : utf-8
 * @Author    : Bing
 * @Time      : 2023/03/05 21:17
 * @Introduce : 处理日志相关
*/

#pragma once

#include "configuration/config.hpp"
#include "spdlog/spdlog.h"
#include "spdlog/sinks/daily_file_sink.h"
#ifndef LOG_SYSTEM_HPP
#define LOG_SYSTEM_HPP  


namespace LogSystem {
	namespace {
		inline std::shared_ptr<spdlog::logger> _logger{ NULL };
		inline const auto _LOGGER_NAME = Config::config_yaml["log"]["logger-name"].as<std::string>();
		inline const auto _FILENAME = Config::config_yaml["log"]["filename"].as<std::string>();
		inline const auto _HOUR = Config::config_yaml["log"]["hour"].as<int>();
		inline const auto _MINUTE = Config::config_yaml["log"]["minute"].as<int>();
	}

	inline const int initialization_status{ [](){
		//初始化日志信息
		_logger = spdlog::daily_logger_mt(_LOGGER_NAME, _FILENAME, _HOUR, _MINUTE);
		//设置全局日志等级
		_logger->set_level(spdlog::level::info);
		spdlog::set_level(spdlog::level::info);
		return 0;
		}()
	};

	enum class logType :int {
		info = 0,
		debug = 1,
		warn = 2,
		critical = 3,
		error = 4
	};

#ifdef DEBUG
	static void getTestMethod(void) {
		spdlog::info("测试");
	};
#endif	// DEBUG

	static void dailyLogRecord(
		std::string_view record_literal,
		logType type = logType::info) {

		switch (type) {
		case logType::info:
			spdlog::info(record_literal);
			_logger->info(record_literal);
			break;
		case logType::debug:
			spdlog::debug(record_literal);
			_logger->debug(record_literal);
			break;
		case logType::warn:
			spdlog::warn(record_literal);
			_logger->warn(record_literal);
			break;
		case logType::critical:
			spdlog::critical(record_literal);
			_logger->critical(record_literal);
			break;
		case logType::error:
			spdlog::error(record_literal);
			_logger->error(record_literal);
			break;
		}
	};

	inline void logInfo(std::string_view record_literal) {
		dailyLogRecord(record_literal);
	};
	
	inline void logDebug(std::string_view record_literal) {
		dailyLogRecord(record_literal, logType::debug);
	};
	
	inline void logWarn(std::string_view record_literal) {
		dailyLogRecord(record_literal, logType::warn);
	};

	inline void logCritical(std::string_view record_literal) {
		dailyLogRecord(record_literal, logType::critical);
	};

	inline void logError(std::string_view record_literal) {
		dailyLogRecord(record_literal, logType::error);
	};


	class HandleDocumentSubstitutionWarnings : public Aspose::Words::IWarningCallback
	{
	public:
		void Warning(System::SharedPtr<Aspose::Words::WarningInfo> info) override
		{
			if (info->get_WarningType() == Aspose::Words::WarningType::FontSubstitution) {
				LogSystem::logWarn(info->get_Description().ToUtf8String());
			}
		}
	};
};

#endif