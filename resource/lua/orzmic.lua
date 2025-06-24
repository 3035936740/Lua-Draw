local libself = require("libluadraw")
local json = require("cjson")
require("lua/api/orzmic")
require("lua/lib/core")
require("lua/lib/utils")

local illustrationRootDirectory = "/home/resources/orzmic/covers/"
local characterRootDirectory = "/home/resources/orzmic/characters/"

local BLUR_VALUE = 20
local ILL_SCALE = 16 / 9
local UTILS_TOKEN = "bBjhGvsSgY6BvLbN4ZP4mHVBD9QbWc8C"
local API_URL = "http://127.0.0.1:47780"

local ORZMIC_TTF_PATH = "resource/fonts/MiSans-Medium.ttf"

local function getEvaluateImage(evaluateType)
    local evaluatePath = "resource/orzmic/rate/F.png"
    if evaluateType == 0 then
        evaluatePath = "resource/orzmic/rate/ORZ.png"
    elseif evaluateType == 1 then
        evaluatePath = "resource/orzmic/rate/Z.png"
    elseif evaluateType == 2 then
        evaluatePath = "resource/orzmic/rate/R.png"
    elseif evaluateType == 3 then
        evaluatePath = "resource/orzmic/rate/O.png"
    elseif evaluateType == 4 then
        evaluatePath = "resource/orzmic/rate/S.png"
    elseif evaluateType == 5 then
        evaluatePath = "resource/orzmic/rate/A.png"
    elseif evaluateType == 6 then
        evaluatePath = "resource/orzmic/rate/B.png"
    elseif evaluateType == 7 then
        evaluatePath = "resource/orzmic/rate/C.png"
    elseif evaluateType == 8 then
        evaluatePath = "resource/orzmic/rate/D.png"
    else
        evaluatePath = "resource/orzmic/rate/F.png"
    end
    return evaluatePath
end

local function getPlusEvaluateImage(plusType)
    local plusPath = ""
    if plusType == 0 then
        plusPath = "resource/orzmic/rate/GoldPlus.png"
    elseif plusType == 1 then
        plusPath = "resource/orzmic/rate/SilverPlus.png"
    else
        plusPath = ""
    end
    return plusPath
end

local function getClearColor(clearType)
    local clearColor = "#ffffff"
    if clearType <= 2 then
        clearColor = "#fae151"
    elseif clearType == 3 then
        clearColor = "#5cbbd9"
    else
        clearColor = "#ffffff"
    end
    return clearColor
end

local function getLevelColor(levelType)
    local levelColor = "#a0a0a0"
    if levelType == 0 then
        levelColor = "#8be1f8"
    elseif levelType ==1 then
        levelColor = "#ffdd79"
    elseif levelType ==2 then
        levelColor = "#f27171"
    elseif levelType ==3 then
        levelColor = "#d98af7"
    else
        levelColor = "#a0a0a0"
    end
    return levelColor
end

local function formatNumber(num)
    local formattedNum = string.format("%09d", num)
    local result = "0,"

    for i = 1, #formattedNum, 3 do
        local chunk = string.sub(formattedNum, i, i + 2)
        result = result .. chunk .. ","
    end

    result = string.sub(result, 1, -2)  -- 去除最后的逗号
    return result
end

local function addCommas(number)
    local formatted_number = tostring(number)
    local k = #formatted_number % 3
    local result = k > 0 and formatted_number:sub(1, k) or "0"

    for i = k + 1, #formatted_number, 3 do
        result = result .. "," .. formatted_number:sub(i, i + 2)
    end

    return result
end

