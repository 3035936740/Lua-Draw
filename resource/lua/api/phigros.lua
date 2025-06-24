local json = require("cjson")
local http = require("socket.http")
local ltn12 = require("ltn12")

api,phi = {},{} 

function api.getAPI(url, authorization, sessionToken)
    local headers = {
        ["Content-Type"] = "application/json",
        ["Authorization"] = "Bearer " .. authorization,
        ["SessionToken"] = sessionToken
    }

    local response_body = {}
    local result, status_code, response_headers = http.request{
        url = url,
        method = "GET",
        headers = headers,
        sink = ltn12.sink.table(response_body), 
    }

    return json.decode(table.concat(response_body)), status_code
end

function api.GetMusic(url, authorization, songid)
    local songinfo, songinfo_status_code = api.getAPI(url, authorization)
end

function api.MatchAlias(url, authorization, q)
    local data = {
        query = q, 
        hitsPerPage = 1
    }

    local payload = json.encode(data)

    local headers = {
        ["Content-Type"] = "application/json",
        ["Authorization"] = "Bearer " .. authorization,
        ["Content-Length"] = #payload;
    }

    local response_body = {}
    local result, status_code, response_headers = http.request{
        url = url,
        method = "POST",
        headers = headers,
        source = ltn12.source.string(payload),
        sink = ltn12.sink.table(response_body)
    }

    return json.decode(table.concat(response_body)), status_code
end

function api.background_match(url, background_name, illustration_root_dir, authorization)
    local matchInfo, matchInfo_status_code
    if string.len(background_name) > 0 then
        local result = {api.MatchAlias(url, authorization, background_name)}
        matchInfo = result[1]
        matchInfo_status_code = result[2]
    end

    local songinfo = nil

    if #matchInfo == 0 then
        url = "http://127.0.0.1:8299/proxy/phi/song?songid=" .. background_name
        local songinfo_temp, songinfo_status_code = api.getAPI(url, authorization)
        if songinfo_temp == nil then
            url = "http://127.0.0.1:8299/proxy/phi/song?songid=" .. "152"
            songinfo_temp, songinfo_status_code = api.getAPI(url, authorization)
        end
        songinfo = songinfo_temp
    else
        local songid = matchInfo[1].id
        url = "http://127.0.0.1:8299/proxy/phi/song?songid=" .. songid
        local songinfo_temp, songinfo_status_code = api.getAPI(url, authorization)
        songinfo = songinfo_temp
    end

    local illustration_path = illustration_root_dir .. songinfo.illustrationPath

    return illustration_path
end

function phi.score_rate_image(score, is_fc)
    local result, rate = "resource/phi/rating/uniformSize/F_new.png", 0
    if score >= 1000000 then
    -- phi --> 7
        result = "resource/phi/rating/uniformSize/phi_new.png"
        rate = 7
    elseif is_fc then
    -- V(blue) --> 6
        result = "resource/phi/rating/uniformSize/V_FC.png"
        rate = 6
    elseif score >= 960000 then
    -- V --> 5
        result = "resource/phi/rating/uniformSize/V_new.png"
        rate = 5
    elseif score >= 920000 then
    -- S --> 4
        result = "resource/phi/rating/uniformSize/s_new.png"
        rate = 4
    elseif score >= 880000 then
    -- A --> 3
        result = "resource/phi/rating/uniformSize/a_new.png"
        rate = 3
    elseif score >= 820000 then
    -- B --> 2
        result = "resource/phi/rating/uniformSize/B_new.png"
        rate = 2
    elseif score >= 700000 then
    --C --> 1
        result = "resource/phi/rating/uniformSize/C_new.png"
        rate = 1
    else
    --Fales --> 0
        result = "resource/phi/rating/uniformSize/F_new.png"
        rate = 0
    end

    return result, rate
end

function phi.challenge_mode_rank_image(challengeModeRank)
    local courseRatingImg,rate = "resource/phi/rating/uniformSize/0.png",0
    if challengeModeRank >= 500 then
        rate = 5
        courseRatingImg = "resource/phi/rating/uniformSize/5.png"
    elseif challengeModeRank >= 400 then
        rate = 4
        courseRatingImg = "resource/phi/rating/uniformSize/4.png"
    elseif challengeModeRank >= 300 then
        rate = 3
        courseRatingImg = "resource/phi/rating/uniformSize/3.png"
    elseif challengeModeRank >= 200 then
        rate = 2
        courseRatingImg = "resource/phi/rating/uniformSize/2.png"
    elseif challengeModeRank >= 100 then
        rate = 1
        courseRatingImg = "resource/phi/rating/uniformSize/1.png"
    else
        rate = 0
        courseRatingImg = "resource/phi/rating/uniformSize/0.png"
    end
    return courseRatingImg,rate
end

return api,phi