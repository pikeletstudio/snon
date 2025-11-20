
SpriteStack = {}
SpriteStack.__index = SpriteStack


function SpriteStack.new(x_spacing, x_scale, y_spacing, y_scale)
	local instance = setmetatable({}, SpriteStack)
	instance.spritesheet = nil
	instance.spriteBatch = nil
	instance.shared = false
	instance.quads = {}
	instance.x = 0
	instance.y = 0
	instance.width = 0
	instance.height = 0
	instance.x_scale = x_scale and x_scale or 1
	instance.x_spacing = x_spacing and x_spacing * instance.x_scale or 0
	instance.y_scale = y_scale and y_scale or 1
	instance.y_spacing = y_spacing and y_spacing * instance.y_scale or 0
	instance.rotation = 0
	instance.perspective_x = 0
	instance.perspective_y = 0
	return instance
end

function SpriteStack:load_from_path(path, rows, columns)
	local spritesheet = love.graphics.newImage(path)

	local spriteBatch = love.graphics.newSpriteBatch(spritesheet)


	local sheetWidth = spritesheet:getWidth()
    local sheetHeight = spritesheet:getHeight()
	local frameWidth = sheetWidth / columns
    local frameHeight = sheetHeight / rows

    local quads = {}
    for r = 0, rows - 1 do
    	for c = 0, columns - 1 do
			local q = love.graphics.newQuad(frameWidth * c, frameHeight * r, frameWidth, frameHeight, sheetWidth, sheetHeight)
        	table.insert(quads, q)
		end
    end

	self.spritesheet = spritesheet
	self.spriteBatch = spriteBatch
	self.quads = quads
	self.width = frameWidth
	self.height = frameHeight
end

function SpriteStack:load_from_image(spritesheet, rows, columns, sharedSpriteBatch)
	local spriteBatch = sharedSpriteBatch or love.graphics.newSpriteBatch(spritesheet)
	self.shared = sharedSpriteBatch ~= null

	local sheetWidth = spritesheet:getWidth()
    local sheetHeight = spritesheet:getHeight()
	local frameWidth = sheetWidth / columns
    local frameHeight = sheetHeight / rows

    local quads = {}
    for r = 0, rows - 1 do
    	for c = 0, columns - 1 do
			local q = love.graphics.newQuad(frameWidth * c, frameHeight * r, frameWidth, frameHeight, sheetWidth, sheetHeight)
        	table.insert(quads, q)
		end
    end

	self.spritesheet = spritesheet
	self.spriteBatch = spriteBatch
	self.quads = quads
	self.width = frameWidth
	self.height = frameHeight
end

function SpriteStack:load_from_atlas(atlas, start_x, start_y, frameWidth, frameHeight, rows, columns, sharedSpriteBatch)
	local spriteBatch = sharedSpriteBatch or love.graphics.newSpriteBatch(spritesheet)
	self.shared = sharedSpriteBatch ~= null

	local sheetWidth = atlas:getWidth()
    local sheetHeight = atlas:getHeight()

    local quads = {}
    for r = 0, rows - 1 do
    	for c = 0, columns - 1 do
			local q = love.graphics.newQuad(start_x + frameWidth * c, start_y + frameHeight * r, frameWidth, frameHeight, sheetWidth, sheetHeight)
        	table.insert(quads, q)
		end
    end

	self.spritesheet = spritesheet
	self.spriteBatch = spriteBatch
	self.quads = quads
	self.width = frameWidth
	self.height = frameHeight
end

function SpriteStack:draw()
	for q, quad in pairs(self.quads) do
		local x_scale, y_scale = self.x_scale, self.y_scale
		love.graphics.draw(self.spritesheet, quad, self.x - q * self.x_spacing, self.y - q * self.y_spacing, self.rotation, 
							x_scale, y_scale, self.width / 2, self.height / 2)
	end
end

