local PANEL = {}
	local MODEL_ANGLE = Angle(0, 45, 0)

	function PANEL:Init()
		self:setHidden(false)

		for i = 0, 5 do
			if (i == 1 or i == 5) then
				self:SetDirectionalLight(i, Color(155, 155, 155))
			else
				self:SetDirectionalLight(i, Color(255, 255, 255))
			end
		end

		self.OldSetModel = self.SetModel
		self.SetModel = function(self, model, skin, hidden)
			self:OldSetModel(model)

			local entity = self.Entity

			if (skin) then
				entity:SetSkin(skin)
			end

			local sequence = entity:SelectWeightedSequence(ACT_IDLE)

			if (sequence <= 0) then
				sequence = entity:LookupSequence("idle_unarmed")
			end

			if (sequence > 0) then
				entity:ResetSequence(sequence)
			else
				local found = false

				for k, v in ipairs(entity:GetSequenceList()) do
					if ((v:lower():find("idle") or v:lower():find("fly")) and v ~= "idlenoise") then
						entity:ResetSequence(v)
						found = true

						break
					end
				end

				if (!found) then
					entity:ResetSequence(4)
				end
			end

			local data = PositionSpawnIcon(entity, entity:GetPos())

			if (data) then
				self:SetFOV(data.fov)
				self:SetCamPos(data.origin)
				self:SetLookAng(data.angles)
			end

			entity:SetIK(false)
			entity:SetEyeTarget(Vector(0, 0, 64))
		end
	end

	function PANEL:setHidden(hidden)
		if (hidden) then
			self:SetAmbientLight(color_black)
			self:SetColor(Color(0, 0, 0))

			for i = 0, 5 do
				self:SetDirectionalLight(i, color_black)
			end
		else
			self:SetAmbientLight(Color(20, 20, 20))
			self:SetAlpha(255)
			self:SetColor(Color(255, 255, 255))

			for i = 0, 5 do
				if (i == 1 or i == 5) then
					self:SetDirectionalLight(i, Color(155, 155, 155))
				else
					self:SetDirectionalLight(i, Color(255, 255, 255))
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
