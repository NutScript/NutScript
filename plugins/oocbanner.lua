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

nut.chat.register("ooc", {
    onCanSay = function(speaker, text)
        if PLUGIN.oocBans[speaker:SteamID()] then
            speaker:notify("You have been banned from using OOC!!")

            return false
        end

        local delay = nut.config.get("oocDelay", 10)

        if not speaker:IsAdmin() then
            -- Only need to check the time if they have spoken in OOC chat before.
            if delay > 0 and speaker.nutLastOOC then
                local lastOOC = CurTime() - speaker.nutLastOOC

                -- Use this method of checking time in case the oocDelay config changes.
                if lastOOC <= delay then
                    speaker:notifyLocalized("oocDelay", delay - math.ceil(lastOOC))

                    return false
                end
            end
        end

        -- Save the last time they spoke in OOC.
        speaker.nutLastOOC = CurTime()
    end,
    onChatAdd = function(speaker, text)
        local icon = "icon16/user.png"
        icon = Material(hook.Run("GetPlayerIcon", speaker) or icon)
        chat.AddText(icon, Color(255, 50, 50), " [OOC] ", speaker, color_white, ": " .. text)
    end,
    prefix = {"//", "/ooc"},
    noSpaceAfter = true,
    filter = "ooc"
})
