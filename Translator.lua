local m = {}

local ahttp = require("ahttp.ahttp")
local json = require("json")
local term = require("Term")
local encoding = require('gdifonts.encoding')
local url = require('socket.url')

-- 硅基流动 https://api.siliconflow.cn   deepseek-ai/DeepSeek-V3
-- 深度求索 https://api.deepseek.com     deepseek-chat
-- OpenAI   https://api.openai.com       gpt-4o
-- 本地SakuraLLM http://127.0.0.1:8080 
m.config = {
    enable = false,

    use_special_api = nil,

    base_url = 'http://127.0.0.1:8080',
    endpoint = '/v1/chat/completions',
    req_para = {
        model = 'SakuraLLM'
    },
    api_key = '',

    system_prompt = nil,
    dst_lang = 'zh-CN',
    src_lang = 'ja-JP',
    trans_data_dir = addon.path .. 'trans/'
}

m.SYSTEM_PROMPT_JP = '你是一位真正擅长中日文化的本地化专家，你需要将日文游戏文本翻译为中文。这个过程中，1）不要翻译文本中的代码字符，占位符，特殊符号等非日文内容；2）翻译结果需要是流畅准确的中文。3）只需要回复翻译好的中文文本。'
m.SYSTEM_PROMPT_EN = '你是一位真正擅长中美文化的本地化专家，你需要将英文游戏文本翻译为中文。这个过程中，1）不要翻译文本中的代码字符，占位符，特殊符号等非英文内容；2）翻译结果需要是流畅准确的中文。3）只需要回复翻译好的中文文本。'

function m.init(config)
    if nil ~= config then
        m.update_config(config)
        m.config.enable = true
    end

    if not m.config.system_prompt then
        m.config.system_prompt = m.config.src_lang == 'ja-JP' and m.SYSTEM_PROMPT_JP or m.SYSTEM_PROMPT_EN
    end
    term.init()
end

local function get_cookies(headers)
    local ret = {}
    for name, value in pairs(headers) do
        if name:lower() == "set-cookie" then
            local name_value = value:match("^%s*([^;]*)") or ""
            local n, v = name_value:match("^%s*(.-)%s*=%s*(.-)%s*$")
            if n and v then
                ret[n] = v
            end
        end
    end
    return ret
end

local function build_cookie(cookies)
    local list = {}
    for k, v in pairs(cookies) do
        table.insert(list, k .. "=" .. v)
    end
    return #list > 0 and table.concat(list, "; ") or ''
end

local function youdao_init()
    if m.youdao_state then return end

    local request = {
        method = "GET",
        url = "https://m.youdao.com/translate",
        headers = {
            ["Accept"] = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            ["Accept-Language"] = "zh-CN,zh;q=0.8,zh-TW;q=0.7,zh-HK;q=0.5,ja-JP;q=0.3,en;q=0.2",
            ["Origin"] = "https://m.youdao.com",
            ["Referer"] = "https://m.youdao.com/translate",
            ["Upgrade-Insecure-Requests"] = "1",
            ["Sec-Fetch-Dest"] = "document",
            ["Sec-Fetch-Mode"] = "navigate",
            ["Sec-Fetch-Site"] = "same-origin",
            ["Sec-Fetch-User"] = "?1",
            ["Priority"] = "u=0, i",
            ["User-Agent"] = "Mozilla/5.0 (Linux; Android 11; SAMSUNG SM-G973U) AppleWebKit/537.36 (KHTML, like Gecko) SamsungBrowser/14.2 Chrome/87.0.4280.141 Mobile Safari/537.36"
        }
    }

    ahttp.req(request, function (res, err)
        if res == nil then
            callback(nil, 'Error: ' .. err)
            LogManager:Log(2, 'Balloon/Translator', 'HTTP Error: ' .. err)
            return
        end

        if res.status == 200 then
            m.youdao_state = {}
            m.youdao_state.cookies = get_cookies(res.headers)
        end
    end)
end

