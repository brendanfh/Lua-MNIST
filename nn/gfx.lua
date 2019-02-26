namespace "nn.gfx"

if not nn.NeuralNetwork then
	log.log(log.LOG_ERROR, "'nn' needs to be imported before 'gfx.nn'")
end

local function neuron_coord(x, y, xx, yy, w, h, neurons, layers)
	return (x - 0.5) * (w / layers) + xx, (y - 0.5) * (h / neurons) + yy
end

function drawWeights(layers, x, y, w, h, start_layer)
	start_layer = start_layer or 2
	local numLayers = #layers

	local layer, neurons, neuron, color, c, x1, y1, x2, y2

	for i = start_layer, numLayers do
		layer = layers[i]
		neurons = #layer.neurons

		for j = 1, neurons do
			neuron = layer.neurons[j]

			for k = 1, #neuron.weights do
				if neuron.weights[k] ~= 0 then
					color = neuron.weights[k] * 100 * layers[i - 1].neurons[k].value
					c = {0, 0, 0}

					if neuron.weights[k] > 0 then
						c[3] = color / 100
					else
						c[1] = -color / 100
					end

					love.graphics.setColor(c)

					x1, y1 = neuron_coord(i - 1 - start_layer + 2, k, x, y, w, h, #layers[i - 1].neurons, numLayers - start_layer + 2)
					x2, y2 = neuron_coord(i - start_layer + 2, j, x, y, w, h, neurons, numLayers - start_layer + 2)

					love.graphics.line(x1, y1, x2, y2)
				end
			end
		end
	end
end

function drawNeurons(layers, x, y, w, h, start_layer)
	start_layer = start_layer or 1
	local numLayers = #layers

	local layer, neurons, color, cx, cy
	local neuron_radius

	for i = start_layer, numLayers do
		layer = layers[i]
		neurons = #layer.neurons
		neuron_radius = h / (neurons * 3)

		for j = 1, neurons do
			color = (layer.neurons[j].value * 235 + 20) / 255
			if color > 1 then color = 1 end

			cx, cy = neuron_coord(i - start_layer + 1, j, x, y, w, h, neurons, numLayers - start_layer + 1)

			love.graphics.setColor(color, color, color)
			love.graphics.rectangle("fill", cx - neuron_radius, cy - neuron_radius, neuron_radius * 2, neuron_radius * 2)
		end
	end
end

function drawNeuron(x, y, xx, yy, ww, hh, neurons, layers, col)
	love.graphics.setColor(col)
	local cx, cy = neuron_coord(x, y, xx, yy, ww, hh, neurons, layers)
	local neuron_radius = hh / (neurons * 3)
	love.graphics.rectangle("fill", cx - neuron_radius, cy - neuron_radius, neuron_radius * 2, neuron_radius * 2)
end

function nn.NeuralNetwork:draw(x, y, w, h, start_layer)
	--Draw weights
	drawWeights(self.network, x, y, w, h, start_layer + 1)

	--Draw neurons
	drawNeurons(self.network, x, y, w, h, start_layer)
end
