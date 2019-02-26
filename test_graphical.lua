local function requireModules()
	require "lib.general"
	require "lib.inject"

	require "log"
	require "utils"
	require "nn.nn"
	require "nn.gfx"
	require "nn.data"
end

local function setupInjection()
	inject:Setup()

	inject:Bind("NeuralNetwork", nn.NeuralNetwork)
end

local network

local scratchpad

function init()
	requireModules()
	setupInjection()

	network = nn.data.loadNeuralNetwork(arg[2])

	scratchpad = {}
	for i in range(1, 784) do
		scratchpad[i] = math.random()
	end

	local font = love.graphics.newFont(36)
	love.graphics.setFont(font)
end

local scratchpad_square_x = 650
local scratchpad_square_y = 200
local scratchpad_scale = 16

local function panScratchpad(dx, dy)
	local new_scratchpad = {}
	for y = 0, 27 do
		local new_y = y + dy
		if new_y < 0 then new_y = new_y + 28 end if new_y >= 28 then new_y = new_y - 28 end
		for x = 0, 27 do
			local new_x = x + dx
			if new_x < 0 then new_x = new_x + 28 end
			if new_x >= 28 then new_x = new_x - 28 end

			local p = y * 28 + x + 1
			local new_p = new_y * 28 + new_x + 1

			new_scratchpad[new_p] = scratchpad[p]
		end
	end
	scratchpad = new_scratchpad
end

function update(dt)
	if love.keyboard.isDown "space" then
		for i in range(1, 784) do
			scratchpad[i] = 0
		end
	end

	-- Drawing on scratchpad
	if love.mouse.isDown(1) then
		local mx, my = love.mouse.getPosition()

		if (mx >= scratchpad_square_x) and (my >= scratchpad_square_y)
			and (mx < scratchpad_square_x + scratchpad_scale * 28)
			and (my < scratchpad_square_y + scratchpad_scale * 28) then

			mx = mx - scratchpad_square_x
			my = my - scratchpad_square_y
			mx = math.floor(mx / scratchpad_scale)
			my = math.floor(my / scratchpad_scale)

			for yy = -1, 1 do
				if my + yy >= 0 and my + yy < 28 then
					for xx = -1, 1 do
						if mx + xx >= 0 and mx + xx < 28 then
							local idx = (my + yy) * 28 + (mx + xx) + 1
							scratchpad[idx] = scratchpad[idx] + 0.2
							if scratchpad[idx] >= 1 then
								scratchpad[idx] = 1
							end
						end
					end
				end
			end
		end

		network:activate(scratchpad)
	end

	if love.keyboard.isDown "up" then
		panScratchpad(0, -1)
		network:activate(scratchpad)
	elseif love.keyboard.isDown "down" then
		panScratchpad(0, 1)
		network:activate(scratchpad)
	elseif love.keyboard.isDown "left" then
		panScratchpad(-1, 0)
		network:activate(scratchpad)
	elseif love.keyboard.isDown "right" then
		panScratchpad(1, 0)
		network:activate(scratchpad)
	end
end

function draw()
	local curr = i

	love.graphics.setLineWidth(4)
	local w, h = love.window.getMode()
	network:draw(0, 0, w / 2, h, 3)

	-- Draw scratchpad
	love.graphics.setLineWidth(1)
	for y = 0, 27 do
		for x = 0, 27 do
			local col = scratchpad[y * 28 + x + 1] * 0.8 + 0.2
			love.graphics.setColor(col, col, col)
			love.graphics.rectangle("fill",
				scratchpad_square_x + x * scratchpad_scale,
				scratchpad_square_y + y * scratchpad_scale,
				scratchpad_scale, scratchpad_scale
			)
		end
	end

	love.graphics.setColor(0, 0, 0)
	for y = 0, 27 do
		love.graphics.line(
			scratchpad_square_x, scratchpad_square_y + scratchpad_scale * y,
			scratchpad_square_x + 28 * scratchpad_scale, scratchpad_square_y + scratchpad_scale * y
		)
	end
	for x = 0, 27 do
		love.graphics.line(
			scratchpad_square_x + scratchpad_scale * x, scratchpad_square_y,
			scratchpad_square_x + scratchpad_scale * x, scratchpad_square_y + scratchpad_scale * 28
		)
	end

	local highestConfidence = 0
	local whichNumber = -1

	for i = 1, 10 do
		local con = network.network[#network.network].neurons[i].value
		if con > highestConfidence then
			highestConfidence = con
			whichNumber = i - 1
		end
	end

	love.graphics.setColor(1, 1, 1)
	love.graphics.printf(
		tostring(whichNumber) .. ", confidence: " .. tostring(highestConfidence * 100) .. "%",
		scratchpad_square_x, scratchpad_square_y - 120, scratchpad_scale * 28, "center"
	)
end

return {
	init = init;
	update = update;
	draw = draw;
}
