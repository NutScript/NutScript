NS_ICON_SIZE = 64

-- The queue for the rendered icons.
renderedIcons = renderedIcons or {}

-- To make making inventory variant, This must be followed up.
function renderNewIcon(panel, itemTable)
	-- re-render icons
	if ((itemTable.iconCam and not renderedIcons[string.lower(itemTable.model)]) or itemTable.forceRender) then
		local iconCam = itemTable.iconCam
		iconCam = {
			cam_pos = iconCam.pos,
			cam_ang = iconCam.ang,
			cam_fov = iconCam.fov,
		}
		renderedIcons[string.lower(itemTable.model)] = true

		panel.Icon:RebuildSpawnIconEx(
			iconCam
		)
	end
end

local function drawIcon(mat, self, x, y)
	surface.SetDrawColor(color_white)
	surface.SetMaterial(mat)
	surface.DrawTexturedRect(0, 0, x, y)
end

local PANEL = {}

function PANEL:setItemType(itemTypeOrID)
	local item = nut.item.list[itemTypeOrID]
	if (isnumber(itemTypeOrID)) then
		item = nut.item.instances[itemTypeOrID]
		self.itemID = itemTypeOrID
	else
		self.itemType = itemTypeOrID
	end
	assert(item, "invalid item type or ID "..tostring(item))

	self.nutToolTip = true
	self.itemTable = item
	self:SetModel(item:getModel(), item:getSkin())
	self:updateTooltip()

	if (item.exRender) then
		self.Icon:SetVisible(false)
		self.ExtraPaint = function(self, x, y)
			local paintFunc = item.paintIcon

			if (paintFunc and type(paintFunc) == "function") then
				paintFunc(item, self)
			else
				local exIcon = ikon:getIcon(item.uniqueID)
				if (exIcon) then
					surface.SetMaterial(exIcon)
					surface.SetDrawColor(color_white)
					surface.DrawTexturedRect(0, 0, x, y)
				else
					ikon:renderIcon(
						item.uniqueID,
						item.width,
						item.height,
						item.model,
						item.iconCam
					)
				end
			end
		end
	elseif (item.icon) then
		self.Icon:SetVisible(false)
		self.ExtraPaint = function(self, w, h)
			drawIcon(item.icon, self, w, h)
		end
	else
		renderNewIcon(self, item)
	end
end

function PANEL:updateTooltip()
	self:SetTooltip(
		"<font=nutItemBoldFont>"..self.itemTable:getName().."</font>\n"..
		"<font=nutItemDescFont>"..self.itemTable:getDesc()
	)
end

function PANEL:getItem()
	return self.itemTable
end

-- Updates the parts of the UI that could be changed by data changes.
function PANEL:ItemDataChanged(key, oldValue, newValue)
	self:updateTooltip()
end

function PANEL:Init()
	self:Droppable("inv")
	self:SetSize(NS_ICON_SIZE, NS_ICON_SIZE)
end

--[[ function PANEL:Think()
	self.itemTable = nut.item.instances[self.itemID]
	self:updateTooltip()
end ]]

function PANEL:PaintOver(w, h)
	local itemTable = nut.item.instances[self.itemID]
	if (itemTable and itemTable.paintOver) then
		local w, h = self:GetSize()

		itemTable.paintOver(self, itemTable, w, h)
	end

	hook.Run("ItemPaintOver", self, itemTable, w, h)
end

function PANEL:PaintBehind(w, h)
	surface.SetDrawColor(0, 0, 0, 85)
	surface.DrawRect(2, 2, w - 4, h - 4)
end

function PANEL:ExtraPaint(w, h)
end

function PANEL:Paint(w, h)
	self:PaintBehind(w, h)
	self:ExtraPaint(w, h)
end