function m.update_config(config)
    for k, v in pairs(config) do
        m.config[k] = v or ''
    end
    m.config.req_para = {}
    for k, v in pairs(config.req_para or {}) do
        m.config.req_para[k] = v
    end
    m.config.use_special_api = config.use_special_api
    if config.use_special_api then
        print ('Special API->' .. m.config.use_special_api)
        if m.config.use_special_api == "youdao_" then
            youdao_init()
        end
        return
    end
    print ('URL->' .. m.config.base_url .. m.config.endpoint)
    print ('API Key->' .. m.config.api_key:sub(1, 5) .. '***')
    for k, v in pairs(m.config.req_para) do
        print ('req_para.' .. k .. '->' .. v)
    end
end

-- 执行控制符洗脱/术语匹配等：
local function build_llm_prompt (message)
    -- 术语匹配
    local terms = term.pick_terms(message)

    local prompt = ''
    if #terms then
        prompt = '请根据以下术语表：\n'
        for i, v in ipairs(terms) do
            prompt = prompt .. v.src .. '->' .. v.dst
            if v.rm then
                prompt = prompt .. '#' .. v.rm .. '\n'
            else
                prompt = prompt .. '\n'
            end
        end
        prompt = prompt .. '翻译以下文本：'
    else
        prompt = '请翻译以下文本：'
    end

    prompt = prompt .. message
    return prompt    
end

local function build_request_body(message)
    -- local request_body = {
    --     model = m.config.llm_type,
    --     messages = {
    --         {role = 'system', content = m.config.system_prompt},
    --         {role = 'user', content = build_llm_prompt(message)}
    --     },
    --     max_tokens = 2048,
    --     stream = false
    -- }
    local request_body = m.config.req_para
    request_body.messages = {
        {role = 'system', content = m.config.system_prompt},
        {role = 'user', content = build_llm_prompt(message)}
    }

    return json.encode(request_body)
end

-- 使用LLM翻译
local function llm_trans(message, callback)
    local body = build_request_body(message)
    
    local headers = {
        ["Authorization"] = "Bearer " .. m.config.api_key,
        ["Content-Type"] = "application/json",
    }

    local request = {
        method = 'POST',
        url = m.config.base_url .. m.config.endpoint,
        headers = headers,
        body = body
    }
    
    ahttp.req(request, function(response, error)
        if response == nil then
            callback(nil, "Error: " .. error)
            LogManager:Log(2, 'Balloon/Translator', 'HTTP Error: ' .. error)
            return
        end

        if response.status == 200 then
            local response_data = json.decode(response.body)
            local translated_message = response_data.choices[1].message.content
            term.insert_cache(message, translated_message)
            callback(translated_message)
        else
            callback(nil, "Error: " .. response.status_line)
            LogManager:Log(2, 'Balloon/Translator', encoding:UTF8_To_ShiftJIS('HTTP request failed: ' .. response.status_line))
        end
    end)
end

