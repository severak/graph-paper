-- units tracking and conversion library
-- (c) Severák 2023
-- MIT licensed

-- This code tracks your units and converts them automatically so your Mars Climate Orbiter does not crash
--
-- (or it crashes even more because of unit conversion errors below:)
-- 
-- Strongly inspired by Frink language (https://frinklang.org/).

local units = {}
local units_meta = {}

units.size = {}
units.type = {}
units.base = {}
units.alias = {}
units.description = {}

function units.dim(value, unit)
    assert(units.size[unit], "Unknown unit " .. unit .. "!")
    return setmetatable({value=value, unit=unit}, units_meta)
end

function units.is_unit(val)
    return type(val)=="table" and getmetatable(val)==units_meta
end

-- TODO: units.conforms(a,b)
-- TODO units.convert_value(val)

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
    -- TODO if def.alias
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

-- c = a * b
-- TODO: units.relate(a, b, c)

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
units.base.mass = "kg" -- base unit for weight is kilogram, but it got prefix

units.define{name="lb", size=units.size.kg * 0.45359237, type="mass"} -- pound
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

-- TODO - define these

--- derived units: (BIG TODO)

--[[
1   ||| dimensionless

m^2 ||| area
m^3 ||| volume

s^-1   ||| frequency

m s^-1 ||| velocity
m s^-2 ||| acceleration
m kg s^-1 ||| momentum

m kg s^-2    ||| force
m^2  kg s^-3 ||| power
m^-1 kg s^-2 ||| pressure
m^2  kg s^-2 ||| energy
m^2  kg s^-1 ||| angular_momentum
m^2  kg      ||| moment_of_inertia

m^3 s^-1     ||| flow

m^-3 kg      ||| mass_density
m^3  kg^-1   ||| specific_volume         // Reciprocal of mass_density

A m^-2       ||| electric_current_density

dollar kg^-1 ||| price_per_mass

newton :=              kg m / s^2  // force
N :=                   newton
pascal :=              N/m^2       // pressure or stress
Pa :=                  pascal
joule :=               N m         // energy
J :=                   joule
watt :=                J/s         // power
W :=                   watt

J m^-2  ||| surface_tension

coulomb :=             A s         // charge
coulomb ||| charge
coulomb m^-2 ||| surface_charge_density
coulomb m^-3 ||| electric_charge_density
C :=                   coulomb

volt :=                W/A         // potential difference
V :=                   volt
volt ||| electric_potential
V / m   ||| electric_field_strength
A / m   ||| magnetic_field_strength

ohm :=                 V/A         // electrical resistance
\u2126 :=              ohm  // Official Unicode codepoint OHM SIGN
\u03a9 :=              ohm  // "Preferred" Unicode codepoint for ohm
                            // GREEK CAPITAL LETTER OMEGA
ohm ||| electric_resistance

siemens :=             A/V         // electrical conductance
S :=                   siemens
siemens ||| electric_conductance

farad :=               C/V         // capacitance
farad ||| capacitance

F :=                   farad
uF :=                  microfarad  // Concession to electrical engineers
                                   // without adding the questionable "u"
                                   // as a general prefix.

weber :=               V s         // magnetic flux
weber ||| magnetic_flux
Wb :=                  weber

henry :=               Wb/A        // inductance
henry ||| inductance
henries :=             henry       // Irregular plural
H :=                   henry

tesla :=               Wb/m^2      // magnetic flux density
tesla ||| magnetic_flux_density
T :=                   tesla

hertz :=               s^-1        // frequency
Hz :=                  hertz
]]

-- AREA
units.define{name="m2", size=1, type="area", SI_prefixes=true, SI_dimension=2}

-- VOLUME
units.define{name="m3", size=1, type="volume", SI_prefixes=true, SI_dimension=3}
units.define{name="l", size=1/1000, type="volume", SI_prefixes=true}

-- TODO - http://www.geneze.info/pojmy/subdir/stare_ceske_jednotky.htm, http://www.jankopa.cz/wob/PH_001.html a https://plzen.rozhlas.cz/loket-pid-nebo-latro-znate-stare-miry-a-vahy-6737273

-- TODO - musical units - BPM, PPQN

-- TODO - asserts to check if logic is not broken by some code mistakes above

return units