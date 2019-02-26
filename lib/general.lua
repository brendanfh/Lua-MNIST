_G.class = function(base)
	base = base or nil

	local mt = {
		__index = base;
		
		__call = function(cls, ...)
			local o = {}
			local mt = {
				__index = cls
			}

			for k, v in pairs(cls) do
				if k:sub(0, 2) == "__" then
					mt[k] = v
				end
			end

			setmetatable(o, mt)

			if cls.init then
				cls.init(o, ...)
			end

			return o
		end
	}

	return setmetatable({}, mt)
end

local function declare(name)
	local t = _G
	for w, d in name:gmatch "([%w_]+)(.?)" do
		t[w] = t[w] or {}
		t = t[w]
	end

	return t
end

_G.namespace = function(name)
	local vars = declare(name)
	local mt = {
		__index = function(_, k)
			local res = vars[k]
			if res then return res end
			return _G[k]
		end;
		__newindex = function(_, k, v)
			vars[k] = v
		end
	}

	local env = setmetatable({}, mt)

	if _ENV then
		return env
	else
		setfenv(2, env)
		return env
	end
end

local function range_internal(v, i)
	i = i + v[2]
	if i <= v[1] then
		return i
	end
end

range = function(lo, hi, step)
	step = step or 1
	return range_internal, {hi, step}, (lo - step)
end
