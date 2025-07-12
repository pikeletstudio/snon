require("player")
require("item")
require("station")


function love.load()
	s = 1
	N = 5
	for i = 1, N do
		n = (i - s) % 5
		if n == 0 then n = N end
		print(n)
	end

	math.randomseed(os.time())

	love.graphics.setDefaultFilter("nearest")
	screenW = love.graphics.getWidth() / 2
	screenH = love.graphics.getHeight() / 2
	screenScale = 2


	SCREEN_TRANSFORM = love.math.newTransform()
	SCREEN_TRANSFORM:scale(screenScale, screenScale)
	SCREEN_TRANSFORM:translate(screenW / screenScale, screenH / screenScale)

	SCORE = 0

	-- fixed update settings
	PAUSE = false
	fixed_tick = 0.01 -- seconds
	tick_accum = 0
	
	item_timer = 2 -- seconds
	item_accum = 0
	items = {}

	player_sprite_head = love.graphics.newImage("assets/player_head.png")
	player_sprite_body = love.graphics.newImage("assets/player_body_empty.png")
	player = Player.new(fixed_tick, player_sprite_head, player_sprite_body, 0, 0, 1)

	drop_points = {}
	for type = 1, 3 do
		table.insert(drop_points, spawnDropPoint(getKeys(ItemTypes, "EMPTY")[type]))
	end
end

function love.draw()
	love.graphics.print("SCORE: "..SCORE, 0, 0, 0)
	love.graphics.push()
	love.graphics.applyTransform(SCREEN_TRANSFORM)

	love.graphics.rectangle("fill", 0, 0, 1, 1)
	player:draw()
	for i, item in pairs(items) do item:draw() end -- drawBBox("circle", item:getBBox("circle")) end
	for i, dp in pairs(drop_points) do dp:draw() end -- drawBBox("circle", dp:getBBox("circle")) end


	love.graphics.pop()
end

function love.update(dt)
	if PAUSE then return end

	-- player fixed tick update
	tick_accum = tick_accum + dt
	if tick_accum >= fixed_tick then
		tick_accum = 0
		player:update(fixed_tick)
	end

	-- spawning items
	item_accum = item_accum + dt
	if item_accum >= item_timer then
		item_accum = 0
		table.insert(items, spawnItem())
	end

	-- player collision with items
	for i, item in pairs(items) do 
		if item:checkCollision(player:getBBox()) then
			-- player:grow(1)
			collected = player:collect(item.type)
			if collected then table.remove(items, i) end

		end
	end

	-- player collision with drop point pickup radius
	for i, dp in pairs(drop_points) do 
		if dp.ready and dp:checkDesposit(player:getBBox("circle")) then
			seg = player:getFirstFilled()
			if dp:deposit() then
				SCORE = SCORE + 1
				print("here")
				player:emptySegment(seg)
				player.last_filled = player.last_filled - 1
				player:cycleCells(1)
				-- player:grow(1)
			end
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
