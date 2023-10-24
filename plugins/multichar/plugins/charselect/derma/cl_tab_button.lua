local PANEL = {}

function PANEL:Init()
	local alignment = nut.config.get("charMenuAlignment", "center")
	self:Dock(alignment == "right" and RIGHT or LEFT)
	self:DockMargin(0, 0, 32, 0)
	self:SetContentAlignment(4)
end

function PANEL:setText(name)
	self:SetText(L(name):upper())
	self:InvalidateLayout(true)
	self:SizeToContentsX()
end

function PANEL:onSelected(callback)
	self.callback = callback
end

function PANEL:setSelected(isSelected)
	if (isSelected == nil) then isSelected = true end
	if (isSelected and self.isSelected) then return end

	local menu = nut.gui.character
	if (isSelected and IsValid(menu)) then
		if (IsValid(menu.lastTab)) then
			menu.lastTab:SetTextColor(nut.gui.character.color)
			menu.lastTab.isSelected = false
		end
		menu.lastTab = self
	end

	self:SetTextColor(
		isSelected
		and nut.gui.character.colorSelected
		or nut.gui.character.color
	)
	self.isSelected = isSelected
	if (isfunction(self.callback)) then
		self:callback()
	end
end

local gradientR = nut.util.getMaterial("vgui/gradient-r")
local gradientL = nut.util.getMaterial("vgui/gradient-l")

function PANEL:Paint(w, h)
	if (self.isSelected or self:IsHovered()) then
		local r, g, b = nut.config.get("color"):Unpack()
--[[ 		surface.SetDrawColor(
			self.isSelected
			and nut.gui.character.WHITE
			or nut.gui.character.HOVERED
		) ]]
		if (self.isSelected) then
			surface.SetDrawColor(r, g, b, 200)
		else
			surface.SetDrawColor(r, g, b, 100)
		end
		surface.SetMaterial(gradientR)
		surface.DrawTexturedRect(0, h-4, w/2, 4)

		surface.SetMaterial(gradientL)
		surface.DrawTexturedRect(w/2, h-4, w/2, 4)
		--surface.DrawRect(0, h - 4, w, 4)
	end
end

vgui.Register("nutCharacterTabButton", PANEL, "nutCharButton")
