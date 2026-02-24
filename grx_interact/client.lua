ExportInteractions = {}

exports('GetApi', function()
    return ExportInteractions
end)

-- ============================================
-- LOAD CONFIGURATION
-- ============================================

local TEXTURE_DICT = "pc_interaction"
local IS_ALT_PRESSED = false
local CURRENT_INTERACTION_INDEX
local ALPHA = 0
local ASPECT_RATIO = GetAspectRatio()

-- ============================================
-- INTERNAL TABLES
-- ============================================

local Interactions = {}         -- All registered interactions
local ClosestInteractions = {}  -- Nearby interactions cache
local InteractionPedList = {}   -- Dynamic NPC interactions
local RegisteredPedOptions = {} -- Ped options from external resources

-- InteractionsTable Class
local InteractionsTable = {}
InteractionsTable.__index = InteractionsTable
setmetatable(Interactions, InteractionsTable)

-- Create new interaction
function InteractionsTable:CreateInteraction(id, position, options, renderDistance, interactionDistance)
    local interaction = setmetatable({
        id = id,
        position = position,
        options = options,
        renderDistance = renderDistance,
        interactionDistance = interactionDistance,
        selected_index = 1
    }, self)
    Interactions[id] = interaction
    return interaction
end

function InteractionsTable:CreateEntityInteraction(id, entity, options, renderDistance, interactionDistance, offset, bone)
    local interaction = setmetatable({
        id = id,
        entity = entity,
        options = options,
        renderDistance = renderDistance,
        interactionDistance = interactionDistance,
        offset = offset or vector3(0, 0, 0),
        bone = bone,
        selected_index = 1,
    }, self)
    Interactions[id] = interaction
    return interaction
end

-- Get screen distance from center
function InteractionsTable:GetScreenDistance()
    local position = self:GetPosition()
    local isOnScreen, x, y = GetScreenCoordFromWorldCoord(position.x, position.y, position.z)
    return isOnScreen and #(vector2(x, y) - vector2(0.5, 0.5)) or 1.0
end

-- Get distance from player to interaction
function InteractionsTable:GetDistance()
    return #(self:GetPosition() - GetEntityCoords(PlayerPedId()))
end

-- Draw interaction menu

