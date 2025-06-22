
Player = {}
Player.__index = Player


function Player.new(sprite, x, y, scale)
	local instance = setmetatable({}, Player) 
	instance.sprite = sprite
	instance.x = x
	instance.y = y
	instance.w = sprite:getWidth() * scale
	instance.h = sprite:getHeight() * scale
	instance.scale = scale

	instance.vx = 0
	instance.vy = 0
	instance.rot = 0

	return instance
end


function Player:draw()
	love.graphics.draw(self.sprite, 
						self.x - self.w / 2, -- love draws from the top left corner
						self.y - self.h / 2, -- pos x is rightward, pos y is downward, with (0, 0) in the top left corner
						self.rot, self.scale, self.scale,
						self.w / 2, self.h / 2)
end


function Player:update(dt)

	if love.keyboard.isDown("a") then
		self:move(dt, -1, 0)
	end

	if love.keyboard.isDown("d") then
		self:move(dt, 1, 0)
	end

	if love.keyboard.isDown("w") then
		self:move(dt, 0, -1)
	end

	if love.keyboard.isDown("s") then
		self:move(dt, 0, 1)
	end

	local px = self.x
	local py = self.y
	self.x = self.x + self.vx
	self.y = self.y + self.vy
	self.rot = math.atan2((self.y - py), (self.x - px))

end

function Player:move(dt, dx, dy)
	self.vx = self.vx + dx * dt
	self.vy = self.vy + dy * dt
end