
ICON_INFO = ICON_INFO or {}
ICON_INFO.camPos = ICON_INFO.camPos or Vector()
ICON_INFO.camAng = ICON_INFO.camAng or Angle()
ICON_INFO.entAng = ICON_INFO.entAng or Angle()
ICON_INFO.FOV = ICON_INFO.FOV or 50
ICON_INFO.w = ICON_INFO.w or 1
ICON_INFO.h = ICON_INFO.h or 1
ICON_INFO.modelAng = ICON_INFO.modelAng or Angle()
ICON_INFO.modelName = ICON_INFO.modelName or "models/Items/grenadeAmmo.mdl"
ICON_INFO.outline = ICON_INFO.outline or false
ICON_INFO.outlineColor = ICON_INFO.outlineColor or color_white

local vTxt = "xyz"
local aTxt = "pyr"
local bTxt = {
	"best",
	"full",
	"above",
	"right",
	"origin",
	"reset angles"
}
local PANEL = {}


local function adjustSize(pnl, x, y)
	x = x or 1
	y = y or 1
	pnl:SetSize(10 + x*64, 27 + y*64)
	pnl.model:SetSize(x*64, y*64)
end

--[[-------------------------------------------------------------------------
3D ICON PREVIEW WINDOW
---------------------------------------------------------------------------]]
function PANEL:Init()
	self:SetPos(50, 50)
	self:ShowCloseButton(false)
	self:SetTitle("RENDER PREVIEW")

	self.model = self:Add("DModelPanel")
	self.model:SetPos(5, 22)

	function self.model:PaintOver(w, h)
		surface.SetDrawColor(255, 255, 255)
		surface.DrawOutlinedRect(0, 0, w, h)
	end

	function self.model:LayoutEntity()
	end

	self:AdjustSize(ICON_INFO.w, ICON_INFO.h)
end

function PANEL:Paint(w, h)
	surface.SetDrawColor(255, 255, 255)
	surface.DrawOutlinedRect(0, 0, w, h)
end

PANEL.AdjustSize = adjustSize

vgui.Register("iconPreview", PANEL, "DFrame")

--[[-------------------------------------------------------------------------
RENDER ICON PREVIEW
---------------------------------------------------------------------------]]
PANEL = {}
AccessorFunc(PANEL, "m_strModel", 		"Model")
AccessorFunc(PANEL, "m_pOrigin", 		"Origin")
AccessorFunc(PANEL, "m_bCustomIcon", 	"CustomIcon")
function PANEL:Init()
	self:SetPos(50, 300)
	self:ShowCloseButton(false)
	self:SetTitle("PREVIEW")

	self.model = self:Add("SpawnIcon")
	self.model:InvalidateLayout(true)
	self.model:SetPos(5, 22)
	function self.model:PaintOver(w, h)
		surface.SetDrawColor(255, 255, 255)
		surface.DrawOutlinedRect(0, 0, w, h)
	end

	self.model.Icon:SetVisible(false)
	self.model.Paint = function(self, x, y)
		local exIcon = ikon:getIcon("iconEditor")
		if (exIcon) then
			surface.SetMaterial(exIcon)
			surface.SetDrawColor(255, 255, 255)
			surface.DrawTexturedRect(0, 0, x, y)
		end
	end

	self:AdjustSize(ICON_INFO.w, ICON_INFO.h)
end

function PANEL:Paint(w, h)
	surface.SetDrawColor(255, 255, 255)
	surface.DrawOutlinedRect(0, 0, w, h)
end

PANEL.AdjustSize = adjustSize

vgui.Register("iconRenderPreview", PANEL, "DFrame")

--[[-------------------------------------------------------------------------
EDITOR FUNCTION
---------------------------------------------------------------------------]]

