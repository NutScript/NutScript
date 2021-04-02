--[[
https://github.com/mattkrins/surfaceGetURL

MIT License

Copyright (c) 2016 Matt Krins

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]

local WebMaterials = {}
function surface.GetURL(url, w, h, time)
	if not url or not w or not h then return Material("error") end
	if WebMaterials[url] then return WebMaterials[url] end
	local WebPanel = vgui.Create( "HTML" )
	WebPanel:SetAlpha( 0 )
	WebPanel:SetSize( tonumber(w), tonumber(h) )
	WebPanel:OpenURL( url )
	WebPanel.Paint = function(self)
		if not WebMaterials[url] and self:GetHTMLMaterial() then
			WebMaterials[url] = self:GetHTMLMaterial()
			self:Remove()
		end
	end
	timer.Simple( 1 or tonumber(time), function() if IsValid(WebPanel) then WebPanel:Remove() end end ) -- In case we do not render
	return Material("error")
end

--[[
    How to use

    local DPanel = vgui.Create( "DPanel" )
    DPanel:SetSize( 336, 280 )
    DPanel:Center()
    DPanel.Paint = function()
        local WebMaterial = surface.GetURL("http://www.lipsum.com/images/banners/black_336x280.gif", 336, 280)
        surface.SetDrawColor( 255, 255, 255, 255 )
        surface.SetMaterial( WebMaterial )
        surface.DrawTexturedRect( 0, 0, WebMaterial:Width(), WebMaterial:Height() )
    end
]]