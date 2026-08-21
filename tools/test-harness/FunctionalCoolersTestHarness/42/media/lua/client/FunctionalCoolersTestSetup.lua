------------------------------------------------------------
-- Functional Coolers Test Harness
-- Setup prototype v0.3.7-dev
-- Project Zomboid Build 42.20 test infrastructure only
--
-- Purpose:
--   Create a repeatable calibration setup without changing
--   FunctionalCoolers.lua itself.
--
-- The harness deliberately does NOT distribute food or packs
-- between coolers. Those transfers remain manual so later tests
-- can observe normal inventory/container behaviour.
------------------------------------------------------------

local FCTH = {}

local SETUP_VERSION = 9
local SCAN_RADIUS = 8

-- Fixed calibration position supplied for the dedicated test world.
local TEST_SPAWN_X = 10693
local TEST_SPAWN_Y = 9986
local TEST_SPAWN_Z = 0
local FREEZER_STEAKS = 7
local COLDPACKS = 8
local FRESH_STEAKS = 7
local COLDPACK_READY_TEMP = 0.205

local COOLER_LAYOUT = {
    { name = "P0",  x = 0.15, y = 0.20 },
    { name = "P1",  x = 0.32, y = 0.20 },
    { name = "P2",  x = 0.49, y = 0.20 },
    { name = "P4",  x = 0.66, y = 0.20 },
    { name = "P1G", x = 0.83, y = 0.20 },
}

local waitLogCounter = 0
local lastMonitorSignature = nil
local readyMessagePrinted = false

------------------------------------------------------------
-- Small safety helpers
------------------------------------------------------------

local function safeValue(fn, fallback)
    local ok, value = pcall(fn)
    if ok then
        return value
    end
    return fallback
end

local function getFullType(item)
    if not item then
        return nil
    end

    return safeValue(function()
        return item:getFullType()
    end, nil)
end

local function setCustomName(item, name)
    if not item then
        return
    end

    safeValue(function()
        item:setName(name)
        return true
    end, false)

    safeValue(function()
        item:setCustomName(true)
        return true
    end, false)
end

local function markGenerated(item, role)
    if not item then
        return
    end

    local data = item:getModData()
    data.FCTH_generated = true
    data.FCTH_role = role
    data.FCTH_setupVersion = SETUP_VERSION
end

local function isGenerated(item, role)
    if not item then
        return false
    end

    local data = item:getModData()
    if not data or data.FCTH_generated ~= true then
        return false
    end

    if role ~= nil and data.FCTH_role ~= role then
        return false
    end

    return true
end

------------------------------------------------------------
-- Configure the actual single-player spawn before the player
-- and destination chunk are created.
--
-- Build 42.20.3 runtime testing showed that IsoWorld LuaPosX/Y
-- are interpreted as absolute world-square coordinates in this
-- Sandbox path. LuaSpawnCellX/Y were not added to LuaPosX/Y.
-- Therefore use the requested absolute coordinates directly.
------------------------------------------------------------

local function configureFixedSpawn()
    local world = safeValue(function()
        return getWorld()
    end, nil)

    if not world then
        print("[FCTH-ERROR] fixed Lua spawn configuration failed | reason=no IsoWorld")
        return
    end

    local ok = safeValue(function()
        world:setLuaPosX(TEST_SPAWN_X)
        world:setLuaPosY(TEST_SPAWN_Y)
        world:setLuaPosZ(TEST_SPAWN_Z)
        return true
    end, false)

    if not ok then
        print("[FCTH-ERROR] fixed Lua spawn configuration failed | reason=spawn setter unavailable")
        return
    end

    print(
        "[FCTH] fixed absolute Lua spawn configured"
        .. " | x=" .. tostring(TEST_SPAWN_X)
        .. " | y=" .. tostring(TEST_SPAWN_Y)
        .. " | z=" .. tostring(TEST_SPAWN_Z)
    )
end

local function verifyFixedSpawn(player)
    if not player then
        return false
    end

    local actualX = safeValue(function() return player:getX() end, -99999)
    local actualY = safeValue(function() return player:getY() end, -99999)
    local actualZ = safeValue(function() return player:getZ() end, -99999)

    return math.floor(actualX) == TEST_SPAWN_X
       and math.floor(actualY) == TEST_SPAWN_Y
       and math.floor(actualZ) == TEST_SPAWN_Z
end

Events.OnInitWorld.Add(configureFixedSpawn)

------------------------------------------------------------
-- Find one nearby powered vanilla refrigerator object that
-- exposes both a fridge and a freezer container.
------------------------------------------------------------