local buildActionFunc = function(action, actionIndex, itemTable, invID, sub)
	return function()
		itemTable.player = LocalPlayer()
		local send = true

		if (action.onClick) then
			send = action.onClick(itemTable, sub and sub.data)
		end

		local snd = action.sound or SOUND_INVENTORY_INTERACT
		if (snd) then
			if (istable(snd)) then
				LocalPlayer():EmitSound(unpack(snd))
			elseif (isstring(snd)) then
				surface.PlaySound(snd)
			end
		end

		if (send ~= false) then
			netstream.Start("invAct", actionIndex, itemTable.id, invID, sub and sub.data)
		end
		itemTable.player = nil
	end
end

local function nutDermaMenu(parentmenu, parent)
	if ( not parentmenu ) then CloseDermaMenus() end

	local dmenu = vgui.Create( "nutDMenu", parent )

	return dmenu
end

function PANEL:openActionMenu()
	local itemTable = self.itemTable

	assert(itemTable, "attempt to open action menu for invalid item")
	itemTable.player = LocalPlayer()

	local menu = nutDermaMenu()
	local override = hook.Run("OnCreateItemInteractionMenu", self, menu, itemTable)
	if (override) then
		if (IsValid(menu)) then
			menu:Remove()
		end
		return
	end

	for k, v in SortedPairs(itemTable.functions) do
		if (hook.Run("onCanRunItemAction", itemTable, k) == false or isfunction(v.onCanRun) and not v.onCanRun(itemTable)) then
			continue
		end

		-- TODO: refactor custom menu options as a method for items
		if (v.isMulti) then
			local subMenu, subMenuOption =
				menu:AddSubMenu(L(v.name or k), buildActionFunc(v, k, itemTable, self.invID))
			subMenuOption:SetImage(v.icon or "icon16/brick.png")

			if (not v.multiOptions) then return end

			local options = isfunction(v.multiOptions)
				and v.multiOptions(itemTable, LocalPlayer())
				or v.multiOptions
			for _, sub in pairs(options) do
				subMenu:AddOption(L(sub.name or "subOption"), buildActionFunc(v, k, itemTable, self.invID, sub))
				:SetImage(sub.icon or "icon16/brick.png")
			end
		else
			menu:AddOption(L(v.name or k), buildActionFunc(v, k, itemTable, self.invID))
			:SetImage(v.icon or "icon16/brick.png")
		end
	end

	menu:Open(self:LocalToScreen(self:GetWide(), 0))
	-- position menu to be on the right of the icon
	--[[ local x = self:LocalToScreen(self:GetWide(), 0)
	menu:SetX(x) ]]

	itemTable.player = nil
end

vgui.Register("nutItemIcon", PANEL, "SpawnIcon")

PANEL = {}
function PANEL:Init()
	self:MakePopup()
	self:Center()
	self:ShowCloseButton(false)
	self:SetDraggable(true)
	self:SetTitle(L"inv")
end

-- Sets which inventory this panel is representing.
function PANEL:setInventory(inventory)
	self.inventory = inventory
	self:nutListenForInventoryChanges(inventory)
end

-- Called when the data for the local inventory has been initialized.
-- This shouldn't run unless the inventory got resync'd.
function PANEL:InventoryInitialized()
end

-- Called when a data value has been changed for the inventory.
function PANEL:InventoryDataChanged(key, oldValue, newValue)
end

-- Called when the inventory for this panel has been deleted. This may
-- be because the local player no longer has access to the inventory!
function PANEL:InventoryDeleted(inventory)
	if (self.inventory == inventory) then
		self:Remove()
	end
end

-- Called when the given item has been added to the inventory.
function PANEL:InventoryItemAdded(item)
end

-- Called when the given item has been removed from the inventory.
function PANEL:InventoryItemRemoved(item)
end

-- Called when an item within this inventory has its data changed.
function PANEL:InventoryItemDataChanged(item, key, oldValue, newValue)
end

-- Make sure to clean up hooks before removing the panel.
function PANEL:OnRemove()
	self:nutDeleteInventoryHooks()
end
vgui.Register("nutInventory", PANEL, "DFrame")

