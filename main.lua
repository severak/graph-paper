-- GRAPH PAPER vector graphics editor (prototype)
-- (c) Severák 2023
-- MIT licensed

local push = table.insert

-- data of our drawing
local model = {}
-- each item is table with {type=type, d=coordinate or coordinates}
-- with following types and coordinates:
-- point = {x=x, y=y}
-- line = {{x=x1,y=y1}, {x=x2, y=x2}}
-- circle = {x=x, y=y, r=r}
-- polygon = {{x=x1,y=y1}, {x=x2, y=x2}, ...}
-- rectangle = {x=x, y=y, w=width, h=height}
-- TODO dimension marker
-- TODO infinite line

local modes = {
    p = 'point', -- adding point
    l = 'line', -- adding lines by two points (or by point, size and another point to set direction)
    r = 'rectangle', -- adding rectangles
    -- adding circles
    -- adding arcs
    -- adding rectangles
    -- adding dims
    -- measuring from point to point
    -- selecting things
    -- deleting things
    -- move things around
}

local mode = 'intro'
local prev_point = false

local is_dos = love.system.getOS()=='DOS' -- cool kids runs their programs on DOS
if is_dos then
    local og_set_color = love.graphics.setColor
    love.graphics.setColor = function(r,g,b)
        og_set_color(math.floor(r*255), math.floor(g*255), math.floor(b*255)) -- Love 0.2.x uses integer palette
    end
end
-- TODO - move all these is_dos tweaks to separate library

function dump(o)
    if type(o) == 'table' then
       local s = '{ '
       for k,v in pairs(o) do
          if type(k) ~= 'number' then k = '"'..k..'"' end
          s = s .. '['..k..'] = ' .. dump(v) .. ','
       end
       return s .. '} '
    else
       return tostring(o)
    end
 end

-- load model
function load_model(filename, offx, offy, zoom)
    offx=offx or 0
    offy=offy or 0
    zoom=zoom or 1
    local model = {}
    for line in io.lines(filename) do
        if line~="" and string.sub(line, 1, 1)~='#' then
            local coords = {}
            local tokcnt = 0
            local addtype = false
            local prev = false
            local toks = {}
            for token in string.gmatch(line, "[^%s]+") do
                if addtype=='L' then
                    if tokcnt % 2 == 1 then
                        prev = token
                    else
                        push(coords, {x=tonumber(prev)*zoom+offx, y=tonumber(token)*zoom+offy})
                    end
                end
                if tokcnt==0 then
                    addtype = token
                end
                tokcnt = tokcnt + 1
                push(toks, token)
            end
            if addtype=='L' then
                push(model, {type='line', d=coords})
            elseif addtype=='C' then
                push(model, {type='circle', d={x=tonumber(toks[2])*zoom+offx, y=tonumber(toks[3])*zoom+offy, r=tonumber(toks[4])*zoom}})
            end
        end
    end
    return model
end

function love.load(args)
    if not is_dos then love.window.setTitle("Graph paper (prototype)") end
    if is_dos then
        if args[2] then
            model = load_model(args[2], 10, 20, 2)
        end
    else
        if args[1] then
            model = load_model(args[1], 10, 20, 5)
        end
    end
end

function love.update(dt)
    if is_dos then love.timer.sleep(0.05) end -- sleep for 100ms to not boil DOSBox
end

function love.draw()
    
    -- drawing all drawn geometry
    love.graphics.setColor(255/255,255/255,255/255)
    for ord, item in ipairs(model) do
        if item.type=='point' then
            love.graphics.rectangle('fill', item.d.x-1, item.d.y-1, 3, 3)
        elseif item.type=='line' then
            love.graphics.line(item.d[1].x, item.d[1].y, item.d[2].x, item.d[2].y)
        elseif item.type=='rectangle' then
            love.graphics.rectangle('line', item.d.x, item.d.y, item.d.w, item.d.h)
        elseif item.type=='circle' then
            love.graphics.circle('line', item.d.x, item.d.y, item.d.r)
        end
    end

    -- draw currently drawed geometry
    love.graphics.setColor(255/255,85/255,255/255)
    if mode=='line' and prev_point then
        local mouse_x, mouse_y = love.mouse.getPosition()
        love.graphics.line(prev_point.x, prev_point.y, mouse_x, mouse_y)
        love.graphics.rectangle('fill', prev_point.x-1, prev_point.y-1, 3, 3)
        love.graphics.rectangle('fill', mouse_x-1, mouse_y-1, 3, 3)
    end
    if mode=='rectangle' and prev_point then
        local mouse_x, mouse_y = love.mouse.getPosition()
        love.graphics.rectangle('line', prev_point.x, prev_point.y, mouse_x-prev_point.x, mouse_y-prev_point.y)
    end


    -- draw program UI
    love.graphics.setColor(255/255,255/255,85/255)
    love.graphics.print("Graph paper (prototype)", 0, 0)
    love.graphics.print("mode: " .. mode, 0, love.graphics.getHeight()-16)

    if is_dos then
        -- draw mouse (if under DOS)
        local mouse_x, mouse_y = love.mouse.getPosition()
        love.graphics.line(mouse_x, mouse_y, mouse_x+10, mouse_y+10)
        love.graphics.line(mouse_x, mouse_y, mouse_x, mouse_y+5)
        love.graphics.line(mouse_x, mouse_y, mouse_x+5, mouse_y)
    end
end

function love.mousereleased(x, y, button)
    if mode=='point' then
        push(model, {type='point', d={x=x, y=y}})
    elseif mode=='line' then
        if prev_point then
            local mouse_x, mouse_y = love.mouse.getPosition()
            push(model, {type='line', d={{x=prev_point.x, y=prev_point.y}, {x=mouse_x, y=mouse_y}}})
            prev_point = false
        else
            prev_point = {x=x, y=y}
        end
    elseif mode=='rectangle' then
        if prev_point then
            local mouse_x, mouse_y = love.mouse.getPosition()
            push(model, {type='rectangle', d={x=prev_point.x, y=prev_point.y, w=mouse_x-prev_point.x, h=mouse_y-prev_point.y}})
            prev_point = false
        else
            prev_point = {x=x, y=y}
        end    
    end
end

function love.keyreleased(key)
    if key=='escape' then
        -- quits app
        love.event.quit()
    elseif key=="x" then
        -- deletes all things
        model = {}
    elseif modes[key] then
        -- switches mode
        mode = modes[key]
        prev_point = false
    end
end