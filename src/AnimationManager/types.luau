local ReplicatedStorage = game:GetService("ReplicatedStorage")
local crunchyroll = require(ReplicatedStorage.OpenNpc.Packages.crunchyroll)
export type AnimationPlayer = {
	UpdateCFrames: (self: AnimationPlayer, rootCF: CFrame) -> (),
	Step: (self: AnimationPlayer, dt: number) -> (),
	Play: (self: AnimationPlayer) -> (),
	Stop: (self: AnimationPlayer) -> (),
	IsPlaying: boolean,
}

export type AnimationManager = {
	Update: (self: AnimationManager, dt: number) -> (),
	LoadAnimation: (
		self: AnimationManager,
		options: crunchyroll.AnimationTrack,
		animation: KeyframeSequence
	) -> AnimationPlayer,
	GetPlayingTracks: (self: AnimationManager) -> { [string]: AnimationPlayer },
	Start: (self: AnimationManager) -> (),
	Stop: (self: AnimationManager) -> (),
}

export type PlayData = crunchyroll.AnimationTrack & {
	looped: boolean,
}

return {}
