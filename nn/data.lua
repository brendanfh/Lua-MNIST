namespace "nn.data"

function loadImageData(img_path, lbl_path)
	log.log(log.LOG_INFO, "Loading image training data")

	local file = assert(io.open(img_path, 'rb'))

	local buff = {}
	local str
	repeat
		str = file:read(4 * 1024)
		for c in (str or ''):gmatch '.' do
			buff[#buff + 1] = c:byte()
		end
	until not str

	file:close()

	log.log(log.LOG_INFO, "Loaded image training data, " .. tostring(#buff) .. " bytes")
	return buff
end

function loadLabelData(lbl_path)
	log.log(log.LOG_INFO, "Loading label training data")

	local labels = {}
	local file = assert(io.open(lbl_path, 'rb'))
	repeat
		str = file:read(4 * 1024)
		for c in (str or ''):gmatch '.' do
			labels[#labels + 1] = c:byte()
		end
	until not str

	file:close()

	log.log(log.LOG_INFO, "Loaded label training data, " .. tostring(#labels) .. " bytes")
	return labels
end

function loadTrainingData(img_data, lbl_data, start_image, num_images)
	local img_idx = 1
	local magic_number = utils.readBigEndianInt(img_data, img_idx)
	img_idx = img_idx + 4

	local number_of_images = utils.readBigEndianInt(img_data, img_idx)
	img_idx = img_idx + 4

	local rows = utils.readBigEndianInt(img_data, img_idx)
	img_idx = img_idx + 4
	local columns = utils.readBigEndianInt(img_data, img_idx)
	img_idx = img_idx + 4

	local lbl_idx = 9

	img_idx = img_idx + (start_image - 1) * 784
	lbl_idx = lbl_idx + (start_image - 1)

	local training_data = {}
	for i = 1, num_images do
		local img = {}
		for y = 0, rows - 1 do
			for x = 0, columns - 1 do
				img[y * columns + x] = img_data[img_idx] / 255
				img_idx = img_idx + 1
			end
		end

		local label = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
		label[lbl_data[lbl_idx] + 1] = 1
		lbl_idx = lbl_idx + 1

		training_data[i] = { img, label }
	end

	return training_data
end


function saveNeuralNetwork(network, file_path)
	local file = io.open(file_path, 'w+')

	local numLayers = #network.network
	file:write(tostring(numLayers) .. "\n")
	file:write(tostring(network.learningRate) .. "\n")

	for l = 1, numLayers do
		file:write(tostring(#network.network[l].neurons) .. " ")
	end

	file:write("\n")

	for l = 1, numLayers do
		local layer = network.network[l]

		for n = 1, #layer.neurons do
			file:write(tostring(bias) .. ' ')
		end

		file:write("\n")

		for n = 1, #layer.neurons do
			local neuron = layer.neurons[n]

			for w = 1, #neuron.weights do
				local weight = neuron.weights[w]
				file:write(tostring(weight) .. ' ')
			end
		end
		file:write("\n")
	end

	file:close()
end

function loadNeuralNetwork(file_path)
	local file = io.open(file_path, 'r')	

	local numLayers = file:read("*number")
	log.log(log.LOG_INFO, "Loading network with " .. numLayers .. " layers")

	local learningRate = file:read("*number")
	log.log(log.LOG_INFO, "Learning rate: " .. learningRate)

	local layerCount = {}
	for l = 1, numLayers do
		layerCount[l] = file:read("*number")
		log.log(log.LOG_INFO, "Layer " .. l .. " has " .. layerCount[l] .. " nodes")
	end

	local network = nn.NeuralNetwork(layerCount, learningRate)

	for l = 1, numLayers do
		log.log(log.LOG_INFO, "Reading layer " .. l)

		local upper = layerCount[l - 1]
		if upper == nil then upper = layerCount[l] end

		for n = 1, layerCount[l] do
			local bias = file:read("*number")
			network.network[l].neurons[n].bias = bias
		end

		for n = 1, layerCount[l] do
			for w = 1, upper do
				local weight = file:read("*number")
				network.network[l].neurons[n].weights[w] = weight
			end
		end
	end

	file:close()
	
	return network
end
