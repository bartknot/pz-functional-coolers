------------------------------------------------------------
-- Functional Coolers Test Harness
-- FC-004 infrastructure v0.4.2-dev
-- Project Zomboid Build 42.20.3 test infrastructure only
--
-- Purpose:
--   Create the matched FC004-A / FC004-B setup.
--   Observe the actual player-inventory UI container binding.
--   Validate infrastructure without modifying measured Food state.
--
-- Controls:
--   Right-click an FC-004 Cooler or one of its contents.
--   Use the FC-004 context-menu actions to start, arm, or end a run.
------------------------------------------------------------

local FCTH = {}

local SETUP_VERSION = 11
local HARNESS_VERSION = "0.4.2-dev"
local EXPECTED_BUILD = "42.20.3"

local TEST_SPAWN_X = 10693
local TEST_SPAWN_Y = 9986
local TEST_SPAWN_Z = 0
local SCAN_RADIUS = 8

local GROUP_A = "FC004-A"
local GROUP_B = "FC004-B"
local GROUP_ROLE_A = "fc004_a"
local GROUP_ROLE_B = "fc004_b"

local FREEZER_STEAKS = 2
local REQUIRED_DAY_LENGTH = 4
local REQUIRED_FOOD_ROT_SPEED = 3
local REQUIRED_FRIDGE_FACTOR = 3

local SMOKETEST_STABLE_HOURS = 10.0 / 60.0
local EXPERIMENT_TARGET_HOURS = 4.5
local REQUIRED_STABLE_SAMPLES = 2

local waitLogCounter = 0
local lastSetupSignature = nil
local lastObservedSignature = nil
local lastReadySignature = nil

local activeMode = nil
local activeState = "IDLE"
local expectedSelectedID = nil
local beginWorldHours = nil
local stableSampleCount = 0
local targetReported = false
local invalidated = false

local setupFreezer = nil
local setupFreezerSelected = false
local setupFreezerSelectedSince = nil

local smoke = {
    seenA = false,
    seenB = false,
    seenClosed = false,
    seenCollapsed = false,
    seenUnequipped = false,
    stableStartHours = nil,
}

------------------------------------------------------------
-- Safety and value helpers
------------------------------------------------------------

local function safeValue(fn, fallback)
    local ok, value = pcall(fn)
    if ok then
        return value
    end
    return fallback
end

local function boolText(value)
    if value == true then
        return "true"
    end
    if value == false then
        return "false"
    end
    return tostring(value)
end

local function getWorldHours()
    return safeValue(function()
        return getGameTime():getWorldAgeHours()
    end, nil)
end

local function getFullType(item)
    if not item then
        return "NONE"
    end
    return tostring(safeValue(function()
        return item:getFullType()
    end, "UNAVAILABLE"))
end

local function getItemID(item)
    if not item then
        return "NONE"
    end
    return tostring(safeValue(function()
        return item:getID()
    end, "UNAVAILABLE"))
end

local function setCustomName(item, name)
    if not item then
        return false
    end

    local renamed = safeValue(function()
        item:setName(name)
        item:setCustomName(true)
        return true
    end, false)

    return renamed
end

local function markGenerated(item, role)
    if not item then
        return false
    end

    local data = safeValue(function()
        return item:getModData()
    end, nil)

    if not data then
        return false
    end

    data.FCTH_generated = true
    data.FCTH_role = role
    data.FCTH_setupVersion = SETUP_VERSION
    return true
end

local function hasRole(item, role)
    if not item then
        return false
    end

    local data = safeValue(function()
        return item:getModData()
    end, nil)

    return data
       and data.FCTH_generated == true
       and data.FCTH_setupVersion == SETUP_VERSION
       and data.FCTH_role == role
end

local function getCoolerContainer(cooler)
    if not cooler then
        return nil
    end

    local container = safeValue(function()
        return cooler:getItemContainer()
    end, nil)

    if container then
        return container
    end

    return safeValue(function()
        return cooler:getInventory()
    end, nil)
end

local function getBuildVersion()
    return tostring(safeValue(function()
        return getCore():getVersion()
    end, "UNAVAILABLE"))
end

local function getSelectedLootContainer()
    local page = safeValue(function()
        return getPlayerLoot(0)
    end, nil)

    local pane = page and page.inventoryPane or nil
    return pane and pane.inventory or nil
end

local function freezerPreparationFoodFields(item, label)
    if not item then
        return " | " .. label .. "ID=NONE"
    end

    return
        " | " .. label .. "ID=" .. getItemID(item)
        .. " | " .. label .. "lastAged="
        .. tostring(safeValue(function()
            return item:getLastAged()
        end, "UNAVAILABLE"))
        .. " | " .. label .. "heat="
        .. tostring(safeValue(function()
            return item:getHeat()
        end, "UNAVAILABLE"))
        .. " | " .. label .. "freeze="
        .. tostring(safeValue(function()
            return item:getFreezingTime()
        end, "UNAVAILABLE"))
        .. " | " .. label .. "frozen="
        .. boolText(safeValue(function()
            return item:isFrozen()
        end, "UNAVAILABLE"))
end

------------------------------------------------------------
-- Fixed dedicated-sandbox spawn
------------------------------------------------------------