local margin = 10
hook.Add("CreateMenuButtons", "nutInventory", function(tabs)
	if (hook.Run("CanPlayerViewInventory") == false) then return end

	tabs["inv"] = function(panel)
		local inventory = LocalPlayer():getChar():getInv()

		if (not inventory) then return end
		local mainPanel = inventory:show(panel)

		local sortPanels = {}
		local totalSize = {x = 0, y = 0, p = 0}
		table.insert(sortPanels, mainPanel)

		totalSize.x = totalSize.x + mainPanel:GetWide() + margin
		totalSize.y = math.max(totalSize.y, mainPanel:GetTall())

		for id, item in pairs(inventory:getItems()) do
			if (item.isBag and hook.Run("CanOpenBagPanel", item) ~= false) then
				local inventory = item:getInv()

				local childPanels = inventory:show(mainPanel)
				nut.gui["inv"..inventory:getID()] = childPanels
				table.insert(sortPanels, childPanels)

				totalSize.x = totalSize.x + childPanels:GetWide() + margin
				totalSize.y = math.max(totalSize.y, childPanels:GetTall())
			end
		end

		local px, py, pw, ph = mainPanel:GetBounds()
		local x, y = px + pw/2 - totalSize.x / 2, py + ph/2
		for _, panel in pairs(sortPanels) do
			panel:ShowCloseButton(true)
			panel:SetPos(x, y - panel:GetTall()/2)
			x = x + panel:GetWide() + margin
		end

		hook.Add("PostRenderVGUI", mainPanel, function()
			hook.Run("PostDrawInventory", mainPanel)
		end)
	end
end)

PANEL = {}

function PANEL:Open( x, y, skipanimation, ownerpanel )

	RegisterDermaMenuForClose( self )

	local maunal = x and y

	x = x or gui.MouseX()
	y = y or gui.MouseY()

	local OwnerHeight = 0
	local OwnerWidth = 0

	if ( ownerpanel ) then
		OwnerWidth, OwnerHeight = ownerpanel:GetSize()
	end

	self:InvalidateLayout( true )

	local w = self:GetWide()
	local h = self:GetTall()


	self:SetSize(0,0 )

	if ( y + h > ScrH() ) then y = ( ( maunal and ScrH() ) or ( y + OwnerHeight ) ) - h end
	if ( x + w > ScrW() ) then x = ( ( maunal and ScrW() ) or x ) - w end
	if ( y < 1 ) then y = 1 end
	if ( x < 1 ) then x = 1 end

	local p = self:GetParent()
	if ( IsValid( p ) and p:IsModal() ) then
		-- Can't popup while we are parented to a modal panel
		-- We will end up behind the modal panel in that case

		x, y = p:ScreenToLocal( x, y )

		-- We have to reclamp the values
		if ( y + h > p:GetTall() ) then y = p:GetTall() - h end
		if ( x + w > p:GetWide() ) then x = p:GetWide() - w end
		if ( y < 1 ) then y = 1 end
		if ( x < 1 ) then x = 1 end

		self:SetPos( x, y )
	else
		self:SetPos( x, y )

		-- Popup!
		self:MakePopup()
	end

	-- Make sure it's visible!
	self:SetVisible( true )

	-- Keep the mouse active while the menu is visible.
	self:SetKeyboardInputEnabled( false )

end

function PANEL:PerformLayout( w, h )

	w = self:GetMinimumWidth()

	-- Find the widest one
	for k, pnl in ipairs( self:GetCanvas():GetChildren() ) do

		pnl:InvalidateLayout( true )
		w = math.max( w, pnl:GetWide() )

	end

	if self.animComplete then self:SetWide( w ) end

	local y = 0 -- for padding

	for k, pnl in ipairs( self:GetCanvas():GetChildren() ) do

		pnl:SetWide( w )
		pnl:SetPos( 0, y )
		pnl:InvalidateLayout( true )

		y = y + pnl:GetTall()

	end

	y = math.min( y, self:GetMaxHeight() )

	if self.animComplete then self:SetTall( y ) end

	if not self.animComplete and not self.animStarted then
		self.animStarted = true
		self:SetSize(0,0)
		self:SizeTo(w, 10, 0.1, 0, -1, function()
			self:SizeTo(w, y, 0.2, 0, 0.9, function()
				self.animComplete = true
			end)
		end)
	end

	derma.SkinHook( "Layout", "Menu", self )
	DScrollPanel.PerformLayout( self, w, h )

	if not self.animComplete then
		self:GetVBar():SetWide(0)
	end
