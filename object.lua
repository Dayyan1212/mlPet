vector = require 'vector'

GameObject = {
	velocity = vector(0,0),
	position = vector(0,0),
	frame = 1,
	sprite = {}{},
	state = 1
}

function GameObject:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end

function GameObject:draw()
	-- Updates frame
	if (self.frame > 1) then
		self.frame = 1;
	else then self.frame = self.frame +1
	-- Draws object
	love.graphics.draw(sprite[self.state][self.frame], self.position.x, self.position.y)	
end

function GameObject:update(dt)
	
end
