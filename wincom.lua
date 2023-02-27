-- WINCOM - compatibility layer for loveDOS
-- 
-- Translates new calls to old API and monkeypatches user program.
-- Does nothing on other platforms.
-- 
-- (c) Severák 2023
-- MIT-licensed

if love.system.getOS()=='DOS' then
	local og_set_color = love.graphics.setColor
    
	love.graphics.setColor = function(r,g,b)
		if r<2 or g<2 or b<2 then
			og_set_color(math.floor(r*255), math.floor(g*255), math.floor(b*255)) -- Love 0.2.x uses integer palette
		end
    end
	
	love.window = {}
	love.window.setTitle = function() end
	
	local og_update = love.update or nil
	
	function love.update(dt)
		if og_update then og_update(dt) end
		love.timer.sleep(0.05) -- sleep for 100ms to not boil DOSBox
		-- TODO - compute FPS
	end
	
	local og_draw = love.draw or nil
	
	function love.draw()
		if og_draw then og_draw() end
		 -- draw mouse as DOS does not have native one
		love.graphics.setColor(255/255,255/255,85/255)
        local mouse_x, mouse_y = love.mouse.getPosition()
        love.graphics.line(mouse_x, mouse_y, mouse_x+10, mouse_y+10)
        love.graphics.line(mouse_x, mouse_y, mouse_x, mouse_y+5)
        love.graphics.line(mouse_x, mouse_y, mouse_x+5, mouse_y)
	end

	-- needs probably more LOVE but hey - it works now
end