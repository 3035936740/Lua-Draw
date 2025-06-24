local json = require("cjson")
local libself = require("libluadraw")
local phi = require("lua/api/phigros")
local phi = require("lua/lib/core")
local phi = require("lua/lib/utils")

require("lua/lib/core")

function getSvgCode(jsonObject)
    local data = json.decode(jsonObject)

    print(data)

    -- 打开文件
    local file = io.open("./svg/Input.svg", "r")

    if file then
        -- 读取文件内容
        content = file:read("*all")
        
        -- 关闭文件
        file:close()

        -- 将内容打印出来
        return export.success_control(content)
    end
    return export.error(1, 418, "teapot test")
end