-------------------
-- DAMAGE REPORT MODULE
-------------------
-- LUA Parameters
DMGREPORT_defaultFilter = 1 --export: 1 for all,2 for avionics and weapons,3 for avionics only, 4 for weapons only
DMGREPORT_defaultView = 1 --export: 1 for top,2 for side and 3 for front
DMGREPORT_dmg_priority = 2 --export: Show damaged components (3) Below 100%, (2) Below 75%, (1) Below 50%
DMGREPORT_dmg_refresh_rate = 2 --export: Damage report refresh rate every x seconds
DMGREPORT_size = 1000 --export: Display size
DMGREPORT_point_size = 10 --export: Points size
DMGREPORT_disable_shortcuts = false --export: Disable option1 and option2 if you need those for other things

core = nil
screen_list = {}

-------------------
-- General Functions
-------------------
function round(num, numDecimalPlaces)
    return tonumber(string.format("%." .. (numDecimalPlaces or 0) .. "f", num))
end

function sortSlot(slot)
    if slot ~= nil then
        if string.match(slot.getElementClass(), "CoreUnit") then    
            core = slot
        elseif string.match(slot.getElementClass(), "ScreenUnit") then    
            table.insert(screen_list, slot) 	
        end   
    end

end

function activateScreens(screen_list)
    for _,screen in ipairs(screen_list) do
        if screen.getState() == 0 then	
            screen.activate()
        end
    end   
end

function getElemCategory(elemtype)
    elem_category="COMMON"
    if elemtype ~= nil then
        local critical_part_list = {"DYNAMIC CORE","RESURRECTION NODE","RADAR","GUNNER MODULE","COMMAND SEAT CONTROLLER","COCKPIT"}   
        local avionics_part_list = {"ENGINE","FUEL-TANK","ADJUSTOR","VERTICAL BOOSTER","RETRO-ROCKET BRAKE","WING","ATMOSPHERIC AIRBRAKE"}
        local weapon_part_list = {"LASER","CANNON","MISSILE","RAILGUN"}   
        -- CRITICALS
        for _,reftype in ipairs(critical_part_list) do
            if string.match(elemtype, reftype) then
                elem_category="CRITICALS"
                break
            end    
        end
        if elem_category == "COMMON" then
            -- AVIONICS 
            for _,reftype in ipairs(avionics_part_list) do
                if string.match(elemtype, reftype) then
                    elem_category="AVIONICS"
                    break
                end
            end
            if elem_category == "COMMON" then
                -- WEAPONS
                for _,reftype in ipairs(weapon_part_list) do
                    -- Avoid mistaking laser emitter for a weapon...
                    if elemtype == "LASER" then
                        elem_category="WEAPON"
                        break 
                    elseif string.match(elemtype, reftype) then
                        elem_category="WEAPON"
                        break
                    end    
                end 
            end
        end 
    end
    return elem_category
end


-------------------
-- Element Class
-------------------
Element = {}
Element.__index = Element

function Element.new(elem_id,elem_type,elem_category, elem_name, elem_pos_x, elem_pos_y, elem_pos_z)
    local self = setmetatable({}, Element)
    self.elem_id = elem_id
    self.elem_type = elem_type
    self.elem_category = elem_category
    self.elem_name = elem_name
    self.elem_pos_x = elem_pos_x
    self.elem_pos_y = elem_pos_y
    self.elem_pos_z = elem_pos_z

    return self
end

-------------------
-- DamageModule Class
-------------------
DamageModule = {}
DamageModule.__index = DamageModule

