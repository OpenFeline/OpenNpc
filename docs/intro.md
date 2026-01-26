---
sidebar_position: 1
---

# Getting Started with OpenNPC
Install the library via Pesde:
```
pesde install openfeline/opennpc
```
---
## Usage

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
