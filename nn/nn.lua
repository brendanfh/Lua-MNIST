namespace "nn"

Neuron = class()
function Neuron:init(input_count)
	self.value = 0
	self.delta = 0
	self.weights = {}
	self.bias = math.random() * 1 - .5
	for i in range(1, input_count) do
		self.weights[i] = math.random() * 1 - .5 -- Initialize to random weights
	end
end

function Neuron:activate(inputs)
	local weights = self.weights

	local activation = self.bias
	for i = 1, #weights do
		activation = activation + (weights[i] * inputs[i])
	end

	self.value = activation / (2 + 2 * math.abs(activation)) + 0.5
end

Layer = class()
function Layer:init(neuron_count, input_count)
	neuron_count = neuron_count or 1
	input_count = input_count or 1

	self.neurons = {}
	for i = 1, neuron_count do
		self.neurons[i] = Neuron(input_count)
	end
end

NeuralNetwork = class()
function NeuralNetwork:init(layers, learningRate)
	self.learningRate = learningRate

	self.network = {}
	self.network[1] = Layer(layers[1], layers[1])
	for i = 2, #layers do
		self.network[i] = Layer(layers[i], layers[i-1])
	end
end

function NeuralNetwork:activate(inputs)
	local threshold = self.threshold

	for i = 1, #inputs do
		self.network[1].neurons[i].value = inputs[i]
	end

	for i = 2, #self.network do
		local inputs = {}
		local cells = self.network[i].neurons
		local prevCells = self.network[i - 1].neurons

		for j = 1, #prevCells do
			inputs[j] = prevCells[j].value
		end

		for j = 1, #cells do
			cells[j]:activate(inputs)
		end
	end
end

function NeuralNetwork:back_propagate(inputs, outputs)
	self:activate(inputs)

	local numLayers = #self.network
	local learningRate = self.learningRate


	-- Find all partial derivates with respect to the neurons
	for i = numLayers, 2, -1 do
		local numNeurons = #self.network[i].neurons
		local neurons = self.network[i].neurons

		for j = 1, numNeurons do
			local value = neurons[j].value

			if i ~= numLayers then
				local total_weight = 0
				local layer = self.network[i + 1].neurons

				for k = 1, #layer do
					total_weight = total_weight + layer[k].weights[j] * layer[k].delta
				end
				neurons[j].delta = value * (1 - value) * total_weight
			else
				neurons[j].delta = (outputs[j] - value) * value * (1 - value)
			end
		end
	end

	for i = 2, numLayers do
		for j = 1, #self.network[i].neurons do
			self.network[i].neurons[j].bias = self.network[i].neurons[j].bias + self.network[i].neurons[j].delta * learningRate
			for k = 1, #self.network[i].neurons[j].weights do
				local weights = self.network[i].neurons[j].weights

				weights[k] = weights[k] + self.network[i].neurons[j].delta * learningRate * self.network[i - 1].neurons[k].value
			end
		end
	end
end

function NeuralNetwork:getCost(expected)
	local cost = 0

	local numLayers = #self.network

	for i = 1, #self.network[numLayers].neurons do
		local neuron = self.network[numLayers].neurons[i]
		cost = cost + (neuron.value - expected[i]) * (neuron.value - expected[i])
	end

	cost = cost / #self.network[numLayers].neurons
	return cost
end
