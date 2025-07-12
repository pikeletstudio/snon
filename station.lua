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
	instance.colour = ItemTypes[instance.type]

	instance.ox = instance.w / 2
	instance.oy = instance.h / 2

	instance.pickup_radius = instance.w / 2 * 5
	instance.ready = true
	instance.readyTimer = 0
	instance.readyTimerMax = 2
	instance.patience = 0
	
	return instance
end

function DropPoint:draw()
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

function DropPoint:checkDesposit(bbox)
	return checkBBoxCollisionCircle(bbox, self:getDepositBBox(mode))
end

function DropPoint:deposit(cell)
	if not cell then print("dp"..self.type.." - nil cell") return false end
	if self.type ~= cell.type then return false end
	self.colour = {1, 1, 1, 1}
	self.ready = false
	return true
end

function DropPoint:update(dt)
	if not self.ready then
		self.readyTimer = self.readyTimer + dt
		if self.readyTimer >= self.readyTimerMax then
			self.ready = true
			self.readyTimer = 0
			self.readyTimerMax = 2
			self.colour = ItemTypes[self.type]
		end

	else
		self.patience = self.patience + dt
		if self.patience >= 5 then
			self:triggerFail()
		end
	end

end

function DropPoint:triggerFail()
	self.ready = false
	self.readyTimer
end

----

function spawnDropPoint(item_type)
	u, v = math.random(0, screenW * 2), math.random(0, screenH * 2)
	x, y = SCREEN_TRANSFORM:inverseTransformPoint(u, v)
	
	player_sprite_body = love.graphics.newImage("assets/droppoint_empty.png")
	return DropPoint.new(player_sprite_body, x, y, 1, math.random(-math.pi, math.pi), item_type)
end
