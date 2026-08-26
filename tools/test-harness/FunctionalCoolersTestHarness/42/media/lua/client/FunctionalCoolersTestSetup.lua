------------------------------------------------------------
-- Functional Coolers Test Harness
-- FC-006 infrastructure v0.5.1-dev
-- Project Zomboid Build 42.20.3 test infrastructure only
--
-- Purpose:
--   Create the deterministic FC006-GUARD / FC006-TEST setup.
--   Validate the bounded Food handoff control surface.
--   Run the non-evidence FC-006 infrastructure smoketest.
--   Provide the separately gated FC-006 experiment path.
--
-- Controls:
--   Right-click an FC-006 Cooler or one of its contents.
--   Do not arm the experiment without separate Bart authorization.
------------------------------------------------------------

local FCTH = {}

local SETUP_VERSION = 13
local HARNESS_VERSION = "0.5.1-dev"
local HARNESS_MOD_ID = "FunctionalCoolersTestHarness"
local EXPECTED_BUILD = "42.20.3"
local PRODUCTION_MOD_ID = "FunctionalCoolers"

local TEST_SPAWN_X = 10693
local TEST_SPAWN_Y = 9986
local TEST_SPAWN_Z = 0

local REQUIRED_DAY_LENGTH = 4
local REQUIRED_FOOD_ROT_SPEED = 3
local REQUIRED_FRIDGE_FACTOR = 3

local GUARD_NAME = "FC006-GUARD"
local TEST_NAME = "FC006-TEST"
local GUARD_ROLE = "fc006_guard"
local TEST_ROLE = "fc006_test"
local V_ROLE = "fc006_v"
local A_ROLE = "fc006_a"
local U_ROLE = "fc006_u"

-- The accepted protocol specifies one common public projection. Setup and
-- handoff use the same values so the tested contrast is vanilla cursor
-- alignment, not a difference in projected public state.
local PROJECTED_AGE = 0.5
local PROJECTED_HEAT = 1.0
local PROJECTED_FREEZING_TIME = 80.0

local STALE_INTERVAL_HOURS = 1.0
local UPDATE_INTERVAL_HOURS = 10.0 / 60.0
local UPDATE_COUNT = 3
local REQUIRED_STABLE_SAMPLES = 2

local TIME_TOLERANCE = 0.001
local AGE_TOLERANCE = 0.00001
local HEAT_TOLERANCE = 0.01
local FREEZING_TOLERANCE = 0.05

local activeMode = nil
local activeState = "IDLE"
local stableSampleCount = 0
local beginWorldHours = nil
local handoffWorldHours = nil
local nextUpdateWorldHours = nil
local completedUpdates = 0
local lastReadySignature = nil
local lastObservedSignature = nil

local smoke = {
    startWorldHours = nil,
    startSnapshot = nil,
    setterCallsPassed = false,
    phaseFlagsPassed = false,
    phaseGuardPassed = false,
    scheduleCheckPassed = false,
    staleVersionGuardPassed = false,
    mismatchProbePassed = false,
    protocolMarkers = {},
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

local function getBuildVersion()
    return tostring(safeValue(function()
        return getCore():getVersion()
    end, "UNAVAILABLE"))
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

local function within(left, right, tolerance)
    if type(left) ~= "number" or type(right) ~= "number" then
        return false
    end
    return math.abs(left - right) <= tolerance
end

local function runItemCall(item, methodName, argument)
    if not item then
        return false, "item_missing"
    end

    local ok, result = pcall(function()
        if methodName == "setAutoAge" then
            item:setAutoAge()
        elseif methodName == "setAge" then
            item:setAge(argument)
        elseif methodName == "setHeat" then
            item:setHeat(argument)
        elseif methodName == "setFreezingTime" then
            item:setFreezingTime(argument)
        elseif methodName == "updateAge" then
            item:updateAge()
        else
            error("unsupported_method_" .. tostring(methodName))
        end
        return true
    end)

    if not ok or result ~= true then
        return false, methodName .. "_failed"
    end
    return true, nil
end

local function setupVersionCompatible(foundVersion)
    return foundVersion == nil or foundVersion == SETUP_VERSION
end

local function setCustomName(item, name)
    if not item then
        return false
    end
    return safeValue(function()
        item:setName(name)
        item:setCustomName(true)
        return true
    end, false)
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
        visible = visible,
        collapsed = collapsed,
        pinned = pinned,
        selectedContainer = selectedContainer,
        selectedItem = selectedItem,
        selectedID = getItemID(selectedItem),
        selectedType = getFullType(selectedItem),
    }
end

local function buildMatches()
    return string.find(getBuildVersion(), EXPECTED_BUILD, 1, true) ~= nil
end

local function sandboxMatches()
    return SandboxVars
       and SandboxVars.DayLength == REQUIRED_DAY_LENGTH
       and SandboxVars.FoodRotSpeed == REQUIRED_FOOD_ROT_SPEED
       and SandboxVars.FridgeFactor == REQUIRED_FRIDGE_FACTOR
end

local function activatedModState()
    local mods = safeValue(function()
        return getActivatedMods()
    end, nil)

    if not mods then
        return {
            available = false,
            harnessEnabled = nil,
            productionEnabled = nil,
            unexpected = { "UNAVAILABLE" },
            text = "UNAVAILABLE",
        }
    end

    local ids = {}
    local unexpected = {}
    local harnessEnabled = false
    local productionEnabled = false
    local count = safeValue(function() return mods:size() end, 0)

    for index = 0, count - 1 do
        local id = tostring(safeValue(function()
            return mods:get(index)
        end, "UNAVAILABLE"))
        table.insert(ids, id)

        if id == HARNESS_MOD_ID then
            harnessEnabled = true
        elseif id == PRODUCTION_MOD_ID then
            productionEnabled = true
        else
            table.insert(unexpected, id)
        end
    end

    table.sort(ids)
    table.sort(unexpected)
    return {
        available = true,
        harnessEnabled = harnessEnabled,
        productionEnabled = productionEnabled,
        unexpected = unexpected,
        text = #ids > 0 and table.concat(ids, ",") or "NONE",
    }
