-- Async HTTP(S)
-- Author: DeepSeek-R1
-- Reviewer: Xiyan

local socket = require("socket")
local url = require("socket.url")
local ssl = require("socket.ssl")

local _m = {
    requests = {},    -- 当前进行中的请求表
    timeout = 10      -- 默认超时时间（s）
}

local function parse_url(str)
    local parsed = url.parse(str)
    local port = parsed.port or (parsed.scheme == "https" and 443 or 80)
    local path = parsed.path or "/"
    if parsed.query then path = path .. "?" .. parsed.query end
    return parsed.host, port, path, parsed.scheme == "https"
end

local function build_header(headers)
    ret = ''

    if headers == nil then return ret end

    for k, v in pairs(headers) do
        ret = ret .. '\r\n' .. k .. ': ' .. v
    end
    return ret
end

function _m.get(request_url, callback)
    request = {
        method = 'GET',
        url = request_url
    }
    _m.req(request, callback)
end

function _m.post(request_url, body, callback)
    _m.req({
        url = request_url,
        body = body,
        method = 'POST'
    }, callback)
end

function _m.req(request, callback)
    local host, port, path, is_https = parse_url(request.url)

    local method = request.method:upper()

    if method == 'GET' then request.body = '' end
    if request.body == nil then request.body = '' end
    if not request.headers then request.headers = {} end

    if method ~= 'GET' then request.headers["Content-Length"] = #request.body end
    
    -- 创建非阻塞TCP套接字
    local tcp = socket.tcp()
    tcp:settimeout(0)
    
    local request = {
        -- 连接用
        tcp = tcp,
        callback = callback,
        host = host,
        path = path,
        -- 状态控制
        state = "CONNECTING",
        -- 发送用
        send_buffer = table.concat({
            method, " ", path, " HTTP/1.1",
            "\r\nHost: ", host,
            "\r\nConnection: close",
            build_header(request.headers),
            "\r\n\r\n",
            request.body
        }),
        -- 接收用
        recv_buffer = "",
        headers = {},
        body = "",
        start_time = socket.gettime(),
        last_active = socket.gettime(),
        timeout = _m.timeout,
        -- HTTPS 用
        is_https = is_https,
        ssl_cxt = nil,
        ssl_obj = nil
    }

    -- HTTPS配置
    if is_https then
        request.ssl_cxt = ssl.newcontext({
            mode = "client",
            protocol = "tlsv1_2",
            verify = "none",  -- 不验证证书
            options = {"all", "no_sslv2", "no_sslv3", "no_tlsv1"}
        })
    end

    -- 开始异步连接
    local _, err = tcp:connect(host, port)
    if err and err ~= "timeout" then
        return callback(nil, "Connection failed: " .. tostring(err))
    end
    
    table.insert(_m.requests, request)
end

