Item = {}
Item.__index = Item

function Item.new(sprite, x, y, scale, rot)
	local instance = setmetatable({}, Item) 
	instance.x = x
	instance.y = y
	instance.rot = rot
	instance.sprite = sprite
	instance.w = sprite:getWidth() * scale
	instance.h = sprite:getHeight() * scale
	instance.scale = scale

	instance.ox = instance.w / 2
	instance.oy = instance.h / 2
	
	return instance
end

function Item:draw()
	love.graphics.draw(self.sprite, 
						self.x, -- love draws from the top left corner
						self.y, -- pos x is rightward, pos y is downward, with (0, 0) in the top left corner
						self.rot, self.scale, self.scale,
						self.ox, self.oy)
end

function Item:checkCollision(u, v, a, b)
	if (u + a / 2 >= (self.x - self.w / 2)) and 
		(u - a / 2 <= (self.x + self.w / 2)) and 
		(v + b / 2 >= (self.y - self.h / 2)) and 
		(v - b / 2 <= (self.y + self.h / 2)) then
		return true
	else
		return false
	end
end


----

function spawnItem(player_pos)
	if not player_pos then
		u, v = math.random(0, screenW * 2), math.random(0, screenH * 2)
		x, y = SCREEN_TRANSFORM:inverseTransformPoint(u, v)
	end
	
	player_sprite_body = love.graphics.newImage("assets/player_body.png")
	return Item.new(player_sprite_body, x, y, 1, 0)
end