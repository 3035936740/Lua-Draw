local json = require("cjson")

function deleteTempGaussianBlurFile(obj)
    local data = json.decode(obj)
    local filePath = data.filePath
    os.remove(filePath)
end