local function configureFixedSpawn()
    local world = safeValue(function()
        return getWorld()
    end, nil)

    if not world then
        print("[FCTH-FC004] status=ERROR | reason=no_iso_world")
        return
    end

    local ok = safeValue(function()
        world:setLuaPosX(TEST_SPAWN_X)
        world:setLuaPosY(TEST_SPAWN_Y)
        world:setLuaPosZ(TEST_SPAWN_Z)
        return true
    end, false)

    if not ok then
        print("[FCTH-FC004] status=ERROR | reason=spawn_setter_unavailable")
        return
    end

    print(
        "[FCTH-FC004] status=SPAWN_CONFIGURED"
        .. " | x=" .. tostring(TEST_SPAWN_X)
        .. " | y=" .. tostring(TEST_SPAWN_Y)
        .. " | z=" .. tostring(TEST_SPAWN_Z)
    )
end

local function verifyFixedSpawn(player)
    if not player then
        return false
    end

    local x = safeValue(function() return player:getX() end, -99999)
    local y = safeValue(function() return player:getY() end, -99999)
    local z = safeValue(function() return player:getZ() end, -99999)

    return math.floor(x) == TEST_SPAWN_X
       and math.floor(y) == TEST_SPAWN_Y
       and math.floor(z) == TEST_SPAWN_Z
end

Events.OnInitWorld.Add(configureFixedSpawn)

------------------------------------------------------------
-- Powered refrigerator/freezer discovery
------------------------------------------------------------

local function findPoweredFridgeFreezer(player)
    local square = player and player:getSquare()
    local cell = getCell()

    if not square or not cell then
        return nil
    end

    local px = square:getX()
    local py = square:getY()
    local pz = square:getZ()
    local best = nil
    local bestDistance = math.huge

    for x = px - SCAN_RADIUS, px + SCAN_RADIUS do
        for y = py - SCAN_RADIUS, py + SCAN_RADIUS do
            local candidateSquare = cell:getGridSquare(x, y, pz)

            if candidateSquare then
                local objects = safeValue(function()
                    return candidateSquare:getObjects()
                end, nil)

                if objects then
                    for objectIndex = 0, objects:size() - 1 do
                        local object = objects:get(objectIndex)
                        local count = safeValue(function()
                            return object:getContainerCount()
                        end, 0)

                        if count and count > 0 then
                            local fridge = nil
                            local freezer = nil

                            for containerIndex = 0, count - 1 do
                                local container = safeValue(function()
                                    return object:getContainerByIndex(containerIndex)
                                end, nil)

                                local containerType = container and tostring(
                                    safeValue(function()
                                        return container:getType()
                                    end, "")
                                ) or ""

                                if containerType == "fridge" then
                                    fridge = container
                                elseif containerType == "freezer" then
                                    freezer = container
                                end
                            end

                            if fridge and freezer then
                                local fridgePowered = safeValue(function()
                                    return fridge:isPowered()
                                end, false)

                                local freezerPowered = safeValue(function()
                                    return freezer:isPowered()
                                end, false)

                                if fridgePowered and freezerPowered then
                                    local dx = x - px
                                    local dy = y - py
                                    local distance = dx * dx + dy * dy

                                    if distance < bestDistance then
                                        bestDistance = distance
                                        best = {
                                            fridge = fridge,
                                            freezer = freezer,
                                            x = x,
                                            y = y,
                                            z = pz,
                                        }
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    return best
end

------------------------------------------------------------
-- Deterministic FC-004 setup
------------------------------------------------------------

local function clearContainer(container)
    if not container then
        return false
    end

    return safeValue(function()
        container:removeAllItems()
        return true
    end, false)
end

local function prepareFreezer(player, appliance)
    local playerData = player:getModData()

    if playerData.FCTH_setupVersion
    and playerData.FCTH_setupVersion ~= SETUP_VERSION then
        print(
            "[FCTH-FC004] status=ERROR"
            .. " | reason=stale_harness_save"
            .. " | foundSetupVersion="
            .. tostring(playerData.FCTH_setupVersion)
            .. " | requiredSetupVersion="
            .. tostring(SETUP_VERSION)
            .. " | action=create_fresh_save"
        )
        playerData.FCTH_setupError = true
        return false
    end

    if not clearContainer(appliance.fridge)
    or not clearContainer(appliance.freezer) then
        print("[FCTH-FC004] status=ERROR | reason=appliance_clear_failed")
        playerData.FCTH_setupError = true
        return false
    end

    for index = 1, FREEZER_STEAKS do
        local steak = safeValue(function()
            return appliance.freezer:AddItem("Base.Steak")
        end, nil)

        if not steak then
            print(
                "[FCTH-FC004] status=ERROR"
                .. " | reason=freezer_steak_create_failed"
                .. " | index=" .. tostring(index)
            )
            playerData.FCTH_setupError = true
            return false
        end

        markGenerated(steak, "freezer_steak_" .. tostring(index))
    end

    local watch = safeValue(function()
        return player:getInventory():AddItem(
            "Base.WristWatch_Right_DigitalRed"
        )
    end, nil)

    if watch then
        markGenerated(watch, "watch")
    end

    playerData.FCTH_setupVersion = SETUP_VERSION
    playerData.FCTH_fc004Prepared = true
    playerData.FCTH_fc004Distributed = false
    playerData.FCTH_fridgeX = appliance.x
    playerData.FCTH_fridgeY = appliance.y
    playerData.FCTH_fridgeZ = appliance.z
    setupFreezer = appliance.freezer
    setupFreezerSelected = false
    setupFreezerSelectedSince = nil

    print(
        "[FCTH-FC004] status=WAITING_FOR_FREEZER_SELECTION"
        .. " | steaks=" .. tostring(FREEZER_STEAKS)
        .. " | coldpacks=0"
        .. " | artificialFoodState=false"
        .. " | action=select_freezer_keep_selected_until_matched_setup_created"
    )

    return true
