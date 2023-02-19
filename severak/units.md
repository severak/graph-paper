# severak.units

this library is for unit conversion and tracking. It adds units to your numbers and convert it automatically when you when you perform arithmetics on it and it ensures you don't add apples to oranges.

## loading library

Call `units = require "severak.units"` to get reference to a library.

You can use `units.import_globals()` to bring specimen units to global scope (`m`, `km` etc). These are just units with size, created in this style: `_G.m = units.dim(1, "m")`.  This function also enables `%` unit conversion operator.

It's useful to alias commonly used functions, e.g. `local dim = units.dim` or `u=units.parse`.

## unit creation

You can create units in three ways:

- using `units.dim(size, unit)` function, e.g. `meter = units.size(1, "m")`
- using `units.parse(text)` function to parse user input, e.g. `units.parse "1m"`
- by multiplying number with unit, e.g. `meter = 1*m` (when using `units.import_globals()`)

Each created unit has it's value and unit defined:

```
> meter = units.dim(1, "m")
> =meter.value
1
> =meter.unit
m
```

## arithmetics

You can use units as if they were numbers:

```
> dim(1,"m") + dim(6,"cm")
106 cm
> m = dim(1, "m")
> km = dim(1, "km")
> = (9*km)/3 - 100*m
2900 m
```

Sometimes unit can disappear because the cancel out:

```
> D1 = dim(194, "km")
> Fabia = dim(3960, "mm")
> =D1 / Fabia
48989.898989899
```

If you try to perform arithmetics which does not make sense it will throw an error:

```
> kg = dim(1, "kg")
> =1*km+1*kg
.\severak\units.lua:119: Only conformal units can be added. (We will not add kil
ograms to meters.)
stack traceback:
        [C]: in function 'assert'
        .\severak\units.lua:119: in metamethod '__add'
        stdin:1: in main chunk
        [C]: in ?
>
```

## functions reference

- `units.dim(value, unit)` - creates unit with value `value` and unit `unit`
- `units.is_unit(val)` - checks if `val` is unit
- `units.conforms(a, b)` - checks if units are conformal (if one can be converted to another)
- `units.convert(val, unit)` - converts `val` to other unit `unit`
- `units.parse(val)` - parses unit from textual description, if it cannot parse it returns `nil`
- `units.define(def)` - defines new unit (to be described in detail)
- `units.import_globals()` - import specimens units to globals, addds `%` operator for easier conversions

