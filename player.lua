require("spritestack")

Player = {}
Player.__index = Player


function Player.new(fixed_tick, texture_atlas, sprite_batch, x, y, scale)
	local instance = setmetatable({}, Player)
	instance.x = x
	instance.y = y
	instance.vx = 0
	instance.vy = 0
	instance.rot = 0
	instance.scale = scale
	
	instance.texture_atlas = texture_atlas
	instance.sprite_batch = sprite_batch
	
	head = Segment.new(texture_atlas, sprite_batch, x, y, scale)
	head.sprite_stack = Segment.createSpriteStack(texture_atlas, sprite_batch, "head", instance.x, instance.y, scale)
	instance.segments = {head}
	instance.length = #instance.segments
	instance.last_filled = 1
	instance.spacing = 7
	instance.fixed_tick = fixed_tick

	instance.base_speed = 1.5 / fixed_tick
	instance.speed_mod = 0
	instance.moving = true
	instance.boost = false
	instance.brake = false
	
	instance.fuelMax = 30
	instance.fuel = instance.fuelMax

	return instance
end

function Player:getSpeed()
	return math.min(self.base_speed + 3 * self.length + self.speed_mod, self.base_speed * 1.4 + self.speed_mod)
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
	--if boundedX == maxX then boundedX = minX end
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
		table.insert(self.segments, TransportCell.new(self.texture_atlas, self.sprite_batch, x, y, self.scale))
	end
end

function Player:fillSegment(seg, item_type)
	seg.type = item_type
end

function Player:emptySegment(seg)
	Player:fillSegment(seg, "EMPTY")
end

function Player:collect(item)
	-- if no empty cells, return
	if #self.segments <= self.last_filled then return false end
	for i = 1, item.points do
		self.last_filled = self.last_filled + 1
		self:fillSegment(self.segments[self.last_filled], item.type)
		if #self.segments <= self.last_filled then break end
	end
	return true
end

function Player:getFirstFilled()
	if self.last_filled > 1 then
		return self.segments[2]
	end
	return nil -- just to be clear
end

function Player:cycleCells(steps)
	t_cells = {}
	for n, cell in pairs(self.segments) do
		if cell.__index == TransportCell then
			table.insert(t_cells, {n, cell.type})
		end
	end

	for i = 1, #t_cells do
		cell = self.segments[t_cells[i][1]]
		new_pos = (i - steps) % #t_cells
		if new_pos == 0 then new_pos = #t_cells end
		new_type = t_cells[new_pos][2]
		cell.type = new_type
	end
end

function Player:draw()
	for s = #self.segments, 1, -1 do
		-- self.segments[s]:draw()
		self.segments[s]:draw_stack()
		-- drawBBox("circle", seg:getBBox("circle"))
	end
end

function Player:update(dt)
	if self.boost or self.brake then using_move_action = 1 else using_move_action = 0 end
	fuel_use_mod = 1
	self.fuel = self.fuel - dt * (1 + fuel_use_mod * using_move_action)

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

	-- if love.keyboard.isDown("w") then
	-- 	self.segments[1]:test()
	-- end

	if love.keyboard.isDown("lshift") then
		self.speed_mod = self.base_speed * 0.4
		self.boost = true
	elseif love.keyboard.isDown("space") then
		self.speed_mod = - self.base_speed * 0.35
		self.brake = true
	else
		self.speed_mod = 0
		self.boost = false
		self.brake = false
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

	self.last_filled = math.min(self.last_filled, #self.segments)

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


function Segment.new(texture_atlas, sprite_batch, x, y, scale)
	local instance = setmetatable({}, Segment) 
	instance.sprite = sprite
	instance.x = x
	instance.y = y
	instance.scale = scale
	instance.type = "EMPTY"
	instance.colour = EntityTypes[instance.type]

	instance.vx = 0
	instance.vy = 0
	instance.rot = 0

	instance.path = {}

	instance.sprite_stack = Segment.createSpriteStack(texture_atlas, sprite_batch, "body", instance.x, instance.y, scale)

	instance.w = instance.sprite_stack:getWidth() * scale
	instance.h = instance.sprite_stack:getHeight() * scale

	instance.ox = instance.w / 2
	instance.oy = instance.h / 2

	instance.sprite_stack_item = Segment.createSpriteStack(texture_atlas, BATCH2, "item", instance.x, instance.y, scale, modulate)

	return instance
end

function Segment.createSpriteStack(texture_atlas, sprite_batch, body_or_item, x, y, scale)
	local sprite_stack = SpriteStack.new(0.1, scale, 0.6, scale)
	if body_or_item == "body" then
		sprite_stack:load_from_atlas(texture_atlas, 0, 0, 16, 10, 1, 6, sprite_batch)
	elseif body_or_item == "head" then
		sprite_stack:load_from_atlas(texture_atlas, 0, 16, 16, 10, 1, 6, sprite_batch)
	else
		sprite_stack:load_from_atlas(texture_atlas, 0, 10 + 1, 12, 4, 1, 6, sprite_batch)
	end
	sprite_stack:set_position(x, y)
	return sprite_stack
end

function Segment:getBBox(mode)
	if mode == "circle" then
		return {self.x, self.y, math.max(self.w, self.h) / 2}
	end
	return {self.x - self.ox, self.y - self.oy, self.w, self.h}
end

function Segment:draw()
	love.graphics.setColor(self.colour)
	love.graphics.draw(self.sprite, 
						self.x, -- love draws from the top left corner
						self.y, -- pos x is rightward, pos y is downward, with (0, 0) in the top left corner
						self.rot, self.scale, self.scale,
						self.ox, self.oy)
	love.graphics.setColor(1, 1, 1, 1)
end

function Segment:draw_stack()
	self.sprite_stack.x = self.x
	self.sprite_stack.y = self.y
	self.sprite_stack.rotation = self.rot
	self.sprite_stack:add_to_batch()
	if self.type == "EMPTY" then return end
	self.sprite_stack_item.x = self.x
	self.sprite_stack_item.y = self.y
	self.sprite_stack_item.rotation = self.rot
	self.sprite_stack_item:add_to_batch()
end

function Segment:update(x, y, rot)
	self.colour = EntityTypes[self.type]
	-- save current position to path
	table.insert(self.path, PathNode.new(self.x, self.y, self.rot))
	
	self.x = x
	self.y = y
	self.rot = rot
	screenW = love.graphics.getWidth() / 2
	screenH = love.graphics.getHeight() / 2
	px = 1 / ((self.x) / math.abs(self.x) * ((self.x  / screenW)^2 + 1) + (self.x == 0 and 1 or 0) )
	py = 1 / ((self.y) / math.abs(self.y) * ((self.y  / screenH)^2 + 1) + (self.y == 0 and 1 or 0) )
	
	px = 1 - math.abs( math.sin( math.atan( self.x / screenW) ) )
	py = 1 - math.abs( math.sin( math.atan( self.y / screenH) ) )

	if px ~= px then px = 1 end
	if py ~= py then py = 1 end
	print(py)
	self.sprite_stack:set_perspective(px, py)
	-- self.sprite_stack:set_perspective(-self.x / screenW * 6, -self.y / screenH * 6)
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

function TransportCell.new(texture_atlas, sprite_batch, x, y, scale)
	local instance = Segment.new(texture_atlas, sprite_batch, x, y, scale)
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