local function check(condition, message)
	if not condition then
		error("[FAIL] " .. message)
	end
	print("[PASS] " .. message)
end

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local bootstrap = ServerScriptService.ArtAcademyServer:FindFirstChild("Bootstrap")
check(bootstrap ~= nil and bootstrap:IsA("Script"), "server bootstrap script exists")

RunService:Run()
task.wait(3)

local remotes = ReplicatedStorage:FindFirstChild("ArtAcademyRemotes")
check(remotes ~= nil, "server bootstrap creates remote folder")

for _, name in require(ReplicatedStorage.ArtAcademy.RemoteNames) do
	check(remotes:FindFirstChild(name) ~= nil, "runtime remote exists: " .. name)
end

local map = workspace:FindFirstChild("ArtAcademyMap")
check(map ~= nil, "server bootstrap creates academy map")
check(map:FindFirstChild("AcademySpawn") ~= nil, "runtime map has spawn")
check(game:GetAttribute("ExperienceMode") ~= nil, "runtime publishes experience mode attribute")

local RoundService = require(ServerScriptService.ArtAcademyServer.Services.RoundService)
local state = RoundService.getState()
check(state == "Waiting", "round service enters waiting state without queued players")

RunService:Stop()
print("[RUNTIME COMPLETE] Art Academy server bootstrap validated")

