-- simple GUI for Graph paper (LOVE 2D)
-- (c) Severák 2023
-- MIT licensed

-- internals are ugly as hell, but API works

local push = table.insert

function in_bbox(x, y, bbox)
    return x>=bbox.x and x<=(bbox.x+bbox.w) and y>=bbox.y and y<=(bbox.y+bbox.h)
end

function fix_pos(def)
    if def.x < 0 then
        def.x = love.graphics.getWidth() - def.w + def.x
    end
    if def.y < 0 then
        def.y = love.graphics.getHeight() - def.h + def.y
    end
    -- TODO - padding
end

local gui = {}
gui.screens = {}
gui.focused = false
gui.font = love.graphics.getFont()


-- DOS color scheme from https://www.colorbook.io/colorschemes/view/1475
gui.colors = {
    border = {r=85/255, g=85/255, b=85/255},
    background = {r=170/255, g=170/255, b=170/255},
    text = {r=0, g=0, b=0},
    input = {r=255/255, g=255/255, b=255/255}
}

function gui.set_color(color)
    love.graphics.setColor(color.r, color.g, color.b)
end

-- label
local label = {}

function label.new(def)
    def.text = def.text or error "Label needs defined text!"
    def.x = def.x or 0
    def.y = def.y or 0
    def.w = gui.font:getWidth(def.text)
    def.h = gui.font:getHeight()
    fix_pos(def)
    return setmetatable(def, {__index=label})
end

function label:draw()
    gui.set_color(self.color or gui.colors.text)
    love.graphics.print(self.text, self.x, self.y)
end

function label:mousereleased() end
function label:textinput() end
function label:keyreleased() end
-- no onclick etc as label is not interactive

-- button
local button = {}

function button.new(def)
    def.padding = def.padding or 2
    def.x = def.x or 0
    def.y = def.y or 0
    if def.text then
        def.w = def.w or gui.font:getWidth(def.text)
        def.h = def.h or gui.font:getHeight()
    elseif def.image then
        if type(def.image)=="string" then
            def.image = love.graphics.newImage(def.image)
        end
        def.w = def.image:getWidth()
        def.h = def.image:getHeight()
    else
        error "Button needs to have image or text defined."
    end
    fix_pos(def)
    return setmetatable(def, {__index=button})
end

function button:on_click()
    -- nop
end

function button:draw()
    gui.set_color(gui.colors.background)
    love.graphics.rectangle("fill",self.x, self.y, self.w, self.h)
    gui.set_color(gui.colors.border)
    love.graphics.rectangle("line",self.x, self.y, self.w, self.h)
    if self.text then
        gui.set_color(gui.colors.text)
        love.graphics.print(self.text, self.x, self.y)
    elseif self.image then
        love.graphics.draw(self.image, self.x, self.y)
    end
    -- TODO - drawing title
end

function button:mousereleased(x,y,button)
    if in_bbox(x,y,self) then
        self:on_click()
        return true
    end
end

function button:textinput() end
function button:keyreleased() end -- TODO - shortcuts

-- input
local input = {}

function input.new(def)
    def.x = def.x or 0
    def.y = def.y or 0
    if def.placeholder then
        def.w = gui.font:getWidth(def.placeholder)
    elseif not def.w then
        def.w = gui.font:getWidth("brambora")
    end
    def.h = def.h or gui.font:getHeight()
    fix_pos(def)
    def.value = def.value or ""
    return setmetatable(def, {__index=input})
end

function input:draw()
    gui.set_color(gui.colors.input)
    love.graphics.rectangle("fill",self.x, self.y, self.w, self.h)
    gui.set_color(gui.colors.border)
    love.graphics.rectangle("line",self.x, self.y, self.w, self.h)
    if self.value ~= "" or gui.focused==self then
        gui.set_color(gui.colors.text)
        -- TODO animovat kurzor
        love.graphics.print(self.value .. (gui.focused==self and "|" or ""), self.x, self.y)
    elseif self.placeholder then
        gui.set_color(gui.colors.border)
        love.graphics.print(self.placeholder, self.x, self.y)
    end
end

function input:mousereleased(x,y,button)
    if in_bbox(x,y,self) then
        gui.focused = self
        return true
    end
end

function input:textinput(text)
    if gui.focused==self then
        self.value = self.value .. text
        return true
    end
end

function input:keyreleased(key)
    if gui.focused==self then
        if key=="backspace" then
            self.value = string.sub(self.value, 1, -2) -- TODO utf8
        elseif key=="return" or key=="tab" or key=="escape" then
            gui.focused = false
        end
        return true
    end
end

-- TODO panel with intelligent placing of buttons

-- TODO dialog which obscures rest of the screen

-- screen
local screen = {}

function screen:label(def)
    local b = label.new(def)
    push(self.children, b)
    return b
end

function screen:button(def)
    local b = button.new(def)
    push(self.children, b)
    return b
end

function screen:input(def)
    local b = input.new(def)
    push(self.children, b)
    return b
end

function screen:draw()
    for _, child in ipairs(self.children) do
        child:draw()
    end
end

function screen:mousereleased(x, y, button)
    local done = false
    for _, child in ipairs(self.children) do
        done = child:mousereleased(x, y, button) or done
    end
    return done
end

function screen:textinput(text)
    local done = false
    for _, child in ipairs(self.children) do
        done = child:textinput(text) or done
    end
    return done
end

function screen:keyreleased(key)
    local done = false
    for _, child in ipairs(self.children) do
        done = child:keyreleased(key) or done
    end
    return done
end

-- main gui function
function gui.screen(name)
    local s = {}
    s.name = name
    s.active = false
    s.children = {}
    setmetatable(s, {__index=screen})
    push(gui.screens, s)
    return s
end

function gui.switch(screen_name)
    for _, scr in ipairs(gui.screens) do
        scr.active = scr.name==screen_name
    end
end

function gui.draw()
    gui.font = love.graphics.getFont()
    for _, scr in ipairs(gui.screens) do
        if scr.active then
            scr:draw()
        end
    end
end

function gui.mousereleased(x, y, button)
    local done = false
    gui.focused = false
    for _, scr in ipairs(gui.screens) do
        if scr.active then
            done = scr:mousereleased(x, y, button) or done
        end
    end
    return not done
end

function gui.textinput(text)
    local done = false
    for _, scr in ipairs(gui.screens) do
        if scr.active then
            done = scr:textinput(text) or done
        end
    end
    return not done
end

function gui.keyreleased(key)
    local done = false
    for _, scr in ipairs(gui.screens) do
        if scr.active then
            done = scr:keyreleased(key) or done
        end
    end
    return not done
end

return gui