PLUGIN.name = "Integrated SAM Commands"
PLUGIN.desc = "Integrates SAM Commands into NutScript"
PLUGIN.author = "Tov"

if not (sam and sam.command) then return end -- Make sure SAM is installed

for _, commandInfo in pairs(sam.command.get_commands()) do
    local customSyntax = ""
    for _, argInfo in pairs(commandInfo.args) do
        customSyntax = customSyntax == "" and "[" or customSyntax .. " ["
        customSyntax = customSyntax .. (argInfo.default and tostring(type(argInfo.default)) or "string") .. " "
        customSyntax = customSyntax .. argInfo.name .. "]"
    end

    nut.command.add(commandInfo.name, {
        adminOnly = commandInfo.default_rank == "admin",
        superAdminOnly = commandInfo.default_rank == "superadmin",
        syntax = customSyntax,
        onRun = function(client, arguments)
            --run the sam command
            RunConsoleCommand("sam", commandInfo.name, unpack(arguments))
        end
    })

end