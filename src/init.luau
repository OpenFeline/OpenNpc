--[=[
    NPC controller responsible for movement, animation playback,
    and state management.

    @class NpcClass
]=]

local RunService = game:GetService("RunService")

local AnimationManager = require(script.AnimationManager)
local Signal = require(script.Packages.signal)
local crunchyroll = require(script.Packages.crunchyroll)
local queue = require(script.queue)

local types = require(script.types)

export type OpenNPC = types.CustomNPC
export type AnimationPlayer = AnimationManager.AnimationPlayer
export type NPCStates = types.NPCStates

local Npc = {}

local NpcClass = { metatable = { __index = Npc } }

--[=[
    Creates a new NPC controller instance.

    The NPC model must have a `PrimaryPart` set.
    Signals are initialized but not connected automatically.

    @within NpcClass
    @param npc Model -- NPC model
    @param rig crunchyroll.Rig -- Rig definition used for animation playback
    @param walkspeed number -- Movement speed in studs per second
    @param jumpPower number -- Jump power in studs per second
    @return NpcClass
]=]
function NpcClass.new(npc: Model, rig: crunchyroll.Rig, walkspeed: number, jumpPower: number)
	local self: types._CustomNPC = setmetatable({}, NpcClass.metatable) :: any

	self._npc = npc
	self._walkspeed = walkspeed
	self._walkQueue = queue.new() :: queue.PriorityQueue<Vector3>
	self._loadedAnimations = {} :: { [string]: AnimationTrack }
	self._animationManager = AnimationManager.new(rig, npc)
	self._jumpPower = jumpPower
	self._raycastParams = RaycastParams.new()
	self._raycastParams.FilterDescendantsInstances = { npc }
	self._raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	self._raycastParams.IgnoreWater = true

	self._lastJump = 0

	self.MoveToFinished = Signal.new()
	self.StateChanged = Signal.new()

	self._animationManager:Start()

	return self
end

--[=[
    Sets the NPC's current state.

    This updates the internal state and fires `StateChanged`.

    @within NpcClass
    @param self NpcClass -- The NpcClass object
    @param newState "Idle" | "Walking" -- New NPC state
]=]
function Npc.SetState(self: types._CustomNPC, newState: types.NPCStates)
	self._state = newState
	self.StateChanged:fire(newState)
end

--[=[
    Sets the NPC's walking speed.

    @within NpcClass
    @param self NpcClass -- The NpcClass object
    @param walkspeed number -- New speed in studs per second
]=]
function Npc.SetWalkSpeed(self: types._CustomNPC, walkspeed: number)
	self._walkspeed = walkspeed
end

--[=[
    Returns all currently playing animation tracks.

    @within NpcClass
    @param self NpcClass -- The NpcClass object
    @return { AnimationTrack }
]=]
function Npc.GetTracksPlaying(self: types._CustomNPC)
	return self._animationManager:GetPlayingTracks()
end

--[=[
    Loads an animation into the NPC's animation manager.

    Animations must be provided as a `KeyframeSequence`.

    @within NpcClass
    @param self NpcClass -- The NpcClass object
    @param options AnimationManager.PlayData -- Playback options
    @param animation KeyframeSequence -- Animation keyframes
    @return AnimationPlayer
]=]
function Npc.LoadAnimation(self: types._CustomNPC, options: AnimationManager.PlayData, animation: KeyframeSequence)
	return self._animationManager:LoadAnimation(options, animation)
end

--[=[
    Queues a movement request to a world position.

    Positions are processed in priority order.
    If the NPC is idle, movement begins immediately.

    @within NpcClass
    @param self NpcClass -- The NpcClass object
    @param pos Vector3 -- Target world position
    @param priority number? -- Optional priority (higher executes first)
]=]
function Npc.MoveTo(self: types._CustomNPC, pos: Vector3, priority: number | nil)
	assert(self._npc.PrimaryPart ~= nil, "NPC must have a primary part.")

	priority = priority or 0
	self._walkQueue:Enqueue(pos, priority :: number)

	if self._walkGoal == nil then
		self._walkGoal = self._walkQueue:Dequeue()
		self:SetState("Walking")
	end

	if self._walkingConnection == nil and self._walkQueue:Size() > 0 then
		self:_StartWalking()
	end
end

