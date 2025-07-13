Item = {}
Item.__index = Item

EntityTypes = {
	RED = {1, 0.7, 0.7, 1},
	GREEN = {0.7, 1, 0.7, 1},
	BLUE = {0.7, 0.7, 1, 1},
	EMPTY = {1, 1, 1, 1},
	FUEL = {1, 1, 0.8, 1}
}

function Item.new(sprite, x, y, scale, rot, type)
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

function spawnItem(player_pos, type)
	if not player_pos then
		u, v = math.random(0, screenW * 2), math.random(0, screenH * 2)
		x, y = SCREEN_TRANSFORM:inverseTransformPoint(u, v)
	end
	
	item_sprite = love.graphics.newImage("assets/pickup_blue.png")
	return Item.new(item_sprite, x, y, 1, math.random(-math.pi, math.pi), type)
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
