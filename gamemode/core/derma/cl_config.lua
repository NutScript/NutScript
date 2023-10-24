local gradientD = nut.util.getMaterial("vgui/gradient-d")
local gradientR = nut.util.getMaterial("vgui/gradient-r")
local gradientL = nut.util.getMaterial("vgui/gradient-l")

-- Originally, the plan was to allow both serverside configs and clientside quick settings to be editable here. However, I've decided to keep them separate for now.
-- I do not wish to break the quick menu, nor use ugly hacks.
-- if you wish to change it, then complete populateConfig.client, and at the bottom, uncomment self.selectPanel = self:Add("NutConfigSelectPanel") to show the server/client buttons
-- Tov

local populateConfig = {
    server = function(panel)
        local buffer = {}

        for k, v in pairs(nut.config.stored) do
            -- Get the category name.
            local index = v.data and v.data.category or "misc"

            -- Insert the config into the category list.
            buffer[index] = buffer[index] or {}
            buffer[index][k] = v
        end

        panel.data = buffer
    end,
    client = function(panel)
    end,
}

local serverIcon, clientIcon, check, uncheck
-- wait until icons are loaded, then load icons
hook.Add("EasyIconsLoaded", "nutConfigIcons", function()
	serverIcon = getIcon("icon-equalizer")
	clientIcon = getIcon("icon-child")
	check = getIcon("icon-ok-squared")
	uncheck = getIcon("icon-check-empty")
end)

local PANEL = {}

function PANEL:Init()
    self:SetSize(100, 0)
    self:DockMargin(0, 0, 0, 0)
    self:Dock(LEFT)
    self:InvalidateLayout(true)

    local parent = self:GetParent()

    print(parent, nut.gui.config, nut.gui.config == parent)
    print(parent.populateConfigs)

    self:createConfigButton(serverIcon, "Server", function()
        local config = parent.configListPanel
        populateConfig.server(config)
        config:InvalidateChildren(true)
        config:populateConfigs()
    end)

    self:createConfigButton(clientIcon, "Client", function()
        local config = parent.configListPanel
        populateConfig.client(config)
        config:InvalidateChildren(true)
        config:populateConfigs()
    end)
end

function PANEL:createConfigButton(icon, name, func)
    local button = self:Add("DButton")
    button:Dock(TOP)
    button:DockMargin(0, 0, 0, 0)
    button:SetSize(self:GetWide(), 30)
    button:SetText("")

    local icon_label = button:Add("DLabel")
    icon_label:Dock(LEFT)
    icon_label:DockMargin(0, 0, 0, 0)
    icon_label:SetSize(30, 30)
    icon_label:SetText("")
    icon_label.Paint = function(_, w, h)
        nut.util.drawText(icon, w * 0.5, h * 0.5, color_white, 1, 1, "nutIconsSmallNew")
    end

    local text_label = button:Add("DLabel")
    text_label:SetText(name)
    text_label:SetContentAlignment(5)
    text_label:SetFont("nutMediumConfigFont")
    text_label:Dock(FILL)
    text_label:DockMargin(0, 0, 0, 0)

    button.DoClick = function()
        self:GetParent():ClearConfigs()
        func()
    end

    return button
end

function PANEL:Paint() end

vgui.Register("NutConfigSelectPanel", PANEL, "DPanel")

-- the center panel, listing all the configs
PANEL = {}

function PANEL:Init()
    self:Dock(FILL)
    self:InvalidateParent(true)

    hook.Run("CreateConfigPanel", self)

    -- a dTextEntry that will filter the list of configs
    self.filter = self:Add("DTextEntry")
    self.filter:Dock(TOP)
    self.filter:DockMargin(0, 0, 0, 0)
    self.filter:SetSize(self:GetWide(), 30)
    self.filter:SetPlaceholderText("Filter configs")
    self.filter:SetUpdateOnType(true)
    self.filter.OnChange = function()
        self:filterConfigs(self.filter:GetValue())
    end

    -- a dScrollPanel that will contain the list of configs
    self.scroll = self:Add("DScrollPanel")
    self.scroll:Dock(FILL)
    self.scroll.Paint = function() end

    populateConfig.server(self)

    self:InvalidateChildren(true)

    self:populateConfigs()
end

local paintFunc = function(panel, w, h)
    local r, g, b = nut.config.get("color"):Unpack()
    surface.SetDrawColor(r, g, b, 255)

    surface.SetMaterial(gradientR)
    surface.DrawTexturedRect(0, 0, w/2, h)
    surface.SetMaterial(gradientL)
    surface.DrawTexturedRect(w/2, 0, w/2, h)

end

local mathRound, mathFloor = math.Round, math.floor
local labelSpacing = 0.25

