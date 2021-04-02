local PLUGIN = PLUGIN

PLUGIN.name = "Persistence"
PLUGIN.desc = "Saves persisted entities through restarts."
PLUGIN.author = "STEAM_0:0:50197118"

-- Storage for persisted map entities
PLUGIN.entities = PLUGIN.entities or {}

-- Entities which are blocked from interaction
PLUGIN.blacklist = PLUGIN.blacklist or {
  	[ "func_button" ] = true,
	[ "class C_BaseEntity" ] = true,
	[ "func_brush" ] = true,
	[ "func_tracktrain" ] = true,
	[ "func_door" ] = true,
	[ "func_door_rotating" ] = true,
	[ "prop_door_rotating" ] = true,
	[ "prop_static" ] = true,
	[ "prop_dynamic" ] = true,
	[ "prop_physics_override" ] = true,
}

properties.Add( "persist", {
	MenuLabel = "#makepersistent",
	Order = 400,
	MenuIcon = "icon16/link.png",

	Filter = function( self, ent, ply )

		if ( ent:IsPlayer() ) then return false end
		if ( PLUGIN.blacklist[ent:GetClass()] ) then return false end
		if ( not gamemode.Call( "CanProperty", ply, "persist", ent ) ) then return false end

		return not ent:getNetVar( "persistent", false )

	end,

	Action = function( self, ent )

		self:MsgStart()
			net.WriteEntity( ent )
		self:MsgEnd()

	end,

	Receive = function( self, length, ply )

		local ent = net.ReadEntity()
		if ( not IsValid( ent ) ) then return end
		if ( not self:Filter( ent, ply ) ) then return end

		ent:setNetVar( "persistent", true )

    -- Register the entity
		PLUGIN.entities[#PLUGIN.entities + 1] = ent

		-- Add new log
		nut.log.add(ply, "persistedEntity", ent )
	end

} )

properties.Add( "persist_end", {
	MenuLabel = "#stoppersisting",
	Order = 400,
	MenuIcon = "icon16/link_break.png",

	Filter = function( self, ent, ply )

		if ( ent:IsPlayer() ) then return false end
		if ( not gamemode.Call( "CanProperty", ply, "persist", ent ) ) then return false end

		return ent:getNetVar( "persistent", false )

	end,

	Action = function( self, ent )

		self:MsgStart()
			net.WriteEntity( ent )
		self:MsgEnd()

	end,

	Receive = function( self, length, ply )

		local ent = net.ReadEntity()
		if ( not IsValid( ent ) ) then return end
		if ( not properties.CanBeTargeted( ent, ply ) ) then return end
		if ( not self:Filter( ent, ply ) ) then return end
		ent:setNetVar( "persistent", false )

		-- Remove entity from registration
		for k, v in ipairs(PLUGIN.entities) do
			if (v == entity) then
				PLUGIN.entities[k] = nil

				break
			end
		end

		-- Add new log
		nut.log.add(ply, "unpersistedEntity", ent )
	end

} )

if (SERVER) then
	nut.log.addType("persistedEntity", function(client, entity)
		return string.format("%s has persisted '%s'.", client:Name(), entity)
	end)

	nut.log.addType("unpersistedEntity", function(client, entity)
		return string.format("%s has removed persistence from '%s'.", client:Name(), entity)
	end)

	-- Prevent from picking up persisted entities
	function PLUGIN:PhysgunPickup(client, entity)
		if (entity:getNetVar("persistent", false)) then
			return false
		end
	end

	function PLUGIN:SaveData()
		local data = {}

		for k, v in ipairs(self.entities) do
			if (IsValid(v)) then
				local entData = {}
				entData.class = v:GetClass()
				entData.pos = v:GetPos()
				entData.angles = v:GetAngles()
				entData.model = v:GetModel()
				entData.skin = v:GetSkin()
				entData.color = v:GetColor()
				entData.material = v:GetMaterial()
				entData.bodygroups = v:GetBodyGroups()

				local physicsObject = v:GetPhysicsObject()
				if (IsValid(physicsObject)) then
					entData.moveable = physicsObject:IsMoveable()
				end

				data[#data +1] = entData
			end
		end
		self:setData(data)
	end

	function PLUGIN:LoadData()
		for k, v in pairs(self:getData() or {}) do
			local ent = ents.Create(v.class)
			ent:SetPos(v.pos)
			ent:SetAngles(v.angles)
			ent:SetModel(v.model)
			ent:SetSkin(v.skin)
			ent:SetColor(v.color)
			ent:SetMaterial(v.material)
			ent:Spawn()
			ent:Activate()

			for _, data in pairs(v.bodygroups) do
				ent:SetBodygroup(data.id, data.num)
			end

			local physicsObject = ent:GetPhysicsObject()
			if (IsValid(physicsObject)) then
				physicsObject:EnableMotion(ent.moveable or false)
			end

			ent:setNetVar("persistent", true)

			self.entities[#self.entities + 1] = ent
		end
	end
end
