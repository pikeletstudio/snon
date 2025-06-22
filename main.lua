require("player")

local player
local screenW
local screenH
local screenScale

function love.load()
	love.graphics.setDefaultFilter("nearest")
	screenW = love.graphics.getWidth() / 2
	screenH = love.graphics.getHeight() / 2
	screenScale = 2

	player_sprite_head = love.graphics.newImage("assets/player_head.png")
	player = Player.new(player_sprite_head, 0, 0, 1)
end


function love.draw()
	love.graphics.push()

	love.graphics.scale(screenScale, screenScale)
	love.graphics.translate(screenW / screenScale, screenH / screenScale)
	love.graphics.rectangle("fill", 0, 0, 50, 50)
	player:draw()
	love.graphics.pop()
end


function love.update(dt)
	player:update(dt)
end

function love.keypressed(key, scancode, isrepeat)

end

function love.mousepressed(x, y, button, istouch, presses)

end