local configElement = {
    Int = function(name, config, parent)
        local panel = vgui.Create("DNumSlider")
        panel:SetSize(parent:GetWide(), 30)
        panel:InvalidateChildren(true)

        panel:SetMin(config.data.data and config.data.data.min or 0)
        panel:SetMax(config.data.data and config.data.data.max or 1)
        panel:SetDecimals(0)
        panel:SetValue(config.value)
        panel:SetText(name)
        panel.TextArea:SetFont("nutConfigFont")
        panel.Label:SetFont("nutConfigFont")
        panel.Label:SetTextInset(10, 0)
        panel.OnValueChanged = function(_, newValue)
            timer.Create("nutConfigChange"..name, 1, 1, function() netstream.Start("cfgSet", name, mathFloor(newValue)) end)
        end

        panel.Paint = function(this, w, h)
            paintFunc(this, w, h)
        end

        panel.PerformLayout = function(this)
            this.Label:SetWide( parent:GetWide() * labelSpacing )
        end

        -- prevent right click from triggering default behaviour when we want to reset
        local oldMousePressed = panel.Scratch.OnMousePressed
        panel.Scratch.OnMousePressed = function(this, code)
            if code ~= MOUSE_RIGHT then
                oldMousePressed(this, code)
            end
        end

        return panel
    end,
    Float = function(name, config, parent)
        local panel = vgui.Create("DNumSlider")
        panel:SetSize(parent:GetWide(), 30)
        panel:InvalidateChildren(true)

        panel:SetMin(config.data.data and config.data.data.min or 0)
        panel:SetMax(config.data.data and config.data.data.max or 1)
        panel:SetDecimals(2)
        panel:SetValue(config.value)
        panel:SetText(name)
        panel.TextArea:SetFont("nutConfigFont")
        panel.Label:SetFont("nutConfigFont")
        panel.Label:SetTextInset(10, 0)
        panel.OnValueChanged = function(_, newValue)
           timer.Create("nutConfigChange"..name, 1, 1, function() netstream.Start("cfgSet", name, mathRound(newValue, 2)) end)
        end

        panel.Paint = function(this, w, h)
            paintFunc(this, w, h)
        end

        panel.PerformLayout = function(this)
            this.Label:SetWide( parent:GetWide() * labelSpacing )
        end

        -- prevent right click from triggering default behaviour when we want to reset
        local oldMousePressed = panel.Scratch.OnMousePressed
        panel.Scratch.OnMousePressed = function(this, code)
            if code ~= MOUSE_RIGHT then
                oldMousePressed(this, code)
            end
        end

        return panel
    end,
    Generic = function(name, config, parent)
        local panel = vgui.Create("DPanel")
        panel:SetSize(parent:GetWide(), 30)
        panel:SetTall(30)

        -- draw the label over the entry, docked to the left
        local label = panel:Add("DLabel")
        label:Dock(LEFT)
        label:DockMargin(0, 0, 0, 0)
        label:SetWide(panel:GetWide() * labelSpacing)
        label:SetText(name)
        label:SetFont("nutConfigFont")
        label:SetContentAlignment(4)
        label:SetTextInset(10, 0)

        local entry = panel:Add("DTextEntry")
        entry:Dock(FILL)
        entry:DockMargin(0, 0, 0, 0)
        entry:SetText(tostring(config.value))
        entry.OnValueChange = function(_, newValue)
            netstream.Start("cfgSet", name, newValue)
        end
        entry.OnLoseFocus = function(this)
            timer.Simple(0, function() this:SetText(tostring(config.value)) end)
        end

        panel.SetValue = function(this, value) -- for compatibility
            entry:SetText(tostring(value))
        end

        panel.Paint = function(this, w, h)
            paintFunc(this, w, h)
        end

        return panel
    end,
    Boolean = function(name, config, parent)
        local panel = vgui.Create("DPanel")
        panel:SetSize(parent:GetWide(), 30)
        panel:SetTall(30)

        local button = panel:Add("DButton")
        button:Dock(FILL)
        button:DockMargin(0, 0, 0, 0)
        button:SetText("")
        button.Paint = function(_, w, h)
            nut.util.drawText(config.value and check or uncheck, w * 0.5, h * 0.5, color_white, 1, 1, "nutIconsSmallNew")
        end
        button.DoClick = function()
            netstream.Start("cfgSet", name, not config.value)
        end

        local label = button:Add("DLabel")
        label:Dock(LEFT)
        label:DockMargin(0, 0, 0, 0)
        label:SetWide(parent:GetWide())
        label:SetText(name)
        label:SetFont("nutConfigFont")
        label:SetContentAlignment(4)
        label:SetTextInset(10, 0)

        panel.Paint = function(this, w, h)
            paintFunc(this, w, h)
        end

        return panel

    end,
    Color = function(name, config, parent)
        local panel = vgui.Create("DPanel")
        panel:SetSize(parent:GetWide(), 30)
        panel:SetTall(30)

        local button = panel:Add("DButton")
        button:Dock(FILL)
        button:DockMargin(0, 0, 0, 0)
        button:SetText("")
        button.Paint = function(_, w, h)
            draw.RoundedBox(4, w/2 - 9, h/2 - 9, 18, 18, config.value)
            nut.util.drawText(config.value.r .. " " .. config.value.g .. " " .. config.value.b, w/2 + 18, h/2, nut.config.get("colorText"), 0, 1, "nutConfigFont")
        end
        button.DoClick = function(this)

            local pickerFrame = this:Add("DFrame")

            pickerFrame:SetSize(ScrW()*0.15, ScrH()*0.2) 	-- Good size for example
            pickerFrame:SetPos(gui.MouseX(), gui.MouseY())
            pickerFrame:MakePopup()

            if IsValid(button.picker) then button.picker:Remove() end
            button.picker = pickerFrame

            local Mixer = pickerFrame:Add( "DColorMixer")
            Mixer:Dock(FILL)					-- Make Mixer fill place of Frame
            Mixer:SetPalette(true)  			-- Show/hide the palette 				DEF:true
            Mixer:SetAlphaBar(true) 			-- Show/hide the alpha bar 				DEF:true
            Mixer:SetWangs(true) 				-- Show/hide the R G B A indicators 	DEF:true
            Mixer:SetColor(config.value) 	-- Set the default color
            pickerFrame.curColor = config.value

            local confirm = pickerFrame:Add("DButton")
            confirm:Dock(BOTTOM)
            confirm:DockMargin(0, 0, 0, 0)
            confirm:SetText("Apply")
            confirm:SetTextColor(pickerFrame.curColor)
            confirm.DoClick = function()
                netstream.Start("cfgSet", name, pickerFrame.curColor)
                pickerFrame:Remove()
            end

            Mixer.ValueChanged = function(_, value)
                pickerFrame.curColor = value
                confirm:SetTextColor(value)
            end
        end

        local label = button:Add("DLabel")
        label:Dock(LEFT)
        label:SetWide(parent:GetWide())
        label:SetText(name)
        label:SetFont("nutConfigFont")
        label:SetContentAlignment(4)
        label:SetTextInset(10, 0)

        panel.Paint = function(this, w, h)
            paintFunc(this, w, h)
        end

        return panel
    end,
    Combo = function(name, config, parent)
        -- a DTextEntry with a label on the left
        local panel = vgui.Create("DPanel")
        panel:SetSize(parent:GetWide(), 30)
        panel:SetTall(30)

        -- draw the label over the entry, docked to the left
        local label = panel:Add("DLabel")
        label:Dock(LEFT)
        label:DockMargin(0, 0, 0, 0)
        label:SetWide(panel:GetWide() * labelSpacing)
        label:SetText(name)
        label:SetFont("nutConfigFont")
        label:SetContentAlignment(4)
        label:SetTextInset(10, 0)

        local combo = panel:Add("DComboBox")
        combo:Dock(FILL)
        combo:DockMargin(0, 0, 0, 0)
        combo:SetSortItems(false)
        combo:SetValue(tostring(config.value))
        combo.OnSelect = function(_, index, value)
            netstream.Start("cfgSet", name, value)
        end

        for _, v in ipairs(config.data.options) do
            combo:AddChoice(v)
        end

        panel.Paint = function(this, w, h)
            paintFunc(this, w, h)
        end

        panel.SetValue = function(this, value) -- for compatibility
            combo:SetValue(tostring(value))
        end

        return panel

    end,
}

