require("player")

local player
local screenW
local screenH
local screenScale

function love.load()
	love.graphics.setDefaultFilter("nearest")
	screenW = love.graphics.getWidth() / 2
	screenH = love.graphics.getHeight() / 2
	screenScale = 1

	player_sprite_head = love.graphics.newImage("assets/player_head.png")
	player_sprite_body = love.graphics.newImage("assets/player_body.png")
	player = Player.new(player_sprite_head, player_sprite_body, 0, 0, 1)
end


function love.draw()
	love.graphics.push()

	love.graphics.scale(screenScale, screenScale)
	love.graphics.translate(screenW / screenScale, screenH / screenScale)
	love.graphics.rectangle("fill", 0, 0, 1, 1)
	player:draw()
	love.graphics.pop()
end


function love.update(dt)
	player:update(dt)
end

function love.keypressed(key, scancode, isrepeat)
	if love.keyboard.isDown("r") then
		love.load()
	end

	if love.keyboard.isDown("escape") then
		love.event.quit()
	end
	
end

function love.mousepressed(x, y, button, istouch, presses)

end

