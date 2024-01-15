local PANEL = {}
local color = Color(0, 0, 0, 255)
local colorSelected = Color(0, 0, 0, 255)
local colorHovered = Color(0, 0, 0, 255)

function PANEL:Init()
	self:SetFont("nutMenuButtonLightFont")
	self:SetExpensiveShadow(2, Color(0, 0, 0, 200))
	self:SetPaintBackground(false)
	self.OldSetTextColor = self.SetTextColor
	self.SetTextColor = function(this, color)
		this:OldSetTextColor(color)
		this:SetFGColor(color)
	end

	local nscolor = table.Copy(nut.config.get("colorText", color_white))
	color.r, color.g, color.b = nscolor.r - 30, nscolor.g - 30, nscolor.b - 30
	colorHovered.r, colorHovered.g, colorHovered.b = nscolor.r - 15, nscolor.g - 15, nscolor.b - 15
	colorSelected.r, colorSelected.g, colorSelected.b = nscolor.r, nscolor.g, nscolor.b
	self.color, self.colorHovered, self.colorSelected = color, colorHovered, colorSelected

	self:SetTextColor(self.active and self.colorSelected or self.color)
end

function PANEL:setText(text, noTranslation)
	self:SetText("")
	text = noTranslation and text or L(text)
	self:SetText(text)
end

function PANEL:OnCursorEntered()
	self:SetTextColor(self.colorHovered)
	surface.PlaySound(SOUND_MENU_BUTTON_ROLLOVER)
end

function PANEL:OnCursorExited()
	self:SetTextColor(self.active and self.colorSelected or self.color)
end

function PANEL:OnMousePressed(code)

	self:SetTextColor(self.colorSelected)

	surface.PlaySound(SOUND_MENU_BUTTON_PRESSED)

	if (code == MOUSE_LEFT and self.DoClick) then
		self:DoClick(self)
	end
end

function PANEL:OnMouseReleased(key)
	self:SetTextColor(self.active and self.colorSelected or self.color)
end

function PANEL:setActive(active)
	self.active = active
	self:SetFont(active and "nutMenuButtonFont" or "nutMenuButtonLightFont")
	self:SetTextColor(self.active and self.colorSelected or self.color)
end

vgui.Register("nutMenuButton", PANEL, "DButton")