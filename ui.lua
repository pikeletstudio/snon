






ProgressBar = {}
ProgressBar.__index = ProgressBar

function ProgressBar.new(mode, x, y, w, h)
	local instance = setmetatable({}, ProgressBar)
	if not mode then mode = "vertical" end
	instance.mode = mode
	instance.x = x
	instance.y = y
	instance.w = w
	instance.h = h
	return instance
end

function ProgressBar:draw(progress)
	love.graphics.rectangle("line", self.x, self.y, self.w, self.h)
	if mode == "vertical" then
		love.graphics.rectangle("fill", self.x, self.y, self.w, self.h*progress)
	
	
end