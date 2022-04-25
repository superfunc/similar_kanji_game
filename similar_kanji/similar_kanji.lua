function split(inputstr, sep) sep = sep or '%s'
	local t = {}
	for field, s in string.gmatch(inputstr, "([^" .. sep .. "]*)(" .. sep .. "?)") do
		table.insert(t, field)
		if s == "" then
			return t
		end
	end
end

similar_kanji_data = {}

for line in love.filesystem.lines("similar_kanji.txt") do
	table.insert(similar_kanji_data, split(line, ";"))
end
