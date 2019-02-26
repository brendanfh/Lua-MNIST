--Under MIT License
--Originally developed by Brendan Hansen
--Copyright 2017

--[[ found on http://lua-users.org/lists/lua-l/2010-06/msg00314.html ]]
setfenv = setfenv or function(f, t)
    f = (type(f) == 'function' and f or debug.getinfo(f + 1, 'f').func)
    local name
    local up = 0
    repeat
        up = up + 1
        name = debug.getupvalue(f, up)
    until name == '_ENV' or name == nil
    if name then
        debug.upvaluejoin(f, up, function() return t end, 1) -- use unique upvalue, set it to f
    end
end

getfenv = getfenv or function(fn)
    local i = 1
    while true do
        local name, val = debug.getupvalue(fn, i)
        if name == "_ENV" then
            return val
        elseif not name then
            break
        end
        i = i + 1
    end
end

local function helper(obj, super, f)
    return function(...)
        local a = { ... }
        local data = a[#a]
        local env = getfenv(2)

        data.extends = super
        env[obj] = f(data)
    end
end


--[[
    Module System
    "imports" are defined by:
    import {
        NAME = "path.to.lua.file";
        NAME = "path.to.lua.file:specific_import";
        NAME = "path.to.lua.file:"; --this uses the default export (see below)
    }

    "exports" are defined by:
    return module {
        the_default_export_variable;
        other_export=some_value;
    }
]]

local ALL_DEPS = {}
function import(reqs)
    local function convertPath(req)
        local r = req
        if req:find(":") ~= nil then
            r = req:sub(1, req:find(":") - 1)
        end
        r = r:gsub("%.", "/")
        return r
    end

    local function getField(req)
        if req:find(":") ~= nil then
            if req:sub(-1) == ":" then
                return "default"
            else
                return req:sub(req:find(":")+1)
            end
        else
            return nil
        end
    end

    local dep = {}
    for name, req in pairs(reqs) do
        if type(req) ~= "string" then
            error "Please use strings for referencing modules"
        end

        local mod = require(convertPath(req))
        dep[name] = mod

        if type(mod) == "table" then
            local field = getField(req)
            if field ~= nil then
                if mod[field] ~= nil then
                    dep[name] = mod[field]
                else
                    dep[name] = nil
                end
            end
       end
    end

    local newenv = setmetatable({}, {
        __index = function(_, k)
            local v = dep[k]
            if v == nil then v = _G[k] end
            return v
        end;
        __newindex = function(_, k, v)
            dep[k] = v;
        end;
    })
    setfenv(2, newenv)
end

function module(exp)
    exp["default"] = exp[1]
    exp[1] = nil
    return exp
end

--[[
    Data - basically tables that can only hold numbers, strings, bools, tables, or nil (no functions)
]]
function data(d)
    for k, v in pairs(d) do
        if type(v) == "function" then
            d[k] = nil
        end
    end
    return d
end

--[[
    Factories - basically tables that can only hold functions, normally static
]]
function factory(f)
    for k, v in pairs(f) do
        if type(v) ~= "function" then
            f[k] = nil
        end
    end
    return f
end

--[[
    Classes - factories with a initializer and a self-reference, and are allowed to hold variables

    Initialize with "init"
    Create new instance by calling name of class
    local ClassName = class { ... }
    local ClassName = Base.extend { ... }
    local instance_a = ClassName(args)

    Can also declare classes as
    class "ClassName" { ... }
    or
    class "ClassName extends Base" { ... }
    or
    class "ClassName" ["Base"] { ... }
]]
function class(obj)
    if type(obj) == "string" then
        local sub, super = obj:match "(%w+) +extends +(%w+)"
        if sub then obj = sub end

        if super then
            return helper(obj, super, class)
        else
            local o = {}
            o = setmetatable(o, {
                __call = helper(obj, nil, class);

                __index = function(_, super)
                    return helper(obj, super, class)
                end;
            })
            return o
        end
    end

    local cls = {}
    if obj.extends ~= nil then
        for k, v in pairs(obj.extends) do
            cls[k] = v
        end
    end

    for k, v in pairs(obj) do
        if k ~= "extends" then
            cls[k] = v
        end
    end

    cls = setmetatable(cls, {
        __call = function(_, ...)
            local o = {}
            local mt = {}

            for k, v in pairs(cls) do
                if k:sub(0, 2) == "__" then
                    mt[k] = v
                end
            end

            mt.__index = cls
            o = setmetatable(o, mt)

            if cls.init then
                cls.init(o, ...)
            end

            return o
        end
    })

    cls.extend = function(d)
        d.extends = cls
        return class(d)
    end

    return cls;
end

--[[
    Singleton - a single instance of a class
]]
function singleton(obj)
    return (class(obj))()
end

function enum(obj)
    if type(obj) == "string" then
        return helper(obj, nil, enum)
    end

    local i = 0
    for k, v in pairs(obj) do
        obj[k] = nil
        if type(v) == "string" then
            obj[v] = i
            i = i + 1
        end
    end
    return obj
end

function interface(fns)
    if type(fns) == "string" then
        local sub, super = fns:match "(%w+) +extends +(%w+)"
        if sub then fns = sub end

        if super then
            return helper(fns, super, interface)
        else
            local int = {}
            int = setmetatable(int, {
                __call = helper(fns, nil, interface);

                __index = function(_, super)
                    return helper(fns, super, interface)
                end;
            })
            return int
        end
    end

    local int = {}
    for k, v in pairs(fns) do
        if type(v) == "string" then
            int[v] = function(self) end
        end
    end

    if fns.extends then
        for k, v in pairs(fns.extends) do
            if type(v) == "function" then
                int[k] = function(self) end
            end
        end 
    end

    local mt = {
        __call = function(_, ...)
            error "Interfaces cannot be instatiated with a constructor"
        end;
    }
    int = setmetatable(int, mt)

    return int
end

function match(var)
    return function(tab)
        local ran = false
        for k, v in pairs(tab) do
            if k ~= "default" and var == k then
                v()
                ran = true
                break
            end
        end

        if not ran and tab["default"] then
            tab["default"]()
        end
    end
end

function with(o)
    return function(tab)
        for k, v in pairs(tab) do
            o[k] = v
        end
        return o
    end
end
