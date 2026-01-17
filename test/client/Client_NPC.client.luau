local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AnimationManager = require(ReplicatedStorage.OpenNpc.AnimationManager)
local Rig = require(ReplicatedStorage.rigs.r6)

local npc = ReplicatedStorage.NPC:Clone()
npc.Parent = workspace

local Manager = AnimationManager.new(Rig, npc)
Manager:Start()

local walk = Manager:LoadAnimation({
	stop_fade_time = 0.5,
	start_fade_time = 0.5,
	alpha = 0,
	weight = 1,
	priority = 1,
	looped = true,
}, ReplicatedStorage.animations.Walk)

walk:Play()