end

local function collectPreparedFrozenSteaks(freezer)
    local result = {}
    local items = freezer and freezer:getItems() or nil

    if not items then
        return result
    end

    for index = 0, items:size() - 1 do
        local item = items:get(index)

        if getFullType(item) == "Base.Steak"
        and (
            hasRole(item, "freezer_steak_1")
            or hasRole(item, "freezer_steak_2")
        ) then
            table.insert(result, item)
        end
    end

    table.sort(result, function(left, right)
        return getItemID(left) < getItemID(right)
    end)

    return result
end

local function observePreparedFreezerSelection(player)
    if not player or not setupFreezer then
        return
    end

    local playerData = player:getModData()
    if playerData.FCTH_fc004Distributed == true then
        return
    end

    local selected = getSelectedLootContainer() == setupFreezer

    if selected and not setupFreezerSelected then
        setupFreezerSelected = true
        setupFreezerSelectedSince = getWorldHours()
        print(
            "[FCTH-FC004] status=FREEZER_SELECTED"
            .. " | worldHours=" .. tostring(setupFreezerSelectedSince)
            .. " | containerType="
            .. tostring(safeValue(function()
                return setupFreezer:getType()
            end, "UNAVAILABLE"))
            .. " | requirement=keep_selected_until_matched_setup_created"
        )
    elseif not selected and setupFreezerSelected then
        local now = getWorldHours()
        print(
            "[FCTH-FC004] status=FREEZER_SELECTION_LOST"
            .. " | worldHours=" .. tostring(now)
            .. " | selectedDurationGameHours="
            .. tostring(
                now and setupFreezerSelectedSince
                and now - setupFreezerSelectedSince
                or "UNAVAILABLE"
            )
            .. " | action=reselect_freezer_keep_selected"
        )
        setupFreezerSelected = false
        setupFreezerSelectedSince = nil
    end
end

local function addExistingItem(source, destination, item)
    if not source or not destination or not item then
        return false
    end

    local removed = safeValue(function()
        source:Remove(item)
        return true
    end, false)

    if not removed then
        return false
    end

    local added = safeValue(function()
        destination:AddItem(item)
        return true
    end, false)

    if not added then
        safeValue(function()
            source:AddItem(item)
            return true
        end, false)
        return false
    end

    return true
end

local function createMatchedCooler(inventory, groupName, groupRole)
    local cooler = safeValue(function()
        return inventory:AddItem("Base.Cooler")
    end, nil)

    if not cooler or getFullType(cooler) ~= "Base.Cooler" then
        return nil
    end

    if not setCustomName(cooler, groupName)
    or not markGenerated(cooler, groupRole) then
        return nil
    end

    return cooler
end

