#pragma once
#include "common/http_util.hpp"

namespace self::OtherService {
    inline crow::response favicon() {
        crow::response response;

        const std::string path{ Global::resource_path + "favicon.ico"s };

        if (!std::filesystem::exists(path)) {
            response.set_header("Content-Type", "application/json");
            response.code = 404;
            response.write(HTTPUtil::StatusCodeHandle::getSimpleJsonResult(404).dump(2));
            return response;
        }

        // 获取当前时间
        auto now{ std::chrono::system_clock::now() };

        // 计算七天后的时间
        auto seven_days_later{ now + std::chrono::hours(24 * 7) };

        // 将时间转换为时间戳（秒数）
        auto timestamp{ std::chrono::system_clock::to_time_t(seven_days_later) };

        // 将时间戳转换为 Crow 框架中的 Expires 数值
        std::stringstream ss;
        ss << std::put_time(std::gmtime(&timestamp), "%a, %d %b %Y %H:%M:%S GMT");
        std::string expires{ ss.str() };
        response.set_static_file_info(path);
        response.set_header("Cache-Control", "public");
        response.set_header("Expires", expires);
        return response;
    }
};
