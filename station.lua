DropPoint = {}
DropPoint.__index = DropPoint

function DropPoint.new(sprite, x, y, scale, rot, type)
	local instance = setmetatable({}, DropPoint)
	instance.x = x
	instance.y = y
	instance.rot = rot
	instance.sprite = sprite
	instance.w = sprite:getWidth() * scale
	instance.h = sprite:getHeight() * scale
	instance.scale = scale
	instance.type = type
	instance.colour = EntityTypes[instance.type]

	instance.ox = instance.w / 2
	instance.oy = instance.h / 2
	instance.base_speed = 50
	instance.vx = math.random() * instance.base_speed - instance.base_speed / 2
	instance.vy = math.random() * instance.base_speed - instance.base_speed / 2
	
	instance.pickup_radius = instance.w / 2 * 5
	instance.ready = true
	instance.readyTimer = 0
	instance.readyTimerMax = 2
	instance.patience = 0
	instance.patienceMax = 30
	instance.currentPoints = 0
	instance.targetPoints = 1

	instance.readyBar = ProgressBar.new(x, y, 5, 12, 20, 5)
	instance.patienceBar = ProgressBar.new(x, y, 5, 12, -20, 5)
	
	return instance
end

function DropPoint:draw()
	love.graphics.print(self.targetPoints - self.currentPoints, self.x, self.y - 25)
	self.readyBar:draw(1 - self.readyTimer / self.readyTimerMax, self.x, self.y)
	self.patienceBar:draw(1 - self.patience / self.patienceMax, self.x, self.y)
	love.graphics.setColor(self.colour)
	love.graphics.draw(self.sprite, 
						self.x, -- love draws from the top left corner
						self.y, -- pos x is rightward, pos y is downward, with (0, 0) in the top left corner
						self.rot, self.scale, self.scale,
						self.ox, self.oy)
	love.graphics.setColor(1, 1, 1, 1)
end

function DropPoint:getBBox(mode)
	if mode == "circle" then
		return {self.x, self.y, math.max(self.w, self.h) / 2}
	end
	return {self.x - self.ox, self.y - self.oy, self.w, self.h}
end

function DropPoint:getDepositBBox(mode)
	return {self.x, self.y, self.pickup_radius}
end

function DropPoint:checkCollision(bbox)
	return checkBBoxCollision2(bbox, self:getBBox(mode))
end

function DropPoint:checkDeposit(bbox)
	return checkBBoxCollisionCircle(bbox, self:getDepositBBox(mode))
end

function DropPoint:deposit(cell)
	if not cell then return false end
	if self.type ~= cell.type then return false end
	self.currentPoints = self.currentPoints + 1
	self.patience = math.max(0, self.patience - self.patienceMax * 0.1)
	if self.currentPoints == self.targetPoints then
		self.patience = 0
		self.ready = false
		self.currentPoints = 0
		self.targetPoints = self.targetPoints + 1
	end
	return true
end

function DropPoint:checkBounds(x, y)
	maxX, maxY = SCREEN_TRANSFORM:inverseTransformPoint(screenW * 2, screenH * 2)
	minX, minY = SCREEN_TRANSFORM:inverseTransformPoint(0, 0)
	boundedX = math.max(math.min(x, maxX), minX)
	boundedY = math.max(math.min(y, maxY), minY)
	return boundedX, boundedY
end

function DropPoint:move(dx, dy)
	self.x = self.x + dx
	self.y = self.y + dy
	boundedX, boundedY = self:checkBounds(self.x, self.y)
	if math.abs(self.x) > math.abs(boundedX) then
		self.x = boundedX
		self.vx = - self.vx
	end 
	if math.abs(self.y) > math.abs(boundedY) then
		self.y = boundedY
		self.vy = - self.vy
	end
end

function DropPoint:update(dt)
	if not self.ready then
		self.colour = {1, 1, 1, 1}
		self.readyTimer = self.readyTimer + dt
		if self.readyTimer >= self.readyTimerMax then
			self.ready = true
			self.readyTimer = 0
			self.readyTimerMax = 2
			self.colour = ItemTypes[self.type]
		end

	else
		self.patience = self.patience + dt
		if self.patience >= self.patienceMax then
			self:triggerFail()
		end
	end
	self:move(self.vx * dt, self.vy * dt)