local function buildActionText(self, setModel)

	local p1 = self.prev

	local p = self.prev2
	local icon = p.model

	local iconModel = p1.model
	if (not iconModel) then return end

	local ent = iconModel:GetEntity()
	local tab = {}
	tab.ent		= ent
	tab.cam_pos = iconModel:GetCamPos()
	tab.cam_ang = iconModel:GetLookAng()
	tab.cam_fov = iconModel:GetFOV()

	if (setModel and icon) then
		icon:SetModel(ent:GetModel())
	end

	local text =
	"ITEM.model = \""..ICON_INFO.modelName:gsub("\\", "/"):lower().."\"" .. "\n"..
	"ITEM.width = "..ICON_INFO.w .."\n"..
	"ITEM.height = "..ICON_INFO.h .."\n"..
	"ITEM.iconCam = {" .."\n"..
	"\tpos = Vector("..tab.cam_pos.x..", "..tab.cam_pos.y..", "..tab.cam_pos.z.."),\n"..
	"\tang = Angle("..tab.cam_ang.p..", "..tab.cam_ang.y..", "..tab.cam_ang.r.."),\n"..
	"\tfov = "..tab.cam_fov .. "," .."\n"
	if (ICON_INFO.outline) then
		text = text .. "\toutline = true," .. "\n" ..
		"\toutlineColor = Color("..
		ICON_INFO.outlineColor.r .. ", " ..
		ICON_INFO.outlineColor.g .. ", " ..
		ICON_INFO.outlineColor.b .. ")," .. "\n"
	end
	text = text .. "}"

	return text
end



local function action(self)
	local text = buildActionText(self)

	if not text then return end

	SetClipboardText(text)
end

local function renderAction(self)

	local text = buildActionText(self, true)

	if (not text) then return end

	ikon:renderIcon(
		"iconEditor",
		ICON_INFO.w,
		ICON_INFO.h,
		ICON_INFO.modelName,
		{
			pos = ICON_INFO.camPos,
			ang = ICON_INFO.camAng,
			fov = ICON_INFO.FOV,
			outline = ICON_INFO.outline,
			outlineColor = ICON_INFO.outlineColor,
			drawHook = ICON_INFO.drawHook,
			entAng = ICON_INFO.entAng,
			drawPostHook = ICON_INFO.drawPostHook,
		},
		true
	)
end

