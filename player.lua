
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

	instance.segments = {TransportCell.new(head_sprite, x, y, scale)}
	instance.body_sprite = body_sprite
	instance.length = #instance.segments
	instance.spacing = 15

	instance.base_speed = 700
	instance.moving = true

	return instance
end

function Player:getSpeed()
	return math.min(self.base_speed + 3 * self.length, self.base_speed * 1.4)
end

function Player:getTurnSpeed()
	return self:getSpeed() * 0.05
end

function Player:getBBox(mode)
	return self.segments[1]:getBBox(mode)
end

function Player:checkBounds(x, y)
	maxX, maxY = SCREEN_TRANSFORM:inverseTransformPoint(screenW * 2, screenH * 2)
	minX, minY = SCREEN_TRANSFORM:inverseTransformPoint(0, 0)
	boundedX = math.max(math.min(x, maxX), minX)
	boundedY = math.max(math.min(y, maxY), minY)
	return boundedX, boundedY
end

function Player:grow(length)
	self.length = self.length + length
	self.accum_time = 0
end

function Player:addBodySegments(num_segments)
	-- count from current length
	for n = #self.segments + 1, #self.segments + num_segments do
		prev = self.segments[n - 1]
		x = prev.x - prev.w
		y = prev.y
		prev:clearPath(self.spacing)
		table.insert(self.segments, TransportCell.new(self.body_sprite, x, y, self.scale))
	end
end

function Player:draw()
	for n, seg in pairs(self.segments) do
		seg:draw()
		-- drawBBox("circle", {seg:getBBox("circle")})
	end
end

function Player:update(dt)
	local px = self.x
	local py = self.y

	self:takeInput(dt)

	self:move(dt)

	if self.moving then
		self:updateBodyPath()
	end
	if not (#self.segments >= self.length) then
		self:addBodySegments(1)
	end
end

function Player:takeInput(dt)
	if love.keyboard.isDown("a") then
		self:turn(dt, -1)
	end

	if love.keyboard.isDown("d") then
		self:turn(dt, 1)
	end

	if love.keyboard.isDown("w") then
		self.segments[1]:test()
	end

	if love.keyboard.isDown("lshift") then
		self.base_speed = 700 * 1.4
	elseif love.keyboard.isDown("space") then
		self.base_speed = 700 * 0.65
	else
		self.base_speed = 700
	end
end

function Player:turn(dt, dir)
	self.rot = self.rot + self:getTurnSpeed() * dt * dir
end

function Player:move(dt)
	self.vx = self:getSpeed() * math.cos(self.rot) * dt
	self.vy = self:getSpeed() * math.sin(self.rot) * dt
	self.x, self.y = self:checkBounds(self.x + self.vx, self.y + self.vy)
end

function Player:updateBodyPath(dt)
	-- update head first
	self.segments[1]:update(self.x, self.y, self.rot)

	-- pass path along body
	for s = 2, #self.segments do
		seg = self.segments[s]
		prev_seg = self.segments[s - 1]
		prev_step = table.remove(prev_seg.path, 1)
		seg:update(prev_step.x, prev_step.y, prev_step.rot)

		-- eat the tail if touched by the head
		-- update collision function to account for rotation
		-- if s > 2 and checkBBoxCollision2(seg:getBBox(), self:getBBox()) then
		if s > 2 and checkBBoxCollisionCircle(seg:getBBox("circle"), self:getBBox("circle")) then
			new_segs = {}
			for n = 1, s - 1 do
				table.insert(new_segs, self.segments[n])
			end
			self.segments = new_segs
			self.length = #self.segments
			break
		end

	end

end

function Player:updateBodyDirect()
	for n, seg in pairs(self.segments) do
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
			body_speed = 1
			-- x -------------
			if not seg.x then
				seg.x = prev_x
			else
				seg.x = seg.x + (prev_x - seg.x) * body_speed
			end
			-- y -------------
			if not seg.y then
				seg.y = prev_y
			else
				seg.y = seg.y + (prev_y - seg.y) * body_speed
			end

			-- rotation ------
			-- find the two possible angles and ensure sign is maintained:
			ang_theta = (prev_rot - seg.rot) % (2 * math.pi)
			sign = (ang_theta >=0 and 1 or 0) * 2 - 1
			ang_phi = (2 * math.pi - math.abs(ang_theta)) * sign * -1
			-- pick the smaller one:
			if math.abs(ang_theta) < math.abs(ang_phi) then ang = ang_theta else ang = ang_phi end
			seg.rot = seg.rot + ang * 0.05
			-- seg.rot = seg.rot + math.atan2(math.sin(prev_rot - seg.rot), math.cos(seg.rot - prev_rot)) * 0.05

		end
		
		-- pass on the params to the next segment
		prev_x = prev_x - seg.w * math.cos(seg.rot)
		prev_y = prev_y - seg.h * math.sin(seg.rot)
		prev_rot = seg.rot
	end
end


---------------------


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

	instance.ox = instance.w / 2
	instance.oy = instance.h / 2

	instance.vx = 0
	instance.vy = 0
	instance.rot = 0

	instance.path = {}

	return instance
end

function Segment:getBBox(mode)
	if mode == "circle" then
		return {self.x, self.y, math.max(self.w, self.h) / 2}
	end
	return {self.x - self.ox, self.y - self.oy, self.w, self.h}
end

function Segment:draw()
	love.graphics.draw(self.sprite, 
						self.x, -- love draws from the top left corner
						self.y, -- pos x is rightward, pos y is downward, with (0, 0) in the top left corner
						self.rot, self.scale, self.scale,
						self.ox, self.oy)
end

function Segment:update(x, y, rot)
	-- save current position to path
	table.insert(self.path, PathNode.new(self.x, self.y, self.rot))
	
	self.x = x
	self.y = y
	self.rot = rot
end

function Segment:clearPath(keep)
	keep = math.min(math.ceil(keep), #self.path)
	-- clear current path
	new_path = {}
	for n = #self.path - keep, #self.path do
		table.insert(new_path, self.path[n])
	end
	self.path = new_path
	-- save current position to path
	table.insert(self.path, PathNode.new(self.x, self.y, self.rot))
end


---------------------


TransportCell = {}
TransportCell.__index = TransportCell
setmetatable(TransportCell, Segment)

function TransportCell.new(sprite, x, y, scale)
	local instance = Segment.new(sprite, x, y, scale)
	setmetatable(instance, TransportCell)
	return instance
end

function TransportCell:test()
	print("worked")
end


---------------------


PathNode = {}
PathNode.__index = PathNode

function PathNode.new(x, y, r)
	local instance = setmetatable({}, PathNode) 
	instance.x = x
	instance.y = y
	instance.rot = r
	return instance
end