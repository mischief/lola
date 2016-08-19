local lmath = require('lmath')

local colortab = {
	white = {255, 255, 255},
	red = {255, 0, 0},
	green = {0, 255, 0},
	blue = {0, 0, 255},
	brown = {130,20,20},
	forest = {34,139,34},
}

local M = {}

local Pen = {}
Pen.__index = Pen

function M.create(x, y, angle)
	local r = {
		pos = {
			x = x,
			y = y,
		},
		angle = angle,
		stack = {},
		mycolor = "white",
	}

	setmetatable(r, Pen)
	return r
end

function Pen:forward(px)
	local newp = lmath.angle2pos(self.pos, self.angle, px)

	if love then
		love.graphics.line(self.pos.x, self.pos.y, newp.x, newp.y)
	end

	self.pos = newp
end

-- move pen without drawing
function Pen:jump(px)
	self.pos = lmath.angle2pos(self.pos, self.angle, px)
end

function Pen:turn(deg)
	self.angle = self.angle - deg
end

-- save current state on internal stack
function Pen:push()
	local t = {
		pos = self.pos,
		angle = self.angle,
		mycolor = self.mycolor,
	}
	table.insert(self.stack, t)
end

-- pop saved state into current state
function Pen:pop()
	local t = table.remove(self.stack)
	self.pos = t.pos
	self.angle = t.angle
	self.mycolor = t.mycolor
	self:color(self.mycolor)
end

function Pen:color(col)
	local c = colortab[col]
	if not c then error(string.format("color %s doesn't exist", col)) end
	self.mycolor = col
	if love then
		love.graphics.setColor(unpack(c))
	end
end

return M

