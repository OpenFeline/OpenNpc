local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AnimationManager = require(script.Parent.AnimationManager)
local Signal = require(ReplicatedStorage.Packages.signal)
local crunchyroll = require(ReplicatedStorage.Packages.crunchyroll)
local queue = require(script.Parent.queue)

export type NPCStates = "Idle" | "Walking"

export type CustomNPC = {
	new: (npc: Model, rig: crunchyroll.Rig, walkspeed: number) -> CustomNPC,
	SetState: (self: CustomNPC, newState: NPCStates) -> (),
	LoadAnimation: (
		self: CustomNPC,
		options: AnimationManager.PlayData,
		animation: KeyframeSequence
	) -> AnimationTrack,
	MoveTo: (self: CustomNPC, pos: Vector3, priority: number | nil) -> (),
	ForceMove: (self: CustomNPC, pos: Vector3, clearQueue: boolean | nil) -> (),
	SetWalkSpeed: (self: CustomNPC, walkspeed: number) -> (),
	MoveToFinished: Signal.Signal<>,
	StateChanged: Signal.Signal<NPCStates>,
	Destroy: (self: CustomNPC) -> (),
}

export type _CustomNPC = CustomNPC & {
	_npc: Model,
	_state: NPCStates,
	_loadedAnimations: { [string | number]: AnimationTrack },
	_walkspeed: number,
	_walkingConnection: RBXScriptConnection | nil,
	_walkGoal: Vector3 | nil,
	_walkQueue: queue.PriorityQueue<Vector3>,
	_StartWalking: (self: _CustomNPC) -> (),
	_animationManager: AnimationManager.AnimationManager,
	_jumpPower: number,
	_raycastParams: RaycastParams,
	_lastJump: number,
}

return {}
