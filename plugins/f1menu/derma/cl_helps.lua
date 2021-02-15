if (CLIENT) then
	surface.CreateFont("nshtml", {
		font = "Jeju Gothic",
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

					if (IsValid(cAvatar)) then
						helpFrame:Remove()

						helpFrame = panel:Add("DPanel")
						helpFrame:Dock(FILL)
						helpFrame.Paint = function(this, w, h)
						end

						html = helpFrame:Add("DHTML")
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

			helpFrame = panel:Add("DPanel")
			helpFrame:Dock(FILL)
			helpFrame.Paint = function(this, w, h)
			end

			html = helpFrame:Add("DHTML")
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
end

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
		{desc = "Developer", steamid = "76561198070441753"} -- TovarischPootis
	}

	tabs["Credits"] = function(node)
		local body = ""
		local scrW = ScrW()
		local scrH = ScrH()
		local offsetW = scrW*0.025
		local offsetH = scrH*0.06
		
		local title = helpFrame:Add("DLabel")
		title:SetText("NutScript")
		title:SetFont("nutBigFont")
		title:SetTextColor(Color(86,111,183))
		title:SizeToContents()
		title:Dock(TOP)

		local nscredits = helpFrame:Add("DPanel")
		nscredits:Dock(FILL)
		nscredits:DockMargin(0, 7.5, 0, 0)
		nscredits.Paint = function(this, w, h)
		end

		for k, v in ipairs(authorCredits) do
			local offsetH = k == 1 and 0 or (k*offsetH)-offsetH

			steamworks.RequestPlayerInfo( v.steamid, function(steamName)
				local name = nscredits:Add("DLabel")
				name:SetText(steamName)
				name:SetPos(offsetW, offsetH)
				name:SetFont("nshtml")
				name:SetTextColor(Color(255, 255, 255))
				name:SizeToContents()
			end )

			local desc = nscredits:Add("DLabel")
			desc:SetText(v.desc)
			desc:SetPos(offsetW, offsetH+(scrH*0.022))
			desc:SetFont("nutSmallFont")
			desc:SetTextColor(Color(255, 255, 255))
			desc:SizeToContents()

			cAvatar = vgui.Create("AvatarImage", nscredits)
			cAvatar:SetPos(0, offsetH)
			cAvatar:SetSteamID(v.steamid, 64)
			cAvatar:SetSize(40, 40)
			cAvatar.OnMousePressed = function(self)
				surface.PlaySound("buttons/button14.wav")
				
				gui.OpenURL("http://steamcommunity.com/profiles/"..v.steamid)
			end

			body = body.."</span></p>"
		end

		return body
	end
end)
