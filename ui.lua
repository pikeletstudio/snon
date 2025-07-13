






ProgressBar = {}
ProgressBar.__index = ProgressBar

function ProgressBar.new(x, y, w, h, r)
	local instance = setmetatable({}, ProgressBar)
	instance.x = x
	instance.y = y
	instance.w = w
	instance.h = h
	return instance
end

function ProgressBar:draw(progress)
	love.graphics.rectangle("line", self.x, self.y, self.w, self.h, r)
	love.graphics.rectangle("fill", self.x, self.y, self.w, self.h*progress, r)
	
	
end