PANEL = {}
function PANEL:Init()
	if (editorPanel and editorPanel:IsVisible()) then
		editorPanel:Close()
	end
	editorPanel = self

	self:SetTitle("MODEL ADJUST")
	self:MakePopup()
	self:SetSize(400, ScrH()*.8)
	self:Center()

	self.prev = vgui.Create("iconPreview")
	self.prev2 = vgui.Create("iconRenderPreview")
	self.list = self:Add("DScrollPanel")
	self.list:Dock(FILL)

	self:AddText("Actions")

	self.render = self.list:Add("DButton")
	self.render:Dock(TOP)
	self.render:SetFont("ChatFont")
	self.render:SetText("RENDER")
	self.render:SetTall(30)
	self.render:DockMargin(5, 5, 5, 0)
	self.render.DoClick = function()
		renderAction(self)
	end

	self.copy = self.list:Add("DButton")
	self.copy:Dock(TOP)
	self.copy:SetFont("ChatFont")
	self.copy:SetText("COPY")
	self.copy:SetTall(30)
	self.copy:DockMargin(5, 5, 5, 0)
	self.copy.DoClick = function()
		action(self)
	end

	self:AddText("Presets")
	for i = 1, 6 do
		local btn = self.list:Add("DButton")
		btn:Dock(TOP)
		btn:SetFont("ChatFont")
		btn:SetText(bTxt[i])
		btn:SetTall(30)
		btn:DockMargin(5, 5, 5, 0)
		btn.DoClick = function()
			self:SetupEditor(true, i)
			self:UpdateIcon()
		end
	end

	self:AddText("Model Name")

	self.mdl = self.list:Add("DTextEntry")
	self.mdl:Dock(TOP)
	self.mdl:SetFont("Default")
	self.mdl:SetText("Copy that :)")
	self.mdl:SetTall(25)
	self.mdl:DockMargin(5, 5, 5, 0)
	self.mdl.OnEnter = function()
		ICON_INFO.modelName = self.mdl:GetValue()
		self:SetupEditor(true)
		self:UpdateIcon()
	end

	self:AddText("Icon Size")

	local cfg = self.list:Add("DNumSlider")
	cfg:Dock(TOP)
	cfg:SetText("W")
	cfg:SetMin(0)
	cfg:SetMax(10)
	cfg:SetDecimals(0)
	cfg:SetValue(ICON_INFO.w)
	cfg:DockMargin(10, 0, 0, 5)
	cfg.OnValueChanged = function(cfg, value)
		ICON_INFO.w = value
		self.prev:AdjustSize(ICON_INFO.w, ICON_INFO.h)
		self.prev2:AdjustSize(ICON_INFO.w, ICON_INFO.h)
	end

	local cfg = self.list:Add("DNumSlider")
	cfg:Dock(TOP)
	cfg:SetText("H")
	cfg:SetMin(0)
	cfg:SetMax(10)
	cfg:SetDecimals(0)
	cfg:SetValue(ICON_INFO.h)
	cfg:DockMargin(10, 0, 0, 5)
	cfg.OnValueChanged = function(cfg, value)
		ICON_INFO.h = value
		self.prev:AdjustSize(ICON_INFO.w, ICON_INFO.h)
		self.prev2:AdjustSize(ICON_INFO.w, ICON_INFO.h)
	end

	self:AddText("Camera FOV")

	self.camFOV = self.list:Add("DNumSlider")
	self.camFOV:Dock(TOP)
	self.camFOV:SetText("CAMFOV")
	self.camFOV:SetMin(0)
	self.camFOV:SetMax(180)
	self.camFOV:SetDecimals(3)
	self.camFOV:SetValue(ICON_INFO.FOV)
	self.camFOV:DockMargin(10, 0, 0, 5)
	self.camFOV.OnValueChanged = function(cfg, value)
		if (!isIconUpdating) then
			ICON_INFO.FOV = value

			local p = self.prev
			if (p and p:IsVisible()) then
				p.model:SetFOV(ICON_INFO.FOV)
			end
		end
	end

	self:AddText("Camera Position")

	self.camPos = {}
	for i = 1, 3 do
		self.camPos[i] = self.list:Add("DNumSlider")
		self.camPos[i]:Dock(TOP)
		self.camPos[i]:SetText("CAMPOS_"..vTxt[i])
		self.camPos[i]:SetMin(-500)
		self.camPos[i]:SetMax(500)
		self.camPos[i]:SetDecimals(3)
		self.camPos[i]:SetValue(ICON_INFO.camPos[i])
		self.camPos[i]:DockMargin(10, 0, 0, 5)
		self.camPos[i].OnValueChanged = function(_, value)
			if (!isIconUpdating) then
				ICON_INFO.camPos[i] = value
			end
		end
	end

	self:AddText("Camera Angle")

	self.camAng = {}
	for i = 1, 3 do
		self.camAng[i] = self.list:Add("DNumSlider")
		self.camAng[i]:Dock(TOP)
		self.camAng[i]:SetText("CAMANG_"..aTxt[i])
		self.camAng[i]:SetMin(-180)
		self.camAng[i]:SetMax(180)
		self.camAng[i]:SetDecimals(3)
		self.camAng[i]:SetValue(ICON_INFO.camAng[i])
		self.camAng[i]:DockMargin(10, 0, 0, 5)
		self.camAng[i].OnValueChanged = function(_, value)
			if (!isIconUpdating) then
				ICON_INFO.camAng[i] = value
			end
		end
	end

	self:AddText("Entity Angle")

	self.entAng = {}
	for i = 1, 3 do
		self.entAng[i] = self.list:Add("DNumSlider")
		self.entAng[i]:Dock(TOP)
		self.entAng[i]:SetText("ENTANG_"..aTxt[i])
		self.entAng[i]:SetMin(-180)
		self.entAng[i]:SetMax(180)
		self.entAng[i]:SetDecimals(3)
		self.entAng[i]:SetValue(ICON_INFO.entAng[i])
		self.entAng[i]:DockMargin(10, 0, 0, 5)
		self.entAng[i].OnValueChanged = function(_, value)
			if (!isIconUpdating) then
				ICON_INFO.entAng[i] = value
				self.prev.model.Entity:SetAngles(ICON_INFO.entAng)
			end
		end
	end

	local aaoa = self.list:Add("DPanel")
	aaoa:Dock(TOP)
	aaoa:DockMargin(10, 0, 0, 5)
	aaoa:SetHeight(250)

	self.color = aaoa:Add("DCheckBoxLabel")
	self.color:SetText("Draw Outline?")
	self.color:SetValue(ICON_INFO.outline)
	self.color:DockMargin(10, 5, 0, 5)
	self.color:Dock(TOP)
	function self.color:OnChange(bool)
		ICON_INFO.outline = bool
	end

	self.colormixer = aaoa:Add("DColorMixer")
	self.colormixer:Dock(FILL)
	self.colormixer:SetPalette(true)
	self.colormixer:SetAlphaBar(false)
	self.colormixer:SetWangs(true)
	self.colormixer:SetColor(ICON_INFO.outlineColor )
	self.colormixer:DockMargin(10, 5, 0, 5)
	function self.colormixer:ValueChanged(value)
		 ICON_INFO.outlineColor = value
	end

	self:SetupEditor()
	self:UpdateIcon(true)
