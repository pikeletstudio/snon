
ProgressBar = {}
ProgressBar.__index = ProgressBar

function ProgressBar.new(x, y, w, h, ox, oy, colour, mode, flipped)
	local instance = setmetatable({}, ProgressBar)
	instance.x = x
	instance.y = y
	instance.w = w
	instance.h = h
	instance.ox = ox
	instance.oy = oy
	if not colour then colour = {1, 1, 1, 1} end
	instance.colour = colour
	if mode == nil then mode = "vertical" end
	instance.mode = mode
	instance.flipped = flipped
	return instance
end

function ProgressBar:draw(progress, x, y)
	-- update position
	if x then self.x = x end
	if y then self.y = y end

	love.graphics.setColor(self.colour)
	-- draw outline
	love.graphics.rectangle("line", self.x + self.ox, self.y + self.oy, self.w, self.h)
	
	x, y = self.x + self.ox, self.y + self.oy
	width, height = self.w * progress, self.h

	if self.flipped then f = 1 else f = 0 end
	flip_offset = self.w * (1 - progress) * f

	if self.mode == "vertical" then
		height = self.h * progress
		width = self.w
		flip_offset = self.h * (1 - progress) * f
		y = y + flip_offset
	else
		x = x + flip_offset
	end

	-- draw inner bar
	love.graphics.rectangle("fill", x, y, width, height)
	love.graphics.setColor(1, 1, 1, 1)
end

function drawEndScreen(game_over_sprite)
	spx, spy = 0, 0
	love.graphics.setColor(0, 0, 0, 0.8)
	love.graphics.rectangle("fill", screenW*spx, screenH*spy, screenW*(1-spx)*2, screenH*(1-spy)*2)
	love.graphics.setColor(1, 1, 1, 1)
	scale = 4
	love.graphics.draw(game_over_sprite, screenW - game_over_sprite:getWidth() / 2 * scale, screenH - game_over_sprite:getHeight() / 2 * scale, 0, scale)
end

