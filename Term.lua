local m = {}

local json = require('json')

m.terms = {}
m.fixed = {}
m.cache = {}
m.save_cache = true

function m.init()
    local f = io.open(addon.path .. 'trans/terms.json', 'r')
    m.terms = json.decode(f:read("*a"))
    f:close()
    local f = io.open(addon.path .. 'trans/fixed.json', 'r')
    m.fixed = json.decode(f:read("*a"))
    f:close()
    local f = io.open(addon.path .. 'trans/cache.json', 'r')
    m.cache = json.decode(f:read("*a"))
    f:close()
end

function m.pick_terms (message)
    local ret = L{}
    for i, v in ipairs(m.terms) do 
        if message:find(v.src) then
            table.insert(ret, v)
        end
    end
    return ret
end

function m.query_fixed(message)
    return m.fixed[message] or m.cache[message]
end

function m.insert_cache(msg, trans)
    m.cache[msg] = trans
end

function m.fini()
    if not m.save_cache then
        return 
    end

    local f = io.open(addon.path .. 'trans/cache.json', 'w')
    f:write(json.encode(m.cache))
    f:close()
end

return m
