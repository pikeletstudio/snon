
Player = {}
Player.__index = Player


function Player.new(head_sprite, body_sprite, x, y, scale)
	local instance = setmetatable({}, Player) 
	instance.x = x
	instance.y = y
	instance.vx = 0
	instance.vy = 0
	instance.rot = 0

	instance.segments = {Segment.new(head_sprite, x, y, scale), Segment.new(body_sprite, x, y, scale)}

	return instance
end


function Player:draw()
	-- print(rot)
	x, y, rot, oy, ox = self.x, self.y, self.rot, 0, 0
	for n, seg in pairs(self.segments) do
		if n > 0 then
			ox = seg.w/2
		end
		seg:draw(x, y, rot, oy, ox)
		x = x - seg.w / 2
		y = y
		rot = rot
	end
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
	-- self.rot = self.rot + 0.05
end

function Player:move(dt, dx, dy)
	self.vx = self.vx + dx * dt
	self.vy = self.vy + dy * dt
end


Segment = {}
Segment.__index = Segment


function Segment.new(sprite, x, y, scale)
	local instance = setmetatable({}, Segment) 
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


function Segment:draw(x, y, rot, ox, oy)
	love.graphics.draw(self.sprite, 
						x, -- love draws from the top left corner
						y, -- pos x is rightward, pos y is downward, with (0, 0) in the top left corner
						rot, self.scale, self.scale,
						ox, oy)
end