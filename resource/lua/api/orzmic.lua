local json = require("cjson")
local http = require("socket.http")
local ltn12 = require("ltn12")

api = {} 

function api.getMusicById(url, authorization, musicId)
    local data = {
        mode = 0, 
        key = tostring(musicId),
        is_nocase = false,
        field_index = 0
    }

    local payload = json.encode(data)

    local headers = {
        ["Content-Type"] = "application/json",
        ["Authorization"] = "Bearer " .. authorization,
        ["Content-Length"] = #payload;
    }

    local response_body = {}
    local result, status_code, response_headers = http.request{
        url = url .. "/api/orzmic/getMusic",
        method = "POST",
        headers = headers,
        source = ltn12.source.string(payload),
        sink = ltn12.sink.table(response_body)
    }

    return json.decode(table.concat(response_body)), status_code
end

function api.getPlayerInfo(url, authorization, qrcodeBase64)
    local data = {
        b64QRcode = qrcodeBase64,
        -- json = "{}"
    }

    local payload = json.encode(data)

    local headers = {
        ["Content-Type"] = "application/json",
        ["Authorization"] = "Bearer " .. authorization,
        ["Content-Length"] = #payload;
    }

    local response_body = {}
    local result, status_code, response_headers = http.request{
        url = url .. "/api/orzmic/qrcodeDecode",
        method = "POST",
        headers = headers,
        source = ltn12.source.string(payload),
        sink = ltn12.sink.table(response_body)
    }

    return json.decode(table.concat(response_body)), status_code
end

return api