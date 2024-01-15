local palette = palette or {}

local SKIN = {}
	SKIN.fontFrame = "BudgetLabel"
	SKIN.fontTab = "nutSmallFont"
	SKIN.fontButton = "nutSmallFont"

	SKIN.Colours = table.Copy(derma.SkinList.Default.Colours)
	SKIN.Colours.Window.TitleActive = Color(0, 0, 0)
	SKIN.Colours.Window.TitleInactive = Color(255, 255, 255)

	local defaultLight, defaultDark = color_white, Color(80, 80, 80)

	SKIN.Colours.Button.Normal = defaultDark
	SKIN.Colours.Button.Hover = defaultLight
	SKIN.Colours.Button.Down = Color(180, 180, 180)
	SKIN.Colours.Button.Disabled = Color(0, 0, 0, 100)

	local clamp = function(value)
		return math.Clamp(value, 0.2, 1)
	end

	local toColor = function(baseColor)
		return Color(baseColor.r, baseColor.g, baseColor.b)
	end

	local themeGenerator = {
		["dark"] = function(h, s, l)
			local secondary = HSVToColor(h, s, l - 0.5 <=0.2 and l + 0.3 or l - 0.5)
			local background = HSVToColor(h, s - 0.3 < 0.1 and s + 0.3 or s - 0.3, l - 0.5 <=0.2 and l + 0.3 or l - 0.5)
			local light = HSVToColor(h, 0.1, 1)
			local dark = HSVToColor(h, 1, 0.2)

			return toColor(secondary), toColor(background), toColor(light), toColor(dark)
		end,
		["light"] = function(h, s, l)
			local secondary = HSVToColor(h, s, l - 0.2 <=0.2 and l + 0.6 or l - 0.2)
			local background = HSVToColor(h, s - 0.3 < 0.1 and s + 0.3 or s - 0.3, clamp(s + 0.05))
			local light = HSVToColor(h, 0.1, 1)
			local dark = HSVToColor(h, 1, 0.2)

			return toColor(secondary), toColor(background), toColor(light), toColor(dark)
		end,
	}
		-- Function to create a monochromatic color palette
	local function createMonochromaticPalette()
		-- Calculate the HSL values of the base color
		local theme = nut.config.get("colorAutoTheme", "dark")
		local primary = nut.config.get("color")
		local h, s, l = ColorToHSV(primary)
		local secondary = nut.config.get("colorSecondary", Color(55, 87, 140))
		local background = nut.config.get("colorBackground", Color(45, 45, 45))
		local light, dark = defaultLight, defaultDark
		if themeGenerator[theme] ~= nil then
			secondary, background, light, dark = themeGenerator[theme](h, s, l)
		end

		return {primary = primary, secondary = secondary, background = background, light = light, dark = dark}
	end

	local function updateColors()

		timer.Simple(0, function()
			palette = createMonochromaticPalette()
			local primary, secondary, background, light, dark = palette.primary, palette.secondary, palette.background, palette.light, palette.dark
			nut.config.set("color", primary)
			nut.config.set("colorSecondary", secondary)
			nut.config.set("colorBackground", background)

			if themeGenerator[nut.config.get("colorAutoTheme", "dark")] ~= nil then
				nut.config.setDefault("colorSecondary", secondary)
				nut.config.setDefault("colorBackground", background)
			end

			SKIN.Colours.Window.TitleActive = secondary
			SKIN.Colours.Window.TitleInactive = Color(255, 255, 255)

			SKIN.tex.CategoryList.Header = function( x, y, w, h )
				surface.SetDrawColor( primary )
				surface.DrawRect( x, y, w, h )
			end

			SKIN.colTextEntryTextHighlight	= secondary
		end)
	end

	hook.Add("nutUpdateColors", "nutSkinUpdateColors_Alt", updateColors)

derma.DefineSkin("nutscript_alt", "Alternative skin for the NutScript framework.", SKIN)
derma.RefreshSkins()