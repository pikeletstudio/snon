function printTable(t)
	for k, v in pairs(t) do
		print(tostring(k)..": "..tostring(v))
	end
end

function shallow_copy(t)
	local t2 = {}
	for k,v in pairs(t) do
		t2[k] = v
	end
	return t2
end