local PANEL = {}
local color_offWhite = Color(250, 250, 250)
local color_blackTransparent = Color(0,0,0,175)
local color_blackTransparent2 = Color(0,0,0,150)

local gradientD = nut.util.getMaterial("vgui/gradient-d")
local gradientR = nut.util.getMaterial("vgui/gradient-r")
local gradientL = nut.util.getMaterial("vgui/gradient-l")

function PANEL:Init()
	if (IsValid(nut.gui.quick)) then
		nut.gui.quick:Remove()
	end
	nut.gui.quick = self

	self:SetSize(400, 36)
	self:SetPos(ScrW() - 36, -36)
	self:MakePopup()
	self:SetKeyboardInputEnabled(false)
	self:SetZPos(999)
	self:SetMouseInputEnabled(true)

	self.title = self:Add("DLabel")
	self.title:SetTall(36)
	self.title:Dock(TOP)
	self.title:SetFont("nutMediumFont")
	self.title:SetText(L"quickSettings")
	self.title:SetContentAlignment(4)
	self.title:SetTextInset(44, 0)
	self.title:SetTextColor(nut.config.get("colorText", color_white))
	self.title:SetExpensiveShadow(1, color_blackTransparent)
	self.title.Paint = function(this, w, h)
		surface.SetDrawColor(nut.config.get("color"))
		surface.DrawRect(0, 0, w, h)
	end

	self.expand = self:Add("DButton")
	self.expand:SetContentAlignment(5)
	self.expand:SetText("`")
	self.expand:SetFont("nutIconsMedium")
	self.expand:SetPaintBackground(false)
	self.expand:SetTextColor(nut.config.get("colorText", color_white))
	self.expand:SetExpensiveShadow(1, color_blackTransparent2)
	self.expand:SetSize(36, 36)
	self.expand.DoClick = function(this)
		if (self.expanded) then
			self:SizeTo(self:GetWide(), 36, 0.15, nil, nil, function()
				self:MoveTo(ScrW() - 36, 30, 0.15)
			end)

			self.expanded = false
		else
			self:MoveTo(ScrW() - 400, 30, 0.15, nil, nil, function()
				local height = 0

				for k, v in pairs(self.items) do
					if (IsValid(v)) then
						height = height + v:GetTall() + 1
					end
				end

				height = math.min(height, ScrH() * 0.5)
				self:SizeTo(self:GetWide(), height, 0.15)
			end)

			self.expanded = true
		end
	end

	self.scroll = self:Add("DScrollPanel")
	self.scroll:SetPos(0, 36)
	self.scroll:SetSize(self:GetWide(), ScrH() * 0.5)

	self:MoveTo(self.x, 30, 0.05)

	self.items = {}

	hook.Run("SetupQuickMenu", self)
end

local function paintButton(button, w, h)
	local r, g, b = nut.config.get("color"):Unpack()
	local alpha = 100

	if (button.Depressed or button.m_bSelected) then
		alpha = 255
	elseif (button.Hovered) then
		alpha = 200
	end

--[[ 	surface.SetDrawColor(255, 255, 255, alpha)
	surface.DrawRect(0, 0, w, h) ]]
    surface.SetDrawColor(r, g, b, alpha)

    surface.SetMaterial(gradientR)
    surface.DrawTexturedRect(0, 0, w/2, h)
    surface.SetMaterial(gradientL)
    surface.DrawTexturedRect(w/2, 0, w/2, h)
end

local categoryDoClick = function(this)
	this.expanded = not this.expanded
	local items = nut.gui.quick.items
	local index = table.KeyFromValue(items, this)
	for i = index + 1, #items do
		if items[i].categoryLabel then
			break
		end
		if not items[i].h then
			items[i].w, items[i].h = items[i]:GetSize()
		end

		items[i]:SizeTo(items[i].w, this.expanded and (items[i].h or 36) or 0, 0.15)
	end
end

function PANEL:addCategory(text)
	local label = self:addButton(text, categoryDoClick)
	label.categoryLabel = true
	label.expanded = true
	label:SetText(text)
	label:SetTall(36)
	label:Dock(TOP)
	label:DockMargin(0, 1, 0, 0)
	label:SetFont("nutMediumFont")
	label:SetTextColor(nut.config.get("colorText", color_white))
	label:SetExpensiveShadow(1, color_blackTransparent2)
	label:SetContentAlignment(5)
	label.Paint = function() end
end

function PANEL:addButton(text, callback)
	local button = self.scroll:Add("DButton")
	button:SetText(text)
	button:SetTall(36)
	button:Dock(TOP)
	button:DockMargin(0, 1, 0, 0)
	button:SetFont("nutMediumLightFont")
	button:SetExpensiveShadow(1, color_blackTransparent2)
	button:SetContentAlignment(4)
	button:SetTextInset(8, 0)
	button:SetTextColor(nut.config.get("colorText", color_white))
	button.Paint = paintButton

	if (callback) then
		button.DoClick = callback
	end

	self.items[#self.items + 1] = button

	return button
end

function PANEL:addSpacer()
	local panel = self.scroll:Add("DPanel")
	panel:SetTall(1)
	panel:Dock(TOP)
	panel:DockMargin(0, 1, 0, 0)
	panel.Paint = function(this, w, h)
		surface.SetDrawColor(255, 255, 255, 10)
		surface.DrawRect(0, 0, w, h)
	end

	self.items[#self.items + 1] = panel

	return panel
end

function PANEL:addSlider(text, callback, value, min, max, decimal)
	local slider = self.scroll:Add("DNumSlider")
	slider:SetText(text)
	slider:SetTall(36)
	slider:Dock(TOP)
	slider:DockMargin(0, 1, 0, 0)
	slider:SetExpensiveShadow(1, Color(0, 0, 0, 150))
	slider:SetMin(min or 0)
	slider:SetMax(max or 100)
	slider:SetDecimals(decimal or 0)
	slider:SetValue(value or 0)

	slider.Label:SetFont("nutMediumLightFont")
	slider.Label:SetTextColor(nut.config.get("colorText", color_white))

	local textEntry = slider:GetTextArea()
	textEntry:SetFont("nutMediumLightFont")
	textEntry:SetTextColor(nut.config.get("colorText", color_white))

	if (callback) then
		slider.OnValueChanged = function(this, value)
			value = math.Round(value, decimal)
			callback(this, value)
		end
	end

	self.items[#self.items + 1] = slider

	slider.Paint = paintButton

	return slider
end

local color_dark = Color(255, 255, 255, 5)

function PANEL:addCheck(text, callback, checked)
	local x, y
	local color

	local button = self:addButton(text, function(panel)
		panel.checked = !panel.checked

		if (callback) then
			callback(panel, panel.checked)
		end
	end)
	button.PaintOver = function(this, w, h)
		x, y = w - 8, h * 0.5

		if (this.checked) then
			color = nut.config.get("color")
		else
			color = color_dark
		end

		draw.SimpleText(self.icon or "F", "nutIconsSmall", x, y, color, 2, 1)
	end
	button.checked = checked

	return button
end

function PANEL:setIcon(char)
	self.icon = char
end

function PANEL:Paint(w, h)
	surface.SetDrawColor(0, 0, 0, 200)
	surface.DrawRect(0, 0, w, h)
	nut.util.drawBlur(self)

	surface.SetDrawColor(nut.config.get("color"))
	surface.DrawRect(0, 0, w, 36)

	--[[ surface.SetDrawColor(255, 255, 255, 5)
	surface.DrawRect(0, 0, w, h) ]]
end
vgui.Register("nutQuick", PANEL, "EditablePanel")