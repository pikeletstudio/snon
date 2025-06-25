
Player = {}
Player.__index = Player


function Player.new(head_sprite, body_sprite, x, y, scale)
	local instance = setmetatable({}, Player) 
	instance.x = x
	instance.y = y
	instance.vx = 0
	instance.vy = 0
	instance.rot = 0
	instance.scale = scale
	instance.speed = 5

	instance.segments = {Segment.new(head_sprite, x, y, scale)}
	instance.body_sprite = body_sprite
	instance:grow(100)

	return instance
end

function Player:grow(num_segments)
	for n = 0, num_segments do
		table.insert(self.segments, Segment.new(self.body_sprite, x, y, self.scale))
	end
end


function Player:draw()
	love.graphics.print("player coords: "..string.format("%.1f",self.x).."/"..string.format("%.1f",self.y), -180, -100, 0, 0.5, 0.5)
	love.graphics.print("player rot: "..string.format("%.1f",self.rot), -180, -80, 0, 0.5, 0.5)
	for n, seg in pairs(self.segments) do
		-- offset origin to be the front centre
		seg.ox = seg.w
		seg.oy = seg.h / 2
		
		if n == 1 then
			-- start with the head
			prev_x = self.x
			prev_y = self.y
			prev_rot = self.rot
			seg.x = prev_x
			seg.y = prev_y
			seg.rot = prev_rot

		else
			-- draw body segments
			-- x -------------
			if not seg.x then
				seg.x = prev_x
			else
				seg.x = seg.x + (prev_x - seg.x) * 0.01
			end
			-- y -------------
			if not seg.y then
				seg.y = prev_y
			else
				seg.y = seg.y + (prev_y - seg.y) * 0.01
			end

			-- rotation ------
			-- find the two possible angles:
			ang_theta = (prev_rot - seg.rot)
			ang_phi = (seg.rot - prev_rot)
			-- pick the smaller one, and ensure sign is maintained:
			ang = math.min(math.abs(ang_a), math.abs(ang_b))
			ang_sign = 

			-- if ang_a < ang_b then ang = -ang_a else ang = ang_b end
			-- seg.rot = seg.rot + ang * 0.05
			seg.rot = seg.rot + math.atan2(math.sin(prev_rot - seg.rot), math.cos(seg.rot - prev_rot)) * 0.05
			-- seg.rot = seg.rot + (math.pi - math.abs(math.abs(prev_rot - seg.rot) - math.pi)) * 0.05

		end


		seg:draw()
		-- pass on the params to the next segment
		prev_x = prev_x - seg.w * math.cos(seg.rot)
		prev_y = prev_y - seg.h * math.sin(seg.rot)
		prev_rot = seg.rot
	end
end


function Player:update(dt)

	if love.keyboard.isDown("a") then
		self:move(dt, -self.speed, 0)
	end

	if love.keyboard.isDown("d") then
		self:move(dt, self.speed, 0)
	end

	if love.keyboard.isDown("w") then
		self:move(dt, 0, -self.speed)
	end

	if love.keyboard.isDown("s") then
		self:move(dt, 0, self.speed)
	end

	if love.keyboard.isDown("space") then
		self.vx, self.vy = 0, 0
	end

	local px = self.x
	local py = self.y
	self.x = self.x + self.vx
	self.y = self.y + self.vy
	self.rot = self.rot + (math.atan2((self.y - py), (self.x - px)) - self.rot) * 0.9

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
						self.x, -- love draws from the top left corner
						self.y, -- pos x is rightward, pos y is downward, with (0, 0) in the top left corner
						self.rot, self.scale, self.scale,
						self.ox, self.oy)
end