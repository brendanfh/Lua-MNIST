print "Do you want to? "
print "1) Test"
print "2) Train"
local choice = io.read("*number")

if choice == nil then return end

local app

if choice == 1 then
	app = require "test_graphical"
elseif choice == 2 then
	app = require "train_graphical"
end

-- Uncomment for testing the accuracy of the network
--local app = require "test_graphical"

-- Uncomment for training the network in a graphical way
--local app = require "train_graphical"

function love.load()
	app.init()
end

function love.update()
	app.update()
end

function love.draw()
	app.draw()
end
