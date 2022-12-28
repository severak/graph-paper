# graph paper file format

Idea is to have very simple even somewhat primitive file format which you can literally write by hand.

Whole file is composed by series of commands each written on it's own line.

Lines starting with `#` or empty lines (after trim) are considered to be comments and thus being ignored.

Other lines are split by spaces while parsing and first part is used as command name.

## units and dimensions

Whole graph paper has only one unit system defined by command *TODO*.

It can be zoomed and moved as needed. You can only render part of the graph if you need to do so.

For actual rendering there is another coordinate system which depends on output medium, but it's usually pixel perfect.

*TODO - write more about coordinate system and stuff*

## commands

- `P x y [color|style]` draws point, optionally using specified color or style
- `L x1 y1 x2 y2 [...x3 y3 etc.] [style]` draws line segment (in absolute coordinates), optionally using specified style
- `C x y r [style]` draws circle with radius `r`, optionally using specified style
- `A x1 y1 x2 y2 x3 y3 [style]` draws arc from point `p1` to point `p3` using point `p2` as the center of the circle, optionally using specified style
- `dim x1 y1 x2 y2 x3 y3` draws automatic dimension line (*měřící čáru*) between points `p1` and `p2` placing dimension itself on `p3` 
- `S x y symbol-name` draws symbol at point (useful for maps)
- *TODO - some command for creating areas*
- *TODO - document defining of styles and symbols*

No commands for 3D yet, these are not planned yet. 

## references

- [how to draw arc between threee points](https://stackoverflow.com/questions/30624842/draw-arc-on-canvas-from-two-x-y-points-and-a-center-x-y-point)
- [SVG path syntax](https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/d#path_commands)
- [CadStd](https://www.cadstd.com/)
