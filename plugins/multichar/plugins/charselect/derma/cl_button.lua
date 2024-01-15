local PANEL = {}

function PANEL:Init()
	self:SetFont("nutCharButtonFont")
	self:SizeToContentsY()
	self:SetTextColor(nut.gui.character.color)
	self:SetPaintBackground(false)
end

function PANEL:OnCursorEntered()
	nut.gui.character:hoverSound()
	self:SetTextColor(nut.gui.character.colorHovered)
end

function PANEL:OnCursorExited()
	self:SetTextColor(nut.gui.character.color)
end

function PANEL:OnMousePressed()
	nut.gui.character:clickSound()
	DButton.OnMousePressed(self)
end

vgui.Register("nutCharButton", PANEL, "DButton")
