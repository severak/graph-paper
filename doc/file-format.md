# graph paper file format

Idea is to have very simple even somewhat primitive file format which you can literally write by hand.

Whole file is composed by series of commands each written on it's own line.

Lines starting with `#` or empty lines (after trim) are considered to be comments and thus being ignored.

Other lines are split by spaces while parsing and first part is used as command name.

## units and dimensions

Whole graph paper has only one unit system defined by command `units: <unit-name>`.

Coordinates starts as top left corner, `x` increments to right side and `y` increments down. This is the same coordinate system as used by [HTML5 Canvas](https://developer.mozilla.org/en-US/docs/Web/API/Canvas_API/Tutorial/Drawing_shapes), SVG and [LÖVE game engine](https://love2d.org/wiki/love.graphics).

For actual rendering it can be zoomed or offset as needed (see commands `zoom:` and `offset:`).

## commands

- `units: <unit-name>` sets units to unit-name (default `px`)
- `P x y [color|style]` draws point, optionally using specified color or style
- `L x1 y1 x2 y2 [style]` draws line segment (in absolute coordinates), optionally using specified style
- `C x y r [style]` draws circle with radius `r`, optionally using specified style
- `A x1 y1 x2 y2 x3 y3 [style]` draws arc from point `p1` to point `p3` using point `p2` as the center of the circle, optionally using specified style
- `dim x1 y1 x2 y2 x3 y3` draws automatic dimension line (*měřící čáru*) between points `p1` and `p2` placing dimension itself on `p3` 
- `S x y symbol-name` draws symbol at point (useful for maps)
- *TODO - some command for creating areas*
- *TODO - document defining of styles and symbols*
- *TODO - some command for infinite lines*
- `zoom: <factor>` scales drawing by factor
- `offset: x y` offset origin to `x` and `y` coordinates

No commands for 3D yet, these are not planned yet. 

## implementation details

There are currently three implementations of this format:

- LÖVE based app
- [browser based editor](https://severak.github.io/graph-paper/)
- and `fontgen.php` from [retro-cedule-font]() project (which can export to this format from DXF)

with following limitations:

- `units:` command is not implemented anywhere
- styles and colors are not implemented anywhere
- arcs, dims and symbols also not implemented yet