function song(obj)
    local data = json.decode(obj)
    local APIAuthorization, musicKey = data.authorization, tostring(math.floor(data.musicId))

    utils.authorization = UTILS_TOKEN

    local musicInfo = api.getMusicById(API_URL, APIAuthorization, musicKey)[1]

    local fileName = musicInfo.FileName

    local illPath = illustrationRootDirectory .. fileName .. "/Texture2D.png"

    local gaussianBlurFilePath = utils.gaussianBlurSimple(illPath, BLUR_VALUE).saveFilePath

    local file = io.open("svg/orzmic/song.svg", "r")

    if file then
        local canvasWidth, canvasHeight = utils.toSVGScale(1920), utils.toSVGScale(1080)

        local titleSize, titleMaxSize = 60, 530

        local title = libself.handle_text(
            musicInfo.Title,
            ORZMIC_TTF_PATH,
            titleSize, titleMaxSize
        )

        title = utils.escapeHtml(title)

        titleSize = 48
        local artist = musicInfo.Artist

        if string.len(artist) <= 0 then
            artist = "-"
        end

        artist = libself.handle_text(
            artist,
            ORZMIC_TTF_PATH,
            titleSize, titleMaxSize
        )

        artist = utils.escapeHtml(artist)

        local illustration = libself.handle_text(
            musicInfo.CoverPainter,
            ORZMIC_TTF_PATH,
            titleSize, titleMaxSize
        )

        illustration = utils.escapeHtml(illustration)

        local bpm = musicInfo.BPMRange

        local easySVGCode, normalSVGCode, hardSVGCode, specialSVGCode = "", "", "", ""

        for index, v in ipairs(musicInfo.Difficulties) do
            local chartDesigner, noteCount, rating, difficulty = '-', '-', '-', '-'

            if type(v.ChartDesigner) ~= "userdata" then
                chartDesigner = utils.escapeHtml(v.ChartDesigner)
            end
            if type(v.NoteCount) ~= "userdata" then
                noteCount = string.format("%.0f", v.NoteCount)
            end
            if type(v.Rating) ~= "userdata" then
                rating = string.format("%.1f", v.Rating)
            end
            if type(v.Difficulty) ~= "userdata" then
                difficulty = v.Difficulty
            end

            local difficultyFontSize = 65
            local difficultyWidth, __ = libself.get_text_size(
                string.gsub(difficulty, "⁺", ""), ORZMIC_TTF_PATH, difficultyFontSize)
            difficultyWidth = utils.toSVGScale(difficultyWidth)

            local difficultyWidthOffset = difficultyWidth / 2
            if string.find(difficulty, "⁺") or string.find(difficulty, "11") then
                local difficultyPlusWidth, __ = libself.get_text_size(
                    "⁺", ORZMIC_TTF_PATH, difficultyFontSize)
                difficultyWidthOffset = difficultyWidthOffset + difficultyPlusWidth / 2
            end

            if index == 1 then
                easySVGCode = easySVGCode .. string.format([[
                    <text x="%.0f" y="963" font-family="MiSans Medium" fill="white" font-size="87">
                        %s
                    </text>
                ]], 380 - difficultyWidthOffset, difficulty)

                easySVGCode = easySVGCode .. utils.format([[
                    <text x="879" y="991" font-family="MiSans Medium" fill="white" font-size="120" text-anchor="middle">
                        {} / {}
                    </text>
                ]], rating, noteCount)

                easySVGCode = easySVGCode .. utils.format([[
                    <text x="287" y="1090" font-family="MiSans Medium" fill="white" font-size="37">
                        Chart: {}
                    </text>
                ]], chartDesigner)
            elseif index == 2 then
                normalSVGCode = normalSVGCode .. string.format([[
                    <text x="%.0f" y="963" font-family="MiSans Medium" fill="white" font-size="87">
                        %s
                    </text>
                ]], 1432 - difficultyWidthOffset, difficulty)

                normalSVGCode = normalSVGCode .. utils.format([[
                    <text x="1931" y="991" font-family="MiSans Medium" fill="white" font-size="120" text-anchor="middle">
                        {} / {}
                    </text>
                ]], rating, noteCount)

                normalSVGCode = normalSVGCode .. utils.format([[
                    <text x="1339" y="1090" font-family="MiSans Medium" fill="white" font-size="37">
                        Chart: {}
                    </text>
                ]], chartDesigner)
            elseif index == 3 then
                hardSVGCode = hardSVGCode .. string.format([[
                    <text x="%.0f" y="1260" font-family="MiSans Medium" fill="white" font-size="87">
                        %s
                    </text>
                ]], 380 - difficultyWidthOffset, difficulty)

                hardSVGCode = hardSVGCode .. utils.format([[
                    <text x="879" y="1286" font-family="MiSans Medium" fill="white" font-size="120" text-anchor="middle">
                        {} / {}
                    </text>
                ]], rating, noteCount)

                hardSVGCode = hardSVGCode .. utils.format([[
                    <text x="287" y="1385" font-family="MiSans Medium" fill="white" font-size="37">
                        Chart: {}
                    </text>
                ]], chartDesigner)
            elseif index == 4 then
                specialSVGCode = specialSVGCode .. string.format([[
                    <text x="%.0f" y="1260" font-family="MiSans Medium" fill="white" font-size="87">
                        %s
                    </text>
                ]], 1432 - difficultyWidthOffset, difficulty)

                specialSVGCode = specialSVGCode .. utils.format([[
                    <text x="1931" y="1286" font-family="MiSans Medium" fill="white" font-size="120" text-anchor="middle">
                        {} / {}
                    </text>
                ]], rating, noteCount)

                specialSVGCode = specialSVGCode .. utils.format([[
                    <text x="1339" y="1385" font-family="MiSans Medium" fill="white" font-size="37">
                        Chart: {}
                    </text>
                ]], chartDesigner)
            else
                -- unknown
            end
        end

        local level = { "Easy", "Normal", "Hard", "Special" }

        for index, v in ipairs(musicInfo.Additional.SpecialLevel) do
            if type(v) ~= "userdata" then
                level[index] = v
            end
            local levelStr = level[index]

            if index == 1 then
                easySVGCode = easySVGCode ..
                utils.format(
                '<text x="380" y="1020" font-family="MiSans Medium" fill="white" font-size="36" text-anchor="middle">{}</text>',
                    levelStr)
            elseif index == 2 then
                normalSVGCode = normalSVGCode ..
                utils.format(
                '<text x="1432" y="1020" font-family="MiSans Medium" fill="white" font-size="36" text-anchor="middle">{}</text>',
                    levelStr)
            elseif index == 3 then
                hardSVGCode = hardSVGCode ..
                utils.format(
                '<text x="380" y="1316" font-family="MiSans Medium" fill="white" font-size="36" text-anchor="middle">{}</text>',
                    levelStr)
            elseif index == 4 then
                specialSVGCode = specialSVGCode ..
                utils.format(
                '<text x="1432" y="1316" font-family="MiSans Medium" fill="white" font-size="36" text-anchor="middle">{}</text>',
                    levelStr)
            else
                -- unknown
            end
        end

        local content = utils.format(file:read("*all"),
            canvasWidth, canvasHeight, gaussianBlurFilePath, illPath,
            title, artist, illustration, bpm,
            easySVGCode, normalSVGCode, hardSVGCode, specialSVGCode
        )

        file:close()
        return core.complete_control(content, "lua/extra/general.lua", "deleteTempGaussianBlurFile",
            { filePath = gaussianBlurFilePath })
    end
    return core.error(1, 500, "draw lua has mistake.")
