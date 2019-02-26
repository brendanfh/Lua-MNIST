namespace "log"

LOG_ERROR = 10
LOG_WARN  = 5
LOG_INFO  = 1

local LOG_LEVEL = LOG_INFO

local function log_str(level)
	if level == LOG_ERROR then return "ERROR"
	elseif level == LOG_WARN then return "WARN"
	elseif level == LOG_INFO then return "INFO"
	end
end

function log(importance, ...)
	if importance < LOG_LEVEL then
		return
	end

	local params = { ... }
	print(os.date("%X"), "[" .. log_str(importance) .. "]", unpack(params))
end

function setLogLevel(importance)
	LOG_LEVEL = importance
end