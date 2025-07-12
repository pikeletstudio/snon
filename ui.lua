






ProgressBar = {}
ProgressBar.__index = ProgressBar

function ProgressBar.new(x, y, w, h)
	instance = setmetatable({}, ProgressBar)
	instance.x = x
	instance.y = y
	instance.w = w
	instance.h = h
	return instance

function ProgressBar:draw(progress)
	love.graphics.rectangle("line", x, y, w, h)
	love.graphics.rectangle("fill", x, y, w, h*progress)
	
	
end