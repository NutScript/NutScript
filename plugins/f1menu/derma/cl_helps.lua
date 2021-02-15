
	surface.CreateFont("nutSmallCredits", {
		font = "Roboto",
		size = 18,
		weight = 400
	})

	surface.CreateFont("nutBigCredits", {
		font = "Roboto",
		size = 25,
		weight = 600
	})

	local HELP_DEFAULT

	hook.Add("CreateMenuButtons", "nutHelpMenu", function(tabs)		
		HELP_DEFAULT = [[
			<div id="parent"><div id="child">
				<center>
				    <img src="http://img2.wikia.nocookie.net/__cb20140827051941/nutscript/images/c/c9/Logo.png"></img>
					<br><font size=15>]] .. L"helpDefault" .. [[</font>
				</center>
			</div></div>
		]]

		tabs["help"] = function(panel)
			local html
			local header = [[<html>
			<head>
				<style>
					@import url(http://fonts.googleapis.com/earlyaccess/jejugothic.css);

					#parent {
					    padding: 5% 0;
					}

					#child {
					    padding: 10% 0;
					}

					body {
						color: #FAFAFA;
						font-family: 'Jeju Gothic', serif;
						-webkit-font-smoothing: antialiased;
					}

					h2 {
						margin: 0;
					}
				</style>
			</head>
			<body>
			]]

			local tree = panel:Add("DTree")
			tree:SetPadding(5)
			tree:Dock(LEFT)
			tree:SetWide(180)
			tree:DockMargin(0, 0, 15, 0)
			tree.OnNodeSelected = function(this, node)
				if (node.onGetHTML) then
					local source = node:onGetHTML()

					if (IsValid(devAvatar)) then
						helpPanel:Remove()

						helpPanel = panel:Add("DListView")
						helpPanel:Dock(FILL)
						helpPanel.Paint = function(this, w, h)
						end

						html = helpPanel:Add("DHTML")
						html:Dock(FILL)
						html:SetHTML(header..HELP_DEFAULT)
					end

					if (source:sub(1, 4) == "http") then
						html:OpenURL(source)
					else
						html:SetHTML(header..node:onGetHTML().."</body></html>")
					end
				end
			end

			helpPanel = panel:Add("DListView")
			helpPanel:Dock(FILL)
			helpPanel.Paint = function(this, w, h)
			end

			html = helpPanel:Add("DHTML")
			html:Dock(FILL)
			html:SetHTML(header..HELP_DEFAULT)

			local tabs = {}
			hook.Run("BuildHelpMenu", tabs)

			for k, v in SortedPairs(tabs) do
				if (not isfunction(v)) then
					local source = v

					v = function() return tostring(source) end
				end

				tree:AddNode(L(k)).onGetHTML = v or function() return "" end
			end
		end
	end)

