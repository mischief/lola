local keys = {}

function keys:bind(modifiers, key, callback)
	table.insert(self, {modifiers = modifiers, key = key, callback = callback})
end

function keys:handle(key)
	for _, binding in ipairs(self) do
		if binding.key == key then
			local modifiers = true

			for _, modifier in ipairs(binding.modifiers) do
				modifiers = modifiers and love.keyboard.isDown(modifier)
			end

			if modifiers then
				binding.callback()
				return
			end
		end
	end
end

return keys