end

function b30(obj)
    local data = json.decode(obj)
    local APIAuthorization, qrcodeBase64, randomSeed = data.authorization, data.qrcodeBase64, data.randomSeed
    utils.authorization = UTILS_TOKEN

    local playerInfo = api.getPlayerInfo(API_URL, APIAuthorization, qrcodeBase64)

    -- 随机背景图
    local bgTable = utils.getSubdirectories(illustrationRootDirectory)

	math.randomseed(randomSeed)
    local bgIndex = math.random(1, #bgTable)
	local fileName = bgTable[bgIndex]
    local bgPath = illustrationRootDirectory .. fileName .. "/Texture2D.png"
    local gaussianBlurFilePath = utils.gaussianBlurSimple(bgPath, BLUR_VALUE).saveFilePath

    local file = io.open("svg/orzmic/b30.svg", "r")
    if file then
        local canvasWidth, canvasHeight = utils.toSVGScale(1920), utils.toSVGScale(4315)

        local playerName, playerRating, playerSPRating = playerInfo.Name, playerInfo.Rat, playerInfo.SPRat

        -- 获取当前时间戳
        local currentTimestamp = os.time()
        local dateTime, dateTimeFontSize = os.date("%Y-%m-%d %H:%M:%S", currentTimestamp), 28
        local dateTimeWidth, __ = libself.get_text_size(dateTime, ORZMIC_TTF_PATH, dateTimeFontSize)
        local dateSVGPosition = 2474 - utils.toSVGScale(dateTimeWidth)

        -- 判断字符串
        if #playerRating <= 0 then
            playerRating = "0.000"
        end
        if #playerSPRating <= 0 then
            playerSPRating = "0"
        end

        local beginPlayerRating, endPlayerRating = playerRating:sub(1, #playerRating - 1), playerRating:sub(#playerRating, #playerRating)

        local beginPlayerRatingFontSize = 42
        local beginPlayerRatingWidth, __ = libself.get_text_size(beginPlayerRating, ORZMIC_TTF_PATH, beginPlayerRatingFontSize)

        -- 角色相关
        local charID, charSkinID = playerInfo.CharID, playerInfo.CharSkinID
        local characterFile = characterRootDirectory .. string.format("%.0f_%.0f.png", charID, charSkinID)
        local characterMsgFile = io.open(characterRootDirectory .. string.format("%.0f_ZH.json", charID), "r")
        local characterDialogs = {}
        if characterMsgFile then
            local charInfo = json.decode(characterMsgFile:read("*all"))

            for __, dialog in ipairs(charInfo.Dialogs) do
                dialog = string.gsub(dialog,"%[%]", playerName)
                table.insert(characterDialogs, dialog)
            end

            characterMsgFile:close()
        end

        local dialogIndex = math.random(1, #characterDialogs)
        local characterDialog, characterDialogFontSize, maxRow, maxEdge = characterDialogs[dialogIndex], 26, 4, 624
        local dialogSVG = ""

        -- 对话相关
        characterDialog = libself.handle_text(
            characterDialog,
            "resource/fonts/MiSans-Medium.ttf",
            characterDialogFontSize, maxEdge, true, maxRow
            )

        for index, value in ipairs(characterDialog) do
            dialogSVG = dialogSVG .. string.format("<tspan x=\"0\" y=\"%dpx\">%s</tspan>", (index - 1) * 40, utils.escapeHtml(value))
        end

        -- userdata
        local playerNameFont,maxPlayerNameSize = 64, 680
        playerName = libself.handle_text(
            playerName,
            ORZMIC_TTF_PATH,
            playerNameFont, maxPlayerNameSize
        )

        local playerBest30 = playerInfo.B30Score

        local playerBest30ActualLength = #playerBest30
        -- 如果实际长度小于30，则将后面的元素填充为nil  
        if playerBest30ActualLength < 30 then
            for ___ = playerBest30ActualLength + 1, 30 do
                table.insert(playerBest30, "null")
            end
        end

        local unknownIllustrationPath = "resource/orzmic/unknown.png"

        local best30SVG = ""

        local initPositionX, initPositionY = utils.toSVGScale(38), utils.toSVGScale(694)
        for index, info in ipairs(playerBest30) do
            local row, col = (index - 1) % 3, (index - 1) // 3
            local positionX, positionY = initPositionX + utils.toSVGScale(646) * row, initPositionY + utils.toSVGScale(360) * col
            if info == "null" then
                -- 如果是不存在的
                local ill = unknownIllustrationPath

                best30SVG = best30SVG .. string.format([[<image x="%.0fpx" y="%.0fpx" width="733px" height="413px" href="%s"/>]],
                positionX, positionY,ill)

                best30SVG = best30SVG .. string.format([[<rect x="%.0fpx" y="%.0fpx" width="733px" height="84px"  fill="black" fill-opacity="0.50"/>]],
                positionX, positionY + 413 - 84)

                best30SVG = best30SVG .. string.format([[<rect x="%.0fpx" y="%.0fpx" width="733px" height="250px"  fill="black" fill-opacity="0.60"/>]],
                positionX, positionY + 413 - 250)
                
                local evaluatePath = getEvaluateImage(9)
                
                best30SVG = best30SVG .. string.format([[<image x="%.0fpx" y="%.0fpx" width="133px" height="133px" href="%s"/>]],
                positionX + utils.toSVGScale(424), positionY + utils.toSVGScale(199), evaluatePath)

                best30SVG = best30SVG .. string.format([[
                <text x="%.0fpx" y="%.0fpx" fill="%s" font-size="80px" font-family="Geometos">
                    %s
                </text>]],
                positionX + utils.toSVGScale(16), positionY + utils.toSVGScale(238), getClearColor(4), "-")

                best30SVG = best30SVG .. string.format([[
                <text x="%.0fpx" y="%.0fpx" fill="%s" font-size="56px" font-family="Geometos" text-anchor="middle">
                    %s
                </text>
                <text x="%.0fpx" y="%.0fpx" fill="white" font-size="56px" font-family="Geometos">
                    %.1f >> %.3f
                </text>
                ]],
                positionX + utils.toSVGScale(54), positionY + utils.toSVGScale(294), getLevelColor(4), "-",
                positionX + utils.toSVGScale(95), positionY + utils.toSVGScale(294), 0.0, 0.0)

                local i = tostring(index)

                if #i < 2 then
                    i = "0" .. i
                end

                best30SVG = best30SVG .. string.format([[
                <text x="%.0fpx" y="%.0fpx" fill="white" font-size="24px" font-family="MiSans Medium" text-anchor="end">
                    #%s
                </text>]],
                positionX + utils.toSVGScale(544), positionY + utils.toSVGScale(143),i)

                local title, titleFontSize = "-", 30

                local artist, artistFontSize = "-", 24

                best30SVG = best30SVG .. string.format([[
                <text x="%.0fpx" y="%.0fpx" fill="white" font-size="%.0fpx" font-family="MiSans Medium">
                    %s
                </text>
                <text x="%.0fpx" y="%.0fpx" fill="white" font-size="%.0fpx" font-family="MiSans Medium">
                    %s
                </text>]],
                positionX + utils.toSVGScale(16), positionY + utils.toSVGScale(158), utils.toSVGScale(titleFontSize), title,
                positionX + utils.toSVGScale(16), positionY + utils.toSVGScale(182), utils.toSVGScale(artistFontSize), artist)
            else
                local ill = illustrationRootDirectory .. info.FileName .. "/Texture2D.png"

                best30SVG = best30SVG .. string.format([[<image x="%.0fpx" y="%.0fpx" width="733px" height="413px" href="%s"/>]],
                positionX, positionY,ill)

                best30SVG = best30SVG .. string.format([[<rect x="%.0fpx" y="%.0fpx" width="733px" height="84px"  fill="black" fill-opacity="0.50"/>]],
                positionX, positionY + 413 - 84)

                best30SVG = best30SVG .. string.format([[<rect x="%.0fpx" y="%.0fpx" width="733px" height="250px"  fill="black" fill-opacity="0.60"/>]],
                positionX, positionY + 413 - 250)
                
                local evaluatePath = getEvaluateImage(info.EvaluateType)
                
                best30SVG = best30SVG .. string.format([[<image x="%.0fpx" y="%.0fpx" width="133px" height="133px" href="%s"/>]],
                positionX + utils.toSVGScale(424), positionY + utils.toSVGScale(199), evaluatePath)

                local plusType = info.PlusType
                
                if plusType <= 1 then
                    local plusEvaluatePath = getPlusEvaluateImage(plusType)
                    best30SVG = best30SVG .. string.format([[<image x="%.0fpx" y="%.0fpx" width="42px" height="42px" href="%s"/>]],
                    positionX + utils.toSVGScale(506), positionY + utils.toSVGScale(185), plusEvaluatePath)
                end

                best30SVG = best30SVG .. string.format([[
                <text x="%.0fpx" y="%.0fpx" fill="%s" font-size="80px" font-family="Geometos">
                    %s
                </text>]],
                positionX + utils.toSVGScale(16), positionY + utils.toSVGScale(238), getClearColor(info.ClearType), formatNumber(info.Score):sub(5,-1))

                local levelStr = "-"
                if info.Level == 0 then
                    levelStr = "EZ"
                elseif info.Level == 1 then
                    levelStr = "NR"
                elseif info.Level == 2 then
                    levelStr = "HD"
                elseif info.Level == 3 then
                    levelStr = "SP"
                end
                
                best30SVG = best30SVG .. string.format([[
                <text x="%.0fpx" y="%.0fpx" fill="%s" font-size="56px" font-family="Geometos" text-anchor="middle">
                    %s
                </text>
                <text x="%.0fpx" y="%.0fpx" fill="white" font-size="56px" font-family="Geometos">
                    %.1f >> %.3f
                </text>
                ]],
                positionX + utils.toSVGScale(54), positionY + utils.toSVGScale(294), getLevelColor(info.Level), levelStr,
                positionX + utils.toSVGScale(95), positionY + utils.toSVGScale(294), info.Rating, info.Rate)

                local i = tostring(index)

                if #i < 2 then
                    i = "0" .. i
                end

                best30SVG = best30SVG .. string.format([[
                <text x="%.0fpx" y="%.0fpx" fill="white" font-size="24px" font-family="MiSans Medium" text-anchor="end">
                    #%s
                </text>]],
                positionX + utils.toSVGScale(544), positionY + utils.toSVGScale(143),i)

                local title, titleFontSize, titleMaxSize = info.Title, 30, 484

                title = libself.handle_text(
                    title,
                    ORZMIC_TTF_PATH,
                    titleFontSize, titleMaxSize
                )

                local artist, artistFontSize, artistMaxSize = info.Artist, 24, 484

                artist = libself.handle_text(
                    artist,
                    ORZMIC_TTF_PATH,
                    artistFontSize, artistMaxSize
                )

                best30SVG = best30SVG .. string.format([[
                <text x="%.0fpx" y="%.0fpx" fill="white" font-size="%.0fpx" font-family="MiSans Medium">
                    %s
                </text>
                <text x="%.0fpx" y="%.0fpx" fill="white" font-size="%.0fpx" font-family="MiSans Medium">
                    %s
                </text>]],
                positionX + utils.toSVGScale(16), positionY + utils.toSVGScale(158), utils.toSVGScale(titleFontSize), utils.escapeHtml(title),
                positionX + utils.toSVGScale(16), positionY + utils.toSVGScale(182), utils.toSVGScale(artistFontSize), utils.escapeHtml(artist))
                -- ################################################################
            end
        end

        local content = utils.format(file:read("*all"),
            canvasWidth, canvasHeight, gaussianBlurFilePath, characterFile, dialogSVG, utils.escapeHtml(playerName),
            beginPlayerRating, string.format("%.0f", 2266 + utils.toSVGScale(beginPlayerRatingWidth)), endPlayerRating, playerSPRating,
            dateSVGPosition, dateTime, dateSVGPosition - 56, best30SVG, addCommas(math.tointeger(playerInfo.Coin))
        )
        file:close()
        return core.complete_control(content, "lua/extra/general.lua", "deleteTempGaussianBlurFile",
            { filePath = gaussianBlurFilePath })
    end
    return core.error(1, 500, "draw lua has mistake.")
end

function special(obj)
    local data = json.decode(obj)
    local APIAuthorization, qrcodeBase64, randomSeed = data.authorization, data.qrcodeBase64, data.randomSeed
    utils.authorization = UTILS_TOKEN

    local playerInfo = api.getPlayerInfo(API_URL, APIAuthorization, qrcodeBase64)

    -- 随机背景图
    local bgTable = utils.getSubdirectories(illustrationRootDirectory)

	math.randomseed(randomSeed)
    local bgIndex = math.random(1, #bgTable)
	local fileName = bgTable[bgIndex]
    local bgPath = illustrationRootDirectory .. fileName .. "/Texture2D.png"
    local gaussianBlurFilePath = utils.gaussianBlurSimple(bgPath, BLUR_VALUE).saveFilePath

    local file = io.open("svg/orzmic/special.svg", "r")
    if file then
        local canvasWidth, canvasHeight = utils.toSVGScale(1920), utils.toSVGScale(675)

        local playerName, playerRating, playerSPRating = playerInfo.Name, playerInfo.Rat, playerInfo.SPRat

        -- 获取当前时间戳
        local currentTimestamp = os.time()
        local dateTime, dateTimeFontSize = os.date("%Y-%m-%d %H:%M:%S", currentTimestamp), 28
        local dateTimeWidth, __ = libself.get_text_size(dateTime, ORZMIC_TTF_PATH, dateTimeFontSize)
        local dateSVGPosition = 2474 - utils.toSVGScale(dateTimeWidth)

        -- 判断字符串
        if #playerRating <= 0 then
            playerRating = "0.000"
        end
        if #playerSPRating <= 0 then
            playerSPRating = "0"
        end

        local beginPlayerRating, endPlayerRating = playerRating:sub(1, #playerRating - 1), playerRating:sub(#playerRating, #playerRating)

        local beginPlayerRatingFontSize = 42
        local beginPlayerRatingWidth, __ = libself.get_text_size(beginPlayerRating, ORZMIC_TTF_PATH, beginPlayerRatingFontSize)

        -- 角色相关
        local charID, charSkinID = playerInfo.CharID, playerInfo.CharSkinID
        local characterFile = characterRootDirectory .. string.format("%.0f_%.0f.png", charID, charSkinID)
        local characterMsgFile = io.open(characterRootDirectory .. string.format("%.0f_ZH.json", charID), "r")
        local characterDialogs = {}
        if characterMsgFile then
            local charInfo = json.decode(characterMsgFile:read("*all"))

            for __, dialog in ipairs(charInfo.Dialogs) do
                dialog = string.gsub(dialog,"%[%]", playerName)
                table.insert(characterDialogs, dialog)
            end

            characterMsgFile:close()
        end

        local dialogIndex = math.random(1, #characterDialogs)
        local characterDialog, characterDialogFontSize, maxRow, maxEdge = characterDialogs[dialogIndex], 26, 4, 624
        local dialogSVG = ""

        -- 对话相关
        characterDialog = libself.handle_text(
            characterDialog,
            "resource/fonts/MiSans-Medium.ttf",
            characterDialogFontSize, maxEdge, true, maxRow
            )

        for index, value in ipairs(characterDialog) do
            dialogSVG = dialogSVG .. string.format("<tspan x=\"0\" y=\"%dpx\">%s</tspan>", (index - 1) * 40, utils.escapeHtml(value))
        end

        -- userdata
        local playerNameFont,maxPlayerNameSize = 64, 680
        playerName = libself.handle_text(
            playerName,
            ORZMIC_TTF_PATH,
            playerNameFont, maxPlayerNameSize
        )

        local playerSpecial = playerInfo.SpecialScores

        local specialSVG = ""

        -- SVG BEGIN

        for index, value in ipairs(playerSpecial) do
            local level, levelNum = "SPECIAL", math.tointeger(value.Level)
            local difficulty = value.Difficulty
            fileName = value.FileName
            local evaluatePath = getEvaluateImage(value.EvaluateType)
            local lrSelect = index % 2

            local tableContentSVG = ""

            tableContentSVG = tableContentSVG .. ""

            local function borderLine(x, y)
                return string.format("<rect x=\"%.0fpx\" y=\"%.0fpx\" width=\"%.0fpx\" height=\"%.0fpx\" fill=\"#e572f6\" fill-opacity=\"0.40\"/>",
                x, y, utils.toSVGScale(6), utils.toSVGScale(339))
            end

            -- width 45
            local function contentBottomBG(x, y, width)
                return string.format("<rect x=\"%.0fpx\" y=\"%.0fpx\" width=\"%.0fpx\" height=\"%.0fpx\" fill=\"white\" fill-opacity=\"0.20\"/>",
                x, y, width, utils.toSVGScale(339))
            end

            -- im边缘的2个紫线
            tableContentSVG = tableContentSVG .. borderLine(51 + utils.toSVGScale(26), canvasHeight + utils.toSVGScale(57)) .. borderLine(2509 - utils.toSVGScale(6) - utils.toSVGScale(26), canvasHeight + utils.toSVGScale(57))
            -- 底部边框
            tableContentSVG = tableContentSVG .. contentBottomBG(51 + utils.toSVGScale(6) + utils.toSVGScale(26), canvasHeight + utils.toSVGScale(57), utils.toSVGScale(45))
            tableContentSVG = tableContentSVG .. contentBottomBG(2509 - utils.toSVGScale(6) - utils.toSVGScale(45) - utils.toSVGScale(26), canvasHeight + utils.toSVGScale(57), utils.toSVGScale(45))
            
            local function illContent(x, y)
                return string.format("<rect x=\"%.0fpx\" y=\"%.0fpx\" width=\"%.0fpx\" height=\"%.0fpx\" fill=\"white\" fill-opacity=\"0.45\"/>",
                x, y, utils.toSVGScale(688), utils.toSVGScale(394)) .. string.format("<image x=\"%.0fpx\" y=\"%.0fpx\" width=\"%.0fpx\" height=\"%.0fpx\" href=\"%s\"/>",
                x + utils.toSVGScale(8), y + utils.toSVGScale(8), utils.toSVGScale(672), utils.toSVGScale(378), illustrationRootDirectory .. fileName .. "/Texture2D.png")
            end
            -- 曲绘位置
            if lrSelect == 1 then
                tableContentSVG = tableContentSVG .. illContent(utils.toSVGScale(116), canvasHeight + utils.toSVGScale(31))
                tableContentSVG = tableContentSVG .. contentBottomBG(1072,canvasHeight + utils.toSVGScale(57), 1334)
            else
                tableContentSVG = tableContentSVG .. illContent(utils.toSVGScale(1116), canvasHeight + utils.toSVGScale(31))
                tableContentSVG = tableContentSVG .. contentBottomBG(51 + utils.toSVGScale(77),canvasHeight + utils.toSVGScale(57), 1334)
            end

            -- 分割线
            local tableContentSVGPostionX = 0
            if lrSelect == 0 then
                tableContentSVGPostionX = utils.toSVGScale(101) + utils.toSVGScale(26)
            else
                tableContentSVGPostionX = canvasWidth - utils.toSVGScale(101) - utils.toSVGScale(943) - utils.toSVGScale(26)
            end
            tableContentSVG = tableContentSVG .. string.format("<image x=\"%.0fpx\" y=\"%.0fpx\" width=\"%.0fpx\" height=\"%.0fpx\" href=\"resource/orzmic/divider.png\"/>",
            tableContentSVGPostionX, canvasHeight + utils.toSVGScale(184), utils.toSVGScale(943), utils.toSVGScale(8))

            -- 文本相关
            -- 曲目标题
            local title, titleFontSize, titleMaxSize = value.Title, 64, 950

            title = libself.handle_text(
                title,
                ORZMIC_TTF_PATH,
                titleFontSize, titleMaxSize
            )

            -- 曲目创作者
            local artist, artistFontSize, artistMaxSize = value.Artist, 24, 935

            artist = libself.handle_text(
                artist,
                ORZMIC_TTF_PATH,
                artistFontSize, artistMaxSize
            )

            -- MiSans Medium, Geometos
            local function shadowText(text, x, y, fontSize, color, offsetX, offsetY, shadowColor, shadowTextAlpha, fontFamily)
                return string.format([[
                    <text x="%.0fpx" y="%.0fpx" fill="%s" font-size="%.0fpx" font-family="%s" fill-opacity="%.2f">
                        %s
                    </text><text x="%.0fpx" y="%.0fpx" fill="%s" font-size="%.0fpx" font-family="%s">
                        %s
                    </text>]], x + offsetX, y + offsetY, shadowColor, fontSize, fontFamily, shadowTextAlpha, text, x, y, color, fontSize, fontFamily, text)
            end
            -- 标题
            tableContentSVG = tableContentSVG .. shadowText(utils.escapeHtml(title),
            tableContentSVGPostionX - utils.toSVGScale(10), canvasHeight + utils.toSVGScale(134), utils.toSVGScale(titleFontSize), "white",
            utils.toSVGScale(4), utils.toSVGScale(4), "black", 0.75, "MiSans Medium")
            -- 曲师
            tableContentSVG = tableContentSVG .. shadowText(utils.escapeHtml(artist),
            tableContentSVGPostionX - utils.toSVGScale(2), canvasHeight + utils.toSVGScale(172), utils.toSVGScale(artistFontSize), "white",
            utils.toSVGScale(2), utils.toSVGScale(2), "black", 0.75, "MiSans Medium")
            -- SP标记
            tableContentSVG = tableContentSVG .. shadowText(utils.escapeHtml(level .. " " .. difficulty),
            tableContentSVGPostionX + utils.toSVGScale(1), canvasHeight + utils.toSVGScale(234), utils.toSVGScale(36), "#d98af7",
            utils.toSVGScale(3), utils.toSVGScale(3), "black", 0.75, "MiSans Medium")
            -- Score得分
            tableContentSVG = tableContentSVG .. shadowText(formatNumber(value.Score):sub(5,-1),
            tableContentSVGPostionX - utils.toSVGScale(5), canvasHeight + utils.toSVGScale(362), utils.toSVGScale(144), getClearColor(value.ClearType),
            utils.toSVGScale(8), utils.toSVGScale(8), "black", 0.75, "Geometos")
            -- 评级
            tableContentSVG = tableContentSVG .. string.format([[<image x="%.0fpx" y="%.0fpx" width="273px" height="273px" href="%s"/>]],
            tableContentSVGPostionX + utils.toSVGScale(750), canvasHeight + utils.toSVGScale(192), evaluatePath)

            specialSVG = specialSVG .. tableContentSVG
            canvasHeight = canvasHeight + utils.toSVGScale(444)
        end

        -- 标注
        canvasHeight = canvasHeight + utils.toSVGScale(180)

        --[[
            <text x="1280px" y="5725px" font-family="MiSans Medium" fill="white" font-size="51" text-anchor="middle">
            Generated by tomato Team - Orzmic
            </text>
        --]]

        specialSVG = specialSVG .. string.format([[
            <rect x="86px" y="%.0fpx" width="2388px" height="17px" fill="white"/>
        ]], canvasHeight - utils.toSVGScale(132))

        specialSVG = specialSVG .. string.format([[
            <text x="1280px" y="%.0fpx" font-family="MiSans Medium" fill="white" font-size="80px" text-anchor="middle">
            Generated by tomato Team - Orzmic
            </text>
        ]], canvasHeight - utils.toSVGScale(42))

        -- SVG END

        local bgWidth, bgHeight = canvasWidth, canvasHeight
        if canvasHeight <= utils.toSVGScale(1080) then
            bgHeight = utils.toSVGScale(1080)
            bgWidth = utils.toSVGScale(1920)
        else
            bgHeight = canvasHeight
            bgWidth = (canvasHeight * ILL_SCALE) + 2
        end
        local bgInitPositionX = bgWidth / 2 - utils.toSVGScale(1920) / 2

        local content = utils.format(file:read("*all"),
            canvasWidth, canvasHeight, gaussianBlurFilePath, characterFile, dialogSVG, utils.escapeHtml(playerName),
            beginPlayerRating, string.format("%.0f", 2266 + utils.toSVGScale(beginPlayerRatingWidth)), endPlayerRating, playerSPRating,
            dateSVGPosition, dateTime, dateSVGPosition - 56, addCommas(math.tointeger(playerInfo.Coin)), specialSVG,
            bgInitPositionX, bgWidth, bgHeight)
        file:close()
        return core.complete_control(content, "lua/extra/general.lua", "deleteTempGaussianBlurFile",
            { filePath = gaussianBlurFilePath })
    end
    return core.error(1, 500, "draw lua has mistake.")
end