function SpriteStack:add_to_batch()
	if not self.shared then self.spriteBatch:clear() end
	for q, quad in pairs(self.quads) do
		self.x_scale = (math.cos(self.rotation * 2) / 2 + 0.5) * 0.2 + 0.8
		self.y_scale = (-math.cos(self.rotation * 2) / 2 + 0.5) * 0.2 + 0.8
		local sign_x = (-self.x) / math.abs(self.x)
		local sign_y = (-self.y) / math.abs(self.y)
		local x_scale, y_scale = (self.perspective_x), (self.perspective_y) --self.x_scale, self.y_scale
		self.spriteBatch:add(q, quad, self.x - (q - 1) * self.x_spacing * sign_x * (1 / self.perspective_x), 
									self.y - (q - 1) * self.y_spacing * sign_y * (1 / self.perspective_y), 
									self.rotation, x_scale, y_scale, self.width / 2, self.height / 2)
	end
	if not self.shared then love.graphics.draw(self.spriteBatch) end
end

function SpriteStack:rotate(angle)
	self.rotation = self.rotation + angle
end

function SpriteStack:set_position(x, y)
	self.x = x
	self.y = y
end

function SpriteStack:set_spacing(x_spacing, y_spacing)
	self.x_spacing = x_spacing
	self.y_spacing = y_spacing
end

function SpriteStack:set_perspective(x_angle, y_angle)
	self.perspective_x = x_angle
	self.perspective_y = y_angle
end

function SpriteStack:getWidth()
	return self.width
end

function SpriteStack:getHeight()
	return self.height
end

--------------------------------------------------------------------------------------------------+

LayeredSpriteBatch = {}
LayeredSpriteBatch.__index = LayeredSpriteBatch


function LayeredSpriteBatch.new(texture_atlas)
	local instance = setmetatable({}, LayeredSpriteBatch)
	instance.texture_atlas = texture_atlas
	instance.spriteBatch = love.graphics.newSpriteBatch(texture_atlas)
	instance.quads_by_layer = {} -- {layer_no: quads = {...}}
	instance.verbose = false
	return instance
end

function LayeredSpriteBatch:add(layer, quad, ...)
	if self.quads_by_layer[layer] then
		-- if self.verbose then print("layer "..layer.." exists") end
		table.insert(self.quads_by_layer[layer], {quad, ...})
	else
		-- if self.verbose then print("creating layer "..layer) end
		self.quads_by_layer[layer] = {{quad, ...}}
	end
end

-- function LayeredSpriteBatch:draw()
-- 	self.spriteBatch:clear()
-- 	for layer, quads in pairs(self.quads_by_layer) do
-- 		if self.verbose then print((#self.quads_by_layer - layer + 1) / #self.quads_by_layer) end

-- 		-- love.graphics.setColor({1,1,1, (#self.quads_by_layer - layer + 1) / #self.quads_by_layer + 0.1})
-- 		for q, quad_with_args in pairs(quads) do
-- 			if self.verbose then print("layer "..layer.." quad "..q) end
-- 			if self.verbose then print(unpack(quad_with_args)) end
			
-- 			self.spriteBatch:add(unpack(quad_with_args))
-- 		end
-- 		love.graphics.draw(self.spriteBatch)
-- 		love.graphics.setColor({1,1,1,1})
-- 	end
-- 	self.quads_by_layer = {}
-- end

function LayeredSpriteBatch:draw()
	self.spriteBatch:clear()
	for layer, quads in pairs(self.quads_by_layer) do
		self:draw_layer(layer)
	end
end

function LayeredSpriteBatch:draw_layer(layer)
	self.spriteBatch:clear()
	quads = self.quads_by_layer[layer]
	if not quads then return end
	if self.verbose then print((#self.quads_by_layer - layer + 1) / #self.quads_by_layer) end

	for q, quad_with_args in pairs(quads) do
		if self.verbose then print("layer "..layer.." quad "..q) end
		if self.verbose then print(unpack(quad_with_args)) end
		
		self.spriteBatch:add(unpack(quad_with_args))
	end
	love.graphics.draw(self.spriteBatch)
	self.quads_by_layer[layer] = {}
	-- table.remove(self.quads_by_layer, layer)
end