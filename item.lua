Item = {}
Item.__index = Item

EntityTypes = {
	RED = {1, 0.7, 0.7, 1},
	GREEN = {0.7, 1, 0.7, 1},
	BLUE = {0.7, 0.7, 1, 1},
	EMPTY = {1, 1, 1, 0.7},
	FUEL = {1, 1, 0.7, 1}
}

function Item.new(sprite, x, y, scale, rot, type, points)
	local instance = setmetatable({}, Item)
	instance.x = x
	instance.y = y
	instance.rot = rot
	instance.sprite = sprite
	instance.w = sprite:getWidth() * scale
	instance.h = sprite:getHeight() * scale
	instance.scale = scale
	instance.type = type
	instance.colour = EntityTypes[instance.type]
	if not points then points = 1 end
	instance.points = points

	instance.ox = instance.w / 2
	instance.oy = instance.h / 2
	
	return instance
end

function Item:draw()
	love.graphics.setColor(self.colour)
	love.graphics.draw(self.sprite, 
						self.x, -- love draws from the top left corner
						self.y, -- pos x is rightward, pos y is downward, with (0, 0) in the top left corner
						self.rot, self.scale, self.scale,
						self.ox, self.oy)
	love.graphics.setColor(1, 1, 1, 1)
end

function Item:getBBox(mode)
	if mode == "circle" then
		return {self.x, self.y, math.max(self.w, self.h) / 2}
	end
	return {self.x - self.ox, self.y - self.oy, self.w, self.h}
end


function Item:checkCollision(bbox)
	return checkBBoxCollision2(bbox, self:getBBox(mode))
end

----

function getKeys(t, exclude)
	if not exclude then exclude = {} end
	keys = {}
	for k, v in pairs(t) do
		flag = true
		for i = 1, #exclude do
			if k == exclude[i] then
				flag = false
			end
		end
		if flag then
			table.insert(keys, k)
		end
	end
	return keys
end

function getRandomKey(t)
	keys = getKeys(t)
	return keys[math.random(#keys)]
end

function spawnItem(type, items, time)
	function generatePosition()
		border = 0.15
		u = math.random(0, screenW * (1-border) * 2) + screenW * border
		v = math.random(0, screenH * (1-border) * 2) + screenH * border
		x, y = SCREEN_TRANSFORM:inverseTransformPoint(u, v)
		return x, y
	end
	
	function checkPosition(x, y)
		x, y = generatePosition()
		for _, item in pairs(items) do
			if math.abs(x - item.x) < 10 or math.abs(y - item.y) < 10 then
				return false
			end
		end
		return true
	end

	valid = false
	while not valid do
		x, y = generatePosition()
		valid = checkPosition(x, y)
	end
	
	function chooseSize(time)
		size = 1
		if time > 30 and time < 60 then
			size = math.random(1, 2)
		elseif time > 60 and time < 120 then
			size = math.random(1, 3)
		else
			size = math.random(3, 6)
		end
	end
	
	size = chooseSize(time)
	scale = 1 + size * 0.2
	item_sprite = love.graphics.newImage("assets/pickup_blue.png")
	return Item.new(item_sprite, x, y, scale, math.random(-math.pi, math.pi), type, size)
end

function checkBBoxCollision(u, v, a, b, x, y, w, h)
	if (u + a / 2 >= (x - w / 2)) and 
		(u - a / 2 <= (x + w / 2)) and 
		(v + b / 2 >= (y - h / 2)) and 
		(v - b / 2 <= (y + h / 2)) then
		return true
	else
		return false
	end
end

function checkBBoxCollision2(bbox1, bbox2)
	u, v, a, b = unpack(bbox1)
	x, y, w, h = unpack(bbox2)
	if (u + a / 2 >= (x - w / 2)) and 
		(u - a / 2 <= (x + w / 2)) and 
		(v + b / 2 >= (y - h / 2)) and 
		(v - b / 2 <= (y + h / 2)) then
		return true
	else
		return false
	end
end

function checkBBoxCollisionCircle(bbox1, bbox2)
	u, v, r1 = unpack(bbox1)
	x, y, r2 = unpack(bbox2)
	dist = math.sqrt((x-u)^2 + (y-v)^2)
	if dist <= r1 + r2 then
		return true
	else
		return false
	end
end

function drawBBox(mode, bbox, colour)
	if colour then love.graphics.setColor(colour) end
	if mode == "circle" then
		love.graphics.circle("line", unpack(bbox))
	else
		love.graphics.rectangle("line", unpack(bbox))
	end
	love.graphics.setColor(1,1,1,1)
end
