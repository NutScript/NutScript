PLUGIN.name = "Chat Limiter"
PLUGIN.author = "Leonheart#7476"
PLUGIN.desc = "Adds an Chat Limiter to prevent chat crashes."

nut.config.add("chatLimit", 256, "The amount of characters that players can write in chat.", nil, {
    category = "server",
    data = {
        min = 0,
        max = 10000
    }
})

netstream.Hook("msg", function(client, text)
    local charlimit = nut.config.get("chatLimit", 256)

    if utf8.len(text) > charlimit then
        text = utf8.sub(text, 1, charlimit)
        client:notify(string.format("Your message has been shortened due to being longer than %s characters!", charlimit))
    end

    if (client.nutNextChat or 0) < CurTime() and text:find("%S") then
        hook.Run("PlayerSay", client, text)
        client.nutNextChat = CurTime() + math.max(#text / 250, 0.4)
    end
end)
