vector = require 'vector'
bump = require 'bump'

function lerp(a,b,t) return (1-t)*a + t*b end

function love.gamepadpressed( joystick, button )
	press(button)
end

function love.gamepadreleased( joystick, button )
	release(button)
end

function love.keypressed( key, scancode, isrepeat )
	press(key)
	
end

function love.keyreleased( key, scancode, isrepeat )
	release(key)
end

GameObject = {
	velocity = vector(0,0),
	nextVelocity = vector(0, 0),
	position = nil,
	sprite = nil,
	color = {255, 255, 255},
	mass = 0,
	physical = true,
	typeID = nil
}


function GameObject:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end

function GameObject:draw()
	love.graphics.setColor(self.color)
	tiles:add(ascii[self.sprite], math.floor(self.position.x), math.floor(self.position.y))
end

function GameObject:update(dt)
--make sure no infinite bouncing at some point
	self.velocity = self.nextVelocity:clone()
	local actualX, actualY, cols, len = world:move(self, self.position.x + self.velocity.x*dt, self.position.y + self.velocity.y*dt, projectileFilter)
	for i=1, len do
			if (cols[i].normal.x < 0 and self.nextVelocity.x > 0) or (cols[i].normal.x > 0 and self.nextVelocity.x < 0) then
				self.nextVelocity.x = self.nextVelocity.x * -1
			 end

			if (cols[i].normal.y < 0 and self.nextVelocity.y > 0) or (cols[i].normal.y > 0 and self.nextVelocity.y < 0) then
				self.nextVelocity.y = self.nextVelocity.y * -1
			end
	end
	self.position = vector(actualX, actualY)
end



Player = GameObject:new({typeID = "player", shield = false, shieldVector = vector(0,0)})

function Player:update(dt)
--make sure no infinite bouncing at some point

	if inputTracker.shield and inputTracker.sRelease == true then 
		self.shield = true 
		inputTracker.sRelease = false
	else self.shield = false end
	
	if inputTracker.curr == "left" then self.shieldVector = vector(-1, 0)
	elseif inputTracker.curr == "up" then  self.shieldVector =  vector(0, -1)
	elseif inputTracker.curr == "right" then self.shieldVector = vector(1, 0)
	elseif inputTracker.curr == "down" then self.shieldVector = vector(0, 1) end
	
	if self.shield then 
		local items, len = world:queryRect(self.position.x+16*self.shieldVector.x,self.position.y+16*self.shieldVector.y, 16, 16, filter)
		for i=1, len do	
			if items[i].typeID == "projectile" then items[i].nextVelocity = self.shieldVector*(3*dt) end
		end
	end
	self.velocity = self.nextVelocity:clone()
	self.nextVelocity = vector(0,0)
	
	local inputVector = vector(0,0)

	if inputTracker.up then inputVector.y = inputVector.y-(3*dt) end
	if inputTracker.down then inputVector.y = inputVector.y+(3*dt) end
	if inputTracker.left then inputVector.x = inputVector.x-(3*dt) end
	if inputTracker.right then inputVector.x = inputVector.x+(3*dt) end
	
	self.velocity = self.velocity + (inputVector:trimInplace(3))
	
	local actualX, actualY, cols, len = world:move(self, self.position.x + self.velocity.x*dt, self.position.y + self.velocity.y*dt, projectileFilter)
	
	--update 
	self.position = vector(actualX, actualY)
end

function Player:draw()

	if self.shield then shieldSprite = 0x2B self.shield = false else shieldSprite = 0x0B end
	
	love.graphics.setColor(self.color)
	tiles:add(ascii[self.sprite], math.floor(self.position.x), math.floor(self.position.y))
	tiles:add(ascii[shieldSprite], math.floor(self.position.x+(self.shieldVector.x*16)), math.floor(self.position.y+(self.shieldVector.y*16)))
end

local projectileFilter = function(item, other)
	if item.typeID == "projectile" and other.typeID == "wall" then
		return "bounce"
	elseif item.typeID == "player" and other.typeID == "wall" then
		return "slide"
	end
end

function release(key) 
	if inputMap[key] then
		inputTracker[inputMap[key]] = false
		if inputMap[key] == "shield" then inputTracker.sRelease = true end
		if inputTracker[inputTracker.curr] == false then
			if inputTracker.left then inputTracker.curr = "left"
			elseif inputTracker.right then inputTracker.curr = "right" 
			elseif inputTracker.up then inputTracker.curr = "up"
			elseif inputTracker.down then inputTracker.curr = "down" end
		end
	end
end

function press(key)
	if inputMap[key] then
		if inputTracker[inputTracker.curr] == false and (inputMap[key] == "left" or inputMap[key] == "right" or inputMap[key] == "up" or inputMap[key] == "down") then
			inputTracker.curr = inputMap[key]
		end
		inputTracker[inputMap[key]] = true
	end
end

function love.run()
 
	if love.math then
		love.math.setRandomSeed(os.time())
	end
 
	if love.load then love.load(arg) end
 
	-- We don't want the first frame's dt to include time taken by love.load.
	if love.timer then love.timer.step() end
 
	local dt = 0
 
	-- Main loop time.
	while true do
		-- Process events.
		if love.event then
			love.event.pump()
			for name, a,b,c,d,e,f in love.event.poll() do
				if name == "quit" then
					if not love.quit or not love.quit() then
						return a
					end
				end
				love.handlers[name](a,b,c,d,e,f)
			end
		end
 
		-- Update dt, as we'll be passing it to update
		if love.timer then
			love.timer.step()
			dt = love.timer.getDelta()
		end
 
		-- Call update and draw
		if love.update then love.update(dt) end -- will pass 0 if love.timer is disabled
 
		if love.graphics and love.graphics.isActive() then
			love.graphics.clear(love.graphics.getBackgroundColor())
			love.graphics.origin()
			if love.draw then love.draw() end
			love.graphics.present()
		end
 
		if love.timer then love.timer.sleep(0.001) end
	end
 
