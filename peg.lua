local peg = require('lpeg')

local L = peg.locale()

-- string -> number or error
local mustnumber = function(s)
	local r = tonumber(s)
	if not r then error("not a number: " .. s, 3) end
	return r
end

-- error handler
local perr = function(txt, i, msg)
	local sub = string.sub(txt, i)
	local n, e = string.find(sub, "\n")
	local line = ""
	if n then
		line = string.sub(sub, 1, n-1)
	else
		line = sub
	end

	if msg ~= "" then
		error(msg .. " at position " .. i .. ": '" .. line .. "'", 3)
	end

	error("invalid encoding at position " .. i .. " : '" .. line .. "'", 3)
end

-- number not parseable
local nanerr = function(txt, i)
	return perr(txt, i, "not a number")
end

local ct = {
	MaybeSpace = peg.S(" \t")^0,
	MultiSpace = peg.S(" \t")^1,
	Comment = peg.P("#") * (1 - peg.S("\n"))^0,

	Newlines = peg.P("\n")^1,

	Sym = peg.C(peg.R("az", "AZ", "!/", ":@", "[`", "{~")),
	Word = peg.C(peg.R("az", "AZ", "!/", ":@", "[`", "{~")^1),
	Num = (peg.C(peg.P("-")^-1 * peg.R("09")^1) / mustnumber), -- + nanerr,

	Axiom = peg.C("axiom"),
	Var = peg.C("var"),
	Const = peg.C("const"),
	Macro = peg.C("macro"),
	Rule = peg.C("rule"),
	TG = peg.C("tg"),
}

local Thing = peg.V("Thing")
local Axiom = peg.V("Axiom")
local Var = peg.V("Var")
local Const = peg.V("Const")
local Macro = peg.V("Macro")
local Rule = peg.V("Rule")
local TG = peg.V("TG")
local Action = peg.V("Action")

-- grammar table
local Gt = {
	-- initial rule
	"LSystem",

	-- parse all, or error
	LSystem = peg.Ct((Thing * ct.Newlines)^1) * (-1 + lpeg.P(perr)),

	-- any of below
	Thing = peg.Ct(Axiom + Macro + Var + Const + Rule + TG) + ct.Comment,

	-- "axiom X"
	Axiom = ct.Axiom * ct.MultiSpace * ct.Word,
	-- "var X"
	Var = ct.Var * ct.MultiSpace * ct.Sym,
	-- "const F"
	Const = ct.Const * ct.MultiSpace * ct.Sym,

	-- "macro Z FFF"
	Macro = ct.Macro * ct.MultiSpace * ct.Sym * ct.MultiSpace * ct.Word,
	-- "rule X XFX"
	Rule = ct.Rule * ct.MultiSpace * ct.Sym * ct.MultiSpace * ct.Word,

	-- "tg F <action>"
	TG = ct.TG * ct.MultiSpace * ct.Sym * ct.MultiSpace * Action,
	-- "forward 5" / "pic foo.png"
	Action = ct.Word * (ct.MultiSpace * (ct.Num + ct.Word))^0,
}

local G = peg.P(Gt)

-- convert parsed rules into more useable form
local fixup = function(t)
	local r = {}
	for i = 1, #t do
		local op = table.remove(t[i], 1)

		if op ~= "axiom" then
			if not r[op] then r[op] = {} end
		end

		if op == "axiom" then
			r.axiom = t[i][1]
		elseif op == "const" or op == "var" then
			if not r[op] then r[op] = {} end
			table.insert(r[op], t[i][1])
		elseif op == "rule" or op == "macro" then
			local sym = table.remove(t[i], 1)
			local exp = table.remove(t[i], 1)
			if r[op][sym] then
				if type(r[op][sym]) == "string" then
					local newt = { r[op][sym], exp }
					r[op][sym] = newt
				elseif type(r[op][sym]) == "table" then
					table.insert(r[op][sym], exp)
				end
			else
				r[op][sym] = exp
			end
		elseif op == "tg" then
			local sym = table.remove(t[i], 1)
			local cmd = table.remove(t[i], 1)
			local arg = table.remove(t[i], 1)
			r[op][sym] = {cmd, arg}
		else
			error("unknown op: " .. op)
		end
	end

	return r
end

local parse = function(txt)
	local t = peg.match(G, txt)
	if not t then error("syntax error", 2) end

	return fixup(t)
end

return {
	parse = parse,
}

