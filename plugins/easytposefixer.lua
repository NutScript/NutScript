PLUGIN.name = "Easy T-Poser"
PLUGIN.author = "Leonheart#7476"
PLUGIN.desc = "Adds an easy way to fix T-Pose.."

// Put the model here. Will work on most models
local modelList = {
    "model.mdl",
    "model.mdl",
    "model.mdl",
    "model.mdl", 
    "model.mdl",
    "model.mdl",
    "model.mdl",
    "model.mdl",
    "model.mdl",
    "model.mdl",
    "model.mdl",
    "model.mdl",
    "model.mdl",
    "model.mdl",
    "model.mdl",
    "model.mdl",
}

for _, v in pairs(modelList) do
    nut.anim.setModelClass(v, "player")
end