end

function PANEL:UpdateIcon()
	isIconUpdating = true
		self.camFOV:SetValue(ICON_INFO.FOV)

		for i = 1, 3 do
			self.camPos[i]:SetValue(ICON_INFO.camPos[i])
			self.camAng[i]:SetValue(ICON_INFO.camAng[i])
			self.entAng[i]:SetValue(ICON_INFO.entAng[i])
		end
	isIconUpdating = false
end

function PANEL:SetupEditor(update, mode)
	local p = self.prev
	local p2 = self.prev2

	if not (p and p:IsVisible() and p2 and p2:IsVisible()) then return end

	p.model:SetModel(ICON_INFO.modelName)
	p2.model:SetModel(ICON_INFO.modelName)
	if (not update) then
		self.mdl:SetText(ICON_INFO.modelName)
	end

	if (not mode) then
		mode = 1
	end

	if (mode == 1) then
		self:BestGuessLayout()
	elseif (mode == 2) then
		self:FullFrontalLayout()
	elseif (mode == 3) then
		self:AboveLayout()
	elseif (mode == 4) then
		self:RightLayout()
	elseif (mode == 5) then
		self:OriginLayout()
	elseif (mode == 6) then
		ICON_INFO.entAng = Angle()
	end

	p.model:SetCamPos(ICON_INFO.camPos)
	p.model:SetFOV(ICON_INFO.FOV)
	p.model:SetLookAng(ICON_INFO.camAng)

	if (IsValid(p.model.Entity)) then
		p.model.Entity:SetAngles(ICON_INFO.entAng)
	end
end

function PANEL:BestGuessLayout()
	local p = self.prev
	local ent = p.model:GetEntity()
	local pos = ent:GetPos()
	local tab = PositionSpawnIcon(ent, pos)

	if (tab) then
		ICON_INFO.camPos = tab.origin
		ICON_INFO.FOV = tab.fov
		ICON_INFO.camAng = tab.angles
	end
end

function PANEL:FullFrontalLayout()
	local p = self.prev
	local ent = p.model:GetEntity()
	local pos = ent:GetPos()
	local campos = pos + Vector(-200, 0, 0)

	ICON_INFO.camPos = campos
	ICON_INFO.FOV = 45
	ICON_INFO.camAng = (campos * -1):Angle()
end

function PANEL:AboveLayout()
	local p = self.prev
	local ent = p.model:GetEntity()
	local pos = ent:GetPos()
	local campos = pos + Vector(0, 0, 200)

	ICON_INFO.camPos = campos
	ICON_INFO.FOV = 45
	ICON_INFO.camAng = (campos * -1):Angle()
end

function PANEL:RightLayout()
	local p = self.prev
	local ent = p.model:GetEntity()
	local pos = ent:GetPos()
	local campos = pos + Vector(0, 200, 0)

	ICON_INFO.camPos = campos
	ICON_INFO.FOV = 45
	ICON_INFO.camAng = (campos * -1):Angle()
end

function PANEL:OriginLayout()
	local p = self.prev
	local ent = p.model:GetEntity()
	local pos = ent:GetPos()
	local campos = pos + Vector(0, 0, 0)

	ICON_INFO.camPos = campos
	ICON_INFO.FOV = 45
	ICON_INFO.camAng = Angle(0, -180, 0)
end

function PANEL:AddText(str)
	local label = self.list:Add("DLabel")
	label:SetFont("ChatFont")
	label:SetTextColor(nut.config.get("colorText", color_white))
	label:Dock(TOP)
	label:DockMargin(5, 5, 5, 0)
	label:SetContentAlignment(5)
	label:SetText(str)
end

function PANEL:OnRemove()
	if (self.prev and self.prev:IsVisible()) then
		self.prev:Close()
	end

	if (self.prev2 and self.prev2:IsVisible()) then
		self.prev2:Close()
	end
end
vgui.Register("iconEditor", PANEL, "DFrame")

concommand.Add("nut_dev_icon", function()
	if (LocalPlayer():IsAdmin()) then
		vgui.Create("iconEditor")
	end
end)
