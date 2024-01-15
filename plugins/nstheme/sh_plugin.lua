PLUGIN.name = "NutScript Theme"
PLUGIN.author = "Cheesenut"
PLUGIN.desc = "Adds a dark Derma skin for NutScript."

local function getRegisteredThemes()
	local themes = {}
	if CLIENT then
		for k in pairs(derma.GetSkinTable()) do
			themes[#themes + 1] = k
		end
	end

	return themes
end

nut.config.add("theme", "nutscript", "Which derma skin to use. Requires restart to apply", nil, {
	form = "Combo",
	category = "appearance",
	options = getRegisteredThemes()
	}
)

if (CLIENT) then
	function PLUGIN:ForceDermaSkin()
		local theme = nut.config.get("theme", "nutscript")
		return derma.GetNamedSkin(theme) and theme or "nutscript"
	end
end