-- 需要定期调用
function _m.process()
    local current_time = socket.gettime()
    local i = 1
    
    while i <= #_m.requests do
        local req = _m.requests[i]
        local tcp = req.tcp
        
        -- 超时处理
        if current_time - req.start_time > req.timeout then
            req.callback(nil, "Timeout in state: "..req.state)
            tcp:close()
            table.remove(_m.requests, i)
            goto continue
        end

        -- 状态机处理
        if req.state == "CONNECTING" then
            local _, writable = socket.select(nil, {tcp}, 0)
            if #writable > 0 then
                if req.is_https then
                    -- 创建SSL对象
                    req.ssl_obj = ssl.wrap(tcp, req.ssl_cxt)
                    req.ssl_obj:settimeout(0)
                    req.ssl_obj:sni(req.host)
                    req.state = "SSL_HANDSHAKE"
                else
                    req.state = "SENDING"
                end
                req.last_active = current_time
            end

        -- SSL 握手，对象建立
        elseif req.state == "SSL_HANDSHAKE" then
            local success, err
            repeat
                success, err = req.ssl_obj:dohandshake()
                if err == "wantread" then
                    local readable = socket.select({tcp}, nil, 0)
                    if #readable == 0 then break end
                elseif err == "wantwrite" then
                    local writable = socket.select(nil, {tcp}, 0)
                    if #writable == 0 then break end
                else
                    break
                end
            until false
    
            if success then
                req.state = "SENDING"
                req.tcp = req.ssl_obj  -- 替换为SSL对象，之后对tcp的调用都由ssl对象处理
            elseif err and err ~= "wantread" and err ~= "wantwrite" then
                req.callback(nil, "SSL handshake failed: "..err)
                tcp:close()
                table.remove(_m.requests, i)
                goto continue
            end

        elseif req.state == "SENDING" then
            local bytes, err = tcp:send(req.send_buffer)
            if bytes then
                req.send_buffer = req.send_buffer:sub(bytes + 1)
                if #req.send_buffer == 0 then
                    req.state = "RECEIVING"
                    req.recv_buffer = ""
                    req.last_active = current_time
                end
            elseif err ~= "timeout" and err ~= "wantsend" then
                req.callback(nil, "Send failed: " .. err)
                tcp:close()
                table.remove(_m.requests, i)
                goto continue
            end

        elseif req.state == "RECEIVING" then
            -- 非阻塞读取数据到缓冲区
            local data, err, partial = tcp:receive(512)
            if data and #data > 0 then
                req.recv_buffer = req.recv_buffer .. data
                req.last_active = current_time
            end
            if partial and #partial > 0 then
                req.recv_buffer = req.recv_buffer .. partial
                req.last_active = current_time
            end
            
            -- 头部解析
            if not req.parsed_headers then
                -- 查找头部结束标记
                local header_end = req.recv_buffer:find("\r\n\r\n", 1, true)
                if header_end then
                    -- 解析状态行和头部
                    local header_str = req.recv_buffer:sub(1, header_end-1)
                    req.recv_buffer = req.recv_buffer:sub(header_end + 4)
                    
                    -- 解析状态行
                    for line in header_str:gmatch("[^\r\n]+") do
                        if not req.status_line then
                            req.status_line = line
                            local code = line:match(" (%d+) ")
                            req.status_code = tonumber(code)
                        else
                            local key, value = line:match("^(.-):%s*(.*)$")
                            if key then
                                key = key:lower()
                                req.headers[key] = value
                                if key == "content-length" then
                                    req.content_length = tonumber(value)
                                elseif key == "transfer-encoding" then
                                    if value:lower() == "chunked" then
                                        req.chunked = true
                                    end
                                end
                            end
                        end
                    end
                    
                    req.parsed_headers = true
                    req.last_active = current_time
                end
            end

            -- 头部解析完成后处理正文
            if req.parsed_headers then
                -- 根据Content-Length处理固定长度正文
                if req.content_length then
                    if #req.recv_buffer >= req.content_length then
                        req.body = req.recv_buffer:sub(1, req.content_length)
                        req.state = "COMPLETE"
                    end
                else

                    -- 分块数据处理
                    if req.chunked then
                        -- 头部有了吗？
                        if not req.chunk_size then
                            local length_end = string.find(req.recv_buffer, '\r\n', 1, true)
                            if length_end then
                                local length_str = string.sub(req.recv_buffer, 1, length_end - 1)
                                req.chunk_size = tonumber(length_str, 16) -- 注意十六进制
                                req.recv_buffer = string.sub(req.recv_buffer, length_end + 2)
                            end
                        end

                        -- 可以解析吗？
                        if req.chunk_size then
                            if #req.recv_buffer >= req.chunk_size + 2 then
                                req.body = req.body .. string.sub(req.recv_buffer, 1, req.chunk_size)
                                local end_marker = string.sub(req.recv_buffer, req.chunk_size + 1, req.chunk_size + 2)
                                if end_marker ~= '\r\n' then
                                    req.callback(nil, "Invalid chunk end marker.")
                                    tcp:close()
                                    table.remove(_m.requests, i)
                                    goto continue
                                end
                                req.recv_buffer = string.sub(req.recv_buffer, req.chunk_size + 2 + 1)
                                if req.chunk_size == 0 then
                                    -- 处理结束块头部
                                    req.state = "COMPLETE"
                                end
                                req.chunk_size = nil -- 重置以处理下一块
                            end
                        end
                        if err == "closed" then
                            -- 结束块尾部缺失
                            --print ('Warning! Weird chunck format!')
                            req.state = "COMPLETE" -- 需要吗？
                        end
                    
                    -- 非分块连接关闭时结束
                    elseif err == "closed" then
                        req.body = req.recv_buffer
                        req.state = "COMPLETE"
                    end
                end
            end

            -- 错误处理
            if err and err ~= "timeout" and err ~= "wantread" and req.state ~= "COMPLETE" then
                req.callback(nil, "Receive error: "..err)
                tcp:close()
                table.remove(_m.requests, i)
                goto continue
            end
        end

        -- 完成处理
        if req.state == "COMPLETE" then
            local success = req.status_code
            if success then
                req.callback({
                    status = req.status_code,
                    status_line = req.status_line,
                    headers = req.headers,
                    body = req.body
                }, nil)
            else
                req.callback(nil, "Connection closed unexpectedly")
            end
            tcp:close()
            table.remove(_m.requests, i)
            goto continue
        end

        i = i + 1
        ::continue::
    end
end

return _m
