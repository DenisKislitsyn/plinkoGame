local TYPE_TABLE = "table"

function table.deepcopy(orig)
	local orig_type = type(orig)
	local copy
	if orig_type == TYPE_TABLE then
		copy = {}
		for orig_key, orig_value in next, orig, nil do
			copy[table.deepcopy(orig_key)] = table.deepcopy(orig_value)
		end
	else
		copy = orig
	end
	return copy
end

function table.shuffle(t)
	local size = #t
	for i = size, 2, -1 do
		local j = math.random(i)
		t[i], t[j] = t[j], t[i]
	end
	return t
end
