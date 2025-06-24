local json = require("cjson")

core = {}

-- json编码
function core.encode(status, svg_code, data, extra_control)
    status = status or 0
    svg_code = svg_code or ""
    data = data or nil
    extra_control = extra_control or false

    payload = json.encode({
	status = status,
	code = svg_code,
	data = data,
	extraControl = extra_control
    })

    return tostring(payload)
end

-- 抛出HTTP错误
function core.error(status, code, msg, extra)
    extra = extra or {}
    msg = msg or ""

    return core.encode(status, "", {msg = msg, code = code, extra = extra}, false)
end

-- 复杂操作(第二步执行)
function core.complete_control(svg_code, lua_file, lua_function , content)
    local data = {
        luaFile = lua_file,
        luaFunction = lua_function,
        content = content or {}
    }
    return core.encode(0, svg_code, data, true)
end

-- 成功操作
function core.success_control(svg_code)
    return core.encode(0, svg_code)
end

return core