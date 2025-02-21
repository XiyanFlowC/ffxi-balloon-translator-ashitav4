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

    use_google_translate = false,

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

function m.update_config(config)
    for k, v in pairs(config) do
        m.config[k] = v or ''
    end
    m.config.req_para = {}
    for k, v in pairs(config.req_para or {}) do
        m.config.req_para[k] = v
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

local function google_trans (message, callback)
    message = message:gsub('\n', '')
    print(encoding:UTF8_To_ShiftJIS(message))
    
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

    if m.config.use_google_translate then
        google_trans(message, callback)
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
