#pragma once

// 设置1为开启跨域访问(想要性能问题的话建议关闭,使用反向代理)
#include <chrono> 
#include <filesystem>
#include <functional>
#include "crow.h"

#include "spdlog/spdlog.h"
#include "fmt/format.h"

namespace std {
    using fmt::format;
    using fmt::format_error;
    using fmt::formatter;
}
#include "configuration/config.hpp"
#include "common/utils.hpp"
#include "common/self_exception.hpp"
#include "common/http_util.hpp"
#include "common/log_system.hpp"
#include "self/reusable.hpp"
#include "route/route_other.hpp"
#include "route/route_utils.hpp"

#ifndef MAIN_H
#define MAIN_H

// O3优化
#pragma GCC optimize(3)
#pragma G++ optimize(3)

using namespace std::literals::string_view_literals;
using namespace std::chrono_literals;

//初始化
void init(void) {
#ifdef DEBUG
    std::cout << "init status: " << Config::initialization_status << std::endl;
    std::cout << "log system status: " << LogSystem::initialization_status << std::endl;
#endif // DEBUG
    if (LogSystem::initialization_status == 0 and Config::initialization_status == 0) {
        spdlog::info("初始化完成");
    } else {
        throw std::runtime_error("初始化失败");
    }
}

// 启动项
inline void start(void) {
    init();

    uint16_t port{ Config::config_yaml["server"]["port"].as<uint16_t>() };

    crow::SimpleApp app;

    // 关于其他的配置相关
    self::RouteOther other(app);
    other.favicon();
    other.draw();

    self::RouteUtils utils(app);
    utils.gaussianBlur();

    app.port(port).multithreaded().run_async();

    return;
}

#endif