end

function DropPoint:triggerFail()
	self.ready = false
	self.readyTimerMax = 6
	self.patience = 0
end

----

function spawnStation(item_type, StationType, stations)
	function generatePosition()
		border = 0.35
		u = math.random(0, screenW * (1-border) * 2) + screenW * border
		v = math.random(0, screenH * (1-border) * 2) + screenH * border
		x, y = SCREEN_TRANSFORM:inverseTransformPoint(u, v)
		return x, y
	end
	
	function checkPosition(x, y)
		x, y = generatePosition()
		for _, s_type in pairs(stations) do
			for _, station in pairs(s_type) do
					if math.abs(x - station.x) < 50 or math.abs(y - station.y) < 50 then
						return false
					end
			end
		end
		return true
	end

	valid = false
	while not valid do
		x, y = generatePosition()
		valid = checkPosition(x, y)
	end

	station_sprite = love.graphics.newImage("assets/droppoint_empty.png")
	return StationType.new(station_sprite, x, y, 1, math.random(-math.pi, math.pi), item_type)
end


----

FuelStation = {}
FuelStation.__index = FuelStation
setmetatable(FuelStation, DropPoint)

function FuelStation.new(sprite, x, y, scale, rot, type)
	instance = DropPoint.new(sprite, x, y, scale, rot, type)
	instance.readyTimerMax = 6
	setmetatable(instance, FuelStation)
	return instance
end

function FuelStation:draw()
	love.graphics.print(self.targetPoints - self.currentPoints, self.x, self.y - 20)
	self.readyBar:draw(1 - self.readyTimer / self.readyTimerMax)
	--self.patienceBar:draw(1 - self.patience / self.patienceMax)
	love.graphics.setColor(self.colour)
	love.graphics.draw(self.sprite, 
						self.x, -- love draws from the top left corner
						self.y, -- pos x is rightward, pos y is downward, with (0, 0) in the top left corner
						self.rot, self.scale, self.scale,
						self.ox, self.oy)
	love.graphics.setColor(1, 1, 1, 1)
end

function FuelStation:update(dt)
	if not self.ready then
		self.colour = {1, 1, 1, 1}
		self.readyTimer = self.readyTimer + dt
		if self.readyTimer >= self.readyTimerMax then
			self.ready = true
			self.readyTimer = 0
			self.colour = EntityTypes[self.type]
		end
	end
end

function FuelStation:refill()
	self.ready = false
end

----

Shipyard = {}
Shipyard.__index = Shipyard
setmetatable(Shipyard, DropPoint)

function Shipyard.new(sprite, x, y, scale, rot, type)
	instance = DropPoint.new(sprite, x, y, scale, rot, type)
	instance.readyTimerMax = 12
	setmetatable(instance, Shipyard)
	return instance
end

function Shipyard:draw()
	love.graphics.print(self.targetPoints - self.currentPoints, self.x, self.y - 20)
	self.readyBar:draw(1 - self.readyTimer / self.readyTimerMax)
	--self.patienceBar:draw(1 - self.patience / self.patienceMax)
	love.graphics.setColor(self.colour)
	love.graphics.draw(self.sprite, 
						self.x, -- love draws from the top left corner
						self.y, -- pos x is rightward, pos y is downward, with (0, 0) in the top left corner
						self.rot, self.scale, self.scale,
						self.ox, self.oy)
	love.graphics.setColor(1, 1, 1, 1)
end

function Shipyard:update(dt)
	if not self.ready then
		self.colour = {1, 1, 1, 1}
		self.readyTimer = self.readyTimer + dt
		if self.readyTimer >= self.readyTimerMax then
			self.ready = true
			self.readyTimer = 0
			self.colour = EntityTypes[self.type]
		end
	end
end

function Shipyard:refill()
	self.ready = false
end