function DamageModule.new()
    local self = setmetatable({}, DamageModule)
    self.elem_list = {}
    -- Init slots
    sortSlot(slot1)
    sortSlot(slot2)
    sortSlot(slot3)
    sortSlot(slot4)
    sortSlot(slot5)
    sortSlot(slot6)
    sortSlot(slot7)
    sortSlot(slot8)
    sortSlot(slot9)
    sortSlot(slot10)

    self.elem_filter = DMGREPORT_defaultFilter -- 4 for all,3 for avionics and weapons,2 for avionics only, 1 for weapons
    self.active_view = DMGREPORT_defaultView -- 1 for top,2 for side and 3 for front
    self.last_time_updated = 0

    if core ~= nil then    
        -- Getting the core offset
        -- XS CORE
        local core_offset = 0
        local core_hp = core.getElementHitPointsById(core.getId())
        
        self.core_offset=core_offset   
        self.max_x= -999999999
        self.min_x= 999999999
        self.max_y= -999999999
        self.min_y = 999999999
        self.max_z= -999999999
        self.min_z = 999999999

        -- STORING SHIP ELEMENTS
        for i,idelem in ipairs(core.getElementIdList()) do
            local elem_type = core.getElementTypeById(idelem):upper()
            local elem_categ = getElemCategory(elem_type)
            local elem_name = core.getElementNameById(idelem)
            local x,y,z = table.unpack(core.getElementPositionById(idelem))
            x=(x+core_offset)
            y=(y+core_offset)
            z=(z+core_offset)
            if self.min_x > x then
                self.min_x = x
            end    
            if self.min_y > y then
                self.min_y = y
            end
            if self.min_z > z then
                self.min_z = z
            end 
            if self.max_x < x then
                self.max_x = x
            end    
            if self.max_y < y then
                self.max_y = y
            end
            if self.max_z < z then
                self.max_z = z
            end
            self:add(Element.new(idelem,elem_type, elem_categ, elem_name, x, y, z))
        end


        -- Computing ship size
        self.ship_width = 0
        if self.min_x < 0 then
            self.ship_width = self.ship_width + (self.min_x)*-1
        else
            self.ship_width = self.ship_width + self.min_x
        end      
        if self.max_x < 0 then
            self.ship_width = self.ship_width + (self.max_x)*-1
        else
            self.ship_width = self.ship_width + self.max_x
        end
        self.ship_height = 0
        if self.min_y < 0 then
            self.ship_height = self.ship_height + (self.min_y)*-1
        else
            self.ship_height = self.ship_height + self.min_y
        end      
        if self.max_y < 0 then
            self.ship_height = self.ship_height + (self.max_y)*-1
        else
            self.ship_height = self.ship_height + self.max_y
        end
        self.ship_z = 0
        if self.min_z < 0 then
            self.ship_z = self.ship_z + (self.min_z)*-1
        else
            self.ship_z = self.ship_z + self.min_z
        end      
        if self.max_z < 0 then
            self.ship_z = self.ship_z + (self.max_z)*-1
        else
            self.ship_z = self.ship_z + self.max_z
        end
        if self.ship_width >= self.ship_height then
            self.xyscaleFactor=DMGREPORT_size/self.ship_width    
        else
            self.xyscaleFactor=DMGREPORT_size/self.ship_height    
        end
        if self.ship_width >= self.ship_z then
            self.xzscaleFactor=DMGREPORT_size/self.ship_width    
        else
            self.xzscaleFactor=DMGREPORT_size/self.ship_z    
        end
        if self.ship_height >= self.ship_z then
            self.yzscaleFactor=DMGREPORT_size/self.ship_height    
        else
            self.yzscaleFactor=DMGREPORT_size/self.ship_z    
        end
    end
    return self
end

function DamageModule.add(self,element)
    table.insert(self.elem_list, element)
end

function DamageModule.nextFilter(self)
    if self.elem_filter < 4 then
        self.elem_filter = self.elem_filter + 1
    else 
        self.elem_filter = 1 	    
    end 
end

function DamageModule.nextView(self)
    if self.active_view < 3 then
        self.active_view = self.active_view + 1
    else 
        self.active_view = 1 	    
    end 
end

function DamageModule.getActiveView(self)
    return self.active_view
end

function DamageModule.renderHTML(self)
    local front_view_html = ""
    local side_view_html = ""
    local top_view_html = ""
    local table_view_html = ""
    if system.getTime() > self.last_time_updated + DMGREPORT_dmg_refresh_rate then
        --Data gathering
        local dead_elem_list=""
        local high_damage_list=""
        local medium_damage_list=""
        local light_damage_list=""
        local maxtoptv = -99999999999
        local maxtopfv = -99999999999
        local maxtopsv = -99999999999

        local top_pristine_dot_list=""
        local top_light_dot_list=""
        local top_medium_dot_list=""
        local top_high_dot_list=""
        local top_dead_dot_list=""

        local front_pristine_dot_list=""
        local front_light_dot_list=""
        local front_medium_dot_list=""
        local front_high_dot_list=""
        local front_dead_dot_list=""

        local side_pristine_dot_list=""
        local side_light_dot_list=""
        local side_medium_dot_list=""
        local side_high_dot_list=""
        local side_dead_dot_list=""

        for _,elem in ipairs(self.elem_list) do
            local element_excluded = false
            if self.elem_filter == 2 and elem.elem_category ~= "AVIONICS" and elem.elem_category ~= "WEAPON" and elem.elem_category ~= "CRITICAL" then
                element_excluded = true
            elseif self.elem_filter == 3 and elem.elem_category ~= "AVIONICS" and elem.elem_category ~= "CRITICAL" then
                element_excluded = true
            elseif self.elem_filter == 4 and elem.elem_category ~= "WEAPON" and elem.elem_category ~= "CRITICAL" then
                element_excluded = true   
            end    
            if element_excluded == false then
                local elem_hp = core.getElementHitPointsById(elem.elem_id)
                local elemmax_hp = core.getElementMaxHitPointsById(elem.elem_id)
                local elem_hp_percentage = (elem_hp*100)/elemmax_hp
                local color=""
                local opacity=1

                -- COMPUTE DAMAGE
                elem_hp_percentage = round(elem_hp_percentage)
                if elem_hp_percentage >= 100 then
                    color="#9BFFAC"
                elseif elem_hp_percentage >= 75 then
                    opacity=1
                    color="#FFDD8E"
                    if DMGREPORT_dmg_priority > 2 then
                        light_damage_list=light_damage_list..[[<tr class="ldmg"><td>]]..elem.elem_category..[[</td><td>]]..elem.elem_name..[[</td><td class="r">]]..elem_hp_percentage..[[%</td></tr>]]
                    end
                elseif elem_hp_percentage >= 50 then
                    color="#FF9E66"
                    opacity=1
                    if DMGREPORT_dmg_priority > 1 then
                        medium_damage_list=medium_damage_list..[[<tr class="mdmg"><td>]]..elem.elem_category..[[</td><td>]]..elem.elem_name..[[</td><td class="r">]]..elem_hp_percentage..[[%</td></tr>]]
                    end
                elseif elem_hp_percentage > 0 then
                    color="#FF2819"
                    opacity=1
                    high_damage_list=high_damage_list..[[<tr class="hdmg"><td>]]..elem.elem_category..[[</td><td>]]..elem.elem_name..[[</td><td class="r">]]..elem_hp_percentage..[[%</td></tr>]]
                elseif elem_hp_percentage == 0 then
                    color="#7F120C"
                    opacity=1
                    dead_elem_list=dead_elem_list..[[<tr class="dead"><td>]]..elem.elem_category..[[</td><td>]]..elem.elem_name..[[</td><td class="r">0%</td></tr>]]
                end

                local left = 0
                local top = 0
                -- We are using quadrants to place points correctly
                -- 1 2
                -- 3 4
                if (elem.elem_pos_x>=self.min_x and elem.elem_pos_x<=0) and (elem.elem_pos_y>=0 and elem.elem_pos_y<=self.max_y) then    
                    -- 1
                    left = (self.min_x*-1) + elem.elem_pos_x
                    top = self.max_y - elem.elem_pos_y
                elseif (elem.elem_pos_x>0 and elem.elem_pos_x<=self.max_x) and (elem.elem_pos_y>=0 and elem.elem_pos_y<=self.max_y) then    
                    -- 2
                    left = (self.min_x*-1) + elem.elem_pos_x
                    top = self.max_y - elem.elem_pos_y
                elseif (elem.elem_pos_x>=self.min_x and elem.elem_pos_x<=0) and (elem.elem_pos_y>=self.min_y and elem.elem_pos_y<0) then    
                    -- 3
                    left = (self.min_x*-1) + elem.elem_pos_x
                    top = self.max_y + (elem.elem_pos_y*-1)
                elseif (elem.elem_pos_x>0 and elem.elem_pos_x<=self.max_x) and (elem.elem_pos_y>=self.min_y and elem.elem_pos_y<0) then    
                    -- 4
                    left = (self.min_x*-1) + elem.elem_pos_x
                    top = self.max_y + (elem.elem_pos_y*-1)
                end 
                -- SCALING
                left = left * self.xyscaleFactor 
                top = top * self.xyscaleFactor
                maxtoptv = maxtoptv * self.xyscaleFactor
                maxtopsv = maxtopsv * self.xyscaleFactor
                -- CENTERING
                xcentering_offset = 1920-DMGREPORT_size
                xcentering_offset = xcentering_offset/2
                left = left + xcentering_offset
                ycentering_offset = 1080-DMGREPORT_size
                ycentering_offset = ycentering_offset/2
                top = top + ycentering_offset + 50
                -- Top view x,y
                if maxtoptv < top then
                    maxtoptv = top
                end
                -- Creating dot 
                if elem_hp_percentage >= 100 then
                    top_pristine_dot_list = top_pristine_dot_list..[[<circle fill-opacity="]]..opacity..[[" cx="]]..left..[[" cy="]]..top..[[" r="]]..DMGREPORT_point_size..[[" fill="]]..color..[[" />]]
                elseif elem_hp_percentage >= 75 then
                    top_light_dot_list = top_light_dot_list..[[<circle fill-opacity="]]..opacity..[[" cx="]]..left..[[" cy="]]..top..[[" r="]]..DMGREPORT_point_size..[[" fill="]]..color..[[" />]]
                elseif elem_hp_percentage >= 50 then
                    top_medium_dot_list = top_medium_dot_list..[[<circle fill-opacity="]]..opacity..[[" cx="]]..left..[[" cy="]]..top..[[" r="]]..DMGREPORT_point_size..[[" fill="]]..color..[[" />]]
                elseif elem_hp_percentage > 0 then
                    top_high_dot_list = top_high_dot_list..[[<circle fill-opacity="]]..opacity..[[" cx="]]..left..[[" cy="]]..top..[[" r="]]..DMGREPORT_point_size..[[" fill="]]..color..[[" />]]
                else 
                    top_dead_dot_list = top_dead_dot_list..[[<circle fill-opacity="]]..opacity..[[" cx="]]..left..[[" cy="]]..top..[[" r="]]..DMGREPORT_point_size..[[" fill="]]..color..[[" />]]
                end   

                --top_view_html = top_view_html..[[<circle fill-opacity="]]..opacity..[[" cx="]]..left..[[" cy="]]..top..[[" r="]]..DMGREPORT_point_size..[[" fill="]]..color..[[" />]]
                -- Front view x,z
                if (elem.elem_pos_x>=self.min_x and elem.elem_pos_x<=0) and (elem.elem_pos_z>=0 and elem.elem_pos_z<=self.max_z) then    
                    -- 1
                    left = (self.min_x*-1) + elem.elem_pos_x
                    top = self.max_z - elem.elem_pos_z
                elseif (elem.elem_pos_x>0 and elem.elem_pos_x<=self.max_x) and (elem.elem_pos_z>=0 and elem.elem_pos_z<=self.max_z) then    
                    -- 2
                    left = (self.min_x*-1) + elem.elem_pos_x
                    top = self.max_z - elem.elem_pos_z
                elseif (elem.elem_pos_x>=self.min_x and elem.elem_pos_x<=0) and (elem.elem_pos_z>=self.min_z and elem.elem_pos_z<0) then    
                    -- 3
                    left = (self.min_x*-1) + elem.elem_pos_x
                    top = self.max_z + (elem.elem_pos_z*-1)
                elseif (elem.elem_pos_x>0 and elem.elem_pos_x<=self.max_x) and (elem.elem_pos_z>=self.min_z and elem.elem_pos_z<0) then    
                    -- 4
                    left = (self.min_x*-1) + elem.elem_pos_x
                    top = self.max_z + (elem.elem_pos_z*-1)
                end
                -- SCALING
                left = left * self.xzscaleFactor 
                top = top * self.xzscaleFactor
                maxtoptv = maxtoptv * self.xzscaleFactor
                maxtopsv = maxtopsv * self.xzscaleFactor
                -- CENTERING
                xcentering_offset = 1920-DMGREPORT_size
                xcentering_offset = xcentering_offset/2
                left = left + xcentering_offset
                ycentering_offset = 1080-DMGREPORT_size
                ycentering_offset = ycentering_offset/2
                top = top + ycentering_offset + 50
                if maxtopfv < top then
                    maxtopfv = top
                end

                -- Creating dot 
                if elem_hp_percentage >= 100 then
                    front_pristine_dot_list = front_pristine_dot_list..[[<circle fill-opacity="]]..opacity..[[" cx="]]..left..[[" cy="]]..top..[[" r="]]..DMGREPORT_point_size..[[" fill="]]..color..[[" />]]
                elseif elem_hp_percentage >= 75 then
                    front_light_dot_list = front_light_dot_list..[[<circle fill-opacity="]]..opacity..[[" cx="]]..left..[[" cy="]]..top..[[" r="]]..DMGREPORT_point_size..[[" fill="]]..color..[[" />]]
                elseif elem_hp_percentage >= 50 then
                    front_medium_dot_list = front_medium_dot_list..[[<circle fill-opacity="]]..opacity..[[" cx="]]..left..[[" cy="]]..top..[[" r="]]..DMGREPORT_point_size..[[" fill="]]..color..[[" />]]
                elseif elem_hp_percentage > 0 then
                    front_high_dot_list = front_high_dot_list..[[<circle fill-opacity="]]..opacity..[[" cx="]]..left..[[" cy="]]..top..[[" r="]]..DMGREPORT_point_size..[[" fill="]]..color..[[" />]]
                else 
                    front_dead_dot_list = front_dead_dot_list..[[<circle fill-opacity="]]..opacity..[[" cx="]]..left..[[" cy="]]..top..[[" r="]]..DMGREPORT_point_size..[[" fill="]]..color..[[" />]]
                end
                --front_view_html = front_view_html..[[<circle fill-opacity="]]..opacity..[[" cx="]]..left..[[" cy="]]..top..[[" r="]]..DMGREPORT_point_size..[[" fill="]]..color..[[" />]]
                -- Side view y,z
                if (elem.elem_pos_y>=self.min_y and elem.elem_pos_y<=0) and (elem.elem_pos_z>=0 and elem.elem_pos_z<=self.max_z) then    
                    -- 1
                    left = (self.min_y*-1) + elem.elem_pos_y
                    top = self.max_z - elem.elem_pos_z
                elseif (elem.elem_pos_y>0 and elem.elem_pos_y<=self.max_y) and (elem.elem_pos_z>=0 and elem.elem_pos_z<=self.max_z) then    
                    -- 2
                    left = (self.min_y*-1) + elem.elem_pos_y
                    top = self.max_z - elem.elem_pos_z
                elseif (elem.elem_pos_y>=self.min_y and elem.elem_pos_y<=0) and (elem.elem_pos_z>=self.min_z and elem.elem_pos_z<0) then    
                    -- 3
                    left = (self.min_y*-1) + elem.elem_pos_y
                    top = self.max_z + (elem.elem_pos_z*-1)
                elseif (elem.elem_pos_y>0 and elem.elem_pos_y<=self.max_y) and (elem.elem_pos_z>=self.min_z and elem.elem_pos_z<0) then    
                    -- 4
                    left = (self.min_y*-1) + elem.elem_pos_y
                    top = self.max_z + (elem.elem_pos_z*-1)
                end
                -- SCALING
                left = left * self.yzscaleFactor 
                top = top * self.yzscaleFactor
                maxtoptv = maxtoptv * self.yzscaleFactor
                maxtopsv = maxtopsv * self.yzscaleFactor
                -- CENTERING
                xcentering_offset = 1920-DMGREPORT_size
                xcentering_offset = xcentering_offset/2
                left = left + xcentering_offset
                ycentering_offset = 1080-DMGREPORT_size
                ycentering_offset = ycentering_offset/2
                top = top + ycentering_offset + 50
                if maxtopsv < top then
                    maxtopsv = top
                end 
                -- Creating dot 
                if elem_hp_percentage >= 100 then
                    side_pristine_dot_list = side_pristine_dot_list..[[<circle fill-opacity="]]..opacity..[[" cx="]]..left..[[" cy="]]..top..[[" r="]]..DMGREPORT_point_size..[[" fill="]]..color..[[" />]]
                elseif elem_hp_percentage >= 75 then
                    side_light_dot_list = side_light_dot_list..[[<circle fill-opacity="]]..opacity..[[" cx="]]..left..[[" cy="]]..top..[[" r="]]..DMGREPORT_point_size..[[" fill="]]..color..[[" />]]
                elseif elem_hp_percentage >= 50 then
                    side_medium_dot_list = side_medium_dot_list..[[<circle fill-opacity="]]..opacity..[[" cx="]]..left..[[" cy="]]..top..[[" r="]]..DMGREPORT_point_size..[[" fill="]]..color..[[" />]]
                elseif elem_hp_percentage > 0 then
                    side_high_dot_list = side_high_dot_list..[[<circle fill-opacity="]]..opacity..[[" cx="]]..left..[[" cy="]]..top..[[" r="]]..DMGREPORT_point_size..[[" fill="]]..color..[[" />]]
                else 
                    side_dead_dot_list = side_dead_dot_list..[[<circle fill-opacity="]]..opacity..[[" cx="]]..left..[[" cy="]]..top..[[" r="]]..DMGREPORT_point_size..[[" fill="]]..color..[[" />]]
                end   
                --side_view_html = side_view_html..[[<circle fill-opacity="]]..opacity..[[" cx="]]..left..[[" cy="]]..top..[[" r="]]..DMGREPORT_point_size..[[" fill="]]..color..[[" />]]
            end 
        end
        -- Text damage report
        --Adding filter label below
        local filter_label = "(ALL PARTS)"
        if self.elem_filter == 2 then
            filter_label = "(WP & AV ONLY)"
        elseif self.elem_filter == 3 then
            filter_label = "(AVIONICS ONLY)"
        elseif  self.elem_filter == 4 then
            filter_label = "(WEAPONS ONLY)"
        end
        -- Top view code x,y  
        top_view_html=[[<svg class="bootstrap" viewBox="0 0 1920 1080" style="width:100%; height:100%"><rect width="100%" height="100%" fill="#000000" /><rect fill="#f2933a" height="60" width="100%" y="-1" x="-1"/><text x="13" y="45" font-size="60" text-anchor='start' fill="white">Damage report : TOP ]]..filter_label..[[</text>]]..top_pristine_dot_list..top_light_dot_list..top_medium_dot_list..top_high_dot_list..top_dead_dot_list..[[</svg>]]
        -- front view code x,z
        front_view_html=[[<svg class="bootstrap" viewBox="0 0 1920 1080" style="width:100%; height:100%"><rect width="100%" height="100%" fill="#000000" /><rect fill="#f2933a" height="60" width="100%" y="-1" x="-1"/><text x="13" y="45" font-size="60" text-anchor='start' fill="white">Damage report : FRONT ]]..filter_label..[[</text>]]..front_pristine_dot_list..front_light_dot_list..front_medium_dot_list..front_high_dot_list..front_dead_dot_list..[[</svg>]]
        -- side view y,z
        side_view_html=[[<svg class="bootstrap" viewBox="0 0 1920 1080" style="width:100%; height:100%"><rect width="100%" height="100%" fill="#000000" /><rect fill="#f2933a" height="60" width="100%" y="-1" x="-1"/><text x="13" y="45" font-size="60" text-anchor='start' fill="white">Damage report : SIDE ]]..filter_label..[[</text>]]..side_pristine_dot_list..side_light_dot_list..side_medium_dot_list..side_high_dot_list..side_dead_dot_list..[[</svg>]]
        -- Table view
        table_view_html = table_view_html..[[<style>.cdiv{transform: rotate(-90deg);transform-origin: 50vh 50vh;} .cdiv table {width:100vh;} .cdiv table tr{height:4vh;font-size:4vh;font-weight:bold;} .pristine td {color: #9BFFAC;} .ldmg td {color: #FFDD8E;} .mdmg td {color: #FF9E66;} .hdmg td {color: #FF2819;} .dead td {color: #7F120C;}  .r {text-align:right;} </style><div class="cdiv"><table><tr style="background-color:#f2933a;color:white;font-weight:bold;"><td>Element type</td><td>Element name</td><td>Element HP</td></tr>]]..dead_elem_list..high_damage_list..medium_damage_list..light_damage_list..[[</table></div>]]
    end
    return {top_view_html,front_view_html,side_view_html,table_view_html}
end
