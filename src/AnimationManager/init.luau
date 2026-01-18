--!strict
local RunService = game:GetService("RunService")
local Crunchyroll = require(script.Parent.Packages.crunchyroll)

local types = require(script.types)

export type AnimationManager = types.AnimationManager
export type AnimationPlayer = types.AnimationPlayer

--[=[
	@interface PlayData
	@within AnimationManager
	
	@field priority number
	@field weight number
	@field stop_fade_time number
	@field start_fade_time number
	@field alpha number
	@field looped boolean

	A config to describe an Animation Track
]=]
export type PlayData = types.PlayData

type PlayingTracks = { [Crunchyroll.AnimationAsset]: PlayData }

type _AnimationManager = AnimationManager & {
	_rig: Crunchyroll.Rig,
	_playingTracks: PlayingTracks,
	_players: { [string]: AnimationPlayer },
	_connection: RBXScriptConnection?,
	_character: Model,
}

type _AnimationPlayer = types.AnimationPlayer & {
	_track: PlayData,
	_rig: Crunchyroll.Rig,
	_asset: Crunchyroll.AnimationAsset,
	_markForUpdate: (playing: boolean) -> (),
	_motors: { [string]: Motor6D },
}

--[=[
	@class AnimationManager

	Produces a animation player & handles animation updating automatically via :Start()/:Stop() methods
]=]
local AnimationManager = {}
AnimationManager.__index = AnimationManager

--[=[
	@class AnimationPlayer

	Plays & updates animation, handled by its manager
]=]
local AnimationPlayer = {}
AnimationPlayer.__index = AnimationPlayer

--[=[
	Creates a new animation manager to play and stop animations

	@param rig Crunchyroll.Rig -- A rig that has been made and defined using Crunchyroll
	@param character Model -- The model where animations get applied to
	@return AnimationManager -- returns the new AnimationManager
]=]
function AnimationManager.new(rig: Crunchyroll.Rig, character: Model): _AnimationManager
	local self: _AnimationManager = setmetatable({}, AnimationManager) :: any

	self._rig = rig
	self._playingTracks = {}
	self._players = {}
	self._connection = nil
	self._character = character

	return self
end

--[=[
	Loads a new animation onto the rig (Isn't played by default)

	@method LoadAnimation
	@within AnimationManager
	@param self AnimationManager -- The AnimationManager object
	@param options PlayData -- Crunchyroll's animation options to load
	@param animation KeyframeSequence -- A animation id or the actual animation to load
	@return AnimationPlayer -- Returns a new AnimationPlayer
]=]
function AnimationManager.LoadAnimation(
	self: _AnimationManager,
	options: PlayData,
	animation: KeyframeSequence
): types.AnimationPlayer
	local player: _AnimationPlayer = setmetatable({}, AnimationPlayer) :: any

	player.IsPlaying = false
	player._track = options
	player._rig = self._rig
	player._asset = Crunchyroll.load_keyframe_sequence(animation, self._rig)
	player._markForUpdate = function(playing)
		local key = if typeof(animation) == "string" then animation else animation.Name
		self._players[key] = if playing then player else nil :: any
		self._playingTracks[player._asset] = if playing then player._track else nil :: any
	end
	player._motors = {}

	for _, descendant in self._character:GetDescendants() do
		if descendant:IsA("Motor6D") then
			player._motors[descendant.Name] = descendant
		end
	end

	return player
end

--[=[
	Returns the current playing tracks on the character

	@method GetPlayingTracks
	@within AnimationManager
	@param self AnimationManager -- The AnimationManager object
	@return PlayingTracks -- An array of the current animation players
]=]
function AnimationManager.GetPlayingTracks(self: _AnimationManager): { [string]: AnimationPlayer }
	return self._players
end

--[=[
	Updates each animation player that is marked to be updated

	@method Update
	@within AnimationManager
	@param self AnimationManager -- The AnimationPlayer object
	@param dt number -- Delta Time used to calculate time passed for animation updating
]=]
function AnimationManager.Update(self: _AnimationManager, dt: number)
	if self._character.PrimaryPart == nil then
		return
	end

	for _, anim in self._players do
		anim:Step(dt)
		anim:UpdateCFrames(self._character.PrimaryPart.CFrame)
	end

	Crunchyroll.solve_animation(self._rig, self._playingTracks, self._character.PrimaryPart.CFrame)
end

--[=[
	Starts the animation manager

	@method Start
	@within AnimationManager
	@param self AnimationManager -- The AnimationPlayer object
]=]
function AnimationManager.Start(self: _AnimationManager)
	if RunService:IsServer() then
		self._connection = RunService.Heartbeat:Connect(function(dt)
			self:Update(dt)
		end)
	else
		self._connection = RunService.PostSimulation:Connect(function(dt)
			self:Update(dt)
		end)
	end
end

--[=[
	Stops the animation manager

	@method Start
	@within AnimationManager
	@param self AnimationManager -- The AnimationManager object
]=]
function AnimationManager.Stop(self: _AnimationManager)
	if self._connection then
		self._connection:Disconnect()
	end
end

--[=[
	Marks an animation for update

	@method Play
	@within AnimationPlayer
	@param self AnimationPlayer -- The AnimationPlayer object
]=]
function AnimationPlayer.Play(self: _AnimationPlayer)
	self.IsPlaying = true
	self._markForUpdate(self.IsPlaying)
end

--[=[
	Unmarks an animation for update

	@method Play
	@within AnimationPlayer
	@param self AnimationPlayer -- The AnimationPlayer object
]=]
function AnimationPlayer.Stop(self: _AnimationPlayer)
	self.IsPlaying = false
	self._markForUpdate(self.IsPlaying)
end

--[=[
	Updates an animation

	@method Step
	@within AnimationPlayer
	@param self AnimationPlayer -- The AnimationPlayer object
	@param dt number -- Used to calculate next limb(s) position
]=]
function AnimationPlayer.Step(
	self: _AnimationPlayer,
	dt: number
): () -- https://github.com/SteelProjectsRBX/BasicCrunchyrollAnimPlayer/blob/main/src/player.luau Most of impl is from here
	local totalTime = self._asset.length

	local newAlpha = self._track.alpha + (dt / totalTime)

	if newAlpha >= 1 and not self._track.looped then
		self._markForUpdate(false)
	end

	self._track.alpha = newAlpha % 1
end

--[=[
	Updates character limb's CFrames with new ones solved by crunchyroll

	@method UpdateCFrames
	@within AnimationPlayer
	@param self AnimationPlayer -- The AnimationPlayer object
	@param rootCF CFrame -- The root's CFrame of the npc
]=]
function AnimationPlayer.UpdateCFrames(self: _AnimationPlayer, rootCF: CFrame)
	for name, cf in self._rig.result_coordinate_frames do
		if name == "root" then
			continue
		end

		local corresponding: Motor6D = self._motors[name] -- change this to find motor6d in character ASAP
		local newCF = rootCF:ToObjectSpace(cf):Inverse() * corresponding.C0

		corresponding.C1 = newCF
	end
end

return AnimationManager
