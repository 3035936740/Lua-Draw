# Lua Draw
一个Lua + SVG + C++的后端绘图项目<br>

## 使用编译器
gcc 11

## C++标准是多少?
C++20

## Lua版本是多少?
Lua5.4

## C++用了哪些库?

<pre><code>- boost
- openssl
- sqlite3
- opencv
- sqlite-modern-cpp
- cryptopp
- nlohmann-json
- yaml-cpp
- spdlog
- fmt
- crow
- poco
- bcrypt-cpp
- generator_coroutine
- snowflake-cpp
- Aspose.Words.Cpp
- lua5.4
- libmagick++
</code></pre>

※使用了vcpkg需要自己手动配置cmake的vcpkg目录<br>
※使用了PkgConfig

## Lua用了哪些库?
<pre><code>- lua-cjson
- luasocket
- luafilesystem</code></pre>

## 怎么编译

<pre><code>$ mkdir build && cd build
$ cmake ..
$ make
</code></pre>

项目最终会生成到<b>bin</b>目录

<h2>平台</h2>
<ui>
<li>Linux Ubuntu22.04</li>
</ui>

## 编译通过后如何使用?(注:返回的会是图片)
<pre><code>$ curl -X POST -H "Authorization: Bearer bBjhGvsSgY6BvLbN4ZP4mHVBD9QbWc8C" -H "Content-Type: application/json" -d '{"imageType": "jpg", "data": {"path": "./public/0_score.png"}}' http://127.0.0.1:8555/draw/main/getSvgCode
</code></pre>