local json = require("cjson")
require("lua/lib/core")

function getSvgCode(jsonObject)
    local data = json.decode(jsonObject)

    -- 打开文件
    local file = io.open("./svg/example.svg", "r")
    local content = "";

    if file then
        -- 读取文件内容
        content = string.format(file:read("*all"), data.path)
        
        -- 关闭文件
        file:close()
        
        -- 将内容打印出来
        return core.success_control(content)
    end
    return core.error(1, 418, "teapot test")
end