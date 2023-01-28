local PLUGIN = PLUGIN
PLUGIN.name = "OOC Bans"
PLUGIN.author = "Leonheart#7476"
PLUGIN.desc = "Adds an OOC banlist."
PLUGIN.oocBans = PLUGIN.oocBans or {}

PLUGIN.Ranks = {
    root = true,
    superadmin = true
}

--saves the bans
function PLUGIN:SaveData()
    self:setData(self.oocBans)
end

--loads the bans
function PLUGIN:LoadData()
    self.oocBans = self:getData()
end

nut.command.add("banooc", {
    syntax = "<string target>",
    onRun = function(client, arguments)
        local target = nut.command.findPlayer(client, arguments[1]) or client
        local uniqueID = client:GetUserGroup()

        if not PLUGIN.Ranks[uniqueID] then
            client:notify("Your rank is not high enough to use this command.")

            return false
        end

        if target then
            PLUGIN.oocBans[target:SteamID()] = true
            client:notify(target:Name() .. " has been banned from OOC.")
        else
            client:notify("Invalid target.")
        end
    end
})

nut.command.add("unbanooc", {
    syntax = "<string target>",
    onRun = function(client, arguments)
        local target = nut.command.findPlayer(client, arguments[1]) or client
        local uniqueID = client:GetUserGroup()

        if not PLUGIN.Ranks[uniqueID] then
            client:notify("Your rank is not high enough to use this command.")

            return false
        end

        if target then
            PLUGIN.oocBans[target:SteamID()] = nil
            client:notify(target:Name() .. " has been unbanned from OOC.")
        end
    end
})
