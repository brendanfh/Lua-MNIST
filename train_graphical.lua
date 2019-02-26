local function requireModules()
	require "lib.general"
	require "lib.inject"

	require "log"
	require "utils"
	require "nn.nn"
	require "nn.gfx"
	require "nn.train"
	require "nn.data"
end

local function setupInjection()
	inject:Setup()

	inject:Bind("NeuralNetwork", nn.NeuralNetwork)
end

local network
local train_function

function init()
	requireModules()
	setupInjection()

	print(arg[2], arg[3])

	if arg[3] == nil then
		network = inject:Get("NeuralNetwork",
			{28 * 28, 64, 32, 16, 10}, 1, 1
			-- {5, 8, 10, 8, 5}, 3, 1
		)
	else
		network = nn.data.loadNeuralNetwork(arg[3])
	end

	local img_data = nn.data.loadImageData("/home/brendan/tmp/training_images/images")
	local lbl_data = nn.data.loadLabelData("/home/brendan/tmp/training_images/labels")

	trains_data = nn.data.loadTrainingData(img_data, lbl_data, 1, 15000)
	train_function = network:createTrainingModel(trains_data)

	-- "Delete image and label data"
	img_data = nil
	lbl_data = nil
	collectgarbage()
end

local current_test = 1
local t = 0
local paused = false
local function train()
	if paused then return end

	t = t - 1
	if t <= 0 then
		t = 1

		current_test = train_function()
		
		if current_test == 1 then
			log.log(log.LOG_INFO, "Restarting at beginning of training data")
		end
	end
end

function update(dt)
	train()

	if love.keyboard.isDown "p" then
		log.log(log.LOG_INFO, "Paused")
		nn.data.saveNeuralNetwork(network, arg[2])

		paused = true
	end

	if love.keyboard.isDown "u" then
		log.log(log.LOG_INFO, "Unpaused")
		paused = false
	end
end

function draw()
	local curr = current_test

	love.graphics.setLineWidth(4)
	local w, h = love.window.getMode()
	network:draw(0, 0, w, h, 2)

	for j = 1, 10 do
		if trains_data[curr][2][j] > 0 then
			nn.gfx.drawNeuron(5.2, j, 0, 0, w, h, 10, 5, {0, 1, 0})
		end
	end

	for y = 0, 27 do
		for x = 0, 27 do
			local col = trains_data[curr][1][y * 28 + x]
			love.graphics.setColor(col, col, col)
			love.graphics.rectangle("fill", x * 2, y * 2, 2, 2)
		end
	end
end

return {
	init = init;
	update = update;
	draw = draw;
}
