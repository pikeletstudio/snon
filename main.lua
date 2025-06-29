require("player")

local player
local screenW
local screenH
SCREEN_TRANSFORM = love.math.newTransform()

function love.load()
	love.graphics.setDefaultFilter("nearest")
	screenW = love.graphics.getWidth() / 2
	screenH = love.graphics.getHeight() / 2
	screenScale = 1

	player_sprite_head = love.graphics.newImage("assets/player_head.png")
	player_sprite_body = love.graphics.newImage("assets/player_body.png")
	player = Player.new(player_sprite_head, player_sprite_body, 0, 0, 1)

	
	SCREEN_TRANSFORM:scale(screenScale, screenScale)
	SCREEN_TRANSFORM:translate(screenW / screenScale, screenH / screenScale)

end


function love.draw()
	love.graphics.push()

	love.graphics.applyTransform(SCREEN_TRANSFORM)
	love.graphics.rectangle("fill", 0, 0, 1, 1)

	target_x, target_y = SCREEN_TRANSFORM:inverseTransformPoint(love.mouse.getX(), love.mouse.getY())
	love.graphics.print("mouse screen coords: "..string.format("%.1f",love.mouse.getX()).."/"..string.format("%.1f",love.mouse.getY()), -200, -160)
	love.graphics.print("mouse world coords: "..string.format("%.1f",target_x).."/"..string.format("%.1f",target_y), -200, -130)
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