local function findPoweredFridgeFreezer(player)
    local playerSquare = player and player:getSquare()
    if not playerSquare then
        return nil
    end

    local cell = getCell()
    if not cell then
        return nil
    end

    local px = playerSquare:getX()
    local py = playerSquare:getY()
    local pz = playerSquare:getZ()

    local best = nil
    local bestDistance = math.huge

    for x = px - SCAN_RADIUS, px + SCAN_RADIUS do
        for y = py - SCAN_RADIUS, py + SCAN_RADIUS do
            local square = cell:getGridSquare(x, y, pz)

            if square then
                local objects = safeValue(function()
                    return square:getObjects()
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

                                if container then
                                    local containerType = tostring(safeValue(function()
                                        return container:getType()
                                    end, ""))

                                    if containerType == "fridge" then
                                        fridge = container
                                    elseif containerType == "freezer" then
                                        freezer = container
                                    end
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
                                            object = object,
                                            square = square,
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
-- Container helpers
------------------------------------------------------------

local function clearContainer(container)
    if not container then
        return false
    end

    local ok = safeValue(function()
        container:removeAllItems()
        return true
    end, false)

    if ok then
        return true
    end

    return safeValue(function()
        container:clear()
        return true
    end, false)
end

local function countGenerated(container, role, fullType)
    if not container then
        return 0
    end

    local items = container:getItems()
    local count = 0

    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if isGenerated(item, role)
        and (fullType == nil or getFullType(item) == fullType) then
            count = count + 1
        end
    end

    return count
end

------------------------------------------------------------
-- Spawn the five exact Base.Cooler test objects on the floor.
-- Custom names are assigned before any calibration run starts.
------------------------------------------------------------

local function spawnNamedCoolers(square)
    if not square then
        return false
    end

    for _, entry in ipairs(COOLER_LAYOUT) do
        local cooler = safeValue(function()
            return square:AddWorldInventoryItem(
                "Base.Cooler",
                entry.x,
                entry.y,
                0.0
            )
        end, nil)

        if not cooler or getFullType(cooler) ~= "Base.Cooler" then
            print(
                "[FCTH-ERROR] failed to spawn Base.Cooler"
                .. " | name=" .. entry.name
            )
            return false
        end

        setCustomName(cooler, entry.name)
        markGenerated(cooler, "cooler_" .. entry.name)
    end

    return true
end

------------------------------------------------------------
-- Initial setup
--
-- Freezer:
--   8 coldpacks, then 7 steaks.
--
-- Player inventory:
--   one empty NEUTRAL satchel only.
--
-- The 7 fresh steaks are created later, only when the freezer
-- steaks are fully frozen and all coldpacks have reached the
-- Functional Coolers cold-state threshold.
------------------------------------------------------------

local function performSetup(player, appliance)
    local inventory = player:getInventory()
    local square = player:getSquare()

    if not inventory or not square or not appliance then
        return false
    end

    -- Dedicated test world: make both appliance compartments clean.
    if not clearContainer(appliance.fridge) then
        print("[FCTH-ERROR] could not clear fridge container")
        return false
    end

    if not clearContainer(appliance.freezer) then
        print("[FCTH-ERROR] could not clear freezer container")
        return false
    end

    -- Coldpacks first. They are not assigned an artificial temperature.
    for i = 1, COLDPACKS do
        local pack = safeValue(function()
            return appliance.freezer:AddItem("Base.Coldpack")
        end, nil)

        if not pack then
            print("[FCTH-ERROR] failed to add Base.Coldpack to freezer")
            return false
        end

        markGenerated(pack, "freezer_coldpack")
    end

    -- Steaks are also left entirely to vanilla freezing behaviour.
    for i = 1, FREEZER_STEAKS do
        local steak = safeValue(function()
            return appliance.freezer:AddItem("Base.Steak")
        end, nil)

        if not steak then
            print("[FCTH-ERROR] failed to add Base.Steak to freezer")
            return false
        end

        markGenerated(steak, "freezer_steak")
    end

    -- Test convenience items. They are intentionally added to the
    -- normal player inventory only. Equipping them manually avoids
    -- coupling the calibration harness to Build 42 worn-item APIs.
    local schoolbag = safeValue(function()
        return inventory:AddItem("Base.Bag_Schoolbag")
    end, nil)

    if not schoolbag then
        print("[FCTH-ERROR] failed to add Base.Bag_Schoolbag")
        return false
    end

    markGenerated(schoolbag, "schoolbag")

    local watch = safeValue(function()
        return inventory:AddItem("Base.WristWatch_Right_DigitalRed")
    end, nil)

    if not watch then
        print("[FCTH-ERROR] failed to add Base.WristWatch_Right_DigitalRed")
        return false
    end

    markGenerated(watch, "watch")

    -- Empty neutral inventory container for A/C phases.
    local neutral = safeValue(function()
        return inventory:AddItem("Base.Bag_Satchel")
    end, nil)

    if not neutral then
        print("[FCTH-ERROR] failed to add Base.Bag_Satchel")
        return false
    end

    setCustomName(neutral, "NEUTRAL")
    markGenerated(neutral, "neutral")

    if not spawnNamedCoolers(square) then
        return false
    end

    -- Validate the two freezer populations before declaring success.
    local packCount = countGenerated(
        appliance.freezer,
        "freezer_coldpack",
        "Base.Coldpack"
    )

    local steakCount = countGenerated(
        appliance.freezer,
        "freezer_steak",
        "Base.Steak"
    )

    if packCount ~= COLDPACKS or steakCount ~= FREEZER_STEAKS then
        print(
            "[FCTH-ERROR] setup validation failed"
            .. " | coldpacks=" .. tostring(packCount)
            .. "/" .. tostring(COLDPACKS)
            .. " | freezerSteaks=" .. tostring(steakCount)
            .. "/" .. tostring(FREEZER_STEAKS)
        )
        return false
    end

    local playerData = player:getModData()
    playerData.FCTH_setupVersion = SETUP_VERSION
    playerData.FCTH_freshGenerated = false
    playerData.FCTH_fridgeX = appliance.x
    playerData.FCTH_fridgeY = appliance.y
    playerData.FCTH_fridgeZ = appliance.z

    print(
        "[FCTH] setup complete"
        .. " | appliance="
        .. tostring(appliance.x) .. ","
        .. tostring(appliance.y) .. ","
        .. tostring(appliance.z)
    )

    print(
        "[FCTH] freezer prepared"
        .. " | coldpacks=" .. tostring(COLDPACKS)
        .. " | steaks=" .. tostring(FREEZER_STEAKS)
        .. " | artificialTemperature=false"
        .. " | artificialFreezing=false"
    )

    print(
        "[FCTH] floor coolers=P0,P1,P2,P4,P1G"
        .. " | exactType=Base.Cooler"
        .. " | inventoryNeutral=NEUTRAL"
    )

    print(
        "[FCTH] worn gear"
        .. " | schoolbag=Base.Bag_Schoolbag"
        .. " | watch=Base.WristWatch_Right_DigitalRed"
    )

    print("[FCTH] status=WAITING_FOR_FREEZER")

    return true
end

------------------------------------------------------------
-- Readiness monitor
------------------------------------------------------------

local function monitorFreezer(player, appliance)
    if not player or not appliance or not appliance.freezer then
        return
    end

    local items = appliance.freezer:getItems()

    local steakCount = 0
    local frozenCount = 0
    local packCount = 0
    local packReadyCount = 0
    local packUnknownCount = 0
    local minPackTemp = nil
    local maxPackTemp = nil

    for i = 0, items:size() - 1 do
        local item = items:get(i)

        if isGenerated(item, "freezer_steak")
        and getFullType(item) == "Base.Steak" then
            steakCount = steakCount + 1

            local frozen = safeValue(function()
                return item:isFrozen()
            end, false)

            if frozen then
                frozenCount = frozenCount + 1
            end

        elseif isGenerated(item, "freezer_coldpack")
        and getFullType(item) == "Base.Coldpack" then
            packCount = packCount + 1

            -- FunctionalCoolers.lua owns this physical state.
            -- The harness only observes it; it never writes it.
            local data = item:getModData()
            local temp = data and data.FC_temperature or nil

            if type(temp) == "number" then
                if minPackTemp == nil or temp < minPackTemp then
                    minPackTemp = temp
                end

                if maxPackTemp == nil or temp > maxPackTemp then
                    maxPackTemp = temp
                end

                if temp <= COLDPACK_READY_TEMP then
                    packReadyCount = packReadyCount + 1
                end
            else
                packUnknownCount = packUnknownCount + 1
            end
        end
    end

    local signature = table.concat({
        tostring(steakCount),
        tostring(frozenCount),
        tostring(packCount),
        tostring(packReadyCount),
        tostring(packUnknownCount),
        minPackTemp and string.format("%.6f", minPackTemp) or "nil",
        maxPackTemp and string.format("%.6f", maxPackTemp) or "nil",
    }, "|")

    if signature ~= lastMonitorSignature then
        lastMonitorSignature = signature

        print(
            "[FCTH] freezer status"
            .. " | steaksFrozen=" .. tostring(frozenCount)
            .. "/" .. tostring(FREEZER_STEAKS)
            .. " | coldpacksReady=" .. tostring(packReadyCount)
            .. "/" .. tostring(COLDPACKS)
            .. " | coldpacksUnknown=" .. tostring(packUnknownCount)
            .. " | packTempMin=" .. tostring(minPackTemp)
            .. " | packTempMax=" .. tostring(maxPackTemp)
        )
    end

    local freezerReady =
        steakCount == FREEZER_STEAKS
        and frozenCount == FREEZER_STEAKS
        and packCount == COLDPACKS
        and packReadyCount == COLDPACKS

    local playerData = player:getModData()

    if freezerReady and playerData.FCTH_freshGenerated ~= true then
        local inventory = player:getInventory()
        local created = 0

        for i = 1, FRESH_STEAKS do
            local steak = safeValue(function()
                return inventory:AddItem("Base.Steak")
            end, nil)

            if steak then
                markGenerated(steak, "fresh_steak")
                created = created + 1
            end
        end

        if created == FRESH_STEAKS then
            playerData.FCTH_freshGenerated = true

            print(
                "[FCTH] fresh steaks created"
                .. " | count=" .. tostring(FRESH_STEAKS)
                .. " | location=PLAYER_INVENTORY"
            )
        else
            print(
                "[FCTH-ERROR] fresh steak generation incomplete"
                .. " | created=" .. tostring(created)
                .. "/" .. tostring(FRESH_STEAKS)
            )
            return
        end
    end

    if freezerReady
    and playerData.FCTH_freshGenerated == true
    and not readyMessagePrinted then
        readyMessagePrinted = true

        print("[FCTH] status=READY_TO_DISTRIBUTE")
        print(
            "[FCTH] next: distribute packs and steaks manually;"
            .. " do not artificially edit food or coldpack state"
        )
    end
end

------------------------------------------------------------
-- Main tick
--
-- EveryOneMinute is already used successfully by the main mod
-- in the current Build 42.20 test environment.
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

    if playerData.FCTH_setupVersion ~= SETUP_VERSION
    and playerData.FCTH_spawnVerified ~= SETUP_VERSION then
        if not verifyFixedSpawn(player) then
            local actualX = safeValue(function() return player:getX() end, -99999)
            local actualY = safeValue(function() return player:getY() end, -99999)
            local actualZ = safeValue(function() return player:getZ() end, -99999)

            playerData.FCTH_setupError = true
            print(
                "[FCTH-ERROR] fixed Lua spawn not applied"
                .. " | expected="
                .. tostring(TEST_SPAWN_X) .. ","
                .. tostring(TEST_SPAWN_Y) .. ","
                .. tostring(TEST_SPAWN_Z)
                .. " | actual="
                .. tostring(actualX) .. ","
                .. tostring(actualY) .. ","
                .. tostring(actualZ)
                .. " | setup aborted for this save"
            )
            return
        end

        playerData.FCTH_spawnVerified = SETUP_VERSION
        print(
            "[FCTH] fixed spawn verified"
            .. " | x=" .. tostring(TEST_SPAWN_X)
            .. " | y=" .. tostring(TEST_SPAWN_Y)
            .. " | z=" .. tostring(TEST_SPAWN_Z)
        )
    end

    local appliance = findPoweredFridgeFreezer(player)

    if playerData.FCTH_setupVersion ~= SETUP_VERSION then
        if not appliance then
            waitLogCounter = waitLogCounter + 1

            if waitLogCounter == 1 or waitLogCounter % 6 == 0 then
                print(
                    "[FCTH] setup waiting"
                    .. " | reason=no powered fridge+freezer within "
                    .. tostring(SCAN_RADIUS)
                    .. " tiles"
                )
            end

            return
        end

        local ok = safeValue(function()
            return performSetup(player, appliance)
        end, false)

        if not ok then
            playerData.FCTH_setupError = true
            print(
                "[FCTH-ERROR] setup aborted"
                .. " | automatic retry disabled for this save"
            )
        end

        return
    end

    if not appliance then
        -- Once setup is complete, moving away from the refrigerator is
        -- allowed. Monitoring simply resumes when it is nearby again.
        return
    end

    monitorFreezer(player, appliance)
end

Events.EveryOneMinute.Add(FCTH.tick)

print("[FCTH] Functional Coolers Test Harness v0.3.7-dev loaded.")
