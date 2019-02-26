namespace "nn"

if not nn.NeuralNetwork then
	log.log(log.LOG_ERROR, "'nn' needs to be imported before 'gfx.nn'")
end

function nn.NeuralNetwork:createTrainingModel(training_data)
	local i = 0
	local numExamples = #training_data

	return function()
		i = i + 1
		if i > numExamples then
			i = 1
		end

		self.learningRate = self.learningRate * .99999

		local data = training_data[i]
		self:back_propagate(data[1], data[2])

		return i
	end
end
