#pragma once

#include "crow.h"
#include <filesystem>
#include "string"
#include <configuration/config.hpp>
#include <common/utils.hpp>
#include <service/other/other_service.hpp>
#include <opencv2/opencv.hpp>

namespace self {
	class RouteUtils final {
	private:
		crow::SimpleApp& m_app;
	public:
		RouteUtils() = delete;
		~RouteUtils() = default;
		RouteUtils(const RouteUtils&) = delete;
		RouteUtils(RouteUtils&&) = delete;
		RouteUtils& operator=(const RouteUtils&) = delete;
		RouteUtils& operator=(RouteUtils&&) = delete;

		explicit RouteUtils(crow::SimpleApp& app);

		void gaussianBlur(void);
	};
};

self::RouteUtils::RouteUtils(crow::SimpleApp& app) : m_app{ app } {};

void self::RouteUtils::gaussianBlur(void) {
	CROW_ROUTE(this->m_app, "/utils/GaussianBlur").methods(crow::HTTPMethod::Post)([&](const crow::request req) {
		return self::HandleResponseBody([&]() -> std::string {
			if (Global::is_auth) {
				std::string auth{ req.get_header_value("Authorization") };
				if (auth != ("Bearer "s + Global::authorization_code)) throw HTTPException(401);
			}

			json data{ json::parse(req.body.empty() ? "{}" : req.body) };
			std::exchange(data, data[0]);

			std::string imgOutType{ "jpg" };
			std::filesystem::path filePath, saveDir{ Global::temp_path };
			double sigmaX{ 25.0 }, sigmaY{ 0.0 };
			int borderType{ 4 }, ksizeX{ 0 }, ksizeY{ 0 };

			if (data.count("imageType"))imgOutType = data.at("imageType").get<std::string>();
			if (data.count("filePath"))filePath = data.at("filePath").get<std::string>();
			if (data.count("saveDir"))saveDir = data.at("saveDir").get<std::string>();
			if (data.count("sigmaX"))sigmaX = data.at("sigmaX").get<double>();
			if (data.count("sigmaY"))sigmaY = data.at("sigmaY").get<double>();
			if (data.count("borderType"))borderType = data.at("borderType").get<int>();
			if (data.count("ksizeX"))ksizeX = data.at("ksizeX").get<int>();
			if (data.count("ksizeY"))ksizeY = data.at("ksizeY").get<int>();

			cv::Mat img{ cv::imread(filePath, cv::IMREAD_UNCHANGED) };

			cv::GaussianBlur(img, img, cv::Size(ksizeX, ksizeY), sigmaX, sigmaY, borderType);

			std::string filename{ self::Tools::UUIDGenerator() + "." + imgOutType }, savePath{ saveDir / filename };
			cv::imwrite(savePath, img); // ±£´æÍ¼Æ¬

			img.release();

			json result;
			result["saveFilePath"] = savePath;
			result["filename"] = filename;

			return result.dump();
			});
		});
};