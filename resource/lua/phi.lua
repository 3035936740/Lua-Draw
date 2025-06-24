local libself = require("libluadraw")
local json = require("cjson")
require("lua/api/phigros")
require("lua/lib/core")
require("lua/lib/utils")

local illustration_root_dir = "/home/resources/phigros"

baseurl = "http://127.0.0.1:8299/proxy"

function bindinfo(obj)
    local data = json.decode(obj)

    local has_avatar = data.__imagePath[1] ~= nil

    local url = baseurl .. "/phi/all"
    local all_data, all_status_code = api.getAPI(url, data.authorization, data.sessionToken)
    url = baseurl .. "/phi/record"
    local record_data, record_status_code = api.getAPI(url, data.authorization, data.sessionToken)

    url = baseurl .. "/phi/matchAlias"

    
    if record_status_code >= 400 or all_status_code >= 400 then
        return core.error(1, record_status_code)
    end

    local background = all_data.content.other.background

    local matchInfo, matchInfo_status_code
    if string.len(background) > 0 then
        local result = {api.MatchAlias(url, data.authorization, background)}
        matchInfo = result[1]
        matchInfo_status_code = result[2]
    end

    local songid = matchInfo[1].id

    url = baseurl .. "/phi/song?songid=" .. songid
    local songinfo, songinfo_status_code = api.getAPI(url, data.authorization)

    local illustration_path = illustration_root_dir .. songinfo.illustrationPath

    local record_size = #record_data.content.data

    local max_rks,min_rks = record_data.content.statisticalRKS.maxRKS, record_data.content.statisticalRKS.minRKS
    local middle_rks = min_rks + (max_rks - min_rks) / 2
    local min_timestamp, max_timestamp = 
    record_data.content.data[1].timestamp, record_data.content.data[record_size].timestamp

    local indistinguishable_max, indistinguishable_min = record_data.content.statisticalChallengeModeRank.indistinguishableMax, record_data.content.statisticalChallengeModeRank.indistinguishableMin

    local indistinguishable_middle = indistinguishable_min + (indistinguishable_max - indistinguishable_min) / 2

    local line_rks = ""
    local circle_rks = ""
    local line_cmr = ""
    local crm_rank_svg = ""

    -- min_y: 174  ,  max_y: 375   =>  201
    -- min_x: 1144 ,  max_x: 1880  =>  736

    --[[
        0.white: rgb(255, 255, 255)
        1.green: rgb(86, 221, 82)
        2.blue: rgb(115, 148, 223)
        3.red: rgb(242, 102, 102)
        4.gold: rgb(224, 238, 71)
        5.rainbow: url(#rainbow-rank)
    ]]

    if record_size > 1 then
        for key, record in ipairs(record_data.content.data) do
            -- record_size
            local min_x, max_y = 1144, 375
            local x = min_x + 736 * (record.timestamp - min_timestamp) / (max_timestamp - min_timestamp)
            local y = max_y - 201 * (record.rks - min_rks) / (max_rks - min_rks)   

            if utils.isnan(y) then
                y = 274.0
            end
            

            local pass = false
            if key ~= 1 and key ~= record_size then
                if record.rks == record_data.content.data[key + 1].rks and record.rks == record_data.content.data[key - 1].rks then
                    pass = true
                end
            end

            if not pass then
                -- circle_rks = circle_rks .. string.format("<circle cx=\"%.0f\" cy=\"%.0f\" r=\"6\" fill=\"rgb(255, 255, 255)\" stroke=\"rgb(220, 220, 220)\" stroke-width=\"1\" />", x, y)
                line_rks = line_rks .. string.format(" %.0f,%.0f", x, y)
            end

            min_x, max_y = 991, 902
            local rank = record.challengeModeRank
            x = min_x + 736 * (record.timestamp - min_timestamp) / (max_timestamp - min_timestamp)
            y = max_y - 201 * (rank % 100 - indistinguishable_min) / (indistinguishable_max - indistinguishable_min)
            
            if utils.isnan(y) then
                y = 801.0
            end

            --[[
            local color = "rgb(255, 255, 255)"

            if rank >= 500 then
                color = "url(#rainbow-rank)"
            elseif rank >= 400 then
                color = "rgb(251, 255, 0)"
            elseif rank >= 300 then
                color = "rgb(255, 98, 0)"
            elseif rank >= 200 then
                color = "rgb(0, 247, 255)"
            elseif rank >= 100 then
                color = "rgb(60, 255, 0)"
            end
            ]]--

            local crm_img = "resource/phi/diamond/CMR_0.png"

            if rank >= 500 then
                crm_img = "resource/phi/diamond/CMR_5.png"
            elseif rank >= 400 then
                crm_img = "resource/phi/diamond/CMR_4.png"
            elseif rank >= 300 then
                crm_img = "resource/phi/diamond/CMR_3.png"
            elseif rank >= 200 then
                crm_img = "resource/phi/diamond/CMR_2.png"
            elseif rank >= 100 then
                crm_img = "resource/phi/diamond/CMR_1.png"
            end

            pass = false
            if key ~= 1 and key ~= record_size then
                if record.challengeModeRank == record_data.content.data[key + 1].challengeModeRank and record.challengeModeRank == record_data.content.data[key - 1].challengeModeRank then
                    pass = true
                end
            end
            
            if not pass then
                line_cmr = line_cmr .. string.format(" %.0f,%.0f", x, y)
                crm_rank_svg = crm_rank_svg .. string.format("<image x=\"%.0f\" y=\"%.0f\" href=\"%s\" width=\"24\" height=\"24\"/>", x - 12, y - 12, crm_img)
            end
        end
    else
        -- circle_rks = circle_rks .. string.format("<circle cx=\"1144\" cy=\"375\" r=\"6\" fill=\"rgb(255, 255, 255)\" stroke=\"rgb(220, 220, 220)\" stroke-width=\"1\" />")
        -- circle_rks = circle_rks .. string.format("<circle cx=\"1880\" cy=\"174\" r=\"6\" fill=\"rgb(255, 255, 255)\" stroke=\"rgb(220, 220, 220)\" stroke-width=\"1\" />")
        line_rks = line_rks .. string.format("1144,375 1880,174")

        local rank = record_data.content.statisticalChallengeModeRank.min
        
        local crm_img = "resource/phi/diamond/CMR_0.png"

        if rank >= 500 then
            crm_img = "resource/phi/diamond/CMR_5.png"
        elseif rank >= 400 then
            crm_img = "resource/phi/diamond/CMR_4.png"
        elseif rank >= 300 then
            crm_img = "resource/phi/diamond/CMR_3.png"
        elseif rank >= 200 then
            crm_img = "resource/phi/diamond/CMR_2.png"
        elseif rank >= 100 then
            crm_img = "resource/phi/diamond/CMR_1.png"
        end

        crm_rank_svg = crm_rank_svg .. string.format("<image x=\"979\" y=\"890\" href=\"%s\" width=\"24\" height=\"24\"/>", crm_img)
        crm_rank_svg = crm_rank_svg .. string.format("<image x=\"1715\" y=\"689\" href=\"%s\" width=\"24\" height=\"24\"/>", crm_img)
        line_cmr = line_cmr .. string.format("991,902 1727,701")
    end

    utils.authorization = "bBjhGvsSgY6BvLbN4ZP4mHVBD9QbWc8C"

    local gaussianBlurFilePath = utils.gaussianBlurSimple(illustration_path, 30).saveFilePath

    -- 打开文件
    local file = io.open("svg/phi/bindinfo.svg", "r")
    local content = "";

    if file then
        -- 读取文件内容
        -- 头像路径

        local avatarPath = illustration_root_dir
        if all_data.content.other.avatarHasEnable then
            avatarPath = avatarPath .. all_data.content.other.avatarPath
        else
            avatarPath = avatarPath .. "/avatar/avatar.Introduction.png"
        end
        
        if has_avatar then
            avatarPath = data.__imagePath[1]
        end

        local nicknameSize = 48

        local nickname = libself.handle_text(
            all_data.content.playerNickname,
            "resource/fonts/SourceHanSansCNFontFix-Regular.ttf",
            nicknameSize, 350
            )
            
        local profileSize = 32
        local max_row = 9
        
        -- 课题模式分数
        local challengeModeRank = all_data.content.challengeModeRank
        local courseRatingImg = ""

        if challengeModeRank >= 500 then
			courseRatingImg = "resource/phi/rating/uniformSize/5.png"
		elseif challengeModeRank >= 400 then
			courseRatingImg = "resource/phi/rating/uniformSize/4.png"
		elseif challengeModeRank >= 300 then
			courseRatingImg = "resource/phi/rating/uniformSize/3.png"
		elseif challengeModeRank >= 200 then
			courseRatingImg = "resource/phi/rating/uniformSize/2.png"
		elseif challengeModeRank >= 100 then
			courseRatingImg = "resource/phi/rating/uniformSize/1.png"
		else
			courseRatingImg = "resource/phi/rating/uniformSize/0.png"
        end

        challengeModeRank = challengeModeRank % 100
        
        -- rks保留后2位(四舍五入)
        local rks = string.format("%.2f", all_data.content.rankingScore)

        local profile = libself.handle_text(
            all_data.content.other.profile,
            "resource/fonts/SourceHanSansCNFontFix-Regular.ttf",
            profileSize, 646, true, max_row
            )

        local profile_init_pos = 620

        local profile_init_pos = profile_init_pos - ((#profile / 2) * 50)
        
        local svg_profile = ""

        for k, v in ipairs(profile) do
            svg_profile = svg_profile .. string.format("<tspan x=\"34\" y=\"%d\">%s</tspan>", (k - 1) * 50, utils.escapeHtml(v))
        end

        content = string.format(
            file:read("*all"), 
            gaussianBlurFilePath, 
            avatarPath,
            nicknameSize,
            utils.escapeHtml(nickname),
            courseRatingImg,
            challengeModeRank,
            rks,
            profile_init_pos,
            profileSize,
            svg_profile,
            string.format("%.2f", min_rks),
            string.format("%.2f", middle_rks),
            string.format("%.2f", max_rks),
            os.date("%y-%m-%d", min_timestamp),
            os.date("%y-%m-%d", max_timestamp),
            line_rks,
            circle_rks,
            string.format("%.0f", indistinguishable_min),
            string.format("%.0f", indistinguishable_middle),
            string.format("%.0f", indistinguishable_max),
            os.date("%y-%m-%d", min_timestamp),
            os.date("%y-%m-%d", max_timestamp),
            line_cmr,
            crm_rank_svg,
            utils.timestampToDate(os.time())
        )
        -- 关闭文件
        file:close()

        -- 将内容打印出来
        return core.complete_control(content, "lua/extra/general.lua", "deleteTempGaussianBlurFile", {filePath = gaussianBlurFilePath})
    end
    return core.error(1, 500, "draw lua has mistake.")
end

function batch(obj)
    local data = json.decode(obj)

    -- 获取rating范围
    local ratings = data.rating

    if type(ratings) == "number" then
        ratings = {ratings,ratings}
    elseif type(ratings) == "table" then
        if #ratings < 1 then
            return core.error(2, 400, "Incorrect rating")
        elseif #ratings == 1 then
            ratings[2] = ratings[1]
        end
    else
        return core.error(2, 400, "rating type error")
    end

    -- 获取batch的api
    local url = string.format(baseurl .. "/phi/getBatch?rating1=%.1f&rating2=%.1f",ratings[1],ratings[2])
    
    local batch_data, all_status_code = api.getAPI(url, data.authorization, data.sessionToken)

    if all_status_code >= 400 then
        return core.error(1, record_status_code)
    end

    -- 头像设置相关
    local has_avatar = data.__imagePath[1] ~= nil

    -- 头像的路径获取
    local avatar_path = illustration_root_dir
    if batch_data.playerInfo.other.avatarHasEnable then
        avatar_path = avatar_path .. batch_data.playerInfo.other.avatarPath
    else
        avatar_path = avatar_path .. "/avatar/avatar.Introduction.png"
    end
    
    if has_avatar then
        avatar_path = data.__imagePath[1]
    end

    local match_url = baseurl .. "/phi/matchAlias"

    -- 背景图片路径
    local background_path = api.background_match(match_url, batch_data.playerInfo.other.background, illustration_root_dir, data.authorization)

    -- 图片高斯模糊处理
    utils.authorization = "bBjhGvsSgY6BvLbN4ZP4mHVBD9QbWc8C"
    -- 高斯模糊路径
    local gaussianblur_file_path = utils.gaussianBlurSimple(background_path, 35).saveFilePath

    -- 读取svg并且处理
    local file = io.open("svg/phi/batch.svg", "r")
    local content = ""

    --[[
    local w,h = libself.get_text_size(
        "wwaaabbb你是我是",
        "resource/fonts/SourceHanSansCNFontFix-Regular.ttf",30)
    print(w,h)
    ]]--

    if file then
        local hw_scale,fixed_width, min_height = 2048 / 1080, utils.toSVGScale(1080),utils.toSVGScale(570) - 1
        local fixed_offset_x = utils.toSVGScale(512) * hw_scale

        -- 整体图像高度
        -- 480为上部分的基础
        local global_height = 480 - 1 
       
        -- 玩家框相关
        local nickname, nickname_font_size, max_nickname_width = batch_data.playerInfo.playerNickname, 48, 400
        local phi_medium_font_path = "resource/fonts/SourceHanSansCN_SairaCondensed_Hybrid_Medium.ttf"

        nickname = libself.handle_text(
            nickname,
            phi_medium_font_path,
            nickname_font_size, max_nickname_width
        )

        nickname = utils.escapeHtml(nickname)
        
        -- text position + 46
        local nickname_w,nickname_h = libself.get_text_size(
            nickname,
            phi_medium_font_path,
            nickname_font_size)
            nickname_w,nickname_h = utils.toSVGScale(nickname_w), utils.toSVGScale(nickname_h)

        local form_min_pos = fixed_width - nickname_w - 32 - 300 - 96
        local player_info_svg = string.format('<polygon transform="translate(0,38)" points="%.0f,0 1440,0 1440,116 %.0f,116" style="fill: black;fill-opacity: 0.4;" />',
            form_min_pos + 32, form_min_pos
        )

        -- 课题模式分数
        local challenge_mode_rank = batch_data.playerInfo.challengeModeRank
        local course_rating_img = phi.challenge_mode_rank_image(challenge_mode_rank)

        challenge_mode_rank = challenge_mode_rank % 100
        
        local player_rks = batch_data.playerInfo.rankingScore

        local played_data_svg,lock_song_svg,rating_label_svg = "","",""

        --[[
            batch_record:
            1: Clear
            2: FC
            3: AP
            batch_statistics:
            1: /
            2: False
            3: C
            4: B
            5: A
            6: S
            7: V
            8: V(Blue)
            9: Phi
        ]]--
        local batch_record, batch_statistics = {}, {0,0,0,0,0,0,0,0,0}
        batch_record["ez"] = {0,0,0}
        batch_record["hd"] = {0,0,0}
        batch_record["in"] = {0,0,0}
        batch_record["at"] = {0,0,0}

        local batch_level_color = {}
        batch_level_color['ez'] = "#59b852"
        batch_level_color['hd'] = "#3748e9"
        batch_level_color['in'] = "#d71c25"
        batch_level_color['at'] = "#939393"

        local back_level_from_color = {}
        back_level_from_color['ez'] = "#29b71e"
        back_level_from_color['hd'] = "#505fe9"
        back_level_from_color['in'] = "#963b3e"
        back_level_from_color['at'] = "#939393"
        back_level_from_color['unknown'] = "#595959" -- unknown

        local batch = batch_data.batch
        if batch then

            -- 对数据汇总
            for r=ratings[1],ratings[2]+0.1,0.1 do
                local rating_key = string.format("%.1f",r)

                if batch[rating_key] then
                    local lock_song_count,has_divide = 0,false
                    local rating_label_offset_y = 73
                    global_height = global_height + rating_label_offset_y
                    -- 绘制分级标签和分隔线
                    rating_label_svg = rating_label_svg .. string.format('<rect x="34" y="%.0f" width="534" height="13" fill="white" stroke-width="0" stroke-opacity="0" /><rect x="866" y="%.0f" width="534" height="13" fill="white" stroke-width="0" stroke-opacity="0" /><text x="719" y="%.0f" fill="white" font-family="Source Han Sans CN Font Fix" font-size="85" text-anchor="middle">%s</text>',
                        global_height, global_height, global_height + 40, r)
                    global_height = global_height + 82

                    local batch_ranking = 1

                    for k, v in ipairs(batch[rating_key]) do
                        -- big: 262,form: 28
                        -- 信息
                        local info = v.info
                        local level = info.level
                        if v.playedLevel then
                            local score,rks,acc = v.record.score,v.record.rks,v.record.acc
                            local evaluate_path = phi.score_rate_image(score,v.record.isfc)
                            local title = libself.handle_text(
                                info.title,
                                "resource/fonts/SourceHanSansCNFontFix-Regular.ttf",
                                16, 195
                            )

                            local info_form_svg = string.format('<polygon transform="translate(55,%.0f)" points="46,0 1322,0 1276,173 0,173" fill="%s" fill-opacity="0.5"/>', global_height + 28, back_level_from_color[level])
                            local ill_svg = ""
                            local ill_init_x = 34
                            if batch_ranking % 2 == 1 then
                                -- 奇
                                local ill_init_x = 34

                                -- 难度颜色
                                ill_svg = string.format(
                                    '<polygon transform="translate(%d,%.0f)" points="62,0 435,0 373,230 0,230" fill="%s" fill-opacity="0.5"/>',
                                    ill_init_x - 7, global_height + 5, batch_level_color[level]
                                )

                                -- 曲绘
                                ill_svg = ill_svg .. string.format(
                                    '<image transform="translate(%d,%.0f)" href="%s" width="436" height="240" clip-path="url(#cover-parallelogram)"/>', 
                                    ill_init_x, global_height, illustration_root_dir .. info.illustrationPath)
        
                                -- 图像特有的阴影效果
                                ill_svg = ill_svg .. string.format(
                                    '<image transform="translate(%d,%.0f)" href="resource/phi/ill_shadow.png" width="436" height="240" clip-path="url(#cover-parallelogram)"/>',
                                    ill_init_x, global_height)
        
                                -- 排名框
                                ill_svg = ill_svg .. string.format(
                                    '<polygon transform="translate(%d,%.0f)" points="9,0 46,0 37,33 0,33" fill="#b2b2b2"/><polygon transform="translate(%d,%.0f)" points="8,0 40,0 32,29 0,29" fill="#4d4d4d"/>',
                                    ill_init_x + 60, global_height + 10,ill_init_x + 63, global_height + 12
                                )
        
                                -- 分数排名
                                ill_svg = ill_svg .. string.format(
                                    '<text x="%d" y="%.0f" fill="white" font-family="Source Han Sans CN Font Fix" font-size="19" text-anchor="middle">%02d</text>', 
                                    ill_init_x + 83, global_height + 34,batch_ranking)

                                -- 曲目标题
                                ill_svg = ill_svg .. string.format(
                                    '<text x="%d" y="%.0f" fill="white" font-family="Source Han Sans CN Font Fix" font-size="23">%s</text>',
                                    ill_init_x + 10, global_height + 223, utils.escapeHtml(title)
                                )

                                -- 曲目难度
                                ill_svg = ill_svg .. string.format(
                                    '<text x="%d" y="%.0f" fill="white" font-family="Source Han Sans CN Font Fix" font-size="23" text-anchor="end">%s</text>',
                                    ill_init_x + 370, global_height + 223, string.upper(level) .. ". " .. rating_key
                                )

                                -- +20
                                -- 得到的评级
                                ill_svg = ill_svg .. string.format(
                                    '<image transform="translate(%d,%.0f)" href="%s" width="200" height="200"/>',
                                    ill_init_x + 400, global_height + 14, evaluate_path
                                )

                                -- Score相关
                                ill_svg = ill_svg .. string.format(
                                    '<text x="%d" y="%.0f" fill="white" font-family="Source Han Sans CN Font Fix" font-size="43">Best Score</text>',
                                    ill_init_x + 570, global_height + 96
                                )

                                ill_svg = ill_svg .. string.format(
                                    '<text x="%d" y="%.0f" fill="white" font-family="Source Han Sans CN Font Fix" font-size="85">%07d</text>',
                                    ill_init_x + 562, global_height + 174, score
                                )

                                -- 分隔线
                                ill_svg = ill_svg .. string.format(
                                    '<image transform="translate(996,%.0f)" href="resource/phi/batach_divider_line.png" width="41" height="135"/>',
                                    global_height + 46
                                )

                                -- 标记
                                ill_svg = ill_svg .. string.format(
                                    '<text x="%d" y="%.0f" fill="white" font-family="Source Han Sans CN Font Fix" font-size="45">Rate</text>',
                                    ill_init_x + 1016, global_height + 106
                                )
                                ill_svg = ill_svg .. string.format(
                                    '<text x="%d" y="%.0f" fill="white" font-family="Source Han Sans CN Font Fix" font-size="45">Acc</text>',
                                    ill_init_x + 1003, global_height + 166
                                )

                                -- Rate和Acc
                                ill_svg = ill_svg .. string.format(
                                    '<text x="%d" y="%.0f" fill="white" font-family="Source Han Sans CN Font Fix" font-size="45" text-anchor="end">%.2f</text>',
                                    1320, global_height + 106, rks
                                )
                                ill_svg = ill_svg .. string.format(
                                    '<text x="%d" y="%.0f" fill="white" font-family="Source Han Sans CN Font Fix" font-size="45" text-anchor="end">%.2f%%</text>',
                                    1308, global_height + 166, acc
                                )
                            else
                                -- 偶
                                local ill_init_x = 962

                                -- 难度颜色
                                ill_svg = string.format(
                                    '<polygon transform="translate(%d,%.0f)" points="62,0 435,0 373,230 0,230" fill="%s" fill-opacity="0.5"/>',
                                    ill_init_x + 5, global_height + 5, batch_level_color[level]
                                )

                                -- 曲绘
                                ill_svg = ill_svg .. string.format(
                                    '<image transform="translate(%d,%.0f)" href="%s" width="436" height="240" clip-path="url(#cover-parallelogram)"/>',
                                    ill_init_x, global_height, illustration_root_dir .. info.illustrationPath)
        
                                -- 图像特有的阴影效果
                                ill_svg = ill_svg .. string.format(
                                    '<image transform="translate(%d,%.0f)" href="resource/phi/ill_shadow.png" width="436" height="240" clip-path="url(#cover-parallelogram)"/>',
                                    ill_init_x, global_height)
                                
                                -- 排名框
                                ill_svg = ill_svg .. string.format(
                                    '<polygon transform="translate(%d,%.0f)" points="9,0 46,0 37,33 0,33" fill="#b2b2b2"/><polygon transform="translate(%d,%.0f)" points="8,0 40,0 32,29 0,29" fill="#4d4d4d"/>',
                                    ill_init_x + 60, global_height + 10,ill_init_x + 63, global_height + 12
                                )
        
                                -- 分数排名
                                ill_svg = ill_svg .. string.format(
                                    '<text x="%d" y="%.0f" fill="white" font-family="Source Han Sans CN Font Fix" font-size="19" text-anchor="middle">%02d</text>', 
                                    ill_init_x + 83, global_height + 34,batch_ranking)

                                -- 曲目标题
                                ill_svg = ill_svg .. string.format(
                                    '<text x="%d" y="%.0f" fill="white" font-family="Source Han Sans CN Font Fix" font-size="23">%s</text>',
                                    ill_init_x + 10, global_height + 223, utils.escapeHtml(title)
                                )

                                -- 曲目难度
                                ill_svg = ill_svg .. string.format(
                                    '<text x="%d" y="%.0f" fill="white" font-family="Source Han Sans CN Font Fix" font-size="23" text-anchor="end">%s</text>',
                                    ill_init_x + 370, global_height + 223, string.upper(level) .. ". " .. rating_key
                                )

                                -- -20
                                -- 得到的评级
                                ill_svg = ill_svg .. string.format(
                                    '<image transform="translate(%d,%.0f)" href="%s" width="200" height="200"/>',
                                    ill_init_x - 174, global_height + 14, evaluate_path
                                )

                                ill_svg = ill_svg .. string.format(
                                    '<text x="%d" y="%.0f" fill="white" font-family="Source Han Sans CN Font Fix" font-size="43">Best Score</text>',
                                    ill_init_x - 530, global_height + 96
                                )

                                ill_svg = ill_svg .. string.format(
                                    '<text x="%d" y="%.0f" fill="white" font-family="Source Han Sans CN Font Fix" font-size="85">%07d</text>',
                                    ill_init_x - 534, global_height + 174, score
                                )

                                -- 分隔线
                                ill_svg = ill_svg .. string.format(
                                    '<image transform="translate(373,%.0f)" href="resource/phi/batach_divider_line.png" width="41" height="135"/>',
                                    global_height + 46
                                )

                                -- 标记
                                ill_svg = ill_svg .. string.format(
                                    '<text x="%d" y="%.0f" fill="white" font-family="Source Han Sans CN Font Fix" font-size="45">Rate</text>',
                                    112, global_height + 106
                                )
                                ill_svg = ill_svg .. string.format(
                                    '<text x="%d" y="%.0f" fill="white" font-family="Source Han Sans CN Font Fix" font-size="45">Acc</text>',
                                    99, global_height + 166
                                )

                                -- Rate和Acc
                                ill_svg = ill_svg .. string.format(
                                    '<text x="%d" y="%.0f" fill="white" font-family="Source Han Sans CN Font Fix" font-size="45" text-anchor="end">%.2f</text>',
                                    370, global_height + 106, rks
                                )
                                ill_svg = ill_svg .. string.format(
                                    '<text x="%d" y="%.0f" fill="white" font-family="Source Han Sans CN Font Fix" font-size="45" text-anchor="end">%.2f%%</text>',
                                    358, global_height + 166, acc
                                )
                            end
        
                            -- 有数据的
                            -- 记录
                            local record = v.record
                            local __, type = phi.score_rate_image(record.score, record.isfc)
                            batch_statistics[type + 2] = batch_statistics[type + 2] + 1
                            if type == 7 then
                                batch_record[level][3] = batch_record[level][3] + 1
                                batch_record[level][2] = batch_record[level][2] + 1
                                batch_record[level][1] = batch_record[level][1] + 1
                            elseif type == 6 then
                                batch_record[level][2] = batch_record[level][2] + 1
                                batch_record[level][1] = batch_record[level][1] + 1
                            else
                                batch_record[level][1] = batch_record[level][1] + 1
                            end
        
                            played_data_svg = played_data_svg .. info_form_svg .. ill_svg
                            global_height = global_height + 262
                            batch_ranking = batch_ranking + 1
                        else
                            if batch_ranking % 2 ~= 1 then
                                global_height = global_height + 44
                                batch_ranking = 1
                            end
                            local single_lock_song_svg = ""
                            lock_song_count = lock_song_count + 1
                            has_divide = true
                            -- 无数据的
                            batch_statistics[1] = batch_statistics[1] + 1

                            local extend_lock_song = (lock_song_count - 1) % 4

                            single_lock_song_svg = string.format(
                                '<polygon transform="translate(%d,%.0f)" points="36,0 272,0 236,144 0,144"  fill="%s" fill-opacity="0.5"/>',
                                54 + 340 * extend_lock_song ,global_height + 4, batch_level_color[level]
                            )

                            single_lock_song_svg = single_lock_song_svg .. string.format(
                                '<image transform="translate(%d,%.0f)" href="%s" width="273" height="144" clip-path="url(#lock-cover-parallelogram)"/>',
                                60 + 340 * extend_lock_song ,global_height, illustration_root_dir .. info.illustrationPath
                            )

                            single_lock_song_svg = single_lock_song_svg .. string.format(
                                '<polygon transform="translate(%d,%.0f)" points="36,0 272,0 236,144 0,144" fill="black" fill-opacity="0.5"/>',
                                60 + 340 * extend_lock_song ,global_height
                            )

                            single_lock_song_svg = single_lock_song_svg .. string.format(
                                '<image transform="translate(%d,%.0f)" href="resource/phi/lock.png" width="153" height="153"/>',
                                123 + 340 * extend_lock_song ,global_height
                            )

                            local title = libself.handle_text(
                                info.title,
                                "resource/fonts/SourceHanSansCNFontFix-Regular.ttf",
                                10, 120
                            )

                            single_lock_song_svg = single_lock_song_svg .. string.format(
                                '<text x="%d" y="%.0f" fill="white" font-family="Source Han Sans CN Font Fix" font-size="14">%s</text>',
                                65 + 340 * extend_lock_song, global_height + 140, utils.escapeHtml(title)
                            )

                            single_lock_song_svg = single_lock_song_svg .. string.format('<text x="%d" y="%.0f" fill="white" font-family="Source Han Sans CN Font Fix" font-size="14" text-anchor="end">%s</text>',
                                294 + 340 * extend_lock_song, global_height + 140,string.upper(level) .. "." .. rating_key
                            )

                            lock_song_svg = lock_song_svg .. single_lock_song_svg

                            -- 换行
                            if lock_song_count % 4 == 0 then
                                global_height = global_height + 185
                            end
                        end
                    end
                    if has_divide and lock_song_count % 4 ~= 0 then
                        global_height = global_height + 144
                    end
                end
            end
        end

        local batch_record_svg = ""

        local level_num,loop_count = {"ez", "hd", "in", "at"}, 0
        for _, v in ipairs(level_num) do
            local function svg_draw(x, y, text)
                return string.format('<text x="%d" y="%d" fill="white" font-family="Source Han Sans CN Font Fix" font-size="33" text-anchor="middle">%s</text>', x, y, text)
            end
            -- xb_offset: -12
            -- y_offset: +49
            local w_offset = 98
            batch_record_svg = batch_record_svg .. svg_draw(295 + w_offset * loop_count,318,batch_record[v][1]) .. svg_draw(283 + w_offset * loop_count,367,batch_record[v][2]) .. svg_draw(271 + w_offset * loop_count,416,batch_record[v][3])
            loop_count = loop_count + 1
        end

        local batch_statistics_svg = ""

        loop_count = 0
        local max_column = utils.findMaxTable(batch_statistics)
        if max_column <= 0 then
            max_column = 1
        end

        for index = #batch_statistics,1,-1 do
            local num = batch_statistics[index]
            local min_column_height, x_offset = 3, 72
            local modify_column_height = min_column_height + 124 * num / max_column
            local column_svg = string.format('<rect x="%.0f" y="%.0f" width="34" height="%.0f" fill="white" stroke-width="0" stroke-opacity="0" />', 1365 - loop_count * x_offset, 387 - modify_column_height, modify_column_height)
            local column_text_svg = string.format('<text x="%.0f" y="%.0f" fill="white" font-family="Source Han Sans CN Font Fix" font-size="21" text-anchor="middle">%s</text>', 1383 - loop_count * x_offset, 387 - modify_column_height - 5, num)
            batch_statistics_svg = batch_statistics_svg .. column_svg .. column_text_svg
            loop_count = loop_count + 1
        end
 
        global_height = global_height + 112
        local tail_svg = string.format('<text x="718" y="%.0f" fill="white" font-family="Source Han Sans CN Font Fix" font-size="56" text-anchor="middle">Generated by tomato Team - Phigros</text>',global_height)
        global_height = global_height + 32

        -- 背景处理
        local bg_height = global_height

        local modify_width = bg_height * hw_scale

        if bg_height < min_height then
            bg_height = min_height 
            modify_width = utils.toSVGScale(1080)
        end

        local background_svg = string.format('<g transform="translate(720, %.0f) translate(-%.0f, -%.0f)"><image height="%.0f" width="%.0f" href="%s"/></g>',
            bg_height,
            modify_width / 2,
            bg_height,
            bg_height,
            modify_width,
            gaussianblur_file_path
        ) 
        -- 背景处理结束
        
        -- 把svg处理
        content = string.format(
            file:read("*all"),
            global_height,
            background_svg,
            batch_data.playerInfo.updateTime,
            player_info_svg,
            course_rating_img,
            challenge_mode_rank,
            player_rks,
            nickname,
            avatar_path,
            batch_record_svg,
            batch_statistics_svg,
            rating_label_svg,
            played_data_svg,
            lock_song_svg,
            tail_svg
        )

        -- 关闭文件
        file:close()

        -- 将内容打印出来
        return core.complete_control(content, "lua/extra/general.lua", "deleteTempGaussianBlurFile", {filePath = gaussianblur_file_path})
    end
    return core.error(1, 500, "draw lua has mistake.")
end


function bestN(obj)
    local data = json.decode(obj)

    -- 获取rating范围
    local title1, title2 = data.title1, data.title2
    local max_ap, max_record = math.tointeger(data.max_ap), math.tointeger(data.max_record)

    -- 获取batch的api
    local url = baseurl .. "/phi/all?is_aplist=1"
    
    local all_data, all_status_code = api.getAPI(url, data.authorization, data.sessionToken)

    all_data = all_data.content

    if all_status_code >= 400 then
        return core.error(1, all_status_code)
    end

    -- 头像设置相关
    local has_avatar = data.__imagePath[1] ~= nil

    -- 头像的路径获取
    local avatar_path = illustration_root_dir
    if all_data.other.avatarHasEnable then
        avatar_path = avatar_path .. all_data.other.avatarPath
    else
        avatar_path = avatar_path .. "/avatar/avatar.Introduction.png"
    end
    
    if has_avatar then
        avatar_path = data.__imagePath[1]
    end

    local match_url = baseurl .. "/phi/matchAlias"

    -- 背景图片路径
    local background_path = api.background_match(match_url, all_data.other.background, illustration_root_dir, data.authorization)

    -- 图片高斯模糊处理
    utils.authorization = "bBjhGvsSgY6BvLbN4ZP4mHVBD9QbWc8C"
    -- 高斯模糊路径
    local gaussianblur_file_path = utils.gaussianBlurSimple(background_path, 35).saveFilePath

    -- 读取svg并且处理
    local file = io.open("svg/phi/bestN.svg", "r")
    local content = ""

    --[[
    local w,h = libself.get_text_size(
        "wwaaabbb你是我是",
        "resource/fonts/SourceHanSansCNFontFix-Regular.ttf",30)
    print(w,h)
    ]]--

    if file then
        local hw_scale,fixed_width, min_height = 2048 / 1080, utils.toSVGScale(1080),utils.toSVGScale(570) - 1
        local fixed_offset_x = utils.toSVGScale(512) * hw_scale

        -- 整体图像高度
        -- 480为上部分的基础
        local global_height = 480 - 1 
       
        -- 玩家框相关
        local nickname, nickname_font_size, max_nickname_width = all_data.playerNickname, 48, 400
        local phi_medium_font_path = "resource/fonts/SourceHanSansCN_SairaCondensed_Hybrid_Medium.ttf"

        nickname = libself.handle_text(
            nickname,
            phi_medium_font_path,
            nickname_font_size, max_nickname_width
        )

        nickname = utils.escapeHtml(nickname)
        
        -- text position + 46
        local nickname_w,nickname_h = libself.get_text_size(
            nickname,
            phi_medium_font_path,
            nickname_font_size)
            nickname_w,nickname_h = utils.toSVGScale(nickname_w), utils.toSVGScale(nickname_h)

        local form_min_pos = fixed_width - nickname_w - 32 - 300 - 96
        local player_info_svg = string.format('<polygon transform="translate(0,38)" points="%.0f,0 1440,0 1440,116 %.0f,116" style="fill: black;fill-opacity: 0.4;" />',
            form_min_pos + 32, form_min_pos
        )

        -- 课题模式分数
        local challenge_mode_rank = all_data.challengeModeRank
        local course_rating_img = phi.challenge_mode_rank_image(challenge_mode_rank)

        challenge_mode_rank = challenge_mode_rank % 100
        
        local player_rks = all_data.rankingScore

        local played_data_svg,rating_label_svg = "",""

        --[[
            statistics:
            1: False
            2: C
            3: B
            4: A
            5: S
            6: V
            7: V(Blue)
            8: Phi
        ]]--
        local all_statistics = {0,0,0,0,0,0,0,0}

        local level_color = {}
        level_color['ez'] = "#59b852"
        level_color['hd'] = "#3748e9"
        level_color['in'] = "#d71c25"
        level_color['at'] = "#939393"
        level_color['unknown'] = "#595959" -- unknown

        local back_level_from_color = {}
        back_level_from_color['ez'] = "#29b71e"
        back_level_from_color['hd'] = "#505fe9"
        back_level_from_color['in'] = "#963b3e"
        back_level_from_color['at'] = "#939393"
        back_level_from_color['unknown'] = "#595959" -- unknown

        -- ===================================================================

        local best_list = all_data.best_list
        local bests, phis = best_list.best, best_list.phis

        if bests then
            for k, record in ipairs(bests) do
                -- print(k, utils.tabletostring(v))
                local __, type = phi.score_rate_image(record.score, record.isfc)
                all_statistics[type + 1] = all_statistics[type + 1] + 1
            end
        end

        local rating_label_offset_y = 73
        local switch_pos = true

        function draw_single_info(info, curr_index, box_type, is_unknown)
            is_unknown = is_unknown or false
            box_type = box_type or 0

            local box_f_color, box_n_color, box_n_font_color = "#b2b2b2", "#4d4d4d", "white"
            if box_type == 1 then
                box_f_color = "#b2b2b2"
                box_n_color = "#388eff"
                box_n_font_color = "white"
            elseif box_type == 2 then
                box_f_color = "#9a9265"
                box_n_color = "#fff662"
                box_n_font_color = "black"
            end


            local is_single_fc = false
            local level = "unknown"
            local self_ranking = string.format("%02d", curr_index)
            local music_rating = string.format("%.1f", 0.0)
            local score, rks, acc = 0, 0.0, 0.0
            local illustration_path = "resource/phi/Unknow.png"
            local title = "Unknown"

            if not is_unknown then
                is_single_fc = info.isfc
                level = string.lower(info.difficulty)
                self_ranking = string.format("%02d",math.tointeger(info.ranking))
                music_rating = string.format("%.1f", info.level)
                score = info.score
                rks = info.rankingScore
                acc = info.acc
                illustration_path = illustration_root_dir .. info.illustrationPath
                title = libself.handle_text(
                    info.title,
                    "resource/fonts/SourceHanSansCNFontFix-Regular.ttf",
                    16, 195)
            end


            local evaluate_path = phi.score_rate_image(score, is_single_fc)

            -- 后背框
            local info_form_svg = string.format('<polygon transform="translate(55,%.0f)" points="46,0 1322,0 1276,173 0,173" fill="%s" fill-opacity="0.5"/>', global_height + 28, back_level_from_color[level])
            local ill_svg = ""
            local ill_init_x = 34
            if switch_pos then
                -- 奇
                local ill_init_x = 34

                -- 难度颜色
                ill_svg = string.format(
                    '<polygon transform="translate(%d,%.0f)" points="62,0 435,0 373,230 0,230" fill="%s" fill-opacity="0.5"/>',
                    ill_init_x - 7, global_height + 5, level_color[level])

                -- 曲绘
                ill_svg = ill_svg .. string.format(
                    '<image transform="translate(%d,%.0f)" href="%s" width="436" height="240" clip-path="url(#cover-parallelogram)"/>', 
                    ill_init_x, global_height, illustration_path)
        
                -- 图像特有的阴影效果
                ill_svg = ill_svg .. string.format(
                    '<image transform="translate(%d,%.0f)" href="resource/phi/ill_shadow.png" width="436" height="240" clip-path="url(#cover-parallelogram)"/>',
                    ill_init_x, global_height)
    
                -- 排名框
                ill_svg = ill_svg .. string.format(
                    '<polygon transform="translate(%d,%.0f)" points="9,0 46,0 37,33 0,33" fill="%s"/><polygon transform="translate(%d,%.0f)" points="8,0 40,0 32,29 0,29" fill="%s"/>',
                    ill_init_x + 60, global_height + 10, box_f_color,ill_init_x + 63, global_height + 12, box_n_color)
        
                -- 分数排名
                ill_svg = ill_svg .. string.format(
                    '<text x="%d" y="%.0f" fill="%s" font-family="Source Han Sans CN Font Fix" font-size="19" text-anchor="middle">%s</text>', 
                    ill_init_x + 83, global_height + 34, box_n_font_color,self_ranking)

                -- 曲目标题
                ill_svg = ill_svg .. string.format(
                    '<text x="%d" y="%.0f" fill="white" font-family="Source Han Sans CN Font Fix" font-size="23">%s</text>',
                    ill_init_x + 10, global_height + 223, utils.escapeHtml(title))

                -- 曲目难度
                ill_svg = ill_svg .. string.format(
                    '<text x="%d" y="%.0f" fill="white" font-family="Source Han Sans CN Font Fix" font-size="23" text-anchor="end">%s</text>',
                    ill_init_x + 370, global_height + 223, string.upper(level) .. ". " .. music_rating)

                -- +20
                -- 得到的评级
                ill_svg = ill_svg .. string.format(
                    '<image transform="translate(%d,%.0f)" href="%s" width="200" height="200"/>',
                    ill_init_x + 400, global_height + 14, evaluate_path)

                -- Score相关
                ill_svg = ill_svg .. string.format(
                    '<text x="%d" y="%.0f" fill="white" font-family="Source Han Sans CN Font Fix" font-size="43">Best Score</text>',
                    ill_init_x + 570, global_height + 96)

                ill_svg = ill_svg .. string.format(
                    '<text x="%d" y="%.0f" fill="white" font-family="Source Han Sans CN Font Fix" font-size="85">%07d</text>',
                    ill_init_x + 562, global_height + 174, score)

                -- 分隔线
                ill_svg = ill_svg .. string.format(
                    '<image transform="translate(996,%.0f)" href="resource/phi/batach_divider_line.png" width="41" height="135"/>',
                    global_height + 46)

                -- 标记
                ill_svg = ill_svg .. string.format(
                    '<text x="%d" y="%.0f" fill="white" font-family="Source Han Sans CN Font Fix" font-size="45">Rate</text>',
                    ill_init_x + 1016, global_height + 106)
                
                ill_svg = ill_svg .. string.format(
                    '<text x="%d" y="%.0f" fill="white" font-family="Source Han Sans CN Font Fix" font-size="45">Acc</text>',
                    ill_init_x + 1003, global_height + 166)

                -- Rate和Acc
                ill_svg = ill_svg .. string.format(
                    '<text x="%d" y="%.0f" fill="white" font-family="Source Han Sans CN Font Fix" font-size="45" text-anchor="end">%.2f</text>',
                    1320, global_height + 106, rks)
                
                ill_svg = ill_svg .. string.format(
                    '<text x="%d" y="%.0f" fill="white" font-family="Source Han Sans CN Font Fix" font-size="45" text-anchor="end">%.2f%%</text>',
                    1308, global_height + 166, acc)
            else
                -- 偶
                local ill_init_x = 962

                -- 难度颜色
                ill_svg = string.format(
                    '<polygon transform="translate(%d,%.0f)" points="62,0 435,0 373,230 0,230" fill="%s" fill-opacity="0.5"/>',
                    ill_init_x + 5, global_height + 5, level_color[level])

                -- 曲绘
                ill_svg = ill_svg .. string.format(
                    '<image transform="translate(%d,%.0f)" href="%s" width="436" height="240" clip-path="url(#cover-parallelogram)"/>',
                    ill_init_x, global_height, illustration_path)
        
                -- 图像特有的阴影效果
                ill_svg = ill_svg .. string.format(
                    '<image transform="translate(%d,%.0f)" href="resource/phi/ill_shadow.png" width="436" height="240" clip-path="url(#cover-parallelogram)"/>',
                    ill_init_x, global_height)
                                
                -- 排名框
                ill_svg = ill_svg .. string.format(
                    '<polygon transform="translate(%d,%.0f)" points="9,0 46,0 37,33 0,33" fill="%s"/><polygon transform="translate(%d,%.0f)" points="8,0 40,0 32,29 0,29" fill="%s"/>',
                    ill_init_x + 60, global_height + 10, box_f_color,ill_init_x + 63, global_height + 12, box_n_color)
        
                -- 分数排名
                ill_svg = ill_svg .. string.format(
                    '<text x="%d" y="%.0f" fill="%s" font-family="Source Han Sans CN Font Fix" font-size="19" text-anchor="middle">%s</text>', 
                    ill_init_x + 83, global_height + 34, box_n_font_color,self_ranking)

                -- 曲目标题
                ill_svg = ill_svg .. string.format(
                    '<text x="%d" y="%.0f" fill="white" font-family="Source Han Sans CN Font Fix" font-size="23">%s</text>',
                    ill_init_x + 10, global_height + 223, utils.escapeHtml(title))

                -- 曲目难度
                ill_svg = ill_svg .. string.format(
                    '<text x="%d" y="%.0f" fill="white" font-family="Source Han Sans CN Font Fix" font-size="23" text-anchor="end">%s</text>',
                    ill_init_x + 370, global_height + 223, string.upper(level) .. ". " .. music_rating)

                -- -20
                -- 得到的评级
                ill_svg = ill_svg .. string.format(
                    '<image transform="translate(%d,%.0f)" href="%s" width="200" height="200"/>',
                    ill_init_x - 174, global_height + 14, evaluate_path)

                ill_svg = ill_svg .. string.format(
                    '<text x="%d" y="%.0f" fill="white" font-family="Source Han Sans CN Font Fix" font-size="43">Best Score</text>',
                    ill_init_x - 530, global_height + 96)

                ill_svg = ill_svg .. string.format(
                    '<text x="%d" y="%.0f" fill="white" font-family="Source Han Sans CN Font Fix" font-size="85">%07d</text>',
                    ill_init_x - 534, global_height + 174, score)

                -- 分隔线
                ill_svg = ill_svg .. string.format(
                    '<image transform="translate(383,%.0f)" href="resource/phi/batach_divider_line.png" width="41" height="135"/>',
                    global_height + 46)

                -- 标记
                ill_svg = ill_svg .. string.format(
                    '<text x="%d" y="%.0f" fill="white" font-family="Source Han Sans CN Font Fix" font-size="45">Rate</text>',
                    112, global_height + 106)
                
                ill_svg = ill_svg .. string.format(
                    '<text x="%d" y="%.0f" fill="white" font-family="Source Han Sans CN Font Fix" font-size="45">Acc</text>',
                    99, global_height + 166)

                -- Rate和Acc
                ill_svg = ill_svg .. string.format(
                    '<text x="%d" y="%.0f" fill="white" font-family="Source Han Sans CN Font Fix" font-size="45" text-anchor="end">%.2f</text>',
                    385, global_height + 106, rks)
                
                ill_svg = ill_svg .. string.format(
                    '<text x="%d" y="%.0f" fill="white" font-family="Source Han Sans CN Font Fix" font-size="45" text-anchor="end">%.2f%%</text>',
                    373, global_height + 166, acc)
            end
            
            switch_pos = not switch_pos
            played_data_svg = played_data_svg .. info_form_svg .. ill_svg
            global_height = global_height + 262
        end

        
        function dividing_line_text_gen(text, add_line_width)
            add_line_width = add_line_width or 0

            line_width = 510 + add_line_width

            global_height = global_height + rating_label_offset_y
            -- 绘制分级标签和分隔线
            rating_label_svg = rating_label_svg .. string.format( [[
<rect x="34" y="%.0f" width="%d" height="13" fill="white" stroke-width="0" stroke-opacity="0" />
<rect x="%d" y="%.0f" width="%d" height="13" fill="white" stroke-width="0" stroke-opacity="0"/>
<text x="719" y="%.0f" fill="white" font-family="Source Han Sans CN Font Fix" font-size="85" text-anchor="middle">%s</text> ]],
            global_height, line_width, 890 - add_line_width, global_height, line_width, global_height + 38, text)
            global_height = global_height + 82
        end

        -- 这个是ap成绩(AP N)
        if phis then
            switch_pos = true
            if title1 ~= "None" then
                dividing_line_text_gen(title1)
            end

            local box_type = 2 -- 0为normal, 1为fc, 2为phi
            local self_phi_count = #phis
            for index = 1, max_ap do
                local info = nil
                local is_unknown = false
                if index > self_phi_count then
                    is_unknown = true
                else
                    info = phis[index]
                end
                draw_single_info(info, index, box_type, is_unknown)
            end
        end
        
        -- 这个是普通成绩(Best N)
        if bests then
            switch_pos = true
            if title2 ~= "None" then
                dividing_line_text_gen(title2)
            end


            local box_type = 0 -- 0为normal, 1为fc, 2为phi
            local self_best_count = #bests
            for index = 1, max_record do
                if index == 28 then
                    dividing_line_text_gen("Overflow", -30)
                end
                local info = nil
                local is_unknown = false
                if index > self_best_count then
                    is_unknown = true
                else
                    info = bests[index]
                end
                draw_single_info(info, index, box_type, is_unknown)
            end
        end
            
            
            --[[
            -- 对数据汇总
            for r=ratings[1],ratings[2]+0.1,0.1 do
                local rating_key = string.format("%.1f",r)

                if batch[rating_key] then
                    local lock_song_count,has_divide = 0,false
                    local rating_label_offset_y = 73
                    global_height = global_height + rating_label_offset_y
                    -- 绘制分级标签和分隔线
                    rating_label_svg = rating_label_svg .. string.format('<rect x="34" y="%.0f" width="534" height="13" fill="white" stroke-width="0" stroke-opacity="0" /><rect x="866" y="%.0f" width="534" height="13" fill="white" stroke-width="0" stroke-opacity="0" /><text x="719" y="%.0f" fill="white" font-family="Source Han Sans CN Font Fix" font-size="85" text-anchor="middle">%s</text>',
                        global_height, global_height, global_height + 40, r)
                    global_height = global_height + 82

                    local batch_ranking = 1

                    for k, v in ipairs(batch[rating_key]) do
                        -- big: 262,form: 28
                        -- 信息
                        local info = v.info
                        local level = info.level
                        if v.playedLevel then
                            local score,rks,acc = v.record.score,v.record.rks,v.record.acc
                            local evaluate_path = phi.score_rate_image(score,v.record.isfc)
                            local title = libself.handle_text(
                                info.title,
                                "resource/fonts/SourceHanSansCNFontFix-Regular.ttf",
                                16, 195
                            )

                            local info_form_svg = string.format('<polygon transform="translate(55,%.0f)" points="46,0 1322,0 1276,173 0,173" fill="black" fill-opacity="0.5"/>', global_height + 28)
                            local ill_svg = ""
                            local ill_init_x = 34
                            if batch_ranking % 2 == 1 then
                                -- 奇
                                local ill_init_x = 34

                                -- 难度颜色
                                ill_svg = string.format(
                                    '<polygon transform="translate(%d,%.0f)" points="62,0 435,0 373,230 0,230" fill="%s" fill-opacity="0.5"/>',
                                    ill_init_x - 7, global_height + 5, level_color[level]
                                )

                                -- 曲绘
                                ill_svg = ill_svg .. string.format(
                                    '<image transform="translate(%d,%.0f)" href="%s" width="436" height="240" clip-path="url(#cover-parallelogram)"/>', 
                                    ill_init_x, global_height, illustration_root_dir .. info.illustrationPath)
        
                                -- 图像特有的阴影效果
                                ill_svg = ill_svg .. string.format(
                                    '<image transform="translate(%d,%.0f)" href="resource/phi/ill_shadow.png" width="436" height="240" clip-path="url(#cover-parallelogram)"/>',
                                    ill_init_x, global_height)
        
                                -- 排名框
                                ill_svg = ill_svg .. string.format(
                                    '<polygon transform="translate(%d,%.0f)" points="9,0 46,0 37,33 0,33" fill="#b2b2b2"/><polygon transform="translate(%d,%.0f)" points="8,0 40,0 32,29 0,29" fill="#4d4d4d"/>',
                                    ill_init_x + 60, global_height + 10,ill_init_x + 63, global_height + 12
                                )
        
                                -- 分数排名
                                ill_svg = ill_svg .. string.format(
                                    '<text x="%d" y="%.0f" fill="white" font-family="Source Han Sans CN Font Fix" font-size="19" text-anchor="middle">%02d</text>', 
                                    ill_init_x + 83, global_height + 34,batch_ranking)

                                -- 曲目标题
                                ill_svg = ill_svg .. string.format(
                                    '<text x="%d" y="%.0f" fill="white" font-family="Source Han Sans CN Font Fix" font-size="23">%s</text>',
                                    ill_init_x + 10, global_height + 223, utils.escapeHtml(title)
                                )

                                -- 曲目难度
                                ill_svg = ill_svg .. string.format(
                                    '<text x="%d" y="%.0f" fill="white" font-family="Source Han Sans CN Font Fix" font-size="23" text-anchor="end">%s</text>',
                                    ill_init_x + 370, global_height + 223, string.upper(level) .. ". " .. rating_key
                                )

                                -- +20
                                -- 得到的评级
                                ill_svg = ill_svg .. string.format(
                                    '<image transform="translate(%d,%.0f)" href="%s" width="200" height="200"/>',
                                    ill_init_x + 400, global_height + 14, evaluate_path
                                )

                                -- Score相关
                                ill_svg = ill_svg .. string.format(
                                    '<text x="%d" y="%.0f" fill="white" font-family="Source Han Sans CN Font Fix" font-size="43">Best Score</text>',
                                    ill_init_x + 570, global_height + 96
                                )

                                ill_svg = ill_svg .. string.format(
                                    '<text x="%d" y="%.0f" fill="white" font-family="Source Han Sans CN Font Fix" font-size="85">%07d</text>',
                                    ill_init_x + 562, global_height + 174, score
                                )

                                -- 分隔线
                                ill_svg = ill_svg .. string.format(
                                    '<image transform="translate(996,%.0f)" href="resource/phi/batach_divider_line.png" width="41" height="135"/>',
                                    global_height + 46
                                )

                                -- 标记
                                ill_svg = ill_svg .. string.format(
                                    '<text x="%d" y="%.0f" fill="white" font-family="Source Han Sans CN Font Fix" font-size="45">Rate</text>',
                                    ill_init_x + 1016, global_height + 106
                                )
                                ill_svg = ill_svg .. string.format(
                                    '<text x="%d" y="%.0f" fill="white" font-family="Source Han Sans CN Font Fix" font-size="45">Acc</text>',
                                    ill_init_x + 1003, global_height + 166
                                )

                                -- Rate和Acc
                                ill_svg = ill_svg .. string.format(
                                    '<text x="%d" y="%.0f" fill="white" font-family="Source Han Sans CN Font Fix" font-size="45" text-anchor="end">%.2f</text>',
                                    1320, global_height + 106, rks
                                )
                                ill_svg = ill_svg .. string.format(
                                    '<text x="%d" y="%.0f" fill="white" font-family="Source Han Sans CN Font Fix" font-size="45" text-anchor="end">%.2f%%</text>',
                                    1308, global_height + 166, acc
                                )
                            else
                                -- 偶
                                local ill_init_x = 962

                                -- 难度颜色
                                ill_svg = string.format(
                                    '<polygon transform="translate(%d,%.0f)" points="62,0 435,0 373,230 0,230" fill="%s" fill-opacity="0.5"/>',
                                    ill_init_x + 5, global_height + 5, level_color[level]
                                )

                                -- 曲绘
                                ill_svg = ill_svg .. string.format(
                                    '<image transform="translate(%d,%.0f)" href="%s" width="436" height="240" clip-path="url(#cover-parallelogram)"/>',
                                    ill_init_x, global_height, illustration_root_dir .. info.illustrationPath)
        
                                -- 图像特有的阴影效果
                                ill_svg = ill_svg .. string.format(
                                    '<image transform="translate(%d,%.0f)" href="resource/phi/ill_shadow.png" width="436" height="240" clip-path="url(#cover-parallelogram)"/>',
                                    ill_init_x, global_height)
                                
                                -- 排名框
                                ill_svg = ill_svg .. string.format(
                                    '<polygon transform="translate(%d,%.0f)" points="9,0 46,0 37,33 0,33" fill="#b2b2b2"/><polygon transform="translate(%d,%.0f)" points="8,0 40,0 32,29 0,29" fill="#4d4d4d"/>',
                                    ill_init_x + 60, global_height + 10,ill_init_x + 63, global_height + 12
                                )
        
                                -- 分数排名
                                ill_svg = ill_svg .. string.format(
                                    '<text x="%d" y="%.0f" fill="white" font-family="Source Han Sans CN Font Fix" font-size="19" text-anchor="middle">%02d</text>', 
                                    ill_init_x + 83, global_height + 34,batch_ranking)

                                -- 曲目标题
                                ill_svg = ill_svg .. string.format(
                                    '<text x="%d" y="%.0f" fill="white" font-family="Source Han Sans CN Font Fix" font-size="23">%s</text>',
                                    ill_init_x + 10, global_height + 223, utils.escapeHtml(title)
                                )

                                -- 曲目难度
                                ill_svg = ill_svg .. string.format(
                                    '<text x="%d" y="%.0f" fill="white" font-family="Source Han Sans CN Font Fix" font-size="23" text-anchor="end">%s</text>',
                                    ill_init_x + 370, global_height + 223, string.upper(level) .. ". " .. rating_key
                                )

                                -- -20
                                -- 得到的评级
                                ill_svg = ill_svg .. string.format(
                                    '<image transform="translate(%d,%.0f)" href="%s" width="200" height="200"/>',
                                    ill_init_x - 174, global_height + 14, evaluate_path
                                )

                                ill_svg = ill_svg .. string.format(
                                    '<text x="%d" y="%.0f" fill="white" font-family="Source Han Sans CN Font Fix" font-size="43">Best Score</text>',
                                    ill_init_x - 530, global_height + 96
                                )

                                ill_svg = ill_svg .. string.format(
                                    '<text x="%d" y="%.0f" fill="white" font-family="Source Han Sans CN Font Fix" font-size="85">%07d</text>',
                                    ill_init_x - 534, global_height + 174, score
                                )

                                -- 分隔线
                                ill_svg = ill_svg .. string.format(
                                    '<image transform="translate(373,%.0f)" href="resource/phi/batach_divider_line.png" width="41" height="135"/>',
                                    global_height + 46
                                )

                                -- 标记
                                ill_svg = ill_svg .. string.format(
                                    '<text x="%d" y="%.0f" fill="white" font-family="Source Han Sans CN Font Fix" font-size="45">Rate</text>',
                                    112, global_height + 106
                                )
                                ill_svg = ill_svg .. string.format(
                                    '<text x="%d" y="%.0f" fill="white" font-family="Source Han Sans CN Font Fix" font-size="45">Acc</text>',
                                    99, global_height + 166
                                )

                                -- Rate和Acc
                                ill_svg = ill_svg .. string.format(
                                    '<text x="%d" y="%.0f" fill="white" font-family="Source Han Sans CN Font Fix" font-size="45" text-anchor="end">%.2f</text>',
                                    370, global_height + 106, rks
                                )
                                ill_svg = ill_svg .. string.format(
                                    '<text x="%d" y="%.0f" fill="white" font-family="Source Han Sans CN Font Fix" font-size="45" text-anchor="end">%.2f%%</text>',
                                    358, global_height + 166, acc
                                )
                            end
        
                            -- 有数据的
                            -- 记录
                            local record = v.record
                            local __, type = phi.score_rate_image(record.score, record.isfc)
                            batch_statistics[type + 2] = batch_statistics[type + 2] + 1
                            if type == 7 then
                                batch_record[level][3] = batch_record[level][3] + 1
                                batch_record[level][2] = batch_record[level][2] + 1
                                batch_record[level][1] = batch_record[level][1] + 1
                            elseif type == 6 then
                                batch_record[level][2] = batch_record[level][2] + 1
                                batch_record[level][1] = batch_record[level][1] + 1
                            else
                                batch_record[level][1] = batch_record[level][1] + 1
                            end
        
                            played_data_svg = played_data_svg .. info_form_svg .. ill_svg
                            global_height = global_height + 262
                            batch_ranking = batch_ranking + 1
                        else
                            if batch_ranking % 2 ~= 1 then
                                global_height = global_height + 44
                                batch_ranking = 1
                            end
                            local single_lock_song_svg = ""
                            lock_song_count = lock_song_count + 1
                            has_divide = true
                            -- 无数据的
                            batch_statistics[1] = batch_statistics[1] + 1

                            local extend_lock_song = (lock_song_count - 1) % 4

                            single_lock_song_svg = string.format(
                                '<polygon transform="translate(%d,%.0f)" points="36,0 272,0 236,144 0,144"  fill="%s" fill-opacity="0.5"/>',
                                54 + 340 * extend_lock_song ,global_height + 4, level_color[level]
                            )

                            single_lock_song_svg = single_lock_song_svg .. string.format(
                                '<image transform="translate(%d,%.0f)" href="%s" width="273" height="144" clip-path="url(#lock-cover-parallelogram)"/>',
                                60 + 340 * extend_lock_song ,global_height, illustration_root_dir .. info.illustrationPath
                            )

                            single_lock_song_svg = single_lock_song_svg .. string.format(
                                '<polygon transform="translate(%d,%.0f)" points="36,0 272,0 236,144 0,144" fill="black" fill-opacity="0.5"/>',
                                60 + 340 * extend_lock_song ,global_height
                            )

                            single_lock_song_svg = single_lock_song_svg .. string.format(
                                '<image transform="translate(%d,%.0f)" href="resource/phi/lock.png" width="153" height="153"/>',
                                123 + 340 * extend_lock_song ,global_height
                            )

                            local title = libself.handle_text(
                                info.title,
                                "resource/fonts/SourceHanSansCNFontFix-Regular.ttf",
                                10, 120
                            )

                            single_lock_song_svg = single_lock_song_svg .. string.format(
                                '<text x="%d" y="%.0f" fill="white" font-family="Source Han Sans CN Font Fix" font-size="14">%s</text>',
                                65 + 340 * extend_lock_song, global_height + 140, utils.escapeHtml(title)
                            )

                            single_lock_song_svg = single_lock_song_svg .. string.format('<text x="%d" y="%.0f" fill="white" font-family="Source Han Sans CN Font Fix" font-size="14" text-anchor="end">%s</text>',
                                294 + 340 * extend_lock_song, global_height + 140,string.upper(level) .. "." .. rating_key
                            )

                            lock_song_svg = lock_song_svg .. single_lock_song_svg

                            -- 换行
                            if lock_song_count % 4 == 0 then
                                global_height = global_height + 185
                            end
                        end
                    end
                    if has_divide and lock_song_count % 4 ~= 0 then
                        global_height = global_height + 144
                    end
                end
            end
            --]]

        local all_record_svg = ""

        local my_records = all_data.other.records

        local level_num, loop_count = {"EZ", "HD", "IN", "AT"}, 0
        for _, v in ipairs(level_num) do
            local function svg_draw(x, y, text)
                return string.format('<text x="%d" y="%d" fill="white" font-family="Source Han Sans CN Font Fix" font-size="33" text-anchor="middle">%d</text>', x, y, text)
            end
            -- xb_offset: -12
            -- y_offset: +49
            local w_offset = 98
            all_record_svg = all_record_svg .. svg_draw(295 + w_offset * loop_count,318,my_records[v]["clear"]) .. svg_draw(283 + w_offset * loop_count,367,my_records[v]["fc"]) .. svg_draw(271 + w_offset * loop_count,416,my_records[v]["phi"])
            loop_count = loop_count + 1
        end

        local my_statistics_svg = ""

        loop_count = 0
        local max_column = utils.findMaxTable(all_statistics)
        if max_column <= 0 then
            max_column = 1
        end

        for index = #all_statistics,1,-1 do
            local num = all_statistics[index]
            local min_column_height, x_offset = 3, 79
            local modify_column_height = min_column_height + 124 * num / max_column
            local column_svg = string.format('<rect x="%.0f" y="%.0f" width="34" height="%.0f" fill="white" stroke-width="0" stroke-opacity="0" />', 1345 - loop_count * x_offset, 387 - modify_column_height, modify_column_height)
            local column_text_svg = string.format('<text x="%.0f" y="%.0f" fill="white" font-family="Source Han Sans CN Font Fix" font-size="21" text-anchor="middle">%s</text>', 1362 - loop_count * x_offset, 387 - modify_column_height - 5, num)
            my_statistics_svg = my_statistics_svg .. column_svg .. column_text_svg
            loop_count = loop_count + 1
        end
 
        global_height = global_height + 56
        local tail_svg = string.format('<text x="718" y="%.0f" fill="white" font-family="Source Han Sans CN Font Fix" font-size="56" text-anchor="middle">Generated by tomato Team - Phigros</text>',global_height)
        global_height = global_height + 56

        -- 背景处理
        local bg_height = global_height

        local modify_width = bg_height * hw_scale

        if bg_height < min_height then
            bg_height = min_height 
            modify_width = utils.toSVGScale(1080)
        end

        local background_svg = string.format('<g transform="translate(720, %.0f) translate(-%.0f, -%.0f)"><image height="%.0f" width="%.0f" href="%s"/></g>',
            bg_height,
            modify_width / 2,
            bg_height,
            bg_height,
            modify_width,
            gaussianblur_file_path
        ) 
        -- 背景处理结束
        
        -- 把svg处理
        content = string.format(
            file:read("*all"),
            global_height,
            background_svg,
            all_data.updateTime,
            player_info_svg,
            course_rating_img,
            challenge_mode_rank,
            player_rks,
            nickname,
            avatar_path,
            all_record_svg,
            my_statistics_svg,
            rating_label_svg,
            played_data_svg,
            tail_svg
        )

        -- 关闭文件
        file:close()

        -- 将内容打印出来
        return core.complete_control(content, "lua/extra/general.lua", "deleteTempGaussianBlurFile", {filePath = gaussianblur_file_path})
    end
    return core.error(1, 500, "draw lua has mistake.")
end