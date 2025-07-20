
ProgressBar = {}
ProgressBar.__index = ProgressBar

function ProgressBar.new(x, y, w, h, ox, oy, mode, colour)
	local instance = setmetatable({}, ProgressBar)
	if mode == nil then mode = "vertical" end
	instance.mode = mode
	instance.x = x
	instance.y = y
	instance.w = w
	instance.h = h
	instance.ox = ox
	instance.oy = oy
	if not colour then colour = {1, 1, 1, 1} end
	instance.colour = colour
	return instance
end

function ProgressBar:draw(progress, x, y)
	if not x then self.x = x end
	if not y then self.y = y end
	love.graphics.setColor(self.colour)
	love.graphics.rectangle("line", self.x + self.ox, self.y + self.oy, self.w, self.h)
	if self.mode == "vertical" then
		love.graphics.rectangle("fill", self.x + self.ox, self.y + self.oy, self.w, self.h*progress)
	else
		love.graphics.rectangle("fill", self.x + self.ox, self.y + self.oy, self.w*progress, self.h)
	end
	love.graphics.setColor(1, 1, 1, 1)
end

function drawEndScreen()
	spx, spy = 0.1, 0.2
	love.graphics.rectangle("fill", screenW*spx, screenH*spy, screenW*(1-spx)*2, screenH*(1-spy)*2)
	love.graphics.setColor(0, 0, 0, 1)
	love.graphics.print("Score: "..SCORE, screenW*spx*2, screenH*spy*2, 0, 5)
	love.graphics.setColor(1, 1, 1, 1)
end