end

local function evidenceEligible()
    return activeMode == "EXPERIMENT"
end

local function logLine(fields)
    print(
        "[FCTH-FC006]"
        .. " | harnessVersion=" .. HARNESS_VERSION
        .. " | setupVersion=" .. tostring(SETUP_VERSION)
        .. " | evidenceEligible=" .. boolText(evidenceEligible())
        .. " | " .. fields
    )
end

local function recordSmokeProtocolMarker(marker)
    if activeMode == "SMOKETEST" then
        table.insert(smoke.protocolMarkers, marker)
    end
end

------------------------------------------------------------
-- Fixed dedicated-sandbox spawn
------------------------------------------------------------

local function configureFixedSpawn()
    local world = safeValue(function()
        return getWorld()
    end, nil)

    if not world then
        logLine("status=ERROR | reason=no_iso_world")
        return
    end

    local ok = safeValue(function()
        world:setLuaPosX(TEST_SPAWN_X)
        world:setLuaPosY(TEST_SPAWN_Y)
        world:setLuaPosZ(TEST_SPAWN_Z)
        return true
    end, false)

    if not ok then
        logLine("status=ERROR | reason=spawn_setter_unavailable")
        return
    end

    logLine(
        "status=SPAWN_CONFIGURED"
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
-- Food projection and observation
------------------------------------------------------------

local function foodSnapshot(item)
    if not item then
        return nil
    end

    return {
        id = getItemID(item),
        lastAged = safeValue(function() return item:getLastAged() end, nil),
        age = safeValue(function() return item:getAge() end, nil),
        heat = safeValue(function() return item:getHeat() end, nil),
        freezingTime = safeValue(function()
            return item:getFreezingTime()
        end, nil),
        frozen = safeValue(function() return item:isFrozen() end, nil),
        freezing = safeValue(function() return item:isFreezing() end, nil),
        thawing = safeValue(function() return item:isThawing() end, nil),
    }
end

local function foodFields(snapshot, label)
    if not snapshot then
        return " | " .. label .. "ID=NONE"
    end

    return
        " | " .. label .. "ID=" .. tostring(snapshot.id)
        .. " | " .. label .. "lastAged=" .. tostring(snapshot.lastAged)
        .. " | " .. label .. "age=" .. tostring(snapshot.age)
        .. " | " .. label .. "heat=" .. tostring(snapshot.heat)
        .. " | " .. label .. "freezingTime="
        .. tostring(snapshot.freezingTime)
        .. " | " .. label .. "frozen=" .. boolText(snapshot.frozen)
        .. " | " .. label .. "freezing=" .. boolText(snapshot.freezing)
        .. " | " .. label .. "thawing=" .. boolText(snapshot.thawing)
end

local function projectPublicState(item)
    local calls = {
        { "setAge", PROJECTED_AGE },
        { "setHeat", PROJECTED_HEAT },
        { "setFreezingTime", PROJECTED_FREEZING_TIME },
    }

    for _, call in ipairs(calls) do
        local ok, reason = runItemCall(item, call[1], call[2])
        if not ok then
            return false, reason
        end
    end

    return true, nil
end

local function alignAndProject(item)
    local ok, reason = runItemCall(item, "setAutoAge")
    if not ok then
        return false, reason
    end
    return projectPublicState(item)
end

local function phaseFlagsMatch(snapshot)
    return snapshot
       and snapshot.frozen == false
       and snapshot.freezing == false
       and snapshot.thawing == true
end

local function snapshotMatchesProjection(snapshot)
    return snapshot
       and within(snapshot.age, PROJECTED_AGE, AGE_TOLERANCE)
       and within(snapshot.heat, PROJECTED_HEAT, HEAT_TOLERANCE)
       and within(
            snapshot.freezingTime,
            PROJECTED_FREEZING_TIME,
            FREEZING_TOLERANCE
       )
       and phaseFlagsMatch(snapshot)
end

local function publicStatesEqual(left, right)
    return left and right
       and within(left.age, right.age, AGE_TOLERANCE)
       and within(left.heat, right.heat, HEAT_TOLERANCE)
       and within(
            left.freezingTime,
            right.freezingTime,
            FREEZING_TOLERANCE
       )
       and left.frozen == right.frozen
       and left.freezing == right.freezing
       and left.thawing == right.thawing
end

local function snapshotsHaveRequiredPublicState(v, a, u)
    return publicStatesEqual(v, a)
       and publicStatesEqual(v, u)
       and snapshotMatchesProjection(v)
       and snapshotMatchesProjection(a)
       and snapshotMatchesProjection(u)
end

------------------------------------------------------------
-- Deterministic FC-006 setup
------------------------------------------------------------

local function createCooler(inventory, name, role)
    local cooler = safeValue(function()
        return inventory:AddItem("Base.Cooler")
    end, nil)

    if not cooler
    or getFullType(cooler) ~= "Base.Cooler"
    or not setCustomName(cooler, name)
    or not markGenerated(cooler, role) then
        return nil
    end

    return cooler
end

local function createSteak(container, name, role)
    local steak = safeValue(function()
        return container:AddItem("Base.Steak")
    end, nil)

    if not steak
    or not setCustomName(steak, name)
    or not markGenerated(steak, role) then
        return nil
    end

    return steak
end

local function prepareCommonBaseline(items)
    for _, item in ipairs(items) do
        local ok, reason = alignAndProject(item)
        if not ok then
            return false, reason
        end
    end

    local v = foodSnapshot(items[1])
    local a = foodSnapshot(items[2])
    local u = foodSnapshot(items[3])

    if not snapshotsHaveRequiredPublicState(v, a, u) then
        return false, "baseline_public_state_mismatch"
    end

    return true, nil
end

local function createSetup(player)
    local playerData = player:getModData()

    if not setupVersionCompatible(playerData.FCTH_setupVersion) then
        playerData.FCTH_setupError = true
        logLine(
            "status=ERROR"
            .. " | reason=stale_harness_save"
            .. " | foundSetupVersion="
            .. tostring(playerData.FCTH_setupVersion)
            .. " | requiredSetupVersion=" .. tostring(SETUP_VERSION)
            .. " | action=create_fresh_save"
        )
        return false
    end

    local inventory = player:getInventory()
    local guard = createCooler(inventory, GUARD_NAME, GUARD_ROLE)
    local test = createCooler(inventory, TEST_NAME, TEST_ROLE)
    local testContainer = getCoolerContainer(test)

    if not guard or not test or not testContainer then
        playerData.FCTH_setupError = true
        logLine("status=ERROR | reason=cooler_setup_failed")
        return false
    end

    local v = createSteak(testContainer, "FC006-V", V_ROLE)
    local a = createSteak(testContainer, "FC006-A", A_ROLE)
    local u = createSteak(testContainer, "FC006-U", U_ROLE)

    if not v or not a or not u then
        playerData.FCTH_setupError = true
        logLine("status=ERROR | reason=food_setup_failed")
        return false
    end

    local baselineOK, baselineReason = prepareCommonBaseline({ v, a, u })
    if not baselineOK then
        playerData.FCTH_setupError = true
        logLine(
            "status=ERROR | reason=" .. tostring(baselineReason)
        )
        return false
    end

    local watch = safeValue(function()
        return inventory:AddItem("Base.WristWatch_Right_DigitalRed")
    end, nil)
    if watch then
        markGenerated(watch, "watch")
    end

    playerData.FCTH_setupVersion = SETUP_VERSION
    playerData.FCTH_fc006Created = true
    playerData.FCTH_guardID = getItemID(guard)
    playerData.FCTH_testID = getItemID(test)
    playerData.FCTH_vID = getItemID(v)
    playerData.FCTH_aID = getItemID(a)
    playerData.FCTH_uID = getItemID(u)

    logLine(
        "status=MATCHED_SETUP_CREATED"
        .. " | worldHours=" .. tostring(getWorldHours())
        .. " | guardID=" .. getItemID(guard)
        .. " | testID=" .. getItemID(test)
        .. " | vID=" .. getItemID(v)
        .. " | aID=" .. getItemID(a)
        .. " | uID=" .. getItemID(u)
        .. " | guardContents=0"
        .. " | testContents=V_A_U"
        .. " | projectedAge=" .. tostring(PROJECTED_AGE)
        .. " | projectedHeat=" .. tostring(PROJECTED_HEAT)
        .. " | projectedFreezingTime="
        .. tostring(PROJECTED_FREEZING_TIME)
    )

    logLine(
        "status=WAITING_FOR_EQUIP_AND_SELECTION"
        .. " | requiredPrimary=" .. GUARD_NAME
        .. " | requiredSecondary=" .. TEST_NAME
        .. " | requiredSelected=" .. GUARD_NAME
        .. " | action=equip_pin_open_select_guard"
    )

    return true
end

------------------------------------------------------------
-- Group and readiness observation
------------------------------------------------------------

local function findSetupItems(player)
    local result = {
        guard = nil,
        test = nil,
        v = nil,
        a = nil,
        u = nil,
        guardCount = 0,
        testCount = 0,
        unexpectedTestItems = 0,
    }

    local inventory = player and player:getInventory()
    local rootItems = inventory and inventory:getItems() or nil
    if not rootItems then
        return result
    end

    for index = 0, rootItems:size() - 1 do
        local item = rootItems:get(index)
        if hasRole(item, GUARD_ROLE) then
            result.guard = item
        elseif hasRole(item, TEST_ROLE) then
            result.test = item
        end
    end

    local guardContainer = getCoolerContainer(result.guard)
    local guardItems = guardContainer and guardContainer:getItems() or nil
    result.guardCount = guardItems and guardItems:size() or 0

    local testContainer = getCoolerContainer(result.test)
    local testItems = testContainer and testContainer:getItems() or nil
    result.testCount = testItems and testItems:size() or 0

    if testItems then
        for index = 0, testItems:size() - 1 do
            local item = testItems:get(index)
            if hasRole(item, V_ROLE) then
                result.v = item
            elseif hasRole(item, A_ROLE) then
                result.a = item
            elseif hasRole(item, U_ROLE) then
                result.u = item
            else
                result.unexpectedTestItems = result.unexpectedTestItems + 1
            end
        end
    end

    return result
end

local function getState(player)
    local items = findSetupItems(player)
    local ui = getInventoryUIState()
    local primary = safeValue(function()
        return player:getPrimaryHandItem()
    end, nil)
    local secondary = safeValue(function()
        return player:getSecondaryHandItem()
    end, nil)

    local contextsReady = items.guard
       and items.test
       and safeValue(function()
            return items.guard:isInPlayerInventory()
       end, false)
       and safeValue(function()
            return items.test:isInPlayerInventory()
       end, false)

    local contentsReady = items.guardCount == 0
       and items.testCount == 3
       and items.unexpectedTestItems == 0
       and items.v ~= nil
       and items.a ~= nil
       and items.u ~= nil

    local handsReady = primary == items.guard and secondary == items.test
    local selectedReady = ui.selectedItem == items.guard
    local modState = activatedModState()

    local treatmentReady = contextsReady
       and contentsReady
       and handsReady
       and selectedReady
       and ui.visible
       and not ui.collapsed
       and ui.pinned
       and buildMatches()
       and sandboxMatches()
       and modState.available
       and modState.harnessEnabled
       and modState.productionEnabled == false
       and #modState.unexpected == 0

    return {
        items = items,
        ui = ui,
        primary = primary,
        secondary = secondary,
        contextsReady = contextsReady == true,
        contentsReady = contentsReady,
        handsReady = handsReady,
        selectedReady = selectedReady,
        modState = modState,
        productionEnabled = modState.productionEnabled,
        treatmentReady = treatmentReady == true,
        v = foodSnapshot(items.v),
        a = foodSnapshot(items.a),
        u = foodSnapshot(items.u),
    }
end

local function stateFields(state)
    return
        " | worldHours=" .. tostring(getWorldHours())
        .. " | build=" .. getBuildVersion()
        .. " | DayLength=" .. tostring(SandboxVars and SandboxVars.DayLength)
        .. " | FoodRotSpeed="
        .. tostring(SandboxVars and SandboxVars.FoodRotSpeed)
        .. " | FridgeFactor="
        .. tostring(SandboxVars and SandboxVars.FridgeFactor)
        .. " | productionModEnabled="
        .. boolText(state.productionEnabled)
        .. " | harnessModEnabled="
        .. boolText(state.modState.harnessEnabled)
        .. " | activatedMods=" .. state.modState.text
        .. " | unexpectedModCount="
        .. tostring(#state.modState.unexpected)
        .. " | guardID=" .. getItemID(state.items.guard)
        .. " | testID=" .. getItemID(state.items.test)
        .. " | primaryID=" .. getItemID(state.primary)
        .. " | secondaryID=" .. getItemID(state.secondary)
        .. " | selectedID=" .. state.ui.selectedID
        .. " | selectedType=" .. state.ui.selectedType
        .. " | inventoryVisible=" .. boolText(state.ui.visible)
        .. " | inventoryCollapsed=" .. boolText(state.ui.collapsed)
        .. " | inventoryPinned=" .. boolText(state.ui.pinned)
        .. " | contextsReady=" .. boolText(state.contextsReady)
        .. " | contentsReady=" .. boolText(state.contentsReady)
        .. " | handsReady=" .. boolText(state.handsReady)
        .. " | selectedReady=" .. boolText(state.selectedReady)
        .. " | treatmentReady=" .. boolText(state.treatmentReady)
        .. " | guardCount=" .. tostring(state.items.guardCount)
        .. " | testCount=" .. tostring(state.items.testCount)
        .. " | unexpectedTestItems="
        .. tostring(state.items.unexpectedTestItems)
        .. foodFields(state.v, "v")
        .. foodFields(state.a, "a")
        .. foodFields(state.u, "u")
end

local function emit(marker, state, extra)
    logLine(
        "mode=" .. tostring(activeMode or "MONITOR")
        .. " | phase=" .. marker
        .. stateFields(state)
        .. (extra or "")
    )
end

local function readinessReason(state)
    if not buildMatches() then
        return "build_mismatch"
    end
    if not sandboxMatches() then
        return "sandbox_mismatch"
    end
    if not state.modState.available then
        return "activated_mod_state_unavailable"
    end
    if not state.modState.harnessEnabled then
        return "harness_mod_not_in_activated_set"
    end
    if state.productionEnabled == true then
        return "production_mod_enabled"
    end
    if #state.modState.unexpected > 0 then
        return "unexpected_enabled_mods"
    end
    if not state.items.guard or not state.items.test then
        return "fc006_cooler_missing"
    end
    if not state.contextsReady then
        return "carried_context_changed"
    end
    if not state.contentsReady then
        return "matched_contents_changed"
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
        return "selected_container_not_guard"
    end
    return "ready"
end

local function logReadiness(state)
    local reason = readinessReason(state)
    local signature = reason
        .. "|" .. getItemID(state.items.guard)
        .. "|" .. getItemID(state.items.test)
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
        emit("READY", state, " | status=WAITING | reason=" .. reason)
    end
end

local function runViolation(state)
    if not state.treatmentReady then
        return readinessReason(state)
    end
    return nil
end

local function finishInvalid(state, reason)
    activeState = "COMPLETE"
    emit("INVALIDATED", state, " | status=INVALID | reason=" .. reason)
    emit("END", state, " | status=INVALID | reason=" .. reason)
end

local function attemptHandoffCommit(state, extra, expectedSmokeProbe)
    if not snapshotsHaveRequiredPublicState(state.v, state.a, state.u) then
        if expectedSmokeProbe then
            emit(
                "INVALIDATED",
                state,
                " | status=EXPECTED_SMOKE_PROBE"
                .. " | reason=public_phase_state_mismatch"
                .. " | handoffCommitted=false"
            )
        else
            finishInvalid(state, "public_phase_state_mismatch")
        end
        return false, "public_phase_state_mismatch"
    end

    emit(
        "HANDOFF_COMMITTED",
        state,
        " | status=COMMITTED" .. (extra or "")
    )
    recordSmokeProtocolMarker("HANDOFF_COMMITTED")
    return true, nil
end

local function runMismatchCommitProbe(player, state)
    local baselineOK, baselineReason = prepareCommonBaseline({
        state.items.v,
        state.items.a,
        state.items.u,
    })
    if not baselineOK then
        return false, baselineReason or "probe_baseline_failed"
    end

    local mismatchOK, mismatchReason = runItemCall(
        state.items.u,
        "setHeat",
        -1.0
    )
    state = getState(player)
    if not mismatchOK then
        return false, mismatchReason or "probe_mismatch_write_failed"
    end

    local committed, commitReason = attemptHandoffCommit(
        state,
        " | smokeProbe=mismatch",
        true
    )

    local resetOK, resetReason = prepareCommonBaseline({
        state.items.v,
        state.items.a,
        state.items.u,
    })

    if committed then
        return false, "mismatch_probe_unexpected_commit"
    end
    if commitReason ~= "public_phase_state_mismatch" then
        return false, commitReason or "mismatch_probe_wrong_reason"
    end
    if not resetOK then
        return false, resetReason or "mismatch_probe_reset_failed"
    end

    state = getState(player)
    emit(
        "SMOKE_MISMATCH_GUARD",
        state,
        " | status=PASS"
        .. " | invalidReason=public_phase_state_mismatch"
        .. " | handoffCommitted=false"
        .. " | baselineResetPassed=true"
    )
    return true, nil
end

local function beginProtocolRun(player, state)
    local baselineOK, baselineReason = prepareCommonBaseline({
        state.items.v,
        state.items.a,
        state.items.u,
    })
    state = getState(player)

    if not baselineOK then
        finishInvalid(state, baselineReason or "baseline_projection_failed")
        return false
    end

    beginWorldHours = getWorldHours()
    activeState = "STALE_INTERVAL"
    emit(
        "BEGIN",
        state,
        " | status=RUNNING"
        .. " | managedStaleGameHours="
        .. tostring(STALE_INTERVAL_HOURS)
        .. " | harnessStateUpdatesDuringInterval=0"
        .. " | protocolDryRun="
        .. boolText(activeMode == "SMOKETEST")
    )
    recordSmokeProtocolMarker("BEGIN")
    return true
end

------------------------------------------------------------
-- FC-006 infrastructure smoketest
------------------------------------------------------------

local function resetSmoke()
    smoke.startWorldHours = nil
    smoke.startSnapshot = nil
    smoke.setterCallsPassed = false
    smoke.phaseFlagsPassed = false
    smoke.phaseGuardPassed = false
    smoke.scheduleCheckPassed = false
    smoke.staleVersionGuardPassed = false
    smoke.mismatchProbePassed = false
    smoke.protocolMarkers = {}
end

local function phaseGuardSelfCheck(snapshot)
    if not snapshot then
        return false
    end

    local mismatch = {
        id = snapshot.id,
        lastAged = snapshot.lastAged,
        age = snapshot.age,
        heat = snapshot.heat,
        freezingTime = snapshot.freezingTime,
        frozen = snapshot.frozen,
        freezing = snapshot.freezing,
        thawing = false,
    }

    return publicStatesEqual(snapshot, snapshot)
       and not publicStatesEqual(snapshot, mismatch)
end

local function protocolScheduleSelfCheck()
    return STALE_INTERVAL_HOURS == 1.0
       and UPDATE_INTERVAL_HOURS == 10.0 / 60.0
       and UPDATE_COUNT == 3
       and TIME_TOLERANCE == 0.001
end

local function staleVersionGuardSelfCheck()
    return setupVersionCompatible(nil)
       and setupVersionCompatible(SETUP_VERSION)
       and not setupVersionCompatible(SETUP_VERSION - 1)
end

local function startSmoke(player)
    if activeMode and activeState ~= "COMPLETE" then
        logLine(
            "mode=" .. tostring(activeMode)
            .. " | phase=CONTROL | status=REJECTED"
            .. " | reason=run_already_active"
        )
        return
    end

    local state = getState(player)
    if not state.treatmentReady then
        emit(
            "CONTROL",
            state,
            " | status=REJECTED | reason=" .. readinessReason(state)
        )
        return
    end

    resetSmoke()
    activeMode = "SMOKETEST"
    activeState = "RUNNING"

    local aligned, alignReason = alignAndProject(state.items.u)
    state = getState(player)

    smoke.setterCallsPassed = aligned
    smoke.phaseFlagsPassed = phaseFlagsMatch(state.u)
    smoke.phaseGuardPassed = phaseGuardSelfCheck(state.u)
    smoke.scheduleCheckPassed = protocolScheduleSelfCheck()
    smoke.staleVersionGuardPassed = staleVersionGuardSelfCheck()
    smoke.startWorldHours = getWorldHours()
    smoke.startSnapshot = state.u

    emit(
        "SMOKE_BEGIN",
        state,
        " | status=RUNNING"
        .. " | disposableGroup=U"
        .. " | targetGameMinutes=10"
        .. " | setterCallsPassed="
        .. boolText(smoke.setterCallsPassed)
        .. " | setterFailure=" .. tostring(alignReason or "NONE")
        .. " | requiredPhaseFlagsPassed="
        .. boolText(smoke.phaseFlagsPassed)
        .. " | publicPhaseGuardSelfCheck="
        .. boolText(smoke.phaseGuardPassed)
        .. " | scheduleSelfCheck="
        .. boolText(smoke.scheduleCheckPassed)
        .. " | staleVersionGuardSelfCheck="
        .. boolText(smoke.staleVersionGuardPassed)
    )

    if not smoke.setterCallsPassed then
        finishInvalid(state, alignReason or "required_setter_call_failed")
    elseif not smoke.phaseFlagsPassed then
        finishInvalid(state, "smoke_initial_phase_flags_mismatch")
    elseif not smoke.phaseGuardPassed then
        finishInvalid(state, "public_phase_guard_selfcheck_failed")
    elseif not smoke.scheduleCheckPassed then
        finishInvalid(state, "protocol_schedule_selfcheck_failed")
    elseif not smoke.staleVersionGuardPassed then
        finishInvalid(state, "stale_version_guard_selfcheck_failed")
    end
end

local function handleSmokeMinute(player, state, logSample)
    if activeState ~= "RUNNING" then
        return
    end

    local violation = runViolation(state)
    if violation then
        finishInvalid(state, violation)
        return
    end

    local now = getWorldHours()
    local elapsed = now and smoke.startWorldHours
        and now - smoke.startWorldHours or nil

    if logSample then
        emit(
            "SMOKE_WAIT",
            state,
            " | status=RUNNING"
            .. " | elapsedGameHours=" .. tostring(elapsed)
            .. " | explicitUpdateCalls=0"
        )
    end

    if not elapsed or elapsed < UPDATE_INTERVAL_HOURS then
        return
    end

    local before = foodSnapshot(state.items.u)
    local updateOK, updateReason = runItemCall(state.items.u, "updateAge")
    local after = foodSnapshot(state.items.u)
    local freezingDelta = before and after
        and type(before.freezingTime) == "number"
        and type(after.freezingTime) == "number"
        and before.freezingTime - after.freezingTime or nil
    local elapsedOK = within(
        elapsed,
        UPDATE_INTERVAL_HOURS,
        TIME_TOLERANCE
    )
    local responseOK = type(freezingDelta) == "number"
        and freezingDelta > FREEZING_TOLERANCE

    state = getState(player)
    emit(
        "SMOKE_THAW_UPDATE",
        state,
        " | status=OBSERVED"
        .. " | elapsedGameHours=" .. tostring(elapsed)
        .. " | elapsedWithinTolerance=" .. boolText(elapsedOK)
        .. " | updateAgeCallPassed=" .. boolText(updateOK)
        .. " | updateAgeFailure=" .. tostring(updateReason or "NONE")
        .. " | freezingTimeBefore="
        .. tostring(before and before.freezingTime)
        .. " | freezingTimeAfter="
        .. tostring(after and after.freezingTime)
        .. " | freezingTimeDelta=" .. tostring(freezingDelta)
        .. " | measurableResponse=" .. boolText(responseOK)
    )

    local resetOK, resetReason = prepareCommonBaseline({
        state.items.v,
        state.items.a,
        state.items.u,
    })
    state = getState(player)

    local passed = elapsedOK
       and updateOK
       and responseOK
       and resetOK
       and smoke.setterCallsPassed
       and smoke.phaseFlagsPassed
       and smoke.phaseGuardPassed
       and smoke.scheduleCheckPassed
       and smoke.staleVersionGuardPassed

    if not passed then
        activeState = "COMPLETE"
        local playerData = player:getModData()
        playerData.FCTH_fc006SmokePassed = false
        playerData.FCTH_fc006SmokeVersion = HARNESS_VERSION
        emit(
            "END",
            state,
            " | status=FAIL"
            .. " | completionReason=thaw_gate_failed"
            .. " | baselineResetPassed=" .. boolText(resetOK)
            .. " | baselineResetFailure="
            .. tostring(resetReason or "NONE")
        )
        return
    end

    local mismatchOK, mismatchReason = runMismatchCommitProbe(player, state)
    smoke.mismatchProbePassed = mismatchOK
    state = getState(player)

    if not mismatchOK then
        activeState = "COMPLETE"
        local playerData = player:getModData()
        playerData.FCTH_fc006SmokePassed = false
        playerData.FCTH_fc006SmokeVersion = HARNESS_VERSION
        emit(
            "END",
            state,
            " | status=FAIL"
            .. " | completionReason=mismatch_probe_failed"
            .. " | reason=" .. tostring(mismatchReason)
        )
        return
    end

    emit(
        "SMOKE_PROTOCOL_DRY_RUN",
        state,
        " | status=STARTING"
        .. " | expectedMarkers=BEGIN_PRE_HANDOFF_HANDOFF_COMMITTED_UPDATE_1_UPDATE_2_UPDATE_3_END"
        .. " | expectedAdditionalGameMinutes=90"
    )
    beginProtocolRun(player, state)
end

------------------------------------------------------------
-- Separately gated substantive experiment path
------------------------------------------------------------

local function beginExperiment(player, state)
    beginProtocolRun(player, state)
end

local function performHandoff(player, state)
    local handoffStart = getWorldHours()
    local staleElapsed = handoffStart and beginWorldHours
        and handoffStart - beginWorldHours or nil

    if not within(
        staleElapsed,
        STALE_INTERVAL_HOURS,
        TIME_TOLERANCE
    ) then
        finishInvalid(state, "stale_interval_timing_miss")
        return
    end

    emit("PRE_HANDOFF", state, " | status=OBSERVED")
    recordSmokeProtocolMarker("PRE_HANDOFF")

    local timestamps = {}
    local function recordTime()
        local value = getWorldHours()
        table.insert(timestamps, value)
        return value
    end

    recordTime()
    local vUpdateOK, vUpdateReason = runItemCall(state.items.v, "updateAge")
    local vProjectOK, vProjectReason = projectPublicState(state.items.v)
    recordTime()

    local aAlignOK, aAlignReason = runItemCall(state.items.a, "setAutoAge")
    local aProjectOK, aProjectReason = projectPublicState(state.items.a)
    recordTime()

    local uProjectOK, uProjectReason = projectPublicState(state.items.u)
    recordTime()

    local minimum = timestamps[1]
    local maximum = timestamps[1]
    for _, timestamp in ipairs(timestamps) do
        if type(timestamp) ~= "number" then
            state = getState(player)
            finishInvalid(state, "handoff_timestamp_unavailable")
            return
        end
        minimum = math.min(minimum, timestamp)
        maximum = math.max(maximum, timestamp)
    end

    local spread = maximum - minimum
    local callsOK = vUpdateOK and vProjectOK
       and aAlignOK and aProjectOK and uProjectOK

    state = getState(player)
    emit(
        "HANDOFF_APPLIED",
        state,
        " | status=OBSERVED"
        .. " | staleElapsedGameHours=" .. tostring(staleElapsed)
        .. " | vSequence=updateAge_then_public_projection"
        .. " | aSequence=setAutoAge_then_public_projection"
        .. " | uSequence=public_projection_only"
        .. " | timestampSpread=" .. tostring(spread)
        .. " | callsPassed=" .. boolText(callsOK)
        .. " | vUpdateFailure=" .. tostring(vUpdateReason or "NONE")
        .. " | vProjectionFailure="
        .. tostring(vProjectReason or "NONE")
        .. " | aAlignFailure=" .. tostring(aAlignReason or "NONE")
        .. " | aProjectionFailure="
        .. tostring(aProjectReason or "NONE")
        .. " | uProjectionFailure="
        .. tostring(uProjectReason or "NONE")
    )

    if not callsOK then
        finishInvalid(state, "handoff_call_failed")
        return
    end
    if spread > TIME_TOLERANCE then
        finishInvalid(state, "handoff_timestamp_spread")
        return
    end
    handoffWorldHours = maximum
    nextUpdateWorldHours = handoffWorldHours + UPDATE_INTERVAL_HOURS
    completedUpdates = 0

    local committed = attemptHandoffCommit(
        state,
        " | timestampSpread=" .. tostring(spread)
        .. " | requiredFlags=frozen_false_freezing_false_thawing_true"
        .. " | nextUpdateWorldHours="
        .. tostring(nextUpdateWorldHours),
        false
    )

    if not committed then
        return
    end

    activeState = "POST_HANDOFF"
end

local function performScheduledUpdate(player, state)
    local updateStart = getWorldHours()
    local scheduleDelta = updateStart and nextUpdateWorldHours
        and updateStart - nextUpdateWorldHours or nil

    if not within(updateStart, nextUpdateWorldHours, TIME_TOLERANCE) then
        finishInvalid(state, "scheduled_update_timing_miss")
        return
    end

    local calls = {
        { state.items.v, "V" },
        { state.items.a, "A" },
        { state.items.u, "U" },
    }
    local callsOK = true
    local failures = {}

    for _, call in ipairs(calls) do
        local ok, reason = runItemCall(call[1], "updateAge")
        if not ok then
            callsOK = false
            table.insert(failures, call[2] .. ":" .. tostring(reason))
        end
    end

    local updateEnd = getWorldHours()
    completedUpdates = completedUpdates + 1
    state = getState(player)

    emit(
        "UPDATE_" .. tostring(completedUpdates),
        state,
        " | status=OBSERVED"
        .. " | explicitUpdateAgeCalls=V_A_U"
        .. " | scheduledWorldHours=" .. tostring(nextUpdateWorldHours)
        .. " | actualWorldHours=" .. tostring(updateStart)
        .. " | scheduleDelta=" .. tostring(scheduleDelta)
        .. " | callbackSpread="
        .. tostring(updateStart and updateEnd
            and updateEnd - updateStart or "UNAVAILABLE")
        .. " | callsPassed=" .. boolText(callsOK)
        .. " | failures="
        .. (#failures > 0 and table.concat(failures, ",") or "NONE")
    )
    recordSmokeProtocolMarker("UPDATE_" .. tostring(completedUpdates))

    if not callsOK then
        finishInvalid(state, "scheduled_update_call_failed")
        return
    end

    if completedUpdates >= UPDATE_COUNT then
        if activeMode == "SMOKETEST" then
            local expectedBeforeEnd = table.concat({
                "BEGIN",
                "PRE_HANDOFF",
                "HANDOFF_COMMITTED",
                "UPDATE_1",
                "UPDATE_2",
                "UPDATE_3",
            }, ",")
            local observedBeforeEnd = table.concat(
                smoke.protocolMarkers,
                ","
            )
            local markerOrderPassed =
                observedBeforeEnd == expectedBeforeEnd
            local resetOK, resetReason = prepareCommonBaseline({
                state.items.v,
                state.items.a,
                state.items.u,
            })
            state = getState(player)
            recordSmokeProtocolMarker("END")

            local passed = markerOrderPassed
               and resetOK
               and smoke.mismatchProbePassed
            activeState = "COMPLETE"

            local playerData = player:getModData()
            playerData.FCTH_fc006SmokePassed = passed
            playerData.FCTH_fc006SmokeVersion = HARNESS_VERSION

            emit(
                "END",
                state,
                " | status=" .. (passed and "PASS" or "FAIL")
                .. " | completionReason=protocol_dry_run_complete"
                .. " | markerOrderPassed="
                .. boolText(markerOrderPassed)
                .. " | observedMarkers="
                .. table.concat(smoke.protocolMarkers, ",")
                .. " | mismatchProbePassed="
                .. boolText(smoke.mismatchProbePassed)
                .. " | baselineResetPassed=" .. boolText(resetOK)
                .. " | baselineResetFailure="
                .. tostring(resetReason or "NONE")
            )
            return
        end

        activeState = "COMPLETE"
        emit(
            "END",
            state,
            " | status=COMPLETE"
            .. " | completionReason=three_scheduled_updates_complete"
        )
        return
    end

    nextUpdateWorldHours = nextUpdateWorldHours + UPDATE_INTERVAL_HOURS
end

local function handleExperimentMinute(player, state)
    if activeState == "ARMED" then
        if state.treatmentReady then
            stableSampleCount = stableSampleCount + 1
            emit(
                "ARMED_SAMPLE",
                state,
                " | status=WAITING_FOR_BEGIN"
                .. " | stableSamples=" .. tostring(stableSampleCount)
            )
            if stableSampleCount >= REQUIRED_STABLE_SAMPLES then
                beginExperiment(player, state)
            end
        else
            stableSampleCount = 0
            emit(
                "ARMED_SAMPLE",
                state,
                " | status=WAITING_FOR_READY"
                .. " | reason=" .. readinessReason(state)
            )
        end
        return
    end

    if activeState ~= "STALE_INTERVAL"
    and activeState ~= "POST_HANDOFF" then
        return
    end

    local violation = runViolation(state)
    if violation then
        finishInvalid(state, violation)
        return
    end

    local now = getWorldHours()
    if activeState == "STALE_INTERVAL" then
        local elapsed = now and beginWorldHours
            and now - beginWorldHours or nil
        emit(
            "STALE_SAMPLE",
            state,
            " | status=GETTER_ONLY"
            .. " | elapsedGameHours=" .. tostring(elapsed)
            .. " | harnessStateUpdates=0"
        )
        if elapsed and elapsed >= STALE_INTERVAL_HOURS then
            performHandoff(player, state)
        end
        return
    end

    emit(
        "POST_HANDOFF_SAMPLE",
        state,
        " | status=WAITING_FOR_EXPLICIT_UPDATE"
        .. " | completedUpdates=" .. tostring(completedUpdates)
        .. " | nextUpdateWorldHours=" .. tostring(nextUpdateWorldHours)
    )

    if now and nextUpdateWorldHours and now >= nextUpdateWorldHours then
        performScheduledUpdate(player, state)
    end
end

------------------------------------------------------------
-- Operator controls
------------------------------------------------------------

local function armExperiment(player)
    if activeMode and activeState ~= "COMPLETE" then
        logLine(
            "mode=" .. tostring(activeMode)
            .. " | phase=CONTROL | status=REJECTED"
            .. " | reason=run_already_active"
        )
        return
    end

    local state = getState(player)
    if not state.treatmentReady then
        emit(
            "CONTROL",
            state,
            " | status=REJECTED | reason=" .. readinessReason(state)
        )
        return
    end

    activeMode = "EXPERIMENT"
    activeState = "ARMED"
    stableSampleCount = 0
    beginWorldHours = nil
    handoffWorldHours = nil
    nextUpdateWorldHours = nil
    completedUpdates = 0
    lastObservedSignature = nil

    emit(
        "CONTROL",
        state,
        " | status=ARMED"
        .. " | operatorAuthorizationRequired=true"
        .. " | substantiveRunAuthorizedByHarness=false"
    )
end

local function endActiveRun(player)
    if not activeMode or activeState == "COMPLETE" then
        logLine(
            "mode=" .. tostring(activeMode or "MONITOR")
            .. " | phase=END | status=REJECTED"
            .. " | reason=no_active_run"
        )
        return
    end

    local state = getState(player)
    if activeMode == "EXPERIMENT" then
        finishInvalid(state, "operator_cancelled")
    else
        activeState = "COMPLETE"
        emit("END", state, " | status=CANCELLED")
    end
end

local function belongsToFC006(item)
    if not item then
        return false
    end

    if hasRole(item, GUARD_ROLE)
    or hasRole(item, TEST_ROLE)
    or hasRole(item, V_ROLE)
    or hasRole(item, A_ROLE)
    or hasRole(item, U_ROLE) then
        return true
    end

    local container = safeValue(function()
        return item:getContainer()
    end, nil)
    local containingItem = container and safeValue(function()
        return container:getContainingItem()
    end, nil) or nil

    return hasRole(containingItem, GUARD_ROLE)
        or hasRole(containingItem, TEST_ROLE)
end

local function contextIncludesFC006(items)
    for _, entry in ipairs(items or {}) do
        if instanceof(entry, "InventoryItem") then
            if belongsToFC006(entry) then
                return true
            end
        elseif type(entry) == "table" and entry.items then
            for _, item in ipairs(entry.items) do
                if belongsToFC006(item) then
                    return true
                end
            end
        end
    end
    return false
end

function FCTH.onFillInventoryObjectContextMenu(playerNumber, context, items)
    if not contextIncludesFC006(items) then
        return
    end

    local player = getSpecificPlayer(playerNumber)
    if not player then
        return
    end

    if activeMode and activeState ~= "COMPLETE" then
        context:addOption(
            "FC-006: End/cancel active harness run",
            player,
            endActiveRun
        )
        return
    end

    context:addOption(
        "FC-006: Start infrastructure smoketest",
        player,
        startSmoke
    )
    context:addOption(
        "FC-006: Arm experiment (Bart authorization required)",
        player,
        armExperiment
    )
end

------------------------------------------------------------
-- UI transition observer and main tick
------------------------------------------------------------

function FCTH.observeUI()
    if not activeMode
    or activeState == "IDLE"
    or activeState == "COMPLETE" then
        return
    end

    local player = getSpecificPlayer(0)
    if not player then
        return
    end

    local state = getState(player)
    local signature = state.ui.selectedID
        .. "|" .. boolText(state.ui.visible)
        .. "|" .. boolText(state.ui.collapsed)
        .. "|" .. boolText(state.ui.pinned)
        .. "|" .. getItemID(state.primary)
        .. "|" .. getItemID(state.secondary)

    if signature ~= lastObservedSignature then
        lastObservedSignature = signature
        emit("STATE_TRANSITION", state, " | status=OBSERVED")
    end

    local violation = runViolation(state)
    if violation then
        finishInvalid(state, violation)
        return
    end

    local now = getWorldHours()
    if activeMode == "SMOKETEST"
    and activeState == "RUNNING"
    and smoke.startWorldHours
    and now
    and now - smoke.startWorldHours >= UPDATE_INTERVAL_HOURS then
        handleSmokeMinute(player, state, false)
    elseif (activeMode == "EXPERIMENT" or activeMode == "SMOKETEST")
    and activeState == "STALE_INTERVAL"
    and beginWorldHours
    and now
    and now - beginWorldHours >= STALE_INTERVAL_HOURS then
        performHandoff(player, state)
    elseif (activeMode == "EXPERIMENT" or activeMode == "SMOKETEST")
    and activeState == "POST_HANDOFF"
    and nextUpdateWorldHours
    and now
    and now >= nextUpdateWorldHours then
        performScheduledUpdate(player, state)
    end
end

function FCTH.tick()
    local player = getSpecificPlayer(0)
    if not player then
        return
    end

    local playerData = player:getModData()
    if playerData.FCTH_setupError == true then
        return
    end

    if not setupVersionCompatible(playerData.FCTH_setupVersion) then
        playerData.FCTH_setupError = true
        logLine(
            "status=ERROR"
            .. " | reason=stale_harness_save"
            .. " | foundSetupVersion="
            .. tostring(playerData.FCTH_setupVersion)
            .. " | requiredSetupVersion=" .. tostring(SETUP_VERSION)
            .. " | action=create_fresh_save"
        )
        return
    end

    if playerData.FCTH_spawnVerified ~= SETUP_VERSION then
        if not verifyFixedSpawn(player) then
            playerData.FCTH_setupError = true
            logLine(
                "status=ERROR | reason=fixed_spawn_not_applied"
                .. " | action=create_fresh_save"
            )
            return
        end
        playerData.FCTH_spawnVerified = SETUP_VERSION
        logLine(
            "status=SPAWN_VERIFIED"
            .. " | x=" .. tostring(TEST_SPAWN_X)
            .. " | y=" .. tostring(TEST_SPAWN_Y)
            .. " | z=" .. tostring(TEST_SPAWN_Z)
            .. " | build=" .. getBuildVersion()
        )
    end

    if playerData.FCTH_fc006Created ~= true then
        createSetup(player)
        return
    end

    local state = getState(player)
    logReadiness(state)

    if activeMode == "SMOKETEST"
    and activeState == "RUNNING" then
        handleSmokeMinute(player, state, true)
    elseif activeMode == "SMOKETEST" then
        handleExperimentMinute(player, state)
    elseif activeMode == "EXPERIMENT" then
        handleExperimentMinute(player, state)
    end
end

Events.EveryOneMinute.Add(FCTH.tick)
Events.OnTick.Add(FCTH.observeUI)
Events.OnFillInventoryObjectContextMenu.Add(
    FCTH.onFillInventoryObjectContextMenu
)

logLine(
    "status=LOADED"
    .. " | expectedBuild=" .. EXPECTED_BUILD
    .. " | controls=FC006_INVENTORY_CONTEXT_MENU"
    .. " | requiredPrimary=" .. GUARD_NAME
    .. " | requiredSecondary=" .. TEST_NAME
    .. " | requiredSelected=" .. GUARD_NAME
    .. " | substantiveRunAuthorized=false"
)
