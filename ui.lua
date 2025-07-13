






ProgressBar = {}
ProgressBar.__index = ProgressBar

function ProgressBar.new(x, y, w, h, mode)
	local instance = setmetatable({}, ProgressBar)
	if mode == nil then mode = "vertical" end
	instance.mode = mode
	print(mode)
	instance.x = x
	instance.y = y
	instance.w = w
	instance.h = h
	return instance
end

function ProgressBar:draw(progress)
	love.graphics.rectangle("line", self.x, self.y, self.w, self.h)
	if self.mode == "vertical" then
		love.graphics.rectangle("fill", self.x, self.y, self.w, self.h*progress)
	else
		love.graphics.rectangle("fill", self.x, self.y, self.w*progress, self.h)
	end
end

function drawEndScreen()
	spx, spy = 0.1, 0.2
	love.graphics.rectangle("fill", screenW*spx, screenH*spy, screenW*(1-spx)*2, screenH*(1-spy)*2)
	love.graphics.print("Score: "..SCORE, screenW*spx*2, screenH*spy*2)
end

