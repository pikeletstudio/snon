require("utils")
require("item")
require("station")
require("ui")
require("player")

function love.load()

	math.randomseed(os.time())
	love.graphics.setBackgroundColor(0, 0, 0, 1)
	love.graphics.setDefaultFilter("nearest")
	love.graphics.setNewFont(10, "normal", 4)

	screenW = love.graphics.getWidth() / 2
	screenH = love.graphics.getHeight() / 2
	screenScale = 2

	shader_glow = love.graphics.newShader("shader_glow.fs")
	shader_crt = love.graphics.newShader("shader_crt.fs")
	shader_vars = {} --{screenDims = {screenW, screenH}}

	canvas = love.graphics.newCanvas()
	canvas2 = love.graphics.newCanvas()

	SCREEN_TRANSFORM = love.math.newTransform()
	SCREEN_TRANSFORM:scale(screenScale, screenScale)
	SCREEN_TRANSFORM:translate(screenW / screenScale, screenH / screenScale)

	SCORE = 0
	CREDITS = 0
	GAMEOVER = false
	TIME = 0

	score_text_x = 35
	score_text_y = 45
	credits_text_x = score_text_x
	credits_text_y = score_text_y + 20
	score_sprite = love.graphics.newImage("assets/score_text.png")
	credits_sprite = love.graphics.newImage("assets/credits_text.png")
	game_over_sprite = love.graphics.newImage("assets/game_over_text.png")

	-- fixed update settings
	PAUSE = false
	fixed_tick = 0.015 -- seconds
	tick_accum = 0
	
	item_timer = 2 -- seconds
	item_accum = 0
	items = {}

	ignore_types = {"EMPTY", "FUEL"}
	ItemTypes = {}
	item_type_keys = getKeys(EntityTypes, ignore_types)
	for k = 1, #item_type_keys do
		type = item_type_keys[k]
		ItemTypes[type] = EntityTypes[type]
	end

	ATLAS = love.graphics.newImage("assets/spritestacks/texture_atlas.png")
	BATCH = LayeredSpriteBatch.new(ATLAS)
	BATCH2 = LayeredSpriteBatch.new(ATLAS)

	-- player_sprite_head = love.graphics.newImage("assets/player_head.png")
	-- player_sprite_body = love.graphics.newImage("assets/player_body_empty.png")
	player = Player.new(fixed_tick, ATLAS, BATCH, 0, 0, 1)
	player_grow_first = true
	
	pfb_pos = 0.05 -- % of screen width in from left side
	player_fuel_bar = ProgressBar.new(screenW * pfb_pos, 20, screenW * (1-pfb_pos) * 2, 15, 
										0, 0, EntityTypes.FUEL, "horizontal")
	
	drop_points = {}
	fuel_stations = {}
	shipyards = {}
	stations = {drop_points, fuel_stations, shipyards}
	loadStations()
	
end

function love.draw()
	-- set draw target to canvas
	love.graphics.setCanvas(canvas)
	-- set background colour
	love.graphics.clear(0.15, 0.05, 0.15, 1)
	-- apply screen transform
	love.graphics.push()
	love.graphics.applyTransform(SCREEN_TRANSFORM)

	-- draw to canvas
	drawStations()
	player:draw()
	for layer = 1, #BATCH.quads_by_layer do
		BATCH:draw_layer(layer)
		-- love.graphics.setColor(1,1,1,0.5)
		BATCH2:draw_layer(layer)
		love.graphics.setColor(1,1,1,1)
	end
	
	-- stop applying screen transform
	love.graphics.pop()
	-- draw UI outside of screen transform
	drawUI()
	-- set new canvas for glow shader
	love.graphics.setCanvas(canvas2)
	-- apply crt shader and draw canvas to glow shader canvas
	drawCanvasWithShader(canvas, shader_crt)
	-- set draw target to screen
	love.graphics.setCanvas()
	-- apply glow shader
	drawCanvasWithShader(canvas2, shader_glow)
	-- draw game over screen
	if GAMEOVER then drawEndScreen(game_over_sprite) end
	
end

