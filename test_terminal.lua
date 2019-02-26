local function requireModules()
	require "lib.general"
	require "lib.inject"

	require "log"
	require "utils"
	require "nn.nn"
	require "nn.data"
end

local function setupInjection()
	inject:Setup()

	inject:Bind("NeuralNetwork", nn.NeuralNetwork)
end

local network
local trains_data

function init()
	requireModules()
	setupInjection()

	network = nn.data.loadNeuralNetwork(arg[1])

	local img_data = nn.data.loadImageData("/home/brendan/tmp/training_images/test_images")
	local lbl_data = nn.data.loadLabelData("/home/brendan/tmp/training_images/test_labels")

	trains_data = nn.data.loadTrainingData(img_data, lbl_data, 1, 10000)

	-- "Delete image and label data"
	img_data = nil
	lbl_data = nil
	collectgarbage()
end

local total_cost = 0

init()
log.log(log.LOG_INFO, "STARTING TESTING")

local total = 10000
local correct = 0
local numLayers = #network.network

for i = 1, total do
	if i % 100 == 0 then
		log.log(log.LOG_INFO, "[" .. i .. "/" .. total .. "] Running tests...")
	end

	local data = trains_data[i]

	network:activate(data[1])

	local highestConfidence = 0
	local choice = -1
	for i = 1, 10 do
		local con = network.network[numLayers].neurons[i].value
		if con > highestConfidence then
			highestConfidence = con
			choice = i
		end
	end

	if data[2][choice] == 1 then
		correct = correct + 1
	else
		--local right = -1
		--for i = 1, 10 do if data[2][i] == 1 then right = i end end
		--log.log(log.LOG_WARN, "WRONG, choose: " .. (choice - 1) .. " expected: " .. (right - 1))
	end
end

log.log(log.LOG_INFO, "Accuracy: " .. correct .. " / " .. total .. "   |   " .. (correct / total) .. "%")
