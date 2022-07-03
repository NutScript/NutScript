local PANEL = {}
local MODEL_ANGLE = Angle(0, 45, 0)

function PANEL:Init()
	self.brightness = 1

	self:SetCursor("none")
	self.OldSetModel = self.SetModel
	self.SetModel = function(self, model)
		self:OldSetModel(model)

		local entity = self.Entity

		if (not IsValid(entity)) then return end
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
		end

		entity:ResetSequence(4)
	end
end

local gui_MouseX = gui.MouseX
local gui_MouseY = gui.MouseY

function PANEL:LayoutEntity()
	local scrW, scrH = ScrW(), ScrH()
	local xRatio = gui_MouseX() / scrW
	local yRatio = gui_MouseY() / scrH
	local x, _ = self:LocalToScreen(self:GetWide() / 2)
	local xRatio2 = x / scrW
	local entity = self.Entity

	entity:SetPoseParameter("head_pitch", yRatio*90 - 30)
	entity:SetPoseParameter("head_yaw", (xRatio - xRatio2)*90 - 5)
	entity:SetAngles(MODEL_ANGLE)
	if entity:GetIK() then
		entity:SetIK(false)
	end

	if (self.copyLocalSequence) then
		local ply = LocalPlayer()
		entity:SetSequence(ply:GetSequence())
		entity:SetPoseParameter("move_yaw", 360 * ply:GetPoseParameter("move_yaw") - 180)
	end

	self:RunAnimation()
end

function PANEL:PreDrawModel(entity)
	if (self.brightness) then
		local brightness = self.brightness * 0.4
		local brightness2 = self.brightness * 1.5

		render.SetModelLighting(0, brightness2, brightness2, brightness2)

		for i = 1, 4 do
			render.SetModelLighting(i, brightness, brightness, brightness)
		end

		local fraction = (brightness / 1) * 0.1

		render.SetModelLighting(5, fraction, fraction, fraction)
	end

	if (self.enableHook) then
		hook.Run("DrawNutModelView", self, entity)
	end

	return true
end

function PANEL:OnMousePressed()
end

local math_abs = math.abs
local math_deg = math.deg
local math_atan = math.atan

function PANEL:fitFOV()
	local entity = self:GetEntity()
	if (not IsValid(entity)) then return end

	local mins, maxs = entity:GetRenderBounds()
	local height = math_abs(maxs.z) + math_abs(mins.z) + 8
	local distance = self:GetCamPos():Length()
	self:SetFOV(math_deg(2 * math_atan(height / (2 * distance))))
end
vgui.Register("nutModelPanel", PANEL, "DModelPanel")