function love.update(dt)	
	if GAMEOVER then PAUSE = true end
	if player.fuel <= 0 then endGame() end
	if PAUSE then return end
	
	TIME = TIME + dt
	-- shader_vars.time = math.abs(math.mod(TIME, 2) - 1)
	if TIME > 0.15 then
		if player_grow_first then
			player:grow(1)
			player_grow_first = false
		end
	end

	-- player fixed tick update
	tick_accum = tick_accum + dt
	if tick_accum >= fixed_tick then
		tick_accum = 0
		player:update(fixed_tick)
	end

	-- spawning items
	item_accum = item_accum + dt
	if item_accum >= item_timer and #items < 25 then
		item_accum = 0
		
		table.insert(items, spawnItem(getRandomKey(ItemTypes), items, TIME))
	end

	-- player collision with items
	for i, item in pairs(items) do 
		if item:checkCollision(player:getBBox()) then
			collected = player:collect(item)
			if collected then table.remove(items, i) end
		end
	end

	-- player collision with drop point pickup radius
	for i, dp in pairs(drop_points) do 
		dp:update(dt)

		if dp.ready and dp:checkDeposit(player:getBBox("circle")) then
			seg = player:getFirstFilled()
			deposit_success, quota_success, prev_quota = dp:deposit(seg)
			if deposit_success then
				if quota_success then 
					SCORE = SCORE + 1
					CREDITS = CREDITS + prev_quota * 10
				end
				CREDITS = CREDITS + 5
				player:emptySegment(seg)
				player.last_filled = player.last_filled - 1
				player:cycleCells(-1)
			end
		end
	end

	-- player collision with fuel station pickup radius
	for i, fs in pairs(fuel_stations) do 
		fs:update(dt)
		if fs.ready and fs:checkDeposit(player:getBBox("circle")) then
			if CREDITS >= fs:getCost() then
				CREDITS = CREDITS - fs:getCost()
				player.fuel = player.fuel + player.fuelMax * 0.2
				fs:refill()
			end
		end
	end
	
	-- player collision with shipyard pickup radius
	for i, sy in pairs(shipyards) do 
		sy:update(dt)
		if sy.ready and sy:checkDeposit(player:getBBox("circle")) then
			if CREDITS >= sy:getCost() then
				CREDITS = CREDITS - sy:getCost()
				player:grow(1)
				sy:refill()
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
end

function drawCanvasWithShader(canvas, shader)
	love.graphics.setShader(shader)
	love.graphics.draw(canvas)
	love.graphics.setShader()
end

function updateTransform(scale)
	SCREEN_TRANSFORM = love.math.newTransform()
	SCREEN_TRANSFORM:scale(scale, scale)
	SCREEN_TRANSFORM:translate(screenW / scale, screenH / scale)
end

function endGame()
	PAUSE = true
	GAMEOVER = true
end

function drawStations()
	for i, item in pairs(items) do item:draw() end -- drawBBox("circle", item:getBBox("circle")) end
	for i, dp in pairs(drop_points) 
		do dp:draw() drawBBox("circle", dp:getDepositBBox("circle"), dp.colour) end
	
	for i, fs in pairs(fuel_stations) 
		do fs:draw() drawBBox("circle", fs:getDepositBBox("circle"), fs.colour) end
	
	for i, sy in pairs(shipyards) 
		do sy:draw() drawBBox("circle", sy:getDepositBBox("circle"), sy.colour) end
end

function drawUI()
	player_fuel_bar:draw(player.fuel / player.fuelMax)
	love.graphics.draw(score_sprite, score_text_x, score_text_y)
	love.graphics.print(SCORE, score_text_x + credits_sprite:getWidth() + 20, score_text_y, 0, 1.5)
	love.graphics.draw(credits_sprite, credits_text_x, credits_text_y)
	love.graphics.print("¢ "..CREDITS, credits_text_x + credits_sprite:getWidth() + 20, credits_text_y, 0, 1.5)
	
	head = player.segments[1].sprite_stack
	love.graphics.print(string.format("position     %.2f", player.x).." / "..string.format("%.2f", player.y), 70, 100, 0, 1.5)
	love.graphics.print(string.format("perspective  %.2f", head.perspective_x).." / "..string.format("%.2f", head.perspective_y), 70, 120, 0, 1.5)
	love.graphics.print(string.format("scale        %.2f", head.x_scale).." / "..string.format("%.2f", head.y_scale), 70, 140, 0, 1.5)
	love.graphics.print(string.format("rotation     %.2f", head.rotation), 70, 160, 0, 1.5)
	-- love.graphics.print(string.format("%.2f", (math.cos(head.rotation * 2) / 2 + 0.5) * 0.2 + 0.8), 120, 160, 0, 1.5)
	-- love.graphics.print(string.format("%.2f", (-math.cos(head.rotation * 2) / 2 + 0.5) * 0.2 + 0.8), 170, 160, 0, 1.5)

end

function loadStations()
	for f = 1, 2 do
		table.insert(fuel_stations, spawnStation("FUEL", FuelStation, stations))
	end
	
	for s = 1, 1 do
		table.insert(shipyards, spawnStation("EMPTY", Shipyard, stations))
	end

	for d = 1, 3 do
		type = getKeys(ItemTypes)[d]
		table.insert(drop_points, spawnStation(type, DropPoint, stations))
	end
end