local function distributeMatchedSetup(player, appliance)
    local frozenSteaks = collectPreparedFrozenSteaks(appliance.freezer)

    if #frozenSteaks ~= 2 then
        return false, "frozen_steak_count_" .. tostring(#frozenSteaks)
    end

    for _, steak in ipairs(frozenSteaks) do
        local frozen = safeValue(function()
            return steak:isFrozen()
        end, false)

        if not frozen then
            return false, "freezer_steak_not_frozen_" .. getItemID(steak)
        end
    end

    local inventory = player:getInventory()
    local coolerA = createMatchedCooler(inventory, GROUP_A, GROUP_ROLE_A)
    local coolerB = createMatchedCooler(inventory, GROUP_B, GROUP_ROLE_B)

    if not coolerA or not coolerB then
        return false, "cooler_create_failed"
    end

    local containerA = getCoolerContainer(coolerA)
    local containerB = getCoolerContainer(coolerB)

    if not containerA or not containerB then
        return false, "cooler_container_unavailable"
    end

    local freshA = safeValue(function()
        return containerA:AddItem("Base.Steak")
    end, nil)

    local freshB = safeValue(function()
        return containerB:AddItem("Base.Steak")
    end, nil)

    if not freshA or not freshB then
        return false, "fresh_steak_create_failed"
    end

    markGenerated(freshA, "fc004_a_fresh")
    markGenerated(freshB, "fc004_b_fresh")

    if not addExistingItem(appliance.freezer, containerA, frozenSteaks[1]) then
        return false, "frozen_transfer_a_failed"
    end

    if not addExistingItem(appliance.freezer, containerB, frozenSteaks[2]) then
        return false, "frozen_transfer_b_failed"
    end

    markGenerated(frozenSteaks[1], "fc004_a_frozen")
    markGenerated(frozenSteaks[2], "fc004_b_frozen")

    local playerData = player:getModData()
    playerData.FCTH_fc004Distributed = true
    playerData.FCTH_fc004AID = getItemID(coolerA)
    playerData.FCTH_fc004BID = getItemID(coolerB)

    print(
        "[FCTH-FC004] status=MATCHED_SETUP_CREATED"
        .. " | worldHours=" .. tostring(getWorldHours())
        .. " | groupAID=" .. getItemID(coolerA)
        .. " | groupBID=" .. getItemID(coolerB)
        .. " | contents=1_fresh_1_vanilla_frozen_each"
        .. " | coldpacks=0_each"
        .. " | location=PLAYER_INVENTORY"
        .. " | artificialFoodState=false"
    )

    print(
        "[FCTH-FC004] status=WAITING_FOR_EQUIP_AND_SELECTION"
        .. " | requiredPrimary=" .. GROUP_A
        .. " | requiredSecondary=" .. GROUP_B
        .. " | action=equip_pin_open_select"
    )

    return true, nil
end

------------------------------------------------------------
-- Group, Food, and UI observation
------------------------------------------------------------

local function findGroups(player)
    local groups = {
        A = nil,
        B = nil,
    }

    local inventory = player and player:getInventory()
    local items = inventory and inventory:getItems() or nil

    if not items then
        return groups
    end

    for index = 0, items:size() - 1 do
        local item = items:get(index)

        if hasRole(item, GROUP_ROLE_A) then
            groups.A = item
        elseif hasRole(item, GROUP_ROLE_B) then
            groups.B = item
        end
    end

    return groups
end

local function inspectGroup(cooler, freshRole, frozenRole)
    local result = {
        cooler = cooler,
        container = getCoolerContainer(cooler),
        steakCount = 0,
        coldpackCount = 0,
        fresh = nil,
        frozen = nil,
    }

    local items = result.container and result.container:getItems() or nil

    if not items then
        return result
    end

    for index = 0, items:size() - 1 do
        local item = items:get(index)
        local fullType = getFullType(item)

        if fullType == "Base.Steak" then
            result.steakCount = result.steakCount + 1

            if hasRole(item, freshRole) then
                result.fresh = item
            elseif hasRole(item, frozenRole) then
                result.frozen = item
            end
        elseif fullType == "Base.Coldpack" then
            result.coldpackCount = result.coldpackCount + 1
        end
    end

    return result
end

local function getInventoryUIState()
    local page = safeValue(function()
        return getPlayerInventory(0)
    end, nil)

    local visible = page and safeValue(function()
        return page:isVisible()
    end, false) or false

    local collapsed = page and page.isCollapsed == true or false
    local pinned = page and page.pin == true or false
    local pane = page and page.inventoryPane or nil
    local selectedContainer = pane and pane.inventory or nil

    local selectedItem = selectedContainer and safeValue(function()
        return selectedContainer:getContainingItem()
    end, nil) or nil

    return {
        page = page,
        visible = visible,
        collapsed = collapsed,
        pinned = pinned,
        selectedContainer = selectedContainer,
        selectedItem = selectedItem,
        selectedID = getItemID(selectedItem),
        selectedType = getFullType(selectedItem),
    }
end

local function sandboxMatches()
    return SandboxVars
       and SandboxVars.DayLength == REQUIRED_DAY_LENGTH
       and SandboxVars.FoodRotSpeed == REQUIRED_FOOD_ROT_SPEED
       and SandboxVars.FridgeFactor == REQUIRED_FRIDGE_FACTOR
end

local function buildMatches()
    return string.find(
        getBuildVersion(),
        EXPECTED_BUILD,
        1,
        true
    ) ~= nil
end

local function getState(player)
    local groups = findGroups(player)
    local a = inspectGroup(
        groups.A,
        "fc004_a_fresh",
        "fc004_a_frozen"
    )
    local b = inspectGroup(
        groups.B,
        "fc004_b_fresh",
        "fc004_b_frozen"
    )
    local ui = getInventoryUIState()
    local primary = safeValue(function()
        return player:getPrimaryHandItem()
    end, nil)
    local secondary = safeValue(function()
        return player:getSecondaryHandItem()
    end, nil)

    local unexpectedPlayerSteaks = 0
    local rootItems = player:getInventory():getItems()

    for index = 0, rootItems:size() - 1 do
        if getFullType(rootItems:get(index)) == "Base.Steak" then
            unexpectedPlayerSteaks = unexpectedPlayerSteaks + 1
        end
    end

    local selectedGroup = "NONE"
    if ui.selectedItem == groups.A then
        selectedGroup = GROUP_A
    elseif ui.selectedItem == groups.B then
        selectedGroup = GROUP_B
    elseif ui.selectedItem then
        selectedGroup = "OTHER"
    end

    local baseReady =
        groups.A ~= nil
        and groups.B ~= nil
        and safeValue(function()
            return groups.A:isInPlayerInventory()
        end, false)
        and safeValue(function()
            return groups.B:isInPlayerInventory()
        end, false)
        and a.steakCount == 2
        and b.steakCount == 2
        and a.coldpackCount == 0
        and b.coldpackCount == 0
        and a.fresh ~= nil
        and b.fresh ~= nil
        and a.frozen ~= nil
        and b.frozen ~= nil
        and not safeValue(function()
            return a.fresh:isFrozen()
        end, true)
        and not safeValue(function()
            return b.fresh:isFrozen()
        end, true)
        and safeValue(function()
            return a.frozen:isFrozen()
        end, false)
        and safeValue(function()
            return b.frozen:isFrozen()
        end, false)
        and unexpectedPlayerSteaks == 0
        and sandboxMatches()

    local handsReady =
        primary == groups.A
        and secondary == groups.B

    local selectedReady =
        selectedGroup == GROUP_A
        or selectedGroup == GROUP_B

    local treatmentReady =
        baseReady
        and buildMatches()
        and handsReady
        and selectedReady
        and ui.visible
        and not ui.collapsed
        and ui.pinned

    return {
        groups = groups,
        a = a,
        b = b,
        ui = ui,
        primary = primary,
        secondary = secondary,
        selectedGroup = selectedGroup,
        baseReady = baseReady,
        handsReady = handsReady,
        selectedReady = selectedReady,
        treatmentReady = treatmentReady,
        unexpectedPlayerSteaks = unexpectedPlayerSteaks,
    }
end

local function foodFields(item, label)
    if not item then
        return " | " .. label .. "ID=NONE"
    end

    return
        " | " .. label .. "ID=" .. getItemID(item)
        .. " | " .. label .. "lastAged="
        .. tostring(safeValue(function()
            return item:getLastAged()
        end, "UNAVAILABLE"))
        .. " | " .. label .. "age="
        .. tostring(safeValue(function()
            return item:getAge()
        end, "UNAVAILABLE"))
        .. " | " .. label .. "heat="
        .. tostring(safeValue(function()
            return item:getHeat()
        end, "UNAVAILABLE"))
        .. " | " .. label .. "freeze="
        .. tostring(safeValue(function()
            return item:getFreezingTime()
        end, "UNAVAILABLE"))
        .. " | " .. label .. "frozen="
        .. boolText(safeValue(function()
            return item:isFrozen()
        end, "UNAVAILABLE"))
        .. " | " .. label .. "thawing="
        .. boolText(safeValue(function()
            return item:isThawing()
        end, "UNAVAILABLE"))
end

local function stateFields(state)
    return
        " | worldHours=" .. tostring(getWorldHours())
        .. " | build=" .. getBuildVersion()
        .. " | DayLength=" .. tostring(SandboxVars and SandboxVars.DayLength)
        .. " | FoodRotSpeed=" .. tostring(SandboxVars and SandboxVars.FoodRotSpeed)
        .. " | FridgeFactor=" .. tostring(SandboxVars and SandboxVars.FridgeFactor)
        .. " | groupAID=" .. getItemID(state.groups.A)
        .. " | groupBID=" .. getItemID(state.groups.B)
        .. " | primaryID=" .. getItemID(state.primary)
        .. " | secondaryID=" .. getItemID(state.secondary)
        .. " | selectedGroup=" .. state.selectedGroup
        .. " | selectedID=" .. state.ui.selectedID
        .. " | selectedType=" .. state.ui.selectedType
        .. " | inventoryVisible=" .. boolText(state.ui.visible)
        .. " | inventoryCollapsed=" .. boolText(state.ui.collapsed)
        .. " | inventoryPinned=" .. boolText(state.ui.pinned)
        .. " | baseReady=" .. boolText(state.baseReady)
        .. " | handsReady=" .. boolText(state.handsReady)
        .. " | treatmentReady=" .. boolText(state.treatmentReady)
        .. " | aSteaks=" .. tostring(state.a.steakCount)
        .. " | aColdpacks=" .. tostring(state.a.coldpackCount)
        .. " | bSteaks=" .. tostring(state.b.steakCount)
        .. " | bColdpacks=" .. tostring(state.b.coldpackCount)
        .. " | unexpectedPlayerSteaks="
        .. tostring(state.unexpectedPlayerSteaks)
        .. foodFields(state.a.fresh, "aFresh")
        .. foodFields(state.a.frozen, "aFrozen")
        .. foodFields(state.b.fresh, "bFresh")
        .. foodFields(state.b.frozen, "bFrozen")
end

local function emit(marker, state, extra)
    print(
        "[FCTH-FC004]"
        .. " mode=" .. tostring(activeMode or "MONITOR")
        .. " | phase=" .. marker
        .. stateFields(state)
        .. (extra or "")
    )
end

------------------------------------------------------------
-- Readiness and run-state handling
------------------------------------------------------------

local function readinessReason(state)
    if not buildMatches() then
        return "build_mismatch"
    end
    if not sandboxMatches() then
        return "sandbox_mismatch"
    end
    if not state.groups.A or not state.groups.B then
        return "matched_groups_missing"
    end
    if state.a.steakCount ~= 2 or state.b.steakCount ~= 2 then
        return "steak_count_mismatch"
    end
    if state.a.coldpackCount ~= 0 or state.b.coldpackCount ~= 0 then
        return "coldpack_count_mismatch"
    end
    if not state.a.fresh or not state.b.fresh
    or not state.a.frozen or not state.b.frozen then
        return "food_role_missing"
    end
    if safeValue(function()
        return state.a.fresh:isFrozen()
    end, true)
    or safeValue(function()
        return state.b.fresh:isFrozen()
    end, true) then
        return "fresh_steak_state_mismatch"
    end
    if not safeValue(function()
        return state.a.frozen:isFrozen()
    end, false)
    or not safeValue(function()
        return state.b.frozen:isFrozen()
    end, false) then
        return "nominally_frozen_state_lost"
    end
    if not state.handsReady then
        return "equip_assignment"
    end
    if not state.ui.visible then
        return "inventory_not_visible"
    end
    if state.ui.collapsed then
        return "inventory_collapsed"
    end
    if not state.ui.pinned then
        return "inventory_not_pinned"
    end
    if not state.selectedReady then
        return "selected_container_not_fc004"
    end
    return "ready"
end

local function logReadiness(state)
    local reason = readinessReason(state)
    local signature =
        reason
        .. "|" .. getItemID(state.groups.A)
        .. "|" .. getItemID(state.groups.B)
        .. "|" .. getItemID(state.primary)
        .. "|" .. getItemID(state.secondary)
        .. "|" .. state.ui.selectedID
        .. "|" .. boolText(state.ui.visible)
        .. "|" .. boolText(state.ui.collapsed)
        .. "|" .. boolText(state.ui.pinned)

    if signature == lastReadySignature then
        return
    end

    lastReadySignature = signature

    if state.treatmentReady then
        emit(
            "READY",
            state,
            " | status=READY"
            .. " | selectedBinding=playerInventory.inventoryPane.inventory"
        )
    else
        emit(
            "READY",
            state,
            " | status=WAITING"
            .. " | reason=" .. reason
        )
    end
end

local function invalidateExperiment(state, reason)
    if invalidated then
        return
    end

    invalidated = true
    activeState = "INVALIDATED"
    emit(
        "INVALIDATED",
        state,
        " | status=INVALIDATED"
        .. " | reason=" .. reason
    )
end

local function experimentViolation(state)
    if not buildMatches() then
        return "build_mismatch"
    end
    if not sandboxMatches() then
        return "sandbox_mismatch"
    end
    if not state.groups.A or not state.groups.B then
        return "matched_groups_missing"
    end
    if not safeValue(function()
        return state.groups.A:isInPlayerInventory()
    end, false)
    or not safeValue(function()
        return state.groups.B:isInPlayerInventory()
    end, false) then
        return "carried_context_changed"
    end
    if state.a.steakCount ~= 2 or state.b.steakCount ~= 2
    or state.a.coldpackCount ~= 0 or state.b.coldpackCount ~= 0
    or not state.a.fresh or not state.b.fresh
    or not state.a.frozen or not state.b.frozen then
        return "matched_contents_changed"
    end
    if state.unexpectedPlayerSteaks ~= 0 then
        return "unexpected_player_steaks"
    end
    if not state.handsReady then
        return "equip_assignment_changed"
    end
    if not state.ui.visible then
        return "inventory_closed"
    end
    if state.ui.collapsed then
        return "inventory_collapsed"
    end
    if not state.ui.pinned then
        return "inventory_unpinned"
    end
    if state.ui.selectedID ~= expectedSelectedID then
        return "selected_container_changed"
    end
    return nil
end

local function resetSmoke()
    smoke.seenA = false
    smoke.seenB = false
    smoke.seenClosed = false
    smoke.seenCollapsed = false
    smoke.seenUnequipped = false
    smoke.stableStartHours = nil
end

local function smokeChecklistComplete()
    return smoke.seenA
       and smoke.seenB
       and smoke.seenClosed
       and smoke.seenCollapsed
       and smoke.seenUnequipped
end

local function observeSmokeTransition(state)
    if activeMode ~= "SMOKETEST"
    or activeState ~= "RUNNING" then
        return
    end

    if state.selectedGroup == GROUP_A and not smoke.seenA then
        smoke.seenA = true
        emit("SMOKE_DETECTED", state, " | event=selected_a")
    end

    if state.selectedGroup == GROUP_B and not smoke.seenB then
        smoke.seenB = true
        emit("SMOKE_DETECTED", state, " | event=selected_b")
    end

    if not state.ui.visible and not smoke.seenClosed then
        smoke.seenClosed = true
        emit("SMOKE_DETECTED", state, " | event=inventory_closed")
    end

    if state.ui.collapsed and not smoke.seenCollapsed then
        smoke.seenCollapsed = true
        emit("SMOKE_DETECTED", state, " | event=inventory_collapsed")
    end

    if not state.handsReady and not smoke.seenUnequipped then
        smoke.seenUnequipped = true
        emit("SMOKE_DETECTED", state, " | event=equip_assignment_changed")
    end

    if smokeChecklistComplete() and state.treatmentReady then
        if not smoke.stableStartHours then
            smoke.stableStartHours = getWorldHours()
            emit(
                "TREATMENT_STABLE",
                state,
                " | status=STABILITY_TIMER_STARTED"
                .. " | requiredGameMinutes=10"
            )
        end
    else
        smoke.stableStartHours = nil
    end
end

local function handleSmokeMinute(state)
    observeSmokeTransition(state)
    emit(
        "SAMPLE",
        state,
        " | evidenceEligible=false"
        .. " | seenA=" .. boolText(smoke.seenA)
        .. " | seenB=" .. boolText(smoke.seenB)
        .. " | seenClosed=" .. boolText(smoke.seenClosed)
        .. " | seenCollapsed=" .. boolText(smoke.seenCollapsed)
        .. " | seenUnequipped=" .. boolText(smoke.seenUnequipped)
    )

    if smokeChecklistComplete()
    and state.treatmentReady
    and smoke.stableStartHours then
        local now = getWorldHours()
        if now
        and now - smoke.stableStartHours >= SMOKETEST_STABLE_HOURS then
            activeState = "COMPLETE"
            emit(
                "END",
                state,
                " | status=PASS"
                .. " | evidenceEligible=false"
                .. " | stableGameMinutes="
                .. tostring((now - smoke.stableStartHours) * 60.0)
            )
        end
    end
end

local function handleExperimentMinute(state)
    if activeState == "ARMED" then
        if state.treatmentReady
        and state.ui.selectedID == expectedSelectedID then
            stableSampleCount = stableSampleCount + 1

            if stableSampleCount >= REQUIRED_STABLE_SAMPLES then
                activeState = "RUNNING"
                beginWorldHours = getWorldHours()
                emit(
                    "TREATMENT_STABLE",
                    state,
                    " | status=STABLE"
                    .. " | stableSamples="
                    .. tostring(stableSampleCount)
                )
                emit(
                    "BEGIN",
                    state,
                    " | status=RUNNING"
                    .. " | targetGameHours="
                    .. tostring(EXPERIMENT_TARGET_HOURS)
                )
            end
        else
            stableSampleCount = 0
            emit(
                "SAMPLE",
                state,
                " | status=ARMED_WAITING"
                .. " | reason=" .. readinessReason(state)
            )
        end
        return
    end

    if activeState ~= "RUNNING" then
        return
    end

    local violation = experimentViolation(state)
    if violation then
        invalidateExperiment(state, violation)
        return
    end

    emit("SAMPLE", state, " | status=RUNNING")

    local now = getWorldHours()
    if not targetReported
    and now
    and beginWorldHours
    and now - beginWorldHours >= EXPERIMENT_TARGET_HOURS then
        targetReported = true
        emit(
            "TARGET_REACHED",
            state,
            " | status=TARGET_REACHED"
            .. " | elapsedGameHours="
            .. tostring(now - beginWorldHours)
        )
    end
end

------------------------------------------------------------
-- Operator controls
------------------------------------------------------------

local function startSmoke(player)
    if activeMode and activeState ~= "COMPLETE" then
        print(
            "[FCTH-FC004] mode=" .. tostring(activeMode)
            .. " | phase=CONTROL"
            .. " | status=REJECTED"
            .. " | reason=run_already_active"
        )
        return
    end

    resetSmoke()
    activeMode = "SMOKETEST"
    activeState = "RUNNING"
    expectedSelectedID = nil
    beginWorldHours = getWorldHours()
    invalidated = false
    targetReported = false
    lastObservedSignature = nil

    local state = getState(player)
    emit(
        "BEGIN",
        state,
        " | status=RUNNING"
        .. " | evidenceEligible=false"
        .. " | instructions=select_a_select_b_close_collapse_unequip_restore_wait_10_minutes"
    )

    observeSmokeTransition(state)
end

local function armExperiment(player)
    if activeMode and activeState ~= "COMPLETE" then
        print(
            "[FCTH-FC004] mode=" .. tostring(activeMode)
            .. " | phase=CONTROL"
            .. " | status=REJECTED"
            .. " | reason=run_already_active"
        )
        return
    end

    local state = getState(player)

    if not state.treatmentReady then
        emit(
            "CONTROL",
            state,
            " | status=REJECTED"
            .. " | reason=" .. readinessReason(state)
        )
        return
    end

    activeMode = "EXPERIMENT"
    activeState = "ARMED"
    expectedSelectedID = state.ui.selectedID
    beginWorldHours = nil
    stableSampleCount = 0
    targetReported = false
    invalidated = false
    lastObservedSignature = nil

    emit(
        "CONTROL",
        state,
        " | status=ARMED"
        .. " | operatorAuthorizationRequired=true"
        .. " | expectedSelectedID=" .. expectedSelectedID
    )
end

local function endActiveRun(player)
    if not activeMode then
        print(
            "[FCTH-FC004] mode=MONITOR"
            .. " | phase=END"
            .. " | status=REJECTED"
            .. " | reason=no_active_run"
        )
        return
    end

    local state = getState(player)
    local status = activeState

    if activeMode == "EXPERIMENT"
    and activeState == "RUNNING"
    and not targetReported then
        invalidateExperiment(state, "ended_before_target")
        status = activeState
    end

    emit(
        "END",
        state,
        " | status=" .. tostring(status)
        .. " | targetReported=" .. boolText(targetReported)
    )

    activeMode = nil
    activeState = "IDLE"
    expectedSelectedID = nil
    beginWorldHours = nil
    stableSampleCount = 0
    targetReported = false
    invalidated = false
end

local function belongsToFC004Group(item)
    if not item then
        return false
    end

    if hasRole(item, GROUP_ROLE_A)
    or hasRole(item, GROUP_ROLE_B) then
        return true
    end

    local container = safeValue(function()
        return item:getContainer()
    end, nil)

    local containingItem = container and safeValue(function()
        return container:getContainingItem()
    end, nil) or nil

    return hasRole(containingItem, GROUP_ROLE_A)
        or hasRole(containingItem, GROUP_ROLE_B)
end

local function contextIncludesFC004Group(items)
    for _, entry in ipairs(items or {}) do
        if instanceof(entry, "InventoryItem") then
            if belongsToFC004Group(entry) then
                return true
            end
        elseif type(entry) == "table" and entry.items then
            for _, item in ipairs(entry.items) do
                if belongsToFC004Group(item) then
                    return true
                end
            end
        end
    end

    return false
end

function FCTH.onFillInventoryObjectContextMenu(playerNumber, context, items)
    if not contextIncludesFC004Group(items) then
        return
    end

    local player = getSpecificPlayer(playerNumber)
    if not player then
        return
    end

    if activeMode and activeState ~= "COMPLETE" then
        context:addOption(
            "FC-004: End/cancel active harness run",
            player,
            endActiveRun
        )
        return
    end

    context:addOption(
        "FC-004: Start infrastructure smoketest",
        player,
        startSmoke
    )
    context:addOption(
        "FC-004: Arm experiment (Bart authorization required)",
        player,
        armExperiment
    )
end

------------------------------------------------------------
-- UI transition observer
------------------------------------------------------------

function FCTH.observeUI()
    observePreparedFreezerSelection(getSpecificPlayer(0))

    local observingSmoke =
        activeMode == "SMOKETEST"
        and activeState == "RUNNING"

    local observingExperiment =
        activeMode == "EXPERIMENT"
        and activeState == "RUNNING"

    if not observingSmoke
    and not observingExperiment then
        return
    end

    local player = getSpecificPlayer(0)
    if not player then
        return
    end

    local state = getState(player)
    local signature =
        state.ui.selectedID
        .. "|" .. boolText(state.ui.visible)
        .. "|" .. boolText(state.ui.collapsed)
        .. "|" .. boolText(state.ui.pinned)
        .. "|" .. getItemID(state.primary)
        .. "|" .. getItemID(state.secondary)

    if signature ~= lastObservedSignature then
        lastObservedSignature = signature

        if observingSmoke then
            observeSmokeTransition(state)
        else
            emit(
                "STATE_TRANSITION",
                state,
                " | status=OBSERVED"
            )
        end
    end

    if observingExperiment then
        local violation = experimentViolation(state)
        if violation then
            invalidateExperiment(state, violation)
        end
    end
end

------------------------------------------------------------
-- Main one-game-minute tick
------------------------------------------------------------

function FCTH.tick()
    local player = getSpecificPlayer(0)
    if not player then
        return
    end

    local playerData = player:getModData()

    if playerData.FCTH_setupError == true then
        return
    end

    if playerData.FCTH_setupVersion
    and playerData.FCTH_setupVersion ~= SETUP_VERSION then
        playerData.FCTH_setupError = true
        print(
            "[FCTH-FC004] status=ERROR"
            .. " | reason=stale_harness_save"
            .. " | foundSetupVersion="
            .. tostring(playerData.FCTH_setupVersion)
            .. " | requiredSetupVersion="
            .. tostring(SETUP_VERSION)
            .. " | action=create_fresh_save"
        )
        return
    end

    if not playerData.FCTH_spawnVerified then
        if not verifyFixedSpawn(player) then
            playerData.FCTH_setupError = true
            print(
                "[FCTH-FC004] status=ERROR"
                .. " | reason=fixed_spawn_not_applied"
                .. " | action=create_fresh_save"
            )
            return
        end

        playerData.FCTH_spawnVerified = SETUP_VERSION
        print(
            "[FCTH-FC004] status=SPAWN_VERIFIED"
            .. " | x=" .. tostring(TEST_SPAWN_X)
            .. " | y=" .. tostring(TEST_SPAWN_Y)
            .. " | z=" .. tostring(TEST_SPAWN_Z)
            .. " | build=" .. getBuildVersion()
        )
    end

    local appliance = findPoweredFridgeFreezer(player)

    if playerData.FCTH_fc004Prepared ~= true then
        if not appliance then
            waitLogCounter = waitLogCounter + 1
            if waitLogCounter == 1 or waitLogCounter % 6 == 0 then
                print(
                    "[FCTH-FC004] status=WAITING"
                    .. " | reason=no_powered_fridge_freezer"
                    .. " | radius=" .. tostring(SCAN_RADIUS)
                )
            end
            return
        end

        prepareFreezer(player, appliance)
        return
    end

    if playerData.FCTH_fc004Distributed ~= true then
        if not appliance then
            return
        end

        setupFreezer = appliance.freezer

        local frozenSteaks = collectPreparedFrozenSteaks(appliance.freezer)
        local frozenCount = 0

        for _, steak in ipairs(frozenSteaks) do
            if safeValue(function()
                return steak:isFrozen()
            end, false) then
                frozenCount = frozenCount + 1
            end
        end

        local freezerSelected =
            getSelectedLootContainer() == appliance.freezer

        print(
            "[FCTH-FC004] status=FREEZER_SAMPLE"
            .. " | worldHours=" .. tostring(getWorldHours())
            .. " | freezerSelected=" .. boolText(freezerSelected)
            .. " | selectedSinceWorldHours="
            .. tostring(setupFreezerSelectedSince or "NONE")
            .. " | steaksPresent=" .. tostring(#frozenSteaks)
            .. "/" .. tostring(FREEZER_STEAKS)
            .. freezerPreparationFoodFields(
                frozenSteaks[1],
                "freezerSteak1"
            )
            .. freezerPreparationFoodFields(
                frozenSteaks[2],
                "freezerSteak2"
            )
        )

        local signature =
            tostring(#frozenSteaks)
            .. "|" .. tostring(frozenCount)

        if signature ~= lastSetupSignature then
            lastSetupSignature = signature
            print(
                "[FCTH-FC004] status=FREEZER_PROGRESS"
                .. " | steaksPresent=" .. tostring(#frozenSteaks)
                .. "/" .. tostring(FREEZER_STEAKS)
                .. " | steaksFrozen=" .. tostring(frozenCount)
                .. "/" .. tostring(FREEZER_STEAKS)
            )
        end

        if freezerSelected
        and #frozenSteaks == FREEZER_STEAKS
        and frozenCount == FREEZER_STEAKS then
            local ok, reason = distributeMatchedSetup(player, appliance)

            if not ok then
                playerData.FCTH_setupError = true
                print(
                    "[FCTH-FC004] status=ERROR"
                    .. " | reason=" .. tostring(reason)
                )
            else
                setupFreezer = nil
                setupFreezerSelected = false
                setupFreezerSelectedSince = nil
            end
        end

        return
    end

    local state = getState(player)
    logReadiness(state)

    if activeMode == "SMOKETEST"
    and activeState == "RUNNING" then
        handleSmokeMinute(state)
    elseif activeMode == "EXPERIMENT" then
        handleExperimentMinute(state)
    end
end

Events.EveryOneMinute.Add(FCTH.tick)
Events.OnTick.Add(FCTH.observeUI)
Events.OnFillInventoryObjectContextMenu.Add(
    FCTH.onFillInventoryObjectContextMenu
)

print(
    "[FCTH-FC004] status=LOADED"
    .. " | harnessVersion=" .. HARNESS_VERSION
    .. " | setupVersion=" .. tostring(SETUP_VERSION)
    .. " | expectedBuild=" .. EXPECTED_BUILD
    .. " | controls=FC004_INVENTORY_CONTEXT_MENU"
    .. " | freezerSelectionRequired=true"
)