hook.Add("BuildHelpMenu", "nutBasicHelp", function(tabs)
	tabs["commands"] = function(node)
		local body = ""

		for k, v in SortedPairs(nut.command.list) do
			local allowed = false

			if (v.adminOnly and !LocalPlayer():IsAdmin()or v.superAdminOnly and !LocalPlayer():IsSuperAdmin()) then
				continue
			end

			if (v.group) then
				if (istable(v.group)) then
					for k, v in pairs(v.group) do
						if (LocalPlayer():IsUserGroup(v)) then
							allowed = true

							break
						end
					end
				elseif (LocalPlayer():IsUserGroup(v.group)) then
					return true
				end
			else
				allowed = true
			end

			if (allowed) then
				body = body.."<h2>/"..k.."</h2><strong>Syntax:</strong> <em>"..v.syntax.."</em><br /><br />"
			end
		end

		return body
	end

	tabs["flags"] = function(node)
		local body = [[<table border="0" cellspacing="8px">]]

		for k, v in SortedPairs(nut.flag.list) do
			local icon

			if (LocalPlayer():getChar():hasFlags(k)) then
				icon = [[<img src="asset://garrysmod/materials/icon16/tick.png" />]]
			else
				icon = [[<img src="asset://garrysmod/materials/icon16/cross.png" />]]
			end

			body = body..Format([[
				<tr>
					<td>%s</td>
					<td><b>%s</b></td>
					<td>%s</td>
				</tr>
			]], icon, k, v.desc)
		end

		return body.."</table>"
	end

	tabs["plugins"] = function(node)
		local body = ""

		for k, v in SortedPairsByMemberValue(nut.plugin.list, "name") do
			body = (body..[[
				<p>
					<span style="font-size: 22;"><b>%s</b><br /></span>
					<span style="font-size: smaller;">
					<b>%s</b>: %s<br />
					<b>%s</b>: %s
			]]):format(v.name or "Unknown", L"desc", v.desc or L"noDesc", L"author", v.author)

			if (v.version) then
				body = body.."<br /><b>"..L"version".."</b>: "..v.version
			end

			body = body.."</span></p>"
		end

		return body
	end

	local authorCredits = {
		{desc = "Creator", steamid = "76561198030127257"}, -- Chessnut
		{desc = "Co-Creator", steamid = "76561197999893894"}, -- Black Tea
		{desc = "Developer", steamid = "76561198060659964"}, -- Zoephix
		{desc = "Developer", steamid = "76561198070441753"}, -- TovarischPootis
		{desc = "Contributors", button = "View all contributors", url = "https://github.com/NutScript/NutScript/graphs/contributors"}
	}

	tabs["Credits"] = function(node)
		local body = [[
			<div>
				<center>
				    <img src="http://img2.wikia.nocookie.net/__cb20140827051941/nutscript/images/c/c9/Logo.png"></img>
					<br><font size=25>NutScript</font>
				</center>
			</div>
		]]
		local scrW = ScrW()
		local scrH = ScrH()
		local offsetW = scrW*0.025
		local offsetH = scrH*0.08
		local offsetC = scrW*0.25

		local nscredits = helpPanel:Add("DScrollPanel")
		nscredits:Dock(FILL)
		nscredits:DockMargin(0, scrH*0.32, 0, 0)
		nscredits.Paint = function()
		end

		local function createDevName(text)
			devName = nscredits:Add("DLabel")
			devName:SetText(text)
			devName:SetFont("nutBigCredits")
			devName:SetTextColor(Color(255, 255, 255))
			devName:SizeToContents()
		end

		for k, v in ipairs(authorCredits) do
			local offsetH = k == 1 and 0 or (k*offsetH)-offsetH

			if (v.steamid) then
				steamworks.RequestPlayerInfo(v.steamid, function(steamName)
					createDevName(steamName)
				end)
			--
			-- add custom field
			else
				createDevName(v.desc)
			end

			if (v.steamid or v.text) then
				desc = nscredits:Add("DLabel")
				desc:SetText(v.desc)
				desc:SetFont("nutSmallCredits")
				desc:SetTextColor(Color(255, 255, 255))
				desc:SizeToContents()
			elseif (v.button) then
				desc = nscredits:Add("DButton")
				desc:SetText(v.button)
				desc:SizeToContents()
				desc.DoClick = function()
					surface.PlaySound("buttons/button14.wav")

					gui.OpenURL(v.url)
				end

				offsetH = offsetH + 25
			end

			-- fucking end my suffering
			-- this shit took me over three hours...
			local offsetW2 = string.Explode(" ", v.button and desc:GetSize() or desc:GetTextSize())[1]
			local offsetW3 = string.Explode(" ", devName:GetTextSize())[1]

			devName:SetPos(devName:GetPos()+(offsetC-devName:GetPos()), 0)
			devName:SetPos(devName:GetPos()-(offsetW3/2), offsetH)

			desc:SetPos(desc:GetPos()+(offsetC-desc:GetPos()), 0)
			desc:SetPos(desc:GetPos()-(offsetW2/2), offsetH+(v.button and scrH*0.03 or scrH*0.022))

			if (v.steamid) then
				devAvatar = vgui.Create("AvatarImage", nscredits)
				devAvatar:SetPos(devName:GetPos()-(scrW*0.025), offsetH)
				devAvatar:SetSteamID(v.steamid, 64)
				devAvatar:SetSize(40, 40)
				devAvatar.OnCursorEntered = function()
					surface.PlaySound("garrysmod/ui_return.wav")
				end
				devAvatar.OnMousePressed = function()
					surface.PlaySound("buttons/button14.wav")

					gui.OpenURL("http://steamcommunity.com/profiles/"..v.steamid)
				end
			end
		end

		return body
	end
end)
