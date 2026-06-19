local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remotesFolder = ReplicatedStorage:WaitForChild("ArtAcademyRemotes")
local RemoteNames = require(ReplicatedStorage.ArtAcademy.RemoteNames)
local UIController = require(script.Parent.UIController)

local remotes = {}
for _, name in RemoteNames do
	remotes[name] = remotesFolder:WaitForChild(name)
end

local controller = UIController.new(remotes)
controller:build()
controller:bind()