local function preproc(message, terms)
    -- 按照术语长度降序排序（优先处理长字符串）
    table.sort(terms, function(a, b) return #a.src > #b.src end)
    
    local mappings = {}
    local counter = 1
    
    for _, term in ipairs(terms) do
        -- 转义特殊字符以进行精确匹配
        local escaped_term = term.src:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%0")
        -- 生成唯一占位符
        local placeholder = "#" .. counter
        
        -- 执行替换并记录替换次数
        local new_msg, count = message:gsub(escaped_term, placeholder)
        
        if count > 0 then
            message = new_msg
            mappings[placeholder] = term.dst
            counter = counter + 1
        end
    end
    
    return message, mappings
end

local function postproc(message, mappings)
    -- 提取所有占位符并排序（优先处理长字符串和大编号）
    local placeholders = {}
    for k in pairs(mappings) do
        table.insert(placeholders, k)
    end
    
    table.sort(placeholders, function(a, b)
        -- 先按长度降序
        if #a ~= #b then
            return #a > #b
        -- else
        --     -- 长度相同则按数字值降序
        --     local num_a = tonumber(a:match("%d+")) or 0
        --     local num_b = tonumber(b:match("%d+")) or 0
        --     return num_a > num_b
        end
    end)
    
    -- 执行反向替换
    for _, placeholder in ipairs(placeholders) do
        message = message:gsub(placeholder, mappings[placeholder])
    end
    
    return message
end

local function google_trans (message, callback)
    local original_message = message
    message = message:gsub('\n', '')
    message, mappings = preproc(message, term.pick_terms(message))
    
    ahttp.get('http://translate.googleapis.com/translate_a/single?client=gtx&dt=t&sl=' ..
        m.config.src_lang .. '&tl=' .. m.config.dst_lang .. '&q=' ..
        url.escape(message), function (res, err)
            if res == nil then
                callback(nil, 'Error: ' .. err)
                LogManager:Log(2, 'Balloon/Translator', 'HTTP Error: ' .. err)
                return
            end

            if res.status == 200 then
                local response_data = json.decode(res.body)
                local translated_message = ''
                for i, v in ipairs(response_data[1]) do
                    if v then
                        translated_message = v[1] and translated_message .. v[1] or translated_message
                    end
                end
                translated_message = postproc(translated_message:gsub('＃', '#'), mappings)
                term.insert_cache(original_message, translated_message)
                callback(translated_message)
            else
                callback(nil, "Error: " .. response.status_line)
                LogManager:Log(2, 'Balloon/Translator', 'HTTP request failed: ' .. response.status_line)
            end
        end)
end

local function youdao_trans (message, callback)

    if not m.youdao_state then
        youdao_init()
        callback(message)
        return
    end

    local original_message = message
    message = message:gsub('\n', '')
    message, mappings = preproc(message, term.pick_terms(message))

    local type_mapping = {
        ['zh-CN'] = 'ZH_CN',
        ['en-US'] = 'EN',
        ['ja-JP'] = 'JA'
    }

    local type = type_mapping[m.config.src_lang] .. '2' .. type_mapping[m.config.dst_lang]

    local body = 'inputtext=' .. url.escape(message) .. '&type=' .. type

    local request = {
        method = 'POST',
        url = "https://m.youdao.com/translate",
        headers = {
            ["User-Agent"] = "Mozilla/5.0 (Linux; Android 11; SAMSUNG SM-G973U) AppleWebKit/537.36 (KHTML, like Gecko) SamsungBrowser/14.2 Chrome/87.0.4280.141 Mobile Safari/537.36",
            ["Accept"] = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            ["Accept-Language"] = "zh-CN,zh;q=0.8,zh-TW;q=0.7,zh-HK;q=0.5,ja-JP;q=0.3,en;q=0.2",
            ["Cookie"] = build_cookie(m.youdao_state.cookies),
            ["Content-Type"] = "application/x-www-form-urlencoded",
            ["Origin"] = "https://m.youdao.com",
            ["Referer"] = "https://m.youdao.com/translate",
            ["Upgrade-Insecure-Requests"] = "1",
            ["Sec-Fetch-Dest"] = "document",
            ["Sec-Fetch-Mode"] = "navigate",
            ["Sec-Fetch-Site"] = "same-origin",
            ["Sec-Fetch-User"] = "?1",
            ["Priority"] = "u=0, i"
        },
        body = body
    }
    
    ahttp.req(request, function (res, err)
        if res == nil then
            callback(nil, 'Error: ' .. err)
            LogManager:Log(2, 'Balloon/Translator', 'HTTP Error: ' .. err)
            return
        end

        if res.status == 200 then
            local response_data = res.body
            -- LogManager:Log(5, 'Balloon/Translator', res.body)
            local pattern = [[<ul id="translateResult">%s*<li[^>]*>%s*(.-)%s*</li>%s*</ul>]]

            local contents = {}
            for content in res.body:gmatch(pattern) do
                table.insert(contents, content)
            end
            
            translated_message = postproc(table.concat(contents, '\n'), mappings)
            term.insert_cache(original_message, translated_message)
            callback(translated_message)
        else
            callback(nil, "Error: " .. response.status_line)
            LogManager:Log(2, 'Balloon/Translator', encoding:UTF8_To_ShiftJIS('HTTP request failed: ' .. response.status_line))
        end
    end)
end

-- 翻译
function m.translate(message, callback)
    if not m.config.enable then
        callback(message)
        return
    end

    local fixed = term.query_fixed(message)
    if (fixed) then
        callback(fixed)
        return
    end

    if m.config.use_special_api then
        if m.config.use_special_api == "google" then
            google_trans(message, callback)
        elseif m.config.use_special_api == "youdao_" then
            youdao_trans(message, callback)
        end
    else
        llm_trans(message, callback)
    end
    return
end

function m.pump()
    ahttp.process()
end

function m.fini()
    term.fini()
end

return m
