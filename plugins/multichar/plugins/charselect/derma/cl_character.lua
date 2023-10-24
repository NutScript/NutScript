local PANEL = {}

local WHITE = Color(255, 255, 255, 150)

PANEL.ANIM_SPEED = 0.1
PANEL.FADE_SPEED = 0.5

-- Called when the tabs for the character menu should be created.
function PANEL:createTabs()
	local load, create

	-- Only show the load tab if playable characters exist.
	if (nut.characters and #nut.characters > 0) then
		load = self:addTab("continue", self.createCharacterSelection)
	end

	-- Only show the create tab if the local player can create characters.
	if (hook.Run("CanPlayerCreateCharacter", LocalPlayer()) ~= false) then
		create = self:addTab("create", self.createCharacterCreation)
	end

	-- By default, select the continue tab, or the create tab.
	if (IsValid(load)) then
		load:setSelected()
	elseif (IsValid(create)) then
		create:setSelected()
	end

	-- If the player has a character (i.e. opened this menu from F1 menu), then
	-- don't add a disconnect button. Just add a close button.
	if (LocalPlayer():getChar()) then
		self:addTab("return", function()
			if (IsValid(self) and LocalPlayer():getChar()) then
				self:fadeOut()
			end
		end, true)

	else

		-- Otherwise, add a disconnect button.
		self:addTab("leave", function()
			vgui.Create("nutCharacterConfirm")
				:setTitle(L("disconnect"):upper().."?")
				:setMessage(L("You will disconnect from the server."):upper())
				:onConfirm(function() LocalPlayer():ConCommand("disconnect") end)
		end, true)
	end

	-- get the width of the tabs summed up
	local totalWidth = -32
	for _, v in ipairs(self.tabs:GetChildren()) do
		totalWidth = totalWidth + v:GetWide()
	end

	-- set the dock margin of self.tabs to center the tabs
	if nut.config.get("charMenuAlignment", "center") == "center" then
		self.tabs:DockMargin(self.tabs:GetWide() * 0.5 - totalWidth * 0.5, 0, 0, 0)
	end
end

function PANEL:createTitle()
	local alignment = nut.config.get("charMenuAlignment", "center")
	self.title = self:Add("DLabel")
	self.title:Dock(TOP)
	self.title:DockMargin(alignment == "left" and 64 or 0, 48, alignment == "right" and 64 or 0, 0)
	self.title:SetContentAlignment(alignment == "left" and 4 or alignment == "center" and 5 or 6)
	self.title:SetFont("nutCharTitleFont")
	self.title:SetText(L(SCHEMA and SCHEMA.name or "Unknown"):upper())
	self.title:SetTextColor(self.color)

	surface.SetFont("nutCharTitleFont")
	local _, h = surface.GetTextSize(self.title:GetText())
	self.title:SetTall(h)

	self.desc = self:Add("DLabel")
	self.desc:Dock(TOP)
	self.desc:DockMargin(alignment == "left" and 64 or 0, 0, alignment == "right" and 64 or 0, 0)
	self.desc:SetContentAlignment(alignment == "left" and 7 or alignment == "center" and 8 or 9)
	self.desc:SetText(L(SCHEMA and SCHEMA.desc or ""):upper())
	self.desc:SetFont("nutCharDescFont")
	self.desc:SetTextColor(self.color)

	surface.SetFont("nutCharDescFont")
	_, h = surface.GetTextSize(self.title:GetText())
	self.desc:SetTall(h)
end

function PANEL:loadBackground()
	-- Map scene integration.
	local mapScene = nut.plugin.list.mapscene
	if (not mapScene or table.Count(mapScene.scenes) == 0) then
		self.blank = true
	end

	local url = nut.config.get("backgroundURL")
	if (url and url:find("%S")) then
		self.background = self:Add("DHTML")
		self.background:SetSize(ScrW(), ScrH())
		if (url:find("http")) then
			self.background:OpenURL(url)
		else
			self.background:SetHTML(url)
		end
		self.background.OnDocumentReady = function(background)
			self.bgLoader:AlphaTo(0, 2, 1, function()
				self.bgLoader:Remove()
			end)
		end
		self.background:MoveToBack()
		self.background:SetZPos(-999)

		if (nut.config.get("charMenuBGInputDisabled")) then
			self.background:SetMouseInputEnabled(false)
			self.background:SetKeyboardInputEnabled(false)
		end

		self.bgLoader = self:Add("DPanel")
		self.bgLoader:SetSize(ScrW(), ScrH())
		self.bgLoader:SetZPos(-998)
		self.bgLoader.Paint = function(loader, w, h)
			surface.SetDrawColor(20, 20, 20)
			surface.DrawRect(0, 0, w, h)
		end
	end
end

local gradientU = nut.util.getMaterial("vgui/gradient-u")
local gradientD = nut.util.getMaterial("vgui/gradient-d")
local gradientR = nut.util.getMaterial("vgui/gradient-r")
local gradientL = nut.util.getMaterial("vgui/gradient-l")

local sin = math.sin

function PANEL:paintBackground(w, h)
	if (IsValid(self.background)) then return end

	if (self.blank) then
		surface.SetDrawColor(30, 30, 30)
		surface.DrawRect(0, 0, w, h)
	end

	if not self.startTime then self.startTime = CurTime() end

	local r, g, b = nut.config.get("color"):Unpack()
	local curTime = (self.startTime - CurTime())/4
	local alpha = 200 * ((sin(curTime - 1.8719) + sin(curTime - 1.8719/2))/4 + 0.44)


    surface.SetDrawColor(r, g, b, alpha)
    surface.DrawRect(0,0,w,h)

    surface.SetDrawColor(0, 0, 0, 255)
    surface.SetMaterial(gradientD)
    surface.DrawTexturedRect(0,0,w,h)

    surface.SetMaterial(gradientL)
    surface.DrawTexturedRect(0,0,w,h)
end

function PANEL:addTab(name, callback, justClick)
	local button = self.tabs:Add("nutCharacterTabButton")
	button:setText(L(name):upper())

	if (justClick) then
		if (isfunction(callback)) then
			button.DoClick = function(button) callback(self) end
		end
		return
	end

	button.DoClick = function(button)
		button:setSelected(true)
	end
	if (isfunction(callback)) then
		button:onSelected(function()
			callback(self)
		end)
	end

	return button
end

function PANEL:createCharacterSelection()
	self.content:Clear()
	self.content:InvalidateLayout(true)
	self.content:Add("nutCharacterSelection")
end

function PANEL:createCharacterCreation()
	self.content:Clear()
	self.content:InvalidateLayout(true)
	self.content:Add("nutCharacterCreation")
end

function PANEL:fadeOut()
	self:AlphaTo(0, self.ANIM_SPEED, 0, function()
		self:Remove()
	end)
end

function PANEL:Init()
	if (IsValid(nut.gui.loading)) then
		nut.gui.loading:Remove()
	end

	if (IsValid(nut.gui.character)) then
		nut.gui.character:Remove()
	end
	nut.gui.character = self

	local color = nut.config.get("colorText")

	self.color = ColorAlpha(color, 150)
	self.colorSelected = color
	self.colorHovered = ColorAlpha(color, 50)

	self:Dock(FILL)
	self:MakePopup()
	self:SetAlpha(0)
	self:AlphaTo(255, self.ANIM_SPEED * 2)

	self:createTitle()

	self.tabs = self:Add("DPanel")
	self.tabs:Dock(TOP)
	self.tabs:DockMargin(64, 32, 64, 0)
	self.tabs:SetTall(48)
	self.tabs:SetPaintBackground(false)

	self.content = self:Add("DPanel")
	self.content:Dock(FILL)
	self.content:DockMargin(64, 0, 64, 64)
	self.content:SetPaintBackground(false)

	self.music = self:Add("nutCharBGMusic")
	self:loadBackground()

	self:InvalidateParent(true)
	self:InvalidateChildren(true)

	self:showContent()
end

function PANEL:showContent()
	self.tabs:Clear()
	self.content:Clear()
	self:createTabs()
end

function PANEL:setFadeToBlack(fade)
	local d = deferred.new()
	if (fade) then
		if (IsValid(self.fade)) then
			self.fade:Remove()
		end
		local fade = vgui.Create("DPanel")
		fade:SetSize(ScrW(), ScrH())
		fade:SetSkin("Default")
		fade:SetBackgroundColor(color_black)
		fade:SetAlpha(0)
		fade:AlphaTo(255, self.FADE_SPEED, 0, function() d:resolve() end)
		fade:SetZPos(999)
		fade:MakePopup()
		self.fade = fade
	elseif (IsValid(self.fade)) then
		local fadePanel = self.fade
		fadePanel:AlphaTo(0, self.FADE_SPEED, 0, function()
			fadePanel:Remove()
			d:resolve()
		end)
	end
	return d
end

function PANEL:Paint(w, h)
	nut.util.drawBlur(self)
	self:paintBackground(w, h)
end

function PANEL:hoverSound()
	LocalPlayer():EmitSound(unpack(SOUND_CHAR_HOVER))
end

function PANEL:clickSound()
	LocalPlayer():EmitSound(unpack(SOUND_CHAR_CLICK))
end

function PANEL:warningSound()
	LocalPlayer():EmitSound(unpack(SOUND_CHAR_WARNING))
end

vgui.Register("nutCharacter", PANEL, "EditablePanel")
