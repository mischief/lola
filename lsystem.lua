local pen = require('pen')

local M = {}

local LSystem = {}
LSystem.__index = LSystem

function M.create(pos, rules)
	local r = {
		pen = pen.create(pos.x, pos.y, 90),
		-- table of char -> func
		rules = rules,
	}

	setmetatable(r, LSystem)
	return r
end

function LSystem:macroexpand(txt)
	if not self.rules.macro then
		return txt, false
	end

	local expanded = false
	local macros = self.rules.macro
	local msub = function(c)
		local m = macros[c]
		if type(m) == "string" then
			expanded = true
			return m 
		elseif type(m) == "table" then
			expanded = true
			local rand = love.math.random(1, #m)
			return m[rand]
		end

		return c
	end

	return string.gsub(txt, "(.)", msub), expanded
end

function LSystem:expand(steps)
	local a = self.rules.axiom
	local rules = self.rules.rule
	local sub = string.sub
	local insert = table.insert
	for i = 1, steps do
		local newa = {}

		for j = 1, #a do
			local c = sub(a, j, j)
			r = rules[c]
			if not r then
				insert(newa, c)
			else
				if type(r) == "string" then
					insert(newa, r)
				elseif type(r) == "table" then
					local rand = love.math.random(1, #r)
					insert(newa, r[rand])
				end
			end

		end

		a = table.concat(newa)
	end

	for i = 1, 10 do
		local newa, expanded = self:macroexpand(a)
		if not expanded then
			break
		end
		a = newa
	end

	return a
end

function LSystem:draw(s)
	for i = 1, #s do
		local c = s:sub(i, i)
		if c ~= " " then
			local r = self.rules.tg[c]
			if r then
				local cmd = r[1]
				local arg = r[2]
				local f = self.pen[cmd]
				if not f then
					error("no such command: " .. cmd)
				end

				f(self.pen, arg)
			end
		end
	end
end

return M