--[=[
    Forces the NPC to move to a world position immediately.
    If clearQueue is true, the current movement queue is cleared.
    @within NpcClass
    @param self NpcClass -- The NpcClass object
    @param pos Vector3 -- Target world position
    @param clearQueue boolean? -- Whether to clear the movement queue
]=]
function Npc.ForceMove(self: types._CustomNPC, pos: Vector3, clearQueue: boolean | nil)
	assert(self._npc.PrimaryPart ~= nil, "NPC must have a primary part.")

	self._walkGoal = pos
	self:SetState("Walking")

	if self._walkingConnection == nil then
		self:_StartWalking()
	end

	if clearQueue then
		self._walkQueue:Clear()
	end
end

local function NpcToRadius(model: Model): number
	local _, size = model:GetBoundingBox()
	return math.max(size.X, size.Z) * 0.5
end

function Npc._StartWalking(self: types._CustomNPC)
	self:SetState("Walking")

	local function Step(dt: number)
		local root = self._npc.PrimaryPart :: BasePart
		local goal = self._walkGoal
		if not goal then
			-- Stop movement if no goal
			root.AssemblyLinearVelocity = Vector3.new(0, root.AssemblyLinearVelocity.Y, 0)
			return
		end

		local pos = root.Position
		local toGoal = goal - pos
		local distance2D = Vector3.new(toGoal.X, 0, toGoal.Z).Magnitude
		local radius = NpcToRadius(self._npc)

		if distance2D <= radius then
			root.AssemblyLinearVelocity = Vector3.new(0, root.AssemblyLinearVelocity.Y, 0)

			if self._walkQueue:Size() == 0 and self._walkingConnection ~= nil then
				self._walkingConnection:Disconnect()
				self._walkingConnection = nil
				self._walkGoal = nil
				self:SetState("Idle")
				self.MoveToFinished:fire()
				return
			end

			self._walkGoal = self._walkQueue:Dequeue()
			return
		end

		local dir2D = Vector3.new(toGoal.X, 0, toGoal.Z).Unit

		root.AssemblyLinearVelocity =
			Vector3.new(dir2D.X * self._walkspeed, root.AssemblyLinearVelocity.Y, dir2D.Z * self._walkspeed)

		local currentCF = root.CFrame
		local targetRot = CFrame.lookAt(pos, pos + dir2D)

		local turnSpeed = math.rad(360)
		local angle = math.acos(math.clamp(currentCF.LookVector:Dot(dir2D), -1, 1))

		local rotAlpha = math.clamp((turnSpeed * dt) / math.max(angle, 1e-4), 0, 1)

		root.CFrame = CFrame.new(pos) * currentCF.Rotation:Lerp(targetRot.Rotation, rotAlpha)
	end

	local function IsGrounded()
		local root = self._npc.PrimaryPart :: BasePart
		local _, size = self._npc:GetBoundingBox()

		local origin = root.Position + Vector3.new(0, size.Y * 0.5, 0)
		local direction = Vector3.new(0, -(size.Y + 0.5), 0)

		local result = workspace:Raycast(origin, direction * 1.2, self._raycastParams)

		if not result then
			return false
		end

		return result.Normal.Y > 0.6
	end

	local function Jump()
		if not self._walkGoal then
			return
		end

		local root = self._npc.PrimaryPart :: BasePart
		local origin = root.Position
		local direction = root.CFrame.LookVector * 2
		local raycast = workspace:Raycast(origin, direction, self._raycastParams)
		local now = os.clock()

		local grounded = IsGrounded()

		if raycast and grounded and now - self._lastJump >= 0.25 then
			self._lastJump = now

			local vel = root.AssemblyLinearVelocity
			root.AssemblyLinearVelocity = Vector3.new(vel.X, vel.Y + self._jumpPower, vel.Z)
		end
	end

	if RunService:IsServer() then
		self._walkingConnection = RunService.Heartbeat:Connect(function(dt)
			Step(dt)
			Jump()
		end)
	else
		self._walkingConnection = RunService.RenderStepped:Connect(function(dt)
			Step(dt)
			Jump()
		end)
	end
end

--[=[
	Stops animations & cleans Npc object

	@within NpcClass
	@param self NpcClass -- The NpcClass object
]=]
function NpcClass.Destroy(self: types._CustomNPC)
	self._animationManager:Stop()
end

return NpcClass
