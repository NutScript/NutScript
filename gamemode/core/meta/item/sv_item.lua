local ITEM = nut.meta.item

-- Removes the item from the inventory it is in and then itself
function ITEM:removeFromInventory(preserveItem)
	local inventory = nut.inventory.instances[self.invID]
	self.invID = 0
	if (inventory) then
		return inventory:removeItem(self:getID(), preserveItem)
	end
	local d = deferred.new()
	d:resolve()
	return d
end

-- Deletes the data for this item.
function ITEM:delete()
	self:destroy()
	return nut.db.delete("items", "_itemID = "..self:getID())
		:next(function()
			self:onRemoved() -- Poorly named, should've been called onDeleted...
		end)
end

-- Permanently deletes this item instance and from the inventory it is in.
function ITEM:remove()
	local d = deferred.new()

	if (IsValid(self.entity)) then
		self.entity:Remove()
	end

	self:removeFromInventory()
		:next(function()
			d:resolve()
			return self:delete()
		end)

	return d
end

-- Deletes the in-memory data for this item
function ITEM:destroy()
	net.Start("nutItemDelete")
		net.WriteUInt(self:getID(), 32)
	net.Broadcast()
	nut.item.instances[self:getID()] = nil
	self:onDisposed()
end

-- Called when the item data has been cleaned up from memory.
function ITEM:onDisposed()
end

-- Returns the entity representing this item, if one exists.
function ITEM:getEntity()
	local id = self:getID()

	for k, v in ipairs(ents.FindByClass("nut_item")) do
		if (v.nutItemID == id) then
			return v
		end
	end
end

-- Spawn an item entity based off the item table.
function ITEM:spawn(position, angles)
	local instance = nut.item.instances[self.id]

	-- Check if the item has been created before.
	if (instance) then
		if (IsValid(instance.entity)) then
			instance.entity.nutIsSafe = true
			instance.entity:Remove()
		end

		local client

		-- If the first argument is a player, then we will find a position to drop
		-- the item based off their aim.
		if (type(position) == "Player") then
			client = position
			position = position:getItemDropPos()
		end

		-- Spawn the actual item entity.
		local entity = ents.Create("nut_item")
		entity:Spawn()
		entity:SetPos(position)
		entity:SetAngles(angles or Angle(0, 0, 0))
		-- Make the item represent this item.
		entity:setItem(self.id)
		instance.entity = entity

		if (IsValid(client)) then
			entity.nutSteamID = client:SteamID()
			entity.nutCharID = client:getChar():getID()
		end

		-- Return the newly created entity.
		return entity
	end
end

-- Called when an instance of this item has been created.
function ITEM:onInstanced(id)
end

-- Called when data for this item should be replicated to the recipient.
function ITEM:onSync(recipient)
end

-- Called when this item has been deleted permanently.
function ITEM:onRemoved()
end

--- Called when this item has been loaded from the database.
-- @param inventory The optional inventory an item was loaded with.
function ITEM:onRestored(inventory)
end

function ITEM:sync(recipient)
	net.Start("nutItemInstance")
		net.WriteUInt(self:getID(), 32)
		net.WriteString(self.uniqueID)
		net.WriteTable(self.data)
		net.WriteType(self.invID)
		net.WriteUInt(self.quantity, 32)
	if (recipient == nil) then
		net.Broadcast()
	else
		net.Send(recipient)
	end
	self:onSync(recipient)
end

function ITEM:setData(key, value, receivers, noSave, noCheckEntity)
	self.data = self.data or {}
	self.data[key] = value

	if (not noCheckEntity) then
		local ent = self:getEntity()
		if (IsValid(ent)) then
			ent:setNetVar("data", self.data)
		end
	end

	if (receivers or self:getOwner()) then
		netstream.Start(
			receivers or self:getOwner(),
			"invData",
			self:getID(),
			key,
			value
		)
	end

	if (noSave or not nut.db) then return end

	-- Legacy support for x, y data
	if (key == "x" or key == "y") then
		value = tonumber(value)
		if (MYSQLOO_PREPARED) then
			nut.db.preparedCall("item"..key, nil, value, self:getID())
		else
			nut.db.updateTable({
				["_"..key] = value
			}, nil, "items", "_itemID = "..self:getID())
		end
		return
	end

	-- Weird workaround, but essentially xy data should not be saved in the
	-- data column.
	local x, y = self.data.x, self.data.y
	self.data.x, self.data.y = nil, nil

	if (MYSQLOO_PREPARED) then
		nut.db.preparedCall("itemData", nil, self.data, self:getID())
	else
		nut.db.updateTable({
			_data = self.data
		}, nil, "items", "_itemID = "..self:getID())
	end

	self.data.x, self.data.y = x, y
end

function ITEM:addQuantity(quantity, receivers, noCheckEntity)
	self:setQuantity(self:getQuantity() + quantity, receivers, noCheckEntity)
end

function ITEM:setQuantity(quantity, receivers, noCheckEntity)
	self.quantity = quantity

	if (not noCheckEntity) then
		local ent = self:getEntity()

		if (IsValid(ent)) then
			ent:setNetVar("quantity", self.quantity)
		end
	end

	if (receivers or self:getOwner()) then
		netstream.Start(
			receivers or self:getOwner(),
			"invQuantity",
			self:getID(),
			self.quantity
		)
	end

	if (noSave or not nut.db) then return end

	-- Weird workaround, but essentially xy data should not be saved in the
	-- data column.
	if (MYSQLOO_PREPARED) then
		nut.db.preparedCall("itemq", nil, self.quantity, self:getID())
	else
		nut.db.updateTable({
			_quantity = self.quantity
		}, nil, "items", "_itemID = "..self:getID())
	end
end

function ITEM:interact(action, client, entity, data)
	assert(
		type(client) == "Player" and IsValid(client),
		"Item action cannot be performed without a player"
	)

	local canInteract, reason =
		hook.Run("CanPlayerInteractItem", client, action, self, data)
	if (canInteract == false) then
		if (reason) then
			client:notifyLocalized(reason)
		end

		return false
	end

	local oldPlayer, oldEntity = self.player, self.entity

	self.player = client
	self.entity = entity

	local callback = self.functions[action]
	if (not callback) then
		self.player = oldPlayer
		self.entity = oldEntity
		return false
	end

	canInteract = isfunction(callback.onCanRun)
		and not callback.onCanRun(self, data)
		or true
	if (not canInteract) then
		self.player = oldPlayer
		self.entity = oldEntity
		return false
	end

	local result
	-- TODO: better solution for hooking onto these - something like mixins?
	if (isfunction(self.hooks[action])) then
		result = self.hooks[action](self, data)
	end
	if (result == nil and isfunction(callback.onRun)) then
		result = callback.onRun(self, data)
	end
	if (self.postHooks[action]) then
		-- Posthooks shouldn't override the result from onRun
		self.postHooks[action](self, result, data)
	end
	hook.Run("OnPlayerInteractItem", client, action, self, result, data)

	if (result ~= false and not deferred.isPromise(result)) then
		if (IsValid(entity)) then
			entity:Remove()
		else
			self:remove()
		end
	end

	self.player = oldPlayer
	self.entity = oldEntity
	return true
end
