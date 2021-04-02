PLUGIN.name = "Credits Tab"
PLUGIN.desc = "A tab where players can see who made the framework/schema"
PLUGIN.author = "NS Team"

if SERVER then return end

local ScrW, ScrH = ScrW(), ScrH()
local logoMat = Material("nutscript/logo.png")
local logoGlowMat = Material("nutscript/logo_glow.png")
local textureID = surface.GetTextureID("models/effects/portalfunnel_sheet")
local sin = math.sin
surface.CreateFont("nutSmallCredits", {
    font = "Roboto",
    size = 20,
    weight = 400
})

surface.CreateFont("nutBigCredits", {
    font = "Roboto",
    size = 32,
    weight = 600
})

local authorCredits = {
    {desc = "Creator", steamid = "76561198030127257", color = Color(255, 0, 0)}, -- Chessnut
    {desc = "Co-Creator", steamid = "76561197999893894", color = Color(255, 0, 0)}, -- Black Tea
    {desc = "Lead Developer", steamid = "76561198060659964", color = Color(138,43,226)}, -- Zoephix
    {desc = "Lead Developer", steamid = "76561198070441753", color = Color(138,43,226)}, -- TovarischPootis
    {desc = "Developer", steamid = "76561198036551982", color = Color(34,139,34)}, -- Seamus
    {desc = "Developer", steamid = "76561198031437460", color = Color(34,139,34)}, -- Milk
}

local contributors = {desc = "View All Contributors", url = "https://github.com/NutScript/NutScript/graphs/contributors"}
local discord = {desc = "Join the NutScript Community Discord", url = "https://discord.gg/ySZY8TY"}

local PANEL = {}

function PANEL:Init()

    self.avatarImage = self:Add("AvatarImage")
    self.avatarImage:Dock(LEFT)
    self.avatarImage:SetSize(64,64)

    self.name = self:Add("DLabel")
    self.name:SetFont("nutBigCredits")

    self.desc = self:Add("DLabel")
    self.desc:SetFont("nutSmallCredits")
end

function PANEL:setAvatarImage(id)
    if not self.avatarImage then return end
    self.avatarImage:SetSteamID(id, 64)
    self.avatarImage.OnCursorEntered = function()
        surface.PlaySound("garrysmod/ui_return.wav")
    end

    self.avatarImage.OnMousePressed = function()
        surface.PlaySound("buttons/button14.wav")
        gui.OpenURL("http://steamcommunity.com/profiles/"..id)
    end
end

function PANEL:setName(name, isID, color)
    if not self.name then return end
    if isID then
        steamworks.RequestPlayerInfo(name, function(steamName)
            self.name:SetText(steamName or "Loading...")
        end)
    else
        self.name:SetText(name)
    end
    if color then
        self.name:SetTextColor(color)
    end
    self.name:SizeToContents()
    self.name:Dock(TOP)
    self.name:DockMargin(ScrW*0.01, 0,0,0)
end

function PANEL:setDesc(desc)
    if not self.desc then return end
    self.desc:SetText(desc)
    self.desc:SizeToContents()
    self.desc:Dock(TOP)
    self.desc:DockMargin(ScrW*0.01, 0,0,0)
end

function PANEL:Paint(w, h)
    surface.SetTexture(textureID)
    surface.DrawTexturedRect(0, 0, w, h)
end
vgui.Register("CreditsNamePanel", PANEL, "DPanel")

PANEL = {}

function PANEL:Init()
    self.contButton = self:Add("DButton")
    self.contButton:SetFont("nutBigCredits")
    self.contButton:SetText(contributors.desc)
    self.contButton.DoClick = function()
        surface.PlaySound("buttons/button14.wav")
		gui.OpenURL(contributors.url)
    end
    self.contButton.Paint = function() end
    self.contButton:Dock(TOP)

    self.discordButton = self:Add("DButton")
    self.discordButton:SetFont("nutBigCredits")
    self.discordButton:SetText(discord.desc)
    self.discordButton.DoClick = function()
        surface.PlaySound("buttons/button14.wav")
		gui.OpenURL(discord.url)
    end
    self.discordButton.Paint = function() end
    self.discordButton:Dock(TOP)
    self:SizeToChildren(true, true)
