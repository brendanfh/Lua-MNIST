namespace "utils"

function readBigEndianInt(buff, idx)
	local a = buff[idx+0]
	local b = buff[idx+1]
	local c = buff[idx+2]
	local d = buff[idx+3]

	return a * 16777216 + b * 65536 + c * 256 + d
end
