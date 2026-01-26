local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

--local AnimationManager = require(ReplicatedStorage.OpenNpc.AnimationManager)
local OpenNpc = require(ReplicatedStorage.OpenNpc)
local r6 = require(ReplicatedStorage.rigs.r6)

local NPC = ReplicatedStorage.NPC:Clone()
NPC.Parent = workspace

local NPCController = OpenNpc.new(NPC, r6, 16, 32)

local animations: { [string]: OpenNpc.AnimationPlayer } = {
	walk = NPCController:LoadAnimation({
		alpha = 0,
		looped = true,
		priority = 1,
		stop_fade_time = 1,
		start_fade_time = 1,
		weight = 1,
	}, ReplicatedStorage.animations.Walk),
}

NPCController.StateChanged:connect(function(state)
	for _, anim in animations do
		anim:Stop()
	end

	if state == "Walking" then
		animations["walk"]:Play()
	end
end)

UserInputService.InputBegan:Connect(function(a0: InputObject, a1: boolean)
	if a1 then
		return
	end

	if a0.UserInputType == Enum.UserInputType.MouseButton1 then
		local mouseLoc2D = UserInputService:GetMouseLocation()

		local ray = workspace.CurrentCamera:ScreenPointToRay(mouseLoc2D.X, mouseLoc2D.Y)
		local cast = workspace:Raycast(ray.Origin, ray.Direction * 1000)

		if cast then
			NPCController:ForceMove(cast.Position)
		end
	end
end)
