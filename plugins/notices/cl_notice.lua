-- List of notice panels.
nut.notices = nut.notices or {}

-- Move all notices to their proper positions.
local function OrganizeNotices()
	local scrW = ScrW()

	for k, v in ipairs(nut.notices) do
		v:MoveTo(
			scrW - (v:GetWide() + 4),
			(k - 1) * (v:GetTall() + 4) + 4,
			0.15,
			(k / #nut.notices) * 0.25
		)
	end
end

-- Create a notification panel.
function nut.util.notify(message)
	local notice = vgui.Create("nutNotice")
	local i = table.insert(nut.notices, notice)
	local scrW = ScrW()
	
	-- Set up information for the notice.
	notice:SetText(message)
	notice:SetPos(scrW, (i - 1) * (notice:GetTall() + 4) + 4)
	notice:SizeToContentsX()
	notice:SetWide(notice:GetWide() + 16)
	notice.start = CurTime() + 0.25
	notice.endTime = CurTime() + 7.75

	-- Add the notice we made to the list.
	OrganizeNotices()

	-- Show the notification in the console.
	MsgC(Color(0, 255, 255), message.."\n")

	-- Once the notice appears, make a sound and message.
	timer.Simple(0.15, function()
		LocalPlayer():EmitSound(unpack(SOUND_NOTIFY))
	end)

	-- After the notice has displayed for 7.5 seconds, remove it.
	timer.Simple(7.75, function()
		if (IsValid(notice)) then
			-- Search for the notice to remove.
			for k, v in ipairs(nut.notices) do
				if (v == notice) then
					-- Move the notice off the screen.
					notice:MoveTo(scrW, notice.y, 0.15, 0.1, nil, function()
						notice:Remove()
					end)

					-- Remove the notice from the list and move other notices.
					table.remove(nut.notices, k)
					OrganizeNotices()

					break
				end
			end
		end
	end)
end
