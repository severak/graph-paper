local units = require "severak.units"

local welcome = "You can now use these units:"
local push = table.insert
local supported = {}

for unit_name, unit_size in pairs(units.size) do
    if not units.is_prefixed[unit_name] then
        push(supported, unit_name)
    end
end
table.sort(supported);

welcome = welcome .. "\n" .. table.concat(supported, ", ")
units.import_globals()
_G.units = units

return welcome