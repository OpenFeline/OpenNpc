export type AnimationPlayer = {
	UpdateCFrames: (self: AnimationPlayer, rootCF: CFrame) -> (),
	Step: (self: AnimationPlayer, dt: number) -> (),
	Play: (self: AnimationPlayer) -> (),
	Stop: (self: AnimationPlayer) -> (),
	IsPlaying: boolean,
}

export type AnimationManager = {
	Update: (self: AnimationManager, dt: number) -> (),
	LoadAnimation: (self: AnimationManager, animation: string | Animation) -> AnimationPlayer,
	GetPlayingTracks: (self: AnimationManager) -> { [string]: AnimationPlayer },
	Start: (self: AnimationManager) -> (),
	Stop: (self: AnimationManager) -> (),
}

return {}
