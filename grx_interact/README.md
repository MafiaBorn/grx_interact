# 🎮 GRX Interaction System for RedM

A modern, flexible, and performance-optimized interaction system for RedM servers. This resource provides an intuitive ALT-based menu system for interacting with entities, NPCs, and players.

![RedM](https://img.shields.io/badge/RedM-Compatible-red)
![License](https://img.shields.io/badge/license-GPL--3.0-green)
![Version](https://img.shields.io/badge/version-1.0.0-blue)

- Discord: [PolyCode](https://discord.gg/xeK65AX9b5)

## ✨ Features

- **🎯 Smart Entity Detection** - Automatically detects nearby players and NPCs
- **🔄 Dynamic Option System** - Conditional options based on entity state
- **📦 API for Developers** - Easy integration with other resources
- **🎨 Clean UI** - Beautiful, minimalist interaction menu
- **⚡ Performance Optimized** - Efficient entity scanning and rendering
- **🔧 Fully Customizable** - Easy to extend and modify

## 📸 Preview

<img width="356" height="158" alt="image" src="https://github.com/user-attachments/assets/2eaba40e-fa63-407d-a062-71059f149b9c" />


## 📋 Requirements

- RedM Server
- No framework dependencies (standalone)
- `interaction_menu.ytd` texture file (included)

## 🚀 Installation

1. Download the latest release
2. Extract `grx_interact` to your resources folder
3. Place `interaction_menu.ytd` in your server's stream folder
4. Add `ensure grx_interact` to your `server.cfg`
5. Restart your server

## 🎮 Usage

### For Players

1. **Hold ALT key** - Activates interaction mode and shows nearby interaction points
2. **Look at interaction point** - When you look near an interaction point, it will expand into a menu
3. **Mouse Wheel Up/Down** - Navigate through available options in the menu
4. **Left Mouse Button** - Select and execute the highlighted option
5. **Release ALT** - Closes interaction mode and hides all menus

**Tips:**
- Interaction points appear as small circular icons when holding ALT
- Get closer to the icon to see available options
- The menu automatically focuses on the interaction you're looking at
- Some options only appear under certain conditions (e.g., "Search Player" only shows if player is restrained)

---

## 🔧 For Server Owners

### Quick Setup

Edit `config.lua` to customize the system:

```lua
-- Change keybinds
Config.InteractionKey = 0x8AAA0AD4  -- Default: ALT
Config.SelectKey = 0x17BEC168        -- Default: Left Mouse Button

-- Adjust distances
Config.InteractionDistance = 15.0    -- How far to scan for interactions
Config.RenderDistance = 5.0          -- When icons become visible

-- Add default ped interactions
Config.PedOptions = {
    {
        text = "Rob NPC",
        canUse = function(self, entity)
            return not IsPedAPlayer(entity) and not IsEntityDead(entity)
        end,
        onSelect = function(self, entity)
            -- Your robbery logic here
            TriggerServerEvent('robbery:startRobbery', entity)
        end
    }
}
```

---

## 💻 For Developers

### Getting the Export

First, get the interaction export in your resource:

```lua
local Interaction = exports['grx_interact']:GetApi()
```

### 1. Creating Static Interactions (In Any Resource)

Static interactions are fixed points in the world:

```lua
-- Get the export first
local Interaction = exports['grx_interact']:GetApi()

-- Example: Door interaction
Interaction.CreateInteraction(
    "saloon_door_main",                  -- Unique ID (must be unique!)
    vector3(-308.34, 775.28, 118.80),   -- Position in world
    {                                     -- Options table
        {
            text = "Open Door",
            onSelect = function(self, entity)
                -- Code to execute when selected
                TriggerServerEvent('doors:toggle', 'saloon_main')
            end
        },
        {
            text = "Lock Door",
            canUse = function(self, entity)
                -- Only show if player has key
                return hasKey == true
            end,
            onSelect = function(self, entity)
                TriggerServerEvent('doors:lock', 'saloon_main')
            end
        }
    },
    5.0,  -- Render distance (when icon appears)
    2.0   -- Interaction distance (how close to use it)
)
```

### 2. Creating Entity Interactions (Attach to NPCs/Objects)

Entity interactions follow a specific entity:

```lua
-- Get the export
local Interaction = exports['grx_interact']:GetApi()

-- Example: Shop keeper NPC
local shopkeeper = CreatePed(...) -- Your NPC

Interaction.CreateEntityInteraction(
    "shopkeeper_" .. shopkeeper,         -- Unique ID
    shopkeeper,                          -- Entity handle
    {
        {
            text = "Browse Catalog",
            onSelect = function(self, entity)
                TriggerServerEvent('shop:open', 'general')
            end
        },
        {
            text = "Sell Items",
            onSelect = function(self, entity)
                TriggerServerEvent('shop:sell')
            end
        }
    },
    3.0,           -- Render distance
    1.5,           -- Interaction distance
    vector3(0, 0, 1.0),  -- Optional: Offset from entity (X, Y, Z)
    47576          -- Optional: Bone index (47576 = head)
)
```

### 3. Conditional Options (canUse Function)

Show options only when conditions are met:

```lua
local Interaction = exports['grx_interact']:GetApi()

local options = {
    {
        text = "Search Player",
        canUse = function(self, entity)
            -- This option only appears if ALL conditions are true
            return IsPedAPlayer(entity)           -- Is a player
                and IsPedHogtied(entity)          -- Is hogtied
                and not LocalPlayer.state.isBusy  -- You're not busy
        end,
        onSelect = function(self, entity)
            local playerId = NetworkGetPlayerIndexFromPed(entity)
            local serverId = GetPlayerServerId(playerId)
            TriggerServerEvent('police:searchPlayer', serverId)
        end
    },
    {
        text = "Untie",
        canUse = function(self, entity)
            return IsPedHogtied(entity) or IsPedCuffed(entity)
        end,
        onSelect = function(self, entity)
            -- Untie logic
        end
    }
}
```

### 4. Registering Global Ped Options (From Your Resource)

Make your interactions appear on ALL nearby peds automatically:

```lua
-- In your resource's client.lua file

-- Register on resource start

-- Get the export
local Interaction = exports['grx_interact']:GetApi()

CreateThread(function()

    local myPedOptions = {
        {
            text = "Give $10",
            canUse = function(self, entity)
                -- Only show for NPCs, not players
                return not IsPedAPlayer(entity) and not IsEntityDead(entity)
            end,
            onSelect = function(self, entity)
                TriggerServerEvent('money:giveToNpc', 10)
            end
        },
        {
            text = "Arrest Player",
            canUse = function(self, entity)
                -- Only for players, and you must be sheriff
                return IsPedAPlayer(entity) 
                    and LocalPlayer.state.job == 'sheriff'
            end,
            onSelect = function(self, entity)
                local playerId = NetworkGetPlayerIndexFromPed(entity)
                TriggerServerEvent('sheriff:arrest', GetPlayerServerId(playerId))
            end
        }
    }
    
    -- Register the options
    Interaction.RegisterPedOptions(resourceName, myPedOptions)
    print("Registered ped interactions!")
end)

-- IMPORTANT: Clean up when resource stops
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    local Interaction = exports['grx_interact']:GetApi()
    Interaction.UnregisterPedOptions(resourceName)
end)
```

### 5. Dynamic Text Updates

Change interaction text based on state:

```lua
local Interaction = exports['grx_interact']:GetApi()

-- Create interaction with initial text
Interaction.CreateInteraction(
    "dynamic_door",
    vector3(-318.61, 800.10, 116.80),
    {
        { text = "Open Door" }  -- Initial state
    },
    5.0,
    2.0
)

-- Later, update based on state
RegisterNetEvent('door:stateChanged')
AddEventHandler('door:stateChanged', function(doorId, isOpen)
    if doorId == "dynamic_door" then
        local newText = isOpen and "Close Door" or "Open Door"
        Interaction.ChangeOptionText("dynamic_door", 1, newText)
    end
end)
```

### 6. Deleting Interactions

Remove interactions when no longer needed:

```lua
local Interaction = exports['grx_interact']:GetApi()

-- Delete after one-time use
Interaction.CreateInteraction(
    "treasure_chest",
    vector3(-320.0, 785.0, 119.0),
    {
        {
            text = "Open Chest",
            onSelect = function(self, entity)
                TriggerServerEvent('loot:openChest', 'treasure_1')
                -- Remove interaction after opening
                Interaction.DeleteInteraction("treasure_chest")
            end
        }
    },
    5.0,
    2.0
)

-- Or delete based on server event
RegisterNetEvent('interaction:remove')
AddEventHandler('interaction:remove', function(interactionId)
    Interaction.DeleteInteraction(interactionId)
end)
```

### 7. Complete Example: Dynamic NPC Shop

```lua
-- Get the export
local Interaction = exports['grx_interact']:GetApi()

-- Spawn NPC
local shopNpc = CreatePed(
    `A_M_M_UNIDUSTRIAL_01`,
    -308.34, 775.28, 118.80,
    90.0,
    false,
    false
)

-- Make NPC stay in place
FreezeEntityPosition(shopNpc, true)
SetEntityInvincible(shopNpc, true)

-- Add interaction
Interaction.CreateEntityInteraction(
    "gunsmith_npc",
    shopNpc,
    {
        {
            text = "Browse Weapons",
            canUse = function(self, entity)
                -- Only during day time (6am - 10pm)
                local hour = GetClockHours()
                return hour >= 6 and hour < 22
            end,
            onSelect = function(self, entity)
                TriggerServerEvent('shop:open', 'weapons')
            end
        },
        {
            text = "Sell Items",
            onSelect = function(self, entity)
                TriggerServerEvent('shop:sellMenu')
            end
        },
        {
            text = "Shop Closed",
            canUse = function(self, entity)
                local hour = GetClockHours()
                return hour < 6 or hour >= 22
            end,
            onSelect = function(self, entity)
                TriggerEvent('chat:addMessage', {
                    args = { "Shop is closed. Come back between 6am-10pm" }
                })
            end
        }
    },
    3.0,   -- Visible from 3m
    1.5,   -- Must be within 1.5m to use
    vector3(0, 0, 0.0),  -- Offset
    47576  
)

-- Clean up on resource stop
local Interaction = exports['grx_interact']:GetApi()

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    DeleteEntity(shopNpc)
    
    
    Interaction.DeleteInteraction("gunsmith_npc")
end)
```

---

## 📚 Common Use Cases

### Use Case 1: Job-Specific Interactions
```lua
-- Police handcuff interaction
{
    text = "Handcuff",
    canUse = function(self, entity)
        return IsPedAPlayer(entity)
            and LocalPlayer.state.job == 'police'
            and not IsPedCuffed(entity)
            and not IsEntityDead(entity)
    end,
    onSelect = function(self, entity)
        local playerId = NetworkGetPlayerIndexFromPed(entity)
        TriggerServerEvent('police:cuff', GetPlayerServerId(playerId))
    end
}
```

### Use Case 2: Item Requirement
```lua
-- Lockpick door (requires lockpick item)
{
    text = "Lockpick Door",
    canUse = function(self, entity)
        -- Check if player has lockpick
        return exports.inventory:hasItem('lockpick')
    end,
    onSelect = function(self, entity)
        -- Start lockpicking minigame
        TriggerEvent('lockpick:start', 'door_123')
    end
}
```

### Use Case 3: Using Custom Data
```lua
-- Multiple doors with different properties
local doors = {
    {
        coords = vector3(-308.0, 775.0, 118.0),
        doorId = "saloon_main",
        requiredJob = "bartender",
        lockLevel = 1
    },
    {
        coords = vector3(-310.0, 780.0, 118.0),
        doorId = "saloon_storage",
        requiredJob = "bartender",
        lockLevel = 3
    }
}

local Interaction = exports['grx_interact']:GetApi()

for _, door in ipairs(doors) do
    Interaction.CreateInteraction(
        door.doorId,
        door.coords,
        {
            {
                text = "Unlock Door",
                -- Store custom data in the option
                doorId = door.doorId,
                requiredJob = door.requiredJob,
                lockLevel = door.lockLevel,
                
                canUse = function(self, entity)
                    -- Use custom data in conditions
                    return LocalPlayer.state.job == self.requiredJob
                        and exports.inventory:hasItem('lockpick_level_' .. self.lockLevel)
                end,
                
                onSelect = function(self, entity)
                    -- Access custom data
                    print("Unlocking door: " .. self.doorId)
                    print("Required level: " .. self.lockLevel)
                    TriggerServerEvent('doors:unlock', self.doorId)
                end
            }
        },
        5.0,
        2.0
    )
end
```

---

## 🎯 Advanced Usage

### System Events for Dynamic Objects

The interaction system provides events to scan and add interactions to nearby dynamic objects when ALT is pressed.

#### rdr-interactions:load
This event is triggered when the player presses ALT and the system scans for nearby interactions.

**Primary Use Case:** Scan for nearby objects (chairs, rocks, items, etc.) and add interactions to them dynamically.

```lua
-- Example: Add interactions to all nearby chairs
local Interaction = exports['grx_interact']:GetApi()

AddEventHandler('rdr-interactions:load', function()
    
    local playerCoords = GetEntityCoords(PlayerPedId())
    
    -- Get all objects in radius
    local objects = GetGamePool('CObject')
    
    for _, object in ipairs(objects) do
        local objectCoords = GetEntityCoords(object)
        local distance = #(playerCoords - objectCoords)
        
        -- Only process objects within 15 meters
        if distance < 15.0 then
            local objectHash = GetEntityModel(object)
            
            -- Check if it's a chair
            if objectHash == GetHashKey('p_chair01x') or 
               objectHash == GetHashKey('p_chair02x') or
               objectHash == GetHashKey('p_chair_crate01x') then
                
                Interaction.CreateEntityInteraction(
                    "chair_" .. object,
                    object,
                    {
                        {
                            text = "Sit Down",
                            onSelect = function(self, entity)
                                -- Sit on chair logic
                                TaskStartScenarioAtPosition(PlayerPedId(), 
                                    GetHashKey("WORLD_HUMAN_SIT_GROUND"), 
                                    objectCoords.x, objectCoords.y, objectCoords.z, 
                                    0.0, -1, true, false)
                            end
                        }
                    },
                    3.0,
                    1.5
                )
            end
        end
    end
end)
```

#### rdr-interactions:unload
This event is triggered when the player releases ALT. Use it to clean up dynamically created interactions.

**Primary Use Case:** Remove all object interactions that were created in the `load` event.

```lua
-- Clean up all dynamic object interactions
AddEventHandler('rdr-interactions:unload', function()
    -- Object interactions are automatically cleaned up by the system
    -- But you can also manually delete specific ones if needed
    print("Interaction mode closed - dynamic objects cleared")
end)
```

---

### Complete Examples

#### Example 1: Interactive Rocks/Minerals

```lua
-- Table to track which rocks have interactions
local rockInteractions = {}

AddEventHandler('rdr-interactions:load', function()
    local Interaction = exports['grx_interact']:GetApi()
    local playerCoords = GetEntityCoords(PlayerPedId())
    local objects = GetGamePool('CObject')
    
    rockInteractions = {}
    
    for _, object in ipairs(objects) do
        local objectCoords = GetEntityCoords(object)
        local distance = #(playerCoords - objectCoords)
        
        if distance < 15.0 then
            local objectHash = GetEntityModel(object)
            
            -- Check for rock models
            if objectHash == GetHashKey('p_rock01x') or 
               objectHash == GetHashKey('p_rock02x') or
               objectHash == GetHashKey('p_rock_grey_01') then
                
                local interactionId = "rock_" .. object
                table.insert(rockInteractions, interactionId)
                
                Interaction.CreateEntityInteraction(
                    interactionId,
                    object,
                    {
                        {
                            text = "Mine Rock",
                            canUse = function(self, entity)
                                return exports.inventory:hasItem('pickaxe')
                            end,
                            onSelect = function(self, entity)
                                TriggerEvent('mining:start', entity)
                            end
                        },
                        {
                            text = "Inspect Rock",
                            onSelect = function(self, entity)
                                TriggerEvent('chat:addMessage', {
                                    args = { "This rock contains minerals" }
                                })
                            end
                        }
                    },
                    5.0,
                    2.0
                )
            end
        end
    end
    
    print("^2Found " .. #rockInteractions .. " rocks nearby^0")
end)

AddEventHandler('rdr-interactions:unload', function()
    rockInteractions = {}
end)
```

#### Example 2: Interactive Furniture/Props

```lua
local furnitureInteractions = {}

AddEventHandler('rdr-interactions:load', function()
    local Interaction = exports['grx_interact']:GetApi()
    local playerCoords = GetEntityCoords(PlayerPedId())
    local objects = GetGamePool('CObject')
    
    furnitureInteractions = {}
    
    for _, object in ipairs(objects) do
        local objectCoords = GetEntityCoords(object)
        local distance = #(playerCoords - objectCoords)
        
        if distance < 15.0 then
            local objectHash = GetEntityModel(object)
            local interactionId = "furniture_" .. object
            
            -- Beds
            if objectHash == GetHashKey('p_bed01x') or
               objectHash == GetHashKey('p_bed02x') then
                
                table.insert(furnitureInteractions, interactionId)
                
                Interaction.CreateEntityInteraction(
                    interactionId,
                    object,
                    {
                        {
                            text = "Sleep",
                            onSelect = function(self, entity)
                                TriggerEvent('sleep:start', entity)
                            end
                        },
                        {
                            text = "Set Respawn Point",
                            onSelect = function(self, entity)
                                TriggerServerEvent('respawn:setBed', objectCoords)
                            end
                        }
                    },
                    3.0,
                    1.5
                )
                
            -- Stoves/Campfires
            elseif objectHash == GetHashKey('p_campfire01x') or
                   objectHash == GetHashKey('p_stove01x') then
                
                table.insert(furnitureInteractions, interactionId)
                
                Interaction.CreateEntityInteraction(
                    interactionId,
                    object,
                    {
                        {
                            text = "Cook Food",
                            canUse = function(self, entity)
                                return exports.inventory:hasRawFood()
                            end,
                            onSelect = function(self, entity)
                                TriggerEvent('cooking:openMenu', entity)
                            end
                        },
                        {
                            text = "Warm Up",
                            onSelect = function(self, entity)
                                TriggerEvent('temperature:warmUp')
                            end
                        }
                    },
                    3.0,
                    1.5
                )
                
            -- Storage boxes/chests
            elseif objectHash == GetHashKey('p_chest01x') or
                   objectHash == GetHashKey('p_cratebag01x') then
                
                table.insert(furnitureInteractions, interactionId)
                
                Interaction.CreateEntityInteraction(
                    interactionId,
                    object,
                    {
                        {
                            text = "Open Storage",
                            onSelect = function(self, entity)
                                TriggerServerEvent('storage:open', object)
                            end
                        }
                    },
                    3.0,
                    1.5
                )
            end
        end
    end
    
    if #furnitureInteractions > 0 then
        print("^2Found " .. #furnitureInteractions .. " interactive objects^0")
    end
end)

AddEventHandler('rdr-interactions:unload', function()
    furnitureInteractions = {}
end)
```

---

**Best Practices:**
- Use `rdr-interactions:load` to scan for nearby objects/entities
- Always check distance to avoid too many interactions
- Use model hashes to identify specific object types
- Store interaction IDs in a table for reference
- The system automatically cleans up entity-based interactions when entities are deleted
- These events fire every time ALT is pressed/released, so they're perfect for dynamic scanning

---

## 🔧 API Reference

### Getting the Export

In your resource, first get the interaction export:

```lua
local Interaction = exports['grx_interact']:GetApi()
```

---

### Interaction.CreateInteraction
Create a static world interaction at a fixed position.

**Syntax:**
```lua
Interaction.CreateInteraction(id, position, options, renderDistance, interactionDistance)
```

**Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| `id` | string | Unique identifier for this interaction |
| `position` | vector3 | World coordinates (x, y, z) |
| `options` | table | Array of option objects (see below) |
| `renderDistance` | number | Distance in meters when icon appears |
| `interactionDistance` | number | Distance in meters to use interaction |

**Option Object Structure:**
```lua
{
    text = "Action Name",                -- Text shown in menu (required)
    canUse = function(self, entity)      -- Optional: condition check
        return true                      -- Return true to show option
    end,
    onSelect = function(self, entity)    -- Function to execute (required)
        -- Your code here
        -- Access custom data via self
        print(self.myCustomData)
    end,
    
    -- You can add any custom key-value pairs for your script needs
    myCustomData = "some value",
    index = 1,
    town = "valentine",
    itemType = "weapon",
    -- etc...
}
```

**Custom Data in Options:**

You can add any custom key-value pairs to options. Access them via `self` parameter in `canUse` and `onSelect` functions.

**Example with Custom Data:**
```lua
local Interaction = exports['grx_interact']:GetApi()

Interaction.CreateInteraction(
    "town_hall",
    vector3(-308.34, 775.28, 118.80),
    {
        {
            text = "Register Business",
            town = "valentine",           -- Custom data
            businessType = "shop",        -- Custom data
            fee = 50,                     -- Custom data
            
            canUse = function(self, entity)
                -- Access custom data
                local playerMoney = exports.bank:getMoney()
                return playerMoney >= self.fee  -- Using self.fee
            end,
            
            onSelect = function(self, entity)
                -- Access all custom data via self
                print("Registering business in: " .. self.town)
                print("Business type: " .. self.businessType)
                TriggerServerEvent('business:register', self.town, self.businessType, self.fee)
            end
        },
        {
            text = "Pay Taxes",
            town = "valentine",
            taxAmount = 25,
            
            onSelect = function(self, entity)
                TriggerServerEvent('taxes:pay', self.town, self.taxAmount)
            end
        }
    },
    5.0,
    2.0
)
```

**Advanced Example - Menu System with Index:**
```lua
local Interaction = exports['grx_interact']:GetApi()

-- Creating multiple similar options with different data
local shopItems = {
    { name = "Revolver", price = 150, itemId = "weapon_revolver" },
    { name = "Rifle", price = 300, itemId = "weapon_rifle" },
    { name = "Shotgun", price = 250, itemId = "weapon_shotgun" }
}

local shopOptions = {}

for index, item in ipairs(shopItems) do
    table.insert(shopOptions, {
        text = string.format("Buy %s ($%d)", item.name, item.price),
        
        -- Custom data
        index = index,
        itemName = item.name,
        itemPrice = item.price,
        itemId = item.itemId,
        
        canUse = function(self, entity)
            local money = exports.bank:getMoney()
            return money >= self.itemPrice
        end,
        
        onSelect = function(self, entity)
            print(string.format("Buying item #%d: %s", self.index, self.itemName))
            TriggerServerEvent('shop:buyItem', self.itemId, self.itemPrice)
        end
    })
end

Interaction.CreateInteraction("gunsmith_shop", shopCoords, shopOptions, 5.0, 2.0)
```

**Example with Location Data:**
```lua
local Interaction = exports['grx_interact']:GetApi()

-- Create interactions for multiple town halls
local towns = {
    { name = "Valentine", coords = vector3(-175.0, 627.0, 114.0) },
    { name = "Saint Denis", coords = vector3(2509.0, -1306.0, 48.0) },
    { name = "Blackwater", coords = vector3(-813.0, -1324.0, 43.0) }
}

for _, town in ipairs(towns) do
    Interaction.CreateInteraction(
        "town_hall_" .. town.name:lower(),
        town.coords,
        {
            {
                text = "Read Town Notice",
                townName = town.name,  -- Custom data
                
                onSelect = function(self, entity)
                    -- Access town name from self
                    TriggerServerEvent('town:getNotices', self.townName)
                end
            },
            {
                text = "Register Property",
                townName = town.name,
                registrationFee = 100,
                
                onSelect = function(self, entity)
                    TriggerServerEvent('property:register', self.townName, self.registrationFee)
                end
            }
        },
        5.0,
        2.0
    )
end
```
```lua
local Interaction = exports['grx_interact']:GetApi()

Interaction.CreateInteraction(
    "bank_door",
    vector3(-308.34, 775.28, 118.80),
    {
        { 
            text = "Enter Bank",
            onSelect = function() 
                TriggerEvent('bank:enter') 
            end 
        }
    },
    5.0,
    2.0
)
```

---

### Interaction.CreateEntityInteraction
Create an interaction attached to a moving entity (NPC, player, object).

**Syntax:**
```lua
Interaction.CreateEntityInteraction(id, entity, options, renderDistance, interactionDistance, offset, bone)
```

**Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| `id` | string | Unique identifier |
| `entity` | number | Entity handle (from CreatePed, etc.) |
| `options` | table | Array of option objects |
| `renderDistance` | number | Distance when icon appears |
| `interactionDistance` | number | Distance to use interaction |
| `offset` | vector3 | Position offset from entity (optional) |
| `bone` | number | Bone index to attach to (optional) |

**Common Bone Indices:**
- `47576` - Head
- `24818` - Right Hand
- `57005` - Chest

**Example:**
```lua
local Interaction = exports['grx_interact']:GetApi()
local npc = CreatePed(`A_M_M_UNIDUSTRIAL_01`, x, y, z, heading, false, false)

Interaction.CreateEntityInteraction(
    "npc_shopkeeper",
    npc,
    {
        { 
            text = "Talk",
            onSelect = function(self, entity) 
                print("Talking to NPC") 
            end 
        }
    },
    3.0,
    1.5,
    vector3(0, 0, 1.0),  -- 1 meter above entity
    47576                 -- Attach to head
)
```

---

### Interaction.RegisterPedOptions
Register interaction options that appear on ALL nearby peds (from external resources).

**Syntax:**
```lua
Interaction.RegisterPedOptions(resourceName, options)
```

**Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| `resourceName` | string | Name of your resource (use GetCurrentResourceName()) |
| `options` | table | Array of option objects |

**Returns:** `boolean` - Success status

**Example:**
```lua
local Interaction = exports['grx_interact']:GetApi()

CreateThread(function() 
    
    local success = Interaction.RegisterPedOptions(resourceName, {
        {
            text = "Custom Action",
            canUse = function(self, entity) return true end,
            onSelect = function(self, entity) print("Action!") end
        }
    })
    
    if success then
        print("Options registered!")
    end
end)
```

---

### Interaction.UnregisterPedOptions
Remove previously registered ped options.

**Syntax:**
```lua
Interaction.UnregisterPedOptions(resourceName)
```

**Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| `resourceName` | string | Name of your resource |

**Returns:** `boolean` - Success status

**Example:**
```lua
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    Interaction.UnregisterPedOptions(resourceName)
end)
```

---

### Interaction.ChangeOptionText
Dynamically update the text of an interaction option.

**Syntax:**
```lua
Interaction.ChangeOptionText(id, optionIndex, text)
```

**Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| `id` | string | Interaction ID |
| `optionIndex` | number | Option position (1-based index) |
| `text` | string | New text to display |

**Example:**
```lua
local Interaction = exports['grx_interact']:GetApi()

-- Change first option's text
Interaction.ChangeOptionText("my_door", 1, "Door Locked")

-- Update based on state
if doorOpen then
    Interaction.ChangeOptionText("my_door", 1, "Close Door")
else
    Interaction.ChangeOptionText("my_door", 1, "Open Door")
end
```

---

### Interaction.DeleteInteraction
Remove an interaction completely.

**Syntax:**
```lua
Interaction.DeleteInteraction(id)
```

**Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| `id` | string | Interaction ID to remove |

**Example:**
```lua
local Interaction = exports['grx_interact']:GetApi()

-- Remove after use
Interaction.DeleteInteraction("treasure_chest")

-- Remove when entity dies
AddEventHandler('onClientResourceStop', function(resourceName)
    Interaction.DeleteInteraction("my_interaction")
end)
```

---

## 🐛 Troubleshooting

### Interactions not showing up
1. Make sure you're holding the ALT key (or configured key)
2. Check if you're within `Config.InteractionDistance` range
3. Verify the interaction was created successfully (check F8 console)
4. Ensure `interaction_menu.ytd` is properly streamed

### Can't select options
1. Check if `canUse` function is returning `true`
2. Verify you're within `interactionDistance` (not just `renderDistance`)
3. Make sure the interaction has options with `onSelect` functions

### Performance issues
1. Reduce `Config.InteractionDistance` (default: 15.0)
2. Increase `Config.UpdateInterval` (default: 100ms)
3. Use `canUse` to filter unnecessary options
4. Set `Config.ScanOnlyHumans = true`

### External resource options not appearing
1. Ensure resource starts AFTER `grx_interact` (add to `server.cfg` after it)
2. Get the export correctly: `local Interaction = exports['grx_interact']:GetApi()`
3. Check that `Interaction.RegisterPedOptions()` is called on resource start
4. Verify resource name matches: `GetCurrentResourceName()`
5. Make sure to unregister on resource stop

### Entity interactions disappear
1. Check if entity still exists: `DoesEntityExist(entity)`
2. Verify entity is networked if `Config.RequireNetworked = true`
3. Re-create interaction if entity respawns

---

## 🎨 Customization

### Change UI Texture
Replace `interaction_menu.ytd` with your custom texture:
1. Edit your `.ytd` file with OpenIV or similar
2. Keep sprite names: `i_p`, `i_c`, `i_cf`, `i_cfe`
3. Replace file in stream folder
4. Restart resource

---

## 📝 Changelog

### Version 1.0.0
- Initial release
- Basic interaction system
- Entity and static interactions
- External resource API

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 💖 Support

If you find this resource useful, please consider:
- ⭐ Starring the repository
- 🐛 Reporting bugs
- 💡 Suggesting new features
- 🔄 Sharing with other developers

## 📧 Contact

- GitHub: [@Ktos93](#)
- Discord: [PolyCode](https://discord.gg/xeK65AX9b5)

## 🙏 Credits

Created with ❤️ for the RedM community
