local PANEL = {}


local setSequence = function(entity)
	// This code is duplicated from cl_modelpanel.lua
	local sequence = entity:SelectWeightedSequence(ACT_IDLE)

	if (sequence <= 0) then
		sequence = entity:LookupSequence("idle_unarmed")
	end

	entity:SetIK(false)

	if (sequence > 0) then
		entity:ResetSequence(sequence)
		return
	end

	for _, seqName in ipairs(entity:GetSequenceList()) do
		local seqNameLower = seqName:lower()
		if seqNameLower == "idlenoise" then continue end
		if not (seqNameLower:find("idle") or seqNameLower:find("fly")) then continue end

		entity:ResetSequence(seqName)
		return
	end

	entity:ResetSequence(4)
end

local color_grey = Color(155, 155 ,155)
local color_darkgrey = Color(20, 20, 20)

function PANEL:Init()
	self:setHidden(false)

	for i = 0, 5 do
		if (i == 1 or i == 5) then
			self:SetDirectionalLight(i, color_grey)
		else
			self:SetDirectionalLight(i, color_white)
		end
	end

	self.OldSetModel = self.SetModel
	self.SetModel = function(self, model, skin, hidden)
		self:OldSetModel(model)

		local entity = self.Entity

		if (skin) then
			entity:SetSkin(skin)
		end

		setSequence(entity)

		local data = PositionSpawnIcon(entity, entity:GetPos())

		if (data) then
			self:SetFOV(data.fov)
			self:SetCamPos(data.origin)
			self:SetLookAng(data.angles)
		end

		entity:SetEyeTarget(Vector(0, 0, 64))
	end
end

function PANEL:setHidden(hidden)
	if (hidden) then
		self:SetAmbientLight(color_black)
		self:SetColor(color_black)

		for i = 0, 5 do
			self:SetDirectionalLight(i, color_black)
		end
	else
		self:SetAmbientLight(color_darkgrey)
		self:SetAlpha(255)
		self:SetColor(color_white)

		for i = 0, 5 do
			if (i == 1 or i == 5) then
				self:SetDirectionalLight(i, color_grey)
			else
				self:SetDirectionalLight(i, color_white)
			end
		end
	end
end

function PANEL:LayoutEntity()
	self:RunAnimation()
end

function PANEL:OnMousePressed()
	if (self.DoClick) then
		self:DoClick()
	end
end
vgui.Register("nutSpawnIcon", PANEL, "DModelPanel")