function InteractionsTable:DrawFull()
    SetDrawOrigin(self:GetPosition())

    DrawSprite(TEXTURE_DICT, "i_cfe", 0.0, 0.0, 0.02, 0.02 * ASPECT_RATIO, 0.0, 255, 255, 255, 255)

    local start_offset = (#self.activeOptions * Config.RowSpace) / 2 - Config.RowSpace / 2
    for i, data in ipairs(self.activeOptions) do
        local y_offset = (i - 1) * Config.RowSpace - start_offset
        local is_selected = (i == self.selected_index)
        local sprite_type = is_selected and "i_cf" or "i_c"
        local box_type = is_selected and "i_box_s" or "i_box"
        DrawSprite(TEXTURE_DICT, sprite_type, 0.02, y_offset, 0.015, 0.015 * ASPECT_RATIO, 0.0, 255, 255, 255, 255)
        DrawSprite(TEXTURE_DICT, box_type, 0.08, y_offset, 0.1, 0.015 * ASPECT_RATIO, 0.0, 255, 255, 255, 255)

        SetTextScale(0.3, 0.3)
        SetTextDropshadow(3, 0, 0, 0, 255)
        SetTextFontForCurrentCommand(9)
        DisplayText(CreateVarString(10, "LITERAL_STRING", data.text), 0.0325, -0.011 + y_offset)
    end
    ClearDrawOrigin()
end

-- Draw single interaction icon
function InteractionsTable:Draw()
    if self:ShouldDraw() then
        SetDrawOrigin(self:GetPosition())
        DrawSprite(TEXTURE_DICT, "i_c", 0.0, 0.0, 0.02, 0.02 * ASPECT_RATIO, 0.0, 255, 255, 255, ALPHA)
        ClearDrawOrigin()
    end
end

-- Check if interaction should be drawn
function InteractionsTable:ShouldDraw()
    return self:GetDistance() <= self.renderDistance and #self.activeOptions > 0
end

-- Can interact based on distance
function InteractionsTable:CanInteract()
    return self:GetDistance() <= self.interactionDistance
end

-- Get entity or static position
function InteractionsTable:GetPosition()
    if self.entity then
        if self.bone then
            return GetPedBoneCoords(self.entity, self.bone, self.offset)
        else
            return GetEntityCoords(self.entity) + self.offset
        end
    else
        return self.position or vector3(0, 0, 0)
    end
end

function InteractionsTable:IsEntityValid()
    if self.entity ~= nil then
        return DoesEntityExist(self.entity)
    else
        return true
    end
end

function InteractionsTable:ChangeOptionText(optionIndex, text)
    if self.options[optionIndex] then
        self.options[optionIndex].text = text
    end
end

-- Load texture dictionary
CreateThread(function()
    while not HasStreamedTextureDictLoaded(TEXTURE_DICT) do
        RequestStreamedTextureDict(TEXTURE_DICT, true)
        Wait(100)
    end
end)

local fadeDeadline = -1
-- Main interaction loop
CreateThread(function()
    while true do
        Wait(100)
        local now = GetGameTimer()

        -- Pressing or holding the key shows interactions (first time) and refreshes the fade deadline
        if IsControlPressed(0, Config.InteractionKey) or IsDisabledControlJustPressed(0, Config.InteractionKey) then
            fadeDeadline = now + 10000 -- 10s from *this* tick/press
            if not IS_ALT_PRESSED then
                IS_ALT_PRESSED = true
                HandleInteractions()
            end
        end

        -- If UI is up, check if it's time to fade; only fade after 10s since last press
        if IS_ALT_PRESSED then
            if fadeDeadline > 0 and now >= fadeDeadline then
                for i = 26, 0, -1 do
                    Wait(0)
                    ALPHA = i * Config.FadeSpeed
                end
                IS_ALT_PRESSED = false
                fadeDeadline = -1
                ClearInteractionPeds()
            else
                UpdateClosestInteractions()
                UpdateCurrentInteraction()
            end
        end
    end
end)


-- Handle interactions for nearby NPCs
function HandleInteractions()
    CreateThread(function()
        PedInteractions()
        TriggerEvent("rdr-interactions:load")
        Wait(50)
        UpdateClosestInteractions()
        ALPHA = 0
        CreateThread(function()
            for i = 0, 26, 1 do
                Wait(0)
                ALPHA = math.min(i * Config.FadeSpeed, 255)
            end
        end)
        StartDrawProcess()
    end)
end

-- Update closest interactions
function UpdateClosestInteractions()
    ClosestInteractions = {}
    for id, interaction in pairs(Interactions) do
        if interaction:IsEntityValid() then
            if interaction:GetDistance() < Config.InteractionDistance then
                Interactions[id].activeOptions = {}
                for _, v in pairs(interaction.options) do
                    if v.canUse then
                        if v:canUse(interaction.entity) then
                            Interactions[id].activeOptions[#Interactions[id].activeOptions + 1] = v
                        end
                    else
                        Interactions[id].activeOptions[#Interactions[id].activeOptions + 1] = v
                    end
                end
                ClosestInteractions[id] = Interactions[id]
            end
        else
            Interactions[id] = nil
        end
    end
end

-- Clear dynamic NPC interactions
function ClearInteractionPeds()
    TriggerEvent("rdr-interactions:unload")
    for id in pairs(InteractionPedList) do
        Interactions[id] = nil
    end
end

-- Update current interaction based on proximity and focus
function UpdateCurrentInteraction()
    local sortedInteractions = {}
    for id, interaction in pairs(ClosestInteractions) do
        if interaction:ShouldDraw() then
            table.insert(sortedInteractions, { index = id, distance = interaction:GetScreenDistance() })
        end
    end

    table.sort(sortedInteractions, function(a, b) return a.distance < b.distance end)

    if #sortedInteractions > 0 and sortedInteractions[1].distance < Config.FocusThreshold then
        HandleInteractionSelection(sortedInteractions[1].index)
    else
        CURRENT_INTERACTION_INDEX = nil
    end
end

-- Handle interaction selection
function HandleInteractionSelection(index)
    if index ~= CURRENT_INTERACTION_INDEX then
        CURRENT_INTERACTION_INDEX = index
        local interaction = Interactions[CURRENT_INTERACTION_INDEX]
        if interaction and interaction:CanInteract() then
            interaction.selected_index = 1
        else
            CURRENT_INTERACTION_INDEX = nil
        end
    end
end

-- Start drawing interaction process
function StartDrawProcess()
    CreateThread(function()
        while IS_ALT_PRESSED do
            Wait(0)
            DisableAllControls()
            for _, interaction in pairs(ClosestInteractions) do
                if CURRENT_INTERACTION_INDEX ~= interaction.id then
                    interaction:Draw()
                else
                    interaction:DrawFull()
                    HandleControlInputs(interaction)
                end
            end
        end
    end)
end

-- Handle user input during interactions
function HandleControlInputs(currentInteraction)
    -- Navigate options
    if IsControlJustPressed(0, Config.ScrollUpKey) or IsControlJustPressed(0, Config.DownKey) then
        currentInteraction.selected_index = (currentInteraction.selected_index % #currentInteraction.activeOptions) + 1
    elseif IsControlJustPressed(0, Config.ScrollDownKey) or IsControlJustPressed(0, Config.UpKey) then
        currentInteraction.selected_index = (currentInteraction.selected_index - 2) % #currentInteraction.activeOptions +
        1
    end

    -- Select option
    if IsControlJustReleased(0, Config.SelectKey) or IsDisabledControlJustReleased(0, Config.SelectKey) then
        local selected = currentInteraction.activeOptions[currentInteraction.selected_index]
        if selected and selected.onSelect then
            CreateThread(function()
                selected:onSelect(currentInteraction.entity)
            end)
            Wait(500)
            UpdateClosestInteractions()
            Wait(500)

            IS_ALT_PRESSED = false
            fadeDeadline = -1
        end
    end
end

-- Disable relevant controls during interaction
function DisableAllControls()
    for _, control in ipairs(Config.DisabledControls) do
        DisableControlAction(0, control, true)
    end
end

function ExportInteractions.CreateInteraction(id, position, options, renderDistance, interactionDistance)
    Interactions[id] = nil
    InteractionsTable:CreateInteraction(id, position, options, renderDistance, interactionDistance)
end

function ExportInteractions.CreateEntityInteraction(id, entity, options, renderDistance, interactionDistance, offset,
                                                    bone)
    Interactions[id] = nil
    InteractionsTable:CreateEntityInteraction(id, entity, options, renderDistance, interactionDistance, offset, bone)
end

function ExportInteractions.ChangeOptionText(id, optionIndex, text)
    if Interactions[id] then
        Interactions[id]:ChangeOptionText(optionIndex, text)
    end
end

function ExportInteractions.DeleteInteraction(id)
    CURRENT_INTERACTION_INDEX = nil
    Interactions[id] = nil
    ClosestInteractions[id] = nil
end

-- Register ped options from external resources
function ExportInteractions.RegisterPedOptions(resourceName, options)
    if type(options) ~= "table" then
        print("^1[Interactions] Invalid options table from " .. resourceName .. "^0")
        return false
    end

    RegisteredPedOptions[resourceName] = options
    print("^2[Interactions] Registered " .. #options .. " ped options from " .. resourceName .. "^0")
    return true
end

-- Unregister ped options from external resources
function ExportInteractions.UnregisterPedOptions(resourceName)
    if RegisteredPedOptions[resourceName] then
        RegisteredPedOptions[resourceName] = nil
        print("^3[Interactions] Unregistered ped options from " .. resourceName .. "^0")
        return true
    end
    return false
end

-- Get all ped options from built-in and external resources
function GetAllPedOptions()
    local allOptions = {}

    for _, option in ipairs(Config.PedOptions) do
        table.insert(allOptions, option)
    end

    for resourceName, options in pairs(RegisteredPedOptions) do
        for _, option in ipairs(options) do
            table.insert(allOptions, option)
        end
    end

    return allOptions
end

function PedInteractions()
    InteractionPedList = {}
    local allPedOptions = GetAllPedOptions()

    if #allPedOptions == 0 then
        return
    end

    local playerCoords = GetEntityCoords(PlayerPedId())
    local peds = GetGamePool('CPed')

    for i = 1, #peds do
        local ped = peds[i]
        local pedCoords = GetEntityCoords(ped)
        local distance = #(playerCoords - pedCoords)

        if distance <= Config.InteractionDistance
            and ped ~= PlayerPedId()
            and (not Config.ScanOnlyHumans or IsPedHuman(ped))
            and (not Config.SkipMountedPeds or not IsPedOnMount(ped))
            and (not Config.RequireNetworked or NetworkGetEntityIsNetworked(ped))
            and (not Config.SkipDeadPeds or not IsEntityDead(ped)) then
            InteractionsTable:CreateEntityInteraction("npc_" .. ped, ped, allPedOptions, 3.0, 1.5, nil, 47576)
            InteractionPedList["npc_" .. ped] = true
        end
    end
end
