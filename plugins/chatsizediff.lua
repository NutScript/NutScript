PLUGIN.name = "Chat Size Difference"
PLUGIN.desc = "Overrides size for different chat types."
PLUGIN.author = "Zoephix"

nut.config.add("chatSizeDiff", false, "Whether or not to use different chat sizes.", nil, {
	category = "chat"
})

if (CLIENT) then
	function PLUGIN:LoadFonts(font)
		surface.CreateFont("nutSmallChatFont", {
			font = font,
			size = math.max(ScreenScale(6), 17),
			extended = true,
			weight = 750
		})

		surface.CreateFont("nutItalicsChatFont", {
			font = font,
			size = math.max(ScreenScale(7), 17),
			extended = true,
			weight = 600,
			italic = true
		})

		surface.CreateFont("nutMediumChatFont", {
			font = font,
			size = math.max(ScreenScale(7), 17),
			extended = true,
			weight = 200
		})

		surface.CreateFont("nutBigChatFont", {
			font = font,
			size = math.max(ScreenScale(8), 17),
			extended = true,
			weight = 200
		})
	end

	function PLUGIN:ChatAddText(text, ...)
		if (nut.config.get("chatSizeDiff", true)) then
			local chatText = {...}
			local chatMode = #chatText <= 4 and chatText[2] or chatText[3]

			if (!chatMode or istable(chatMode)) then
				return "<font=nutChatFont>"
			else
				local chatMode = string.lower(chatMode)

				if (string.match(chatMode, "yell")) then
					return "<font=nutBigChatFont>"
				elseif (string.sub(chatMode, 1, 2) == "**") then
					return "<font=nutItalicsChatFont>"
				elseif (string.match(chatMode, "whisper")) then
					return "<font=nutSmallChatFont>"
				elseif (string.match(chatMode, "ooc") or string.match(chatMode, "looc")) then
					return "<font=nutChatFont>"
				else
					return "<font=nutMediumChatFont>"
				end
			end
		else
			return text
		end
	end
end
