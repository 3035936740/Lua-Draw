#pragma once

#include <iostream>
#include <fstream>
#include <memory>
#include <exception>
#include <stdexcept>
#include <utility>
#include <filesystem>
#include <locale>
#include <codecvt>
#include <string>
#include <span>

#include <Aspose.Words.Cpp/Document.h>
#include <Aspose.Words.Cpp/DocumentBuilder.h>
#include <Aspose.Words.Cpp/Drawing/Shape.h>
#include <Aspose.Words.Cpp/Drawing/ImageData.h>
#include <Aspose.Words.Cpp/SaveFormat.h>
#include <Aspose.Words.Cpp/Saving/IResourceSavingCallback.h>
#include <Aspose.Words.Cpp/Saving/ResourceSavingArgs.h>
#include <Aspose.Words.Cpp/Saving/SaveOutputParameters.h>
#include <Aspose.Words.Cpp/Saving/SvgSaveOptions.h>
#include <Aspose.Words.Cpp/Saving/SvgTextOutputMode.h>

#ifndef TEST_PROJECT_HPP
#define TEST_PROJECT_HPP  

namespace fs = std::filesystem;

class TestProject final {
public:
	inline static void test(void) {
		StartWatch();

		auto doc{ System::MakeObject<Aspose::Words::Document>() };
		auto builder{ System::MakeObject<Aspose::Words::DocumentBuilder>(doc) };

		std::wstring_convert<std::codecvt_utf8_utf16<char16_t>, char16_t> convert;
		std::u16string u16str = convert.from_bytes("Input.svg");
		auto shape{ builder->InsertImage(System::String(u16str)) };
		shape->get_ImageData()->Save(u"Output.jpg");
		auto result{ shape->get_ImageData()->get_ImageBytes() };
		auto data{ result->data() };
		std::string str(data.begin(), data.end());
		std::cout << str << std::endl;

		StopWatch();
	};
private:
	inline static std::chrono::system_clock::time_point start, end;

	inline static void StartWatch(void) {
		std::cout << "\033[42mstart watch\033[0m\n";
		start = std::chrono::high_resolution_clock::now();
	};

	inline static void StopWatch(void) {
		end = std::chrono::high_resolution_clock::now();
		std::chrono::duration<double, std::milli> elapsed = end - start;
		std::cout << "\033[42mtime consumed " << elapsed.count() << " ms\033[0m\n";
		std::cout.flush();
	};
};

#endif