local function typeConvert(value)
    local t = type(value)
    if t == "boolean" then
        return "Boolean"
    elseif t == "number" then
        if math.floor(value) == value then
            return "Int"
        else
            return "Float"
        end
    elseif t == "table" and value.r and value.g and value.b then
        return "Color"
    end
    return "Generic"
end

function PANEL:populateConfigs()
    local sorted = {}
    self.entries = {}
    self.categories = {}

    if not self.data then return end

    for k in pairs(self.data) do
        table.insert(sorted, k)
    end

    -- sort alphabetically, case insensitive
    table.sort(sorted, function(a, b)
        return a:lower() < b:lower()
    end)

    self:InvalidateLayout(true)


    for _, category in ipairs(sorted) do
        local panel = self.scroll:Add("DPanel")
        panel:Dock(TOP)
        panel:DockMargin(0,1,0,4)
        panel:DockPadding(0,0,0,10)
        panel:SetSize(self:GetWide(), 30)
        panel:SetPaintBackground(false)
        panel.category = category

        local label = panel:Add("DLabel")
        label:Dock(TOP)
        label:DockMargin(1, 1, 1, 4)
        label:SetSize(self:GetWide(), 30)
        label:SetFont("nutMediumConfigFont")
        label:SetContentAlignment(5)
        label:SetText(category:gsub("^%l", string.upper))

        for name, config in SortedPairs(self.data[category]) do
            local form = config.data and config.data.form
            local value = config.default
            if not form then form = typeConvert(value) end
            local entry = panel:Add(configElement[form or "Generic"](name, config, panel))
            entry:Dock(TOP)
            entry:DockMargin(0, 1, 5, 2)
            entry:SetTooltip(config.desc)
            entry.shown = true
            entry.name = name
            entry.config = config

            table.insert(self.entries, entry)
        end
        panel:SizeToChildren(false, true)

        table.insert(self.categories, panel)
    end
end

local function requestReset(panel)
    if panel.name and panel.config then
        -- a query to reset config to default
        Derma_Query("Reset " .. panel.name .. " to default? ("..tostring(panel.config.default)..")", "Reset Config", "Yes", function()
            netstream.Start("cfgSet", panel.name, panel.config.default or nil)
            if panel.SetValue then panel:SetValue(panel.config.default) end
        end, "No")
    end
    if panel:GetParent() then
        requestReset(panel:GetParent())
    end
end

hook.Add("VGUIMousePressed", "nutConfigReset", function(panel, code)
    -- if the panel or any children, recursively, have .name and .config, reset it to default
    if code == MOUSE_RIGHT then requestReset(panel) end
end)

local animTime = 0.3

function PANEL:filterConfigs(filter)
    filter = filter:lower()
    for _, entry in ipairs(self.entries) do
        if not (entry.wide and entry.tall) then
            entry.wide, entry.tall = entry:GetSize()
        end
        local text = entry.name:lower()
        local category = entry.config.data.category:lower()
        local description = entry.config.desc:lower()

        if filter == "" or string.find(text, filter) or string.find(category, filter) or string.find(description, filter) then
            if not entry.shown then
                entry:SetVisible(true)
                entry.shown = true
                entry:SizeTo(entry.wide, entry.tall, animTime, 0, -1, function()

                end)
            end
        else
            if entry.shown then
                entry:SizeTo(entry.wide, 0, animTime, 0, -1, function()
                    entry:SetVisible(false)
                    entry.shown = false
                end)
            end
        end
    end
end

function PANEL:Think()
    for _, category in ipairs(self.categories) do
        local shown = false

        for _, entry in ipairs(self.entries) do
            if entry.shown and entry.config.data.category:lower() == category.category:lower() then
                shown = true
                break
            end
        end

        if shown then
            category:SetVisible(true)
            category:SizeToChildren(false, true)
        else
            category:SetVisible(false)
            category:SetTall(0)
        end
    end
    self.scroll:InvalidateLayout(true)
    self.scroll:SizeToChildren(false, true)
end

function PANEL:Paint() end

vgui.Register("NutConfigListPanel", PANEL, "DPanel")

-- the master panel, containing the left and center panels
PANEL = {}

function PANEL:Init()
    if nut.gui.config then
        nut.gui.config:Remove()
    end

    nut.gui.config = self

    self:InvalidateLayout(true)
end

function PANEL:ClearConfigs()
    if self.scroll then self.scroll:Clear() end
end

function PANEL:AddElements()
    --self.selectPanel = self:Add("NutConfigSelectPanel")
    self.configListPanel = self:Add("NutConfigListPanel")
end

local sin = math.sin

function PANEL:Paint(w, h)
    local colorR, colorG, colorB = nut.config.get("color"):Unpack()
    local backgroundR, backgroundG, backgroundB = nut.config.get("colorBackground"):Unpack()
    nut.util.drawBlur(self, 10)

    if not self.startTime then self.startTime = CurTime() end

	local curTime = (self.startTime - CurTime())/4
	local alpha = 200 * ((sin(curTime - 1.8719) + sin(curTime - 1.8719/2))/4 + 0.44)

    surface.SetDrawColor(colorR, colorG, colorB, alpha)
    surface.DrawRect(0, 0, w, h)

    surface.SetDrawColor(backgroundR, backgroundG, backgroundB, 255)
    surface.SetMaterial(gradientD)
    surface.DrawTexturedRect(0, 0, w, h)
    surface.SetMaterial(gradientR)
    surface.DrawTexturedRect(0, 0, w, h)

--[[     local WebMaterial = surface.GetURL("https://i.redd.it/9tgk6up2ltb11.jpg", w, h)
    surface.SetDrawColor( 255, 255, 255, 255 )
    surface.SetMaterial( WebMaterial )
    surface.DrawTexturedRect( 0, 0, WebMaterial:Width(), WebMaterial:Height() ) ]]
    --lmao
end

vgui.Register("NutConfigPanel", PANEL, "DPanel")
