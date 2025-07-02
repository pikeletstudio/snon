require("player")
require("item")


function love.load()
	love.graphics.setDefaultFilter("nearest")
	screenW = love.graphics.getWidth() / 2
	screenH = love.graphics.getHeight() / 2
	screenScale = 2

	player_sprite_head = love.graphics.newImage("assets/player_head.png")
	player_sprite_body = love.graphics.newImage("assets/player_body_empty.png")
	player = Player.new(player_sprite_head, player_sprite_body, 0, 0, 1)

	SCREEN_TRANSFORM = love.math.newTransform()
	SCREEN_TRANSFORM:scale(screenScale, screenScale)
	SCREEN_TRANSFORM:translate(screenW / screenScale, screenH / screenScale)

	-- fixed update settings
	PAUSE = false
	fixed_tick = 0.001 -- seconds
	tick_accum = 0
	item_timer = 2 -- seconds
	item_accum = 0
	items = {}
end

function love.draw()
	love.graphics.print("SCORE: "..player.length, 0, 0, 0)
	love.graphics.push()
	love.graphics.applyTransform(SCREEN_TRANSFORM)

	love.graphics.rectangle("fill", 0, 0, 1, 1)
	player:draw()
	for i, item in pairs(items) do item:draw() end -- drawBBox("circle", item:getBBox("circle")) end


	love.graphics.pop()
end

function love.update(dt)
	if PAUSE then return end
	tick_accum = tick_accum + dt
	if tick_accum >= fixed_tick then
		tick_accum = 0
		player:update(fixed_tick)
	end

	item_accum = item_accum + dt
	if item_accum >= item_timer then
		item_accum = 0
		table.insert(items, spawnItem())
	end

	for i, item in pairs(items) do 
		if item:checkCollision(player:getBBox()) then
			table.remove(items, i)
			player:grow(1)
		end
	end

	new_scale = 2 - math.min(1.75, player.length / 200)
	updateTransform(new_scale)
end

function love.keypressed(key, scancode, isrepeat)
	if love.keyboard.isDown("r") then
		love.load()
	end

	if love.keyboard.isDown("escape") then
		love.event.quit()
	end

	if love.keyboard.isDown("p") then
		PAUSE = not PAUSE
	end
		
	if key == "s" then
		player:grow(1)
	end
end

function love.mousepressed(x, y, button, istouch, presses)

end

function updateTransform(scale)
	SCREEN_TRANSFORM = love.math.newTransform()
	SCREEN_TRANSFORM:scale(scale, scale)
	SCREEN_TRANSFORM:translate(screenW / scale, screenH / scale)
end