end

function PANEL:Paint()
end

vgui.Register("CreditsContribPanel", PANEL, "DPanel")

PANEL = {}

function PANEL:Init()

end

function PANEL:setPerson(data, left)
    local id = left and "creditleft" or "creditright"
    self[id] = self:Add("CreditsNamePanel")
    self[id]:setAvatarImage(data.steamid)
    self[id]:setName(data.steamid, true, data.color)
    self[id]:setDesc(data.desc)
    self[id]:Dock(left and LEFT or RIGHT)
    self[id]:InvalidateLayout(true)
    self[id]:SizeToChildren(false, true)
    self:InvalidateLayout(true)
    self[id]:SetWide((self:GetWide()/2)+32)
end

function PANEL:Paint()
end

vgui.Register("CreditsCreditsList", PANEL, "DPanel")

PANEL = {}

function PANEL:Init()
end

function PANEL:Paint(w,h)
    surface.SetMaterial(logoGlowMat)
    surface.SetDrawColor(255, 255, 255, 64*sin(CurTime())+191)
    surface.DrawTexturedRect((w/2)-128,(h/2)-128,256,256)
    surface.SetMaterial(logoMat)
    surface.SetDrawColor(255, 255, 255, 255)
    surface.DrawTexturedRect((w/2)-128,(h/2)-128,256,256)
end

vgui.Register("CreditsLogo", PANEL, "DPanel")

PANEL = {}

function PANEL:Init()
    if nut.gui.creditsPanel then
        nut.gui.creditsPanel:Remove()
    end
    nut.gui.creditsPanel = self

    self:SetSize(ScrW*0.3, ScrH*0.7)

    self.logo = self:Add("CreditsLogo")
    self.logo:SetSize(ScrW*0.4, ScrW*0.1)
    self.logo:Dock(TOP)
    self.logo:DockMargin(0,0,0,ScrH*0.05)

    self.nsteam = self:Add("DLabel")
    self.nsteam:SetFont("nutBigCredits")
    self.nsteam:SetText("NutScript Development Team")
    self.nsteam:SizeToContents()
    self.nsteam:Dock(TOP)
    local dockLeft = ScrW*0.15 - (self.nsteam:GetContentSize())/2
    self.nsteam:DockMargin(dockLeft,0,0,ScrH*0.025)

    self.creditPanels = {}
    local curNum = 0

    for k, v in ipairs(authorCredits) do
        if k%2 ~= 0 then -- if k is odd
            self.creditPanels[k] = self:Add("CreditsCreditsList")
            curNum = k
            self.creditPanels[curNum]:SetSize(self:GetWide(), ScrH*0.05)
            self.creditPanels[curNum]:setPerson(v, true)
            self.creditPanels[curNum]:Dock(TOP)
            self.creditPanels[curNum]:DockMargin(0,0,0,ScrH*0.01)
        else
            self.creditPanels[curNum]:setPerson(v, false)
            self.creditPanels[curNum]:Dock(TOP)
            self.creditPanels[curNum]:DockMargin(0,0,0,ScrH*0.01)
        end
    end
    self.contribPanel = self:Add("CreditsContribPanel")
    self.contribPanel:SizeToChildren(true, true)
    self.contribPanel:Dock(TOP)
end

function PANEL:Paint()
end

vgui.Register("nutCreditsList", PANEL, "DPanel")

hook.Add("BuildHelpMenu", "nutCreditsList", function(tabs)
	tabs["Credits"] = function()
        if helpPanel then
            local credits = helpPanel:Add("nutCreditsList")
            credits:Dock(TOP)
            credits:DockMargin(ScrW*0.1, 0, ScrW*0.1, 0)
        end
        return ""
    end
end)