end

local gradientL = nut.util.getMaterial("vgui/gradient-l")
local gradientR = nut.util.getMaterial("vgui/gradient-r")
local gradientD = nut.util.getMaterial("vgui/gradient-d")
local testGradient = nut.util.getMaterial("vgui/gradient_down")

--[[ function PANEL:Paint(w, h)
	local r, g ,b = nut.config.get("color"):Unpack()

	surface.SetDrawColor(r, g, b, 255)
	surface.DrawRect(0, 0, w, h)

	surface.SetDrawColor(0, 0, 0, 255)
	surface.SetMaterial(gradientR)
	surface.DrawTexturedRect(0, 0, w, h)
	surface.SetMaterial(gradientD)
	surface.DrawTexturedRect(0, 0, w, h)
end ]]

function PANEL:AddOption( strText, funcFunction )

	local pnl = vgui.Create( "nutDMenuOption", self )
	pnl:SetMenu( self )
	pnl:SetText( strText )
	if ( funcFunction ) then pnl.DoClick = funcFunction end

	self:AddPanel( pnl )

	return pnl

end

function PANEL:AddSubMenu( strText, funcFunction )

	local pnl = vgui.Create( "nutDMenuOption", self )
	local SubMenu = pnl:AddSubMenu( strText, funcFunction )

	pnl:SetText( strText )
	if ( funcFunction ) then pnl.DoClick = funcFunction end

	self:AddPanel( pnl )

	return SubMenu, pnl

end

vgui.Register("nutDMenu", PANEL, "DMenu")

--remake DMenuOption as nutDMenuOption, so we can use nutDMenuOption in nutDMenu. Make the panel bigger
PANEL = {}

function PANEL:Init()

	self:SetContentAlignment( 4 )
	self:SetTextInset( 32, 0 ) -- Room for icon on left
	self:SetContentAlignment(5)
	self:SetChecked( false )
	self:SetFont("nutSmallFont")
end

function PANEL:PerformLayout( w, h )

	self:SizeToContents()
	self:SetWide( self:GetWide() + 30 )

	local w = math.max( self:GetParent():GetWide(), self:GetWide() )

	surface.SetFont( self:GetFont() )
	local _, y = surface.GetTextSize( "W" )
	self:SetSize( w, y + 5)

	if ( IsValid( self.SubMenuArrow ) ) then

		self.SubMenuArrow:SetSize( 15, 15 )
		self.SubMenuArrow:CenterVertical()
		self.SubMenuArrow:AlignRight( 4 )

	end

	DButton.PerformLayout( self, w, h )

end

local glow = nut.util.getMaterial("particle/Particle_Glow_04_Additive")

--[[ function PANEL:Paint(w, h)
	local r, g, b = nut.config.get("color"):Unpack()

	local alpha = 0
	-- if hovered, alpha is 100, if selected alpha is 255
	if (self.Hovered) then

		alpha = 200

	elseif (self:GetChecked()) then
		alpha = 150
	end

	surface.SetDrawColor(r, g, b, alpha)
	surface.SetMaterial(gradientR)
	surface.DrawTexturedRect(0, 0, w/2, h)
	surface.DrawRect(0, 0, w, h)
	surface.SetMaterial(glow)
	surface.DrawTexturedRect(-w*0.25, 0, w*1.5, h*2.5)
end ]]

function PANEL:AddSubMenu()

	local SubMenu = nutDermaMenu( true, self )
	SubMenu:SetVisible( false )
	SubMenu:SetParent( self )

	self:SetSubMenu( SubMenu )

	return SubMenu

end


vgui.Register("nutDMenuOption", PANEL, "DMenuOption")