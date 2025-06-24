/*
 * @File	  : self_exception.hpp
 * @Coding	  : utf-8
 * @Author    : Bing
 * @Time      : 2023/03/05 21:15
 * @Introduce : 文件异常类
*/

#pragma once

#include <exception>
#include <stdexcept>
#include <limits>
#include <string>
#include <string_view>

#ifndef SELF_EXCEPTION_HPP
#define SELF_EXCEPTION_HPP  

namespace self {
    namespace ExceptionInfo {
        namespace {
            inline constexpr const int _INT_MIN{ -2147483648 };
        }
    }

    class FileException : public std::exception {
    private:
        const char* msg{ "File Exception" };
    public:
        FileException(const char* msg) {
            this->msg = msg;
        }

        const char* getMessage() {
            return msg;
        }

        virtual const char* what() const throw() {
            return msg;
        }
    };

    class TimeoutException : public std::runtime_error {
    private:
        const char* msg{};
    public:
        TimeoutException(const char* msg = "Timeout Exception") : std::runtime_error(msg) {
            this->msg = msg;
        };

        const char* getMessage() {
            return msg;
        }

        virtual const char* what() const throw() override {
            return msg;
        }
    };

    class HTTPException : public std::runtime_error {
    private:
        std::string msg{};
        unsigned short code{ 500 };
        int status{ ExceptionInfo::_INT_MIN };
        json extra{};
    public:
        explicit HTTPException(std::string_view msg = "Severe HTTP Error", unsigned short code = 500, const json& extra = json(), int status = ExceptionInfo::_INT_MIN) : std::runtime_error(msg.data()) {
            this->msg = msg;
            this->code = code;
            this->extra = extra;
            this->status = status;
        };

        HTTPException& operator=(const HTTPException& rhs) {
            this->code = rhs.code;
            this->msg = rhs.msg;
            this->status = rhs.status;
            this->extra = rhs.extra;
            return *this;
        }

        HTTPException(unsigned short code) : HTTPException("", code) { };

        HTTPException(unsigned short code, const std::string& msg) : HTTPException(msg, code) { };

        HTTPException(unsigned short code, int status, const std::string& msg) : HTTPException(msg, code, json(), status) { };

        HTTPException(unsigned short code, const json& extra) : HTTPException("", code, extra) { };

        HTTPException(unsigned short code, int status, const json& extra) : HTTPException("", code, extra, status) { };

        const std::string& getMessage() const {
            return this->msg;
        }

        const unsigned short getCode() const {
            return this->code;
        }

        const int getStatus() const {
            return this->status;
        }
        
        json getJson() const {
            return this->extra;
        }

        virtual const char* what() const throw() override {
            return this->msg.data();
        }
    };
};

#endif