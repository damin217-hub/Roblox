local SoundService = game:GetService("SoundService")

local SoundController = {}
SoundController.__index = SoundController

local SOUND_URI = "rbxasset://sounds/electronicpingshort.wav"

function SoundController.new()
	local self = setmetatable({}, SoundController)
	self.sound = Instance.new("Sound")
	self.sound.Name = "ArtAcademyUIAudio"
	self.sound.SoundId = SOUND_URI
	self.sound.Volume = 0.32
	self.sound.Parent = SoundService
	return self
end

function SoundController:play(kind: string)
	if kind == "success" then
		self.sound.PlaybackSpeed = 1.45
		self.sound.Volume = 0.4
	elseif kind == "round" then
		self.sound.PlaybackSpeed = 1.1
		self.sound.Volume = 0.28
	else
		self.sound.PlaybackSpeed = 0.9
		self.sound.Volume = 0.24
	end
	self.sound.TimePosition = 0
	self.sound:Play()
end

function SoundController:destroy()
	self.sound:Destroy()
end

return SoundController
