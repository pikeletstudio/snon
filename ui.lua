






ProgressBar = {}
ProgressBar.__index = ProgressBar

function ProgressBar.new(x, y, w, h)
	instance = setmetatable({}, ProgressBar)
	instance.x = x
	instance.y = y
	instance.w = w
	instance.h = h
	return instance

function draw