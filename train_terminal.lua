local function requireModules()
	require "lib.general"
	require "lib.inject"

	require "log"
	require "utils"
	require "nn.nn"
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

	if arg[1] == nil then
		print "Specify save location"
		os.exit(-1)
	end

	if arg[2] == nil then
		network = inject:Get("NeuralNetwork",
			{28 * 28, 32, 16, 32, 10}, 3
			-- {5, 8, 10, 8, 5}, 3
		)
	else
		network = nn.data.loadNeuralNetwork(arg[2])
	end

	local img_data = nn.data.loadImageData("/home/brendan/tmp/training_images/images")
	local lbl_data = nn.data.loadLabelData("/home/brendan/tmp/training_images/labels")

	trains_data = nn.data.loadTrainingData(img_data, lbl_data, 1, 60000)
	train_function = network:createTrainingModel(trains_data)

	-- "Delete image and label data"
	img_data = nil
	lbl_data = nil
	collectgarbage()
end

local total_cost = 0

init()
log.log(log.LOG_INFO, "STARTING TRAINING")
while true do
	local i = train_function()

	if i % 2000 == 1 then
		log.log(log.LOG_INFO, "SAVING NETWORK")
		nn.data.saveNeuralNetwork(network, arg[1])
	end

	if i == 1 then
		log.log(log.LOG_INFO, "Restarting at beginning of training data")
	end

	total_cost = total_cost + network:getCost(trains_data[i][2])

	if i % 10 == 0 then
		log.log(log.LOG_INFO, "[" .. i .. " / " .. 60000 .. "] ACCURACY: " .. (1 - tostring(total_cost / 10)))
		total_cost = 0
		os.execute("sleep 0.05")
	end
end