end

function love.load()
	objects = {}
	spriteSize = 16
	love.graphics.setBackgroundColor(0, 0, 0)
	atlas = love.graphics.newImage("EGA16x16.png")
	sAtlas = love.graphics.newImage("shield16x16.png")
	tiles = love.graphics.newSpriteBatch(atlas)
	ascii = {}
	angles = {}
	for i=0, 15 do
		for j=0, 15 do
			ascii[(i*16)+j] = love.graphics.newQuad(i*spriteSize, j*spriteSize, spriteSize, spriteSize, atlas:getDimensions())
		end
	end
	shield = {
		["left"] = love.graphics.newQuad(0, 0, spriteSize, spriteSize, sAtlas:getDimensions()), 
		["up"] = love.graphics.newQuad(spriteSize, 0, spriteSize, spriteSize, sAtlas:getDimensions()), 
		["down"] = love.graphics.newQuad(0, spriteSize, spriteSize, spriteSize, sAtlas:getDimensions()), 
		["right"] = love.graphics.newQuad(spriteSize, spriteSize, spriteSize, spriteSize, sAtlas:getDimensions())}
	
	player = {["xPos"]=0, ["yPos"]=0, ["xVel"]=0, ["yVel"]=0, ["sprite"] = ascii[0x04]}
	inputTracker = {["curr"] = "up", ["left"] = false, ["right"] = false, ["up"] = false, ["down"] = false, ["shield"] = false, ["sRelease"] = true}
	inputMap = {["dpup"] = "up", ["dpdown"] = "down", ["dpleft"] = "left", ["dpright"] = "right", ["w"] = "up", ["a"] = "left", ["s"] = "down", ["d"] = "right", ["j"] = "shield"}
	
	sOffsetX = {["left"] = -spriteSize, ["up"] = 0, ["right"] = spriteSize, ["down"] = 0}
	sOffsetY = {["left"] = 0, ["up"] = -spriteSize, ["right"] = 0, ["down"] = spriteSize}
	world = bump.newWorld(16)
	for i = 0, 39 do
		local a = GameObject:new{sprite = 0x2B, position = vector(16*i, 0), typeID = "wall"}
		world:add(a, 16*i, 0, 16, 16)
		table.insert(objects, a)
		local a = GameObject:new{sprite = 0x2B, position = vector(16*i, 29*16), typeID = "wall"}
		world:add(a, 16*i, 29*16, 16, 16)
		table.insert(objects, a)
	end
	for i = 1, 28 do
		local a = GameObject:new{sprite = 0x2B, position = vector(0, 16*i), typeID = "wall"}
		world:add(a, 0, 16*i, 16, 16)
		table.insert(objects, a)
		local a = GameObject:new{sprite = 0x2B, position = vector(39*16, 16*i), typeID = "wall"}
		world:add(a, 39*16, i*16, 16, 16)
		table.insert(objects, a)
	end
	
	projectile = GameObject:new{sprite = 0x90, position = vector(100, 100), velocity = vector(2,4), typeID = "projectile", nextVelocity = vector(1, 2), mass = 1}
	world:add(projectile, projectile.position.x, projectile.position.y, 16, 16)
	table.insert(objects, projectile)
	
	player = Player:new{sprite = 0x04, position = vector(100, 200),  typeID = "player"}
	world:add(player, player.position.x, player.position.y, 16, 16)
	table.insert(objects, player)
	
end

function love.update()
	dt = love.timer.getDelta()/(1/60)
	for key,value in pairs(objects) do value:update(dt) end
	--[[handle inputs
	if inputTracker.up then player.yVel = player.yVel-(1*dt) end
	if inputTracker.down then player.yVel = player.yVel+(1*dt) end
	if inputTracker.left then player.xVel = player.xVel-(1*dt) end
	if inputTracker.right then player.xVel = player.xVel+(1*dt) end
	
	--update player position
	player.xPos = player.xPos + player.xVel
	player.yPos = player.yPos + player.yVel
	
	--update 
	player.xVel = 0
	player.yVel = 0
	--]]
	
end

function love.draw()
	for key,value in pairs(objects) do value:draw() end
	love.graphics.draw(tiles,0,0)
	tiles:clear()
	--[[
	tiles:add(player.sprite, math.floor(player.xPos), math.floor(player.yPos))
	love.graphics.draw(tiles, 0, 0)

	love.graphics.draw(sAtlas, shield[inputTracker.curr], math.floor(player.xPos+sOffsetX[inputTracker.curr]), math.floor(player.yPos+sOffsetY[inputTracker.curr]))
	--]]
	love.graphics.print("FPS: "..tostring(love.timer.getFPS( )), 20, 20)
end
--[[
function nearestValue(table, number)
    local smallestSoFar, smallestIndex
    for i, y in ipairs(table) do
        if not smallestSoFar or (math.abs(number-y) < smallestSoFar) then
            smallestSoFar = math.abs(number-y)
            smallestIndex = i
        end
	end
    return table[smallestIndex]
end
--]]

