-- units tracking and conversion library
-- (c) Severák 2023
-- MIT licensed

-- This code tracks your units and converts them automatically so your Mars Climate Orbiter does not crash. Or it crashes even more because of unit conversion errors below:
-- 
-- Strongly inspired by Frink language (https://frinklang.org/).

local units = {}
local units_meta = {}

units.size = {}
units.type = {}
units.base = {}

function units.dim(value, unit)
    assert(units.size[unit], "Unknown unit " .. unit .. "!")
    return setmetatable({value=value, unit=unit}, units_meta)
end

function units.is_unit(val)
    return type(val)=="table" and getmetatable(val)==units_meta
end

function units.convert(val, unit)
    assert(units.size[unit], "Unknown target unit " .. unit .. "!")
    assert(units.type[val.unit]==units.type[unit], "Cannot convert to different type of unit!")
    if val.unit==unit then
        return val -- target unit same as source unit
    end
    return units.dim(val.value * units.size[val.unit] / units.size[unit],  unit)
end

function units.parse(val)
    local num, unit = string.match(val, "([%d%.]+)%s-(%w+)")
    if num and unit then
        if units.size[unit] then
            return units.dim(tonumber(num), unit)
        else
            return false, "Unit " .. unit .. " not defined!"
        end
    else
        return false, "Does not look like an unit."
    end
end

-- magic happens here:
function units_meta.__tostring(val)
    return string.format("%g %s", val.value, val.unit)
end

-- TODO implement __eq, __le, __lt


function units_meta.__add(a, b)
    assert(units.is_unit(a) and units.is_unit(b), "Only units can be add together.")
    
    -- units are first converted to the smaller one to perform addition
    if units.size[a.unit] < units.size[b.unit] then
        b = units.convert(b, a.unit)    
    end

    if units.size[a.unit] > units.size[b.unit] then
        a = units.convert(a, b.unit)    
    end

    return units.dim(a.value + b.value, a.unit)
end

function units_meta.__sub(a, b)
    assert(units.is_unit(a) and units.is_unit(b), "Only units can be subtracted.")

    -- units are first converted to the smaller one to perform subtraction
    if units.size[a.unit] < units.size[b.unit] then
        b = units.convert(b, a.unit)    
    end

    if units.size[a.unit] > units.size[b.unit] then
        a = units.convert(a, b.unit)    
    end

    return units.dim(a.value - b.value, a.unit)
end

function units_meta.__mul(a, b)
    if units.is_unit(a) and tonumber(b) then
        return units.dim(a.value * tonumber(b), a.unit)
    end
    if units.is_unit(b) and tonumber(a) then
        return units.dim(b.value * tonumber(a), b.unit)
    end

    error("Multiplication by other units not yet implemented.")
end

function units_meta.__div(a, b)
    if units.is_unit(a) and tonumber(b) then
        return units.dim(a.value / tonumber(b), a.unit)
    end
    if units.is_unit(b) and tonumber(a) then
        return units.dim(b.value / tonumber(a), b.unit)
    end

    error("Division by other units not yet implemented.")
end

function units.define(def)
    assert(def,name, "Undefined unit name!")
    units.size[def.name] = def.size or error("Undefined unit size!")
    units.type[def.name] = def.type or error("Undefined init type!")
    if def.size==1 then
        units.base[def.type] = def.name
    end
    if def.SI_prefixes then
        def.SI_dimension = def.SI_dimension or 1

        local prefixes = {
            P = 10^15,
            T = 10^12,
            G = 10^9,
            M = 10^6,
            k = 10^3,
            h = 10^3,
            da = 10^1,
            d = 10^-1,
            c = 10^-2,
            m = 10^-3,
            u = 10^-6,
            n = 10^-9,
        }

        for prefix, size in pairs(prefixes) do
            units.size[prefix .. def.name] = (def.size * size) ^ def.SI_dimension
            units.type[prefix .. def.name] = def.type
        end 
    end
end

-- pollutes _G with definited units, dim and convert functions
function units.import_globals()
    for unit, size in pairs(units.size) do
        _G[unit] = units.dim(1, unit)
    end
    _G.dim = units.dim
    _G.convert = units.convert
    _G.to = units.convert
end

-- UNIT DEFINITIONS
-- 
-- Mostly stolen from https://frinklang.org/frinkdata/units.txt but only some units are defined.
-- 

-- LENGTH

units.define{name="m", size=1, type="length", SI_prefixes=true}

-- imperial
units.define{name="in", size=units.size.cm * 2.54, type="length"}
units.define{name="ft", size=units.size['in'] * 12, type="length"}
units.define{name="mile", size=units.size.ft * 5280, type="length"}
units.define{name="nmi", size=1852, type="length"} -- nautical mile

-- astronomical unit
units.define{name="AU", size=149597870700, type="length"}

-- TIME
units.define{name="s", size=1, type="time"}
units.define{name="min", size=units.size.s * 60, type="time"}
units.define{name="h", size=units.size.min * 60, type="time"}
units.define{name="day", size=units.size.h * 24, type="time"}
units.define{name="week", size=units.size.day * 7, type="time"}
units.define{name="year", size=units.size.day * 365, type="time"}

-- MASS
units.define{name="g", size=1, type="mass", SI_prefixes=true}
units.base.mass = "kg" -- this is retarded

units.define{name="lb", size=0.45359237, type="mass"} -- pound
units.define{name="oz", size=units.size.lb * 1/16, type="mass"} -- ounce
units.define{name="t", size=units.size.kg * 1000, type="mass"} -- metric ton

-- CURRENT
units.define{name="A", size=1, type="current", SI_prefixes=true} -- ampere

-- TEMPERATURE
units.define{name="K", size=1, type="temperature"} -- kelvin

-- TODO define F and C and conversions

-- AMOUNT OF SUBSTANCE (MOL)

-- ANGLE
units.define{name="circle", size=1, type="angle"} -- I am deviating from official definition to have circle as definition of angle units
units.define{name="rad", size=1/(2*math.pi), type="angle"} -- 2 pi radian = 1 circle
units.define{name="deg", size=1/360, type="angle"}

-- INFORMATION
units.define{name="b", size=1, type="information", SI_prefixes=true}
units.define{name="B", size=8, type="information", SI_prefixes=true}

-- how to define megabytes etc? this is mess
-- 
-- see this mess - https://en.wikipedia.org/wiki/Megabyte
units.define{name="Kib", size=2^10, type="information"}
units.define{name="Mib", size=2^20, type="information"}
units.define{name="Gib", size=2^30, type="information"}
units.define{name="Tib", size=2^40, type="information"}
units.define{name="Pib", size=2^40, type="information"}
-- TODO - check if previous is right


-- LUMINOUS INTENSITY (CANDELA)

-- TODO - define this

--- derived units:
-- AREA
units.define{name="m2", size=1, type="area", SI_prefixes=true, SI_dimension=2}

-- VOLUME
units.define{name="m3", size=1, type="volume", SI_prefixes=true, SI_dimension=3}
units.define{name="l", size=1/1000, type="volume", SI_prefixes=true}

-- TODO - http://www.geneze.info/pojmy/subdir/stare_ceske_jednotky.htm, http://www.jankopa.cz/wob/PH_001.html a https://plzen.rozhlas.cz/loket-pid-nebo-latro-znate-stare-miry-a-vahy-6737273

return units