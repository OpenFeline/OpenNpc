# NpcClass

A lightweight, type-safe NPC controller for Roblox that handles **movement**, **animation playback**, and **state management**, with built-in signaling and priority-based movement queuing.

Designed for **Luau strict typing**, **Moonwave documentation**, and non-Humanoid NPC workflows.

---

## Features

- 🚶 Priority-based movement queue  
- 📏 Size-aware arrival detection (supports NPCs of different sizes)  
- 🎞 Animation playback via `AnimationManager`  
- 🧠 Explicit NPC state management  
- 📡 Signals for movement completion and state changes  
- 🧩 Works on both server and client  
- 📚 Fully Moonwave-documented API  

---

## Basic Usage

### Creating an NPC
```lua
local OpenNPC = require(path.to.OpenNPC)

local npc = OpenNPC.new(
	npcModel,
	rig,
	16 -- walk speed (studs/sec)
)
```

### Moving an NPC
```lua
npc:MoveTo(Vector3.new(0,0,0))
npc:MoveTo(Vector3.new(20, 0, 10), 10) -- higher priority
```

### Listening for Movement Completion
```lua
npc.MoveToFinished:Connect(function()
	print("NPC finished all movement")
end)
```

### State Changes
```lua
npc.StateChanged:Connect(function(state)
	print("New state:", state)
end)
```

### Playing Animations
```lua
local walk = NPCController:LoadAnimation({
	alpha = 0,
	looped = true,
	priority = 1,
	stop_fade_time = 1,
	start_fade_time = 1,
	weight = 1,
}, ReplicatedStorage.animations.Walk)

walk:Play()
```

---

### Design Notes
. Does not rely on Humanoid
. Suitable for AI, enemies, animals, and scripted NPCs
. Movement radius automatically scales with NPC size
. Designed for extension via higher-level AI/state logic

---

### Documentation

This module is documented with **Moonwave**

---

### License

MIT
