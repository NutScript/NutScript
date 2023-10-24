NS_ICON_FONT = nil

local function ScrapPage()
    local d = deferred.new()

    http.Fetch('https://dobytchick.github.io/', function(resp)
        local headpos = select(2, resp:find('<div class="row">'))
        local body = resp:sub(headpos)
        local scrapped = {}

        for str in body:gmatch('(icon-%S+);</i>') do
            local whitespaced = str:gsub('">', ' ')
            local nulled = whitespaced:gsub('&#', '0')

            local splitted = nulled:Split(' ')
            scrapped[splitted[1]] = splitted[2]
        end

        d:resolve(scrapped)
    end)

    return d
end

ScrapPage():next(function(scrapped)
    NS_ICON_FONT = scrapped
    hook.Run("EasyIconsLoaded")
end)

function getIcon(sIcon, bIsCode)
    return not bIsCode and utf8.char(tonumber(NS_ICON_FONT[sIcon])) or utf8.char(tonumber(sIcon))
end