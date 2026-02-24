Config = {}

-- ============================================
-- INTERACTION SYSTEM SETTINGS
-- ============================================

-- Visual Settings
Config.RowSpace = 0.03                         -- Space between menu rows (smaller = closer together)

-- Distance Settings
Config.InteractionDistance = 15.0              -- Max distance to scan for nearby interactions (in meters)
Config.FocusThreshold = 0.125                  -- Screen distance threshold for auto-focusing on interaction

-- Keybinds
Config.InteractionKey = 0x8AAA0AD4             -- Key to hold for interactions (default: ALT)
Config.SelectKey = 0x17BEC168                  -- Key to select option (default: Left Mouse Button)
Config.ScrollUpKey = 0x9DA42644                -- Key to scroll up in menu (default: Mouse Wheel Up)
Config.ScrollDownKey = 0x81457A1A              -- Key to scroll down in menu (default: Mouse Wheel Down)
Config.UpKey = 0x6319DB71                      -- Alternative Up Key (UP ARROW)
Config.DownKey = 0x05CA7C52                    -- Alternative Down Key (DOWN ARROW)

-- Animation Settings
Config.FadeSpeed = 5                            -- Speed of fade in/out animation (higher = faster)


-- Entity Detection Settings
Config.ScanOnlyHumans = true                   -- Only scan human peds for interactions
Config.SkipMountedPeds = true                  -- Skip peds that are on a mount
Config.RequireNetworked = true                 -- Only detect networked entities
Config.SkipDeadPeds = true                    -- Skip dead peds from auto-detection (set false to allow interactions with dead)

-- ============================================
-- BUILT-IN PED INTERACTIONS
-- These options appear when holding ALT near NPCs/Players
-- ============================================

Config.PedOptions = {
    -- {
    --     text = "Sell Items",
    --     town = "xd",
    --     canUse = function(self, entity)
    --         -- Only show for NPCs that are not busy and player is not on mount
    --         return not IsPedAPlayer(entity) 
    --             and not IsPedOnMount(PlayerPedId()) 
    --     end,
    --     onSelect = function(self, entity)
    --         print("Selling items to NPC...")
    --         print(self.town)
    --         -- Add your sell items logic here
    --     end,
    -- },
    -- {
    --     text = "Search Player",
    --     canUse = function(self, entity)
    --         -- Only show for players that are restrained or dead
    --         return IsPedAPlayer(entity) and (
    --             IsEntityPlayingAnim(entity, "script_proc@robberies@shop@rhodes@gunsmith@inside_upstairs", "handsup_register_owner", 3)
    --             or IsEntityDead(entity) 
    --             or IsPedHogtied(entity) 
    --             or IsPedCuffed(entity)
    --         )
    --     end,
    --     onSelect = function(self,entity)
    --         local playerId = NetworkGetPlayerIndexFromPed(entity)
    --         local serverId = GetPlayerServerId(playerId)
    --         print("Searching player inventory... Server ID: " .. serverId)
    --         -- Add your search player logic here
    --     end,
    -- },
    -- Add more default ped options here
}
-- Disabled Controls While Interaction Menu is Open
Config.DisabledControls = {
    0xFD0F0C2C,  -- INPUT_NEXT_WEAPON // MOUSE SCROLL DOWN
    0xCC1075A7,  -- INPUT_PREV_WEAPON // MOUSE SCROLL UP
    0x018C47CF,  -- INPUT_MELEE_GRAPPLE_CHOKE // E
    0x17D3BFF5,  -- INPUT_INTERACT_LEAD_ANIMAL // E
    0x2277FAE9,  -- INPUT_MELEE_GRAPPLE // E
    0x2EAB0795,  -- INPUT_DYNAMIC_SCENARIO // E
    0x399C6619,  -- INPUT_LOOT2 // E
    0x41AC83D1,  -- INPUT_LOOT // E
    0x91C9A817,  -- INPUT_MELEE_GRAPPLE_REVERSAL // E
}

