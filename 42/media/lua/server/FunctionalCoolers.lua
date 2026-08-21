local FC = {}

------------------------------------------------------------
-- FUNCTIONAL COOLERS
-- Prototype v0.3.0-dev
--
-- Testopstelling:
--
-- CONTROL:
--   1 verse steak
--   1 frozen steak
--   direct in player inventory
--
-- FRIDGE:
--   1 verse steak
--   1 frozen steak
--   powered vanilla refrigerator
--
-- P0:
--   1 verse steak
--   1 frozen steak
--   0 coldpacks
--
-- P1:
--   1 verse steak
--   1 frozen steak
--   1 coldpack
--
-- P2:
--   1 verse steak
--   1 frozen steak
--   2 coldpacks
--
-- P4:
--   1 verse steak
--   1 frozen steak
--   4 coldpacks
--
-- P1G:
--   1 verse steak
--   1 frozen steak
--   1 coldpack
--   Cooler op de grond
------------------------------------------------------------


------------------------------------------------------------
-- CONFIG
------------------------------------------------------------

local AMBIENT_TEMP = 1.0
local FREEZER_TEMP = 0.2

local COOLER_CAPACITY = 4.0
local FOOD_CAPACITY = 1.0
local COLDPACK_CAPACITY = 6.0

local COOLER_LEAK_RATE = 0.0015
local FOOD_EXCHANGE_RATE = 0.18
local COLDPACK_EXCHANGE_RATE = 0.12

local FREEZER_RECHARGE_RATE = 0.25

local FREEZER_SCAN_RADIUS = 8
local FRIDGE_SCAN_RADIUS = 8
local GROUND_SCAN_RADIUS = 10

local LOG_INTERVAL = 10

-- Lightweight vanilla/context diagnostics run every game minute so
-- short container-selection/opening events are less likely to be missed.
local DIAGNOSTIC_LOG_INTERVAL = 1

-- Time-based simulation.
-- The current calibration world uses FoodRotSpeed = 3 (Normal).
-- At that setting vanilla food age advances 1.0 age-day per game day.
local BASE_AGE_DAYS_PER_GAME_DAY = 1.0

-- Measured from the previous vanilla control:
-- freezingTime falls by ~1.11111 points per game minute at ambient temperature.
local BASE_THAW_RATE_PER_MINUTE = 1.111111

-- Active simulation normally advances in 1-minute steps.
-- Long catch-up periods use 5-minute steps to keep the cost bounded.
local ACTIVE_STEP_MINUTES = 1.0
local CATCHUP_STEP_MINUTES = 5.0
local CATCHUP_THRESHOLD_MINUTES = 60.0

local TEST_ACTIVE = false
local TEST_FRIDGE = nil
local tickCounter = 0


------------------------------------------------------------
-- Testgroepen
------------------------------------------------------------

local GROUPS = {

    P0 = {
        location = "CARRIED",
        packs = 0
    },

    P1 = {
        location = "CARRIED",
        packs = 1
    },

    P2 = {
        location = "CARRIED",
        packs = 2
    },

    P4 = {
        location = "CARRIED",
        packs = 4
    },

    P1G = {
        location = "GROUND",
        packs = 1
    }
}


local GROUP_ORDER = {
    "P0",
    "P1",
    "P2",
    "P4",
    "P1G"
}


------------------------------------------------------------
-- Helpers
------------------------------------------------------------

local function clamp(value, minimum, maximum)

    if value < minimum then
        return minimum
    end

    if value > maximum then
        return maximum
    end

    return value
end


local function safeValue(func, fallback)

    local ok, value = pcall(func)

    if ok then
        return value
    end

    return fallback
end


local function safeNumber(func, fallback)

    local value =
        safeValue(func, fallback)

    if type(value) == "number" then
        return value
    end

    return fallback
end


local function getItemName(item)

    return tostring(
        safeValue(
            function()
                return item:getName()
            end,
            "UNKNOWN"
        )
    )
end


local function getFullType(item)

    return tostring(
        safeValue(
            function()
                return item:getFullType()
            end,
            "UNKNOWN"
        )
    )
end


local function getCoolerContainer(cooler)

    local ok, container =
        pcall(function()
            return cooler:getInventory()
        end)

    if ok and container then
        return container
    end

    return nil
end


local function getWorldAgeHours()

    return safeNumber(
        function()
            return getGameTime():getWorldAgeHours()
        end,
        nil
    )
end


local function getContainerType(container)

    if not container then
        return "NONE"
    end

    return tostring(
        safeValue(
            function()
                return container:getType()
            end,
            "UNAVAILABLE"
        )
    )
end


local function getContainerActive(container)

    if not container then
        return "NONE"
    end

    return safeValue(
        function()
            return container:isActive()
        end,
        "UNAVAILABLE"
    )
end


local function getItemContext(item)

    local outer =
        safeValue(
            function()
                return item:getOutermostContainer()
            end,
            nil
        )

    return {
        inPlayerInventory =
            safeValue(
                function()
                    return item:isInPlayerInventory()
                end,
                "UNAVAILABLE"
            ),

        outerType =
            getContainerType(outer),

        outerActive =
            getContainerActive(outer)
    }
end


local function getOptionalItemID(item)

    if not item then
        return "NONE"
    end

    return tostring(
        safeValue(
            function()
                return item:getID()
            end,
            "UNAVAILABLE"
        )
    )
end


local function scaledRate(ratePerMinute, minutes)

    if minutes <= 0 then
        return 0
    end

    if ratePerMinute <= 0 then
        return 0
    end

    if ratePerMinute >= 1 then
        return 1
    end

    return 1.0 - math.pow(1.0 - ratePerMinute, minutes)
end


local function chooseStepMinutes(remainingMinutes)

    if remainingMinutes > CATCHUP_THRESHOLD_MINUTES then
        return math.min(CATCHUP_STEP_MINUTES, remainingMinutes)
    end

    return math.min(ACTIVE_STEP_MINUTES, remainingMinutes)
end


------------------------------------------------------------
-- Spoilage factor
------------------------------------------------------------

local function getSpoilageFactor(temp)

    if temp <= FREEZER_TEMP then
        return 0.02
    end

    if temp >= AMBIENT_TEMP then
        return 1.0
    end

    local fraction =
        (temp - FREEZER_TEMP)
        / (AMBIENT_TEMP - FREEZER_TEMP)

    return
        0.02
        + (0.98 * fraction)
end


------------------------------------------------------------
-- Thaw factor
------------------------------------------------------------

local function getThawFactor(temp)

    if temp <= FREEZER_TEMP then
        return 0.0
    end

    if temp >= AMBIENT_TEMP then
        return 1.0
    end

    return
        (temp - FREEZER_TEMP)
        / (AMBIENT_TEMP - FREEZER_TEMP)
end


------------------------------------------------------------
-- Coldpack temperature
------------------------------------------------------------

local function getColdpackTemperature(pack)

    local data =
        pack:getModData()

    if data.FC_temperature == nil then

        data.FC_temperature =
            AMBIENT_TEMP
    end

    return data.FC_temperature
end


local function setColdpackTemperature(pack, temp)

    local data =
        pack:getModData()

    data.FC_temperature =
        clamp(temp, 0.0, 2.0)
end


------------------------------------------------------------
-- Cooler temperature
------------------------------------------------------------

local function getCoolerTemperature(cooler)

    local data =
        cooler:getModData()

    if data.FC_temperature == nil then

        data.FC_temperature =
            AMBIENT_TEMP
    end

    return data.FC_temperature
end


local function setCoolerTemperature(cooler, temp)

    local data =
        cooler:getModData()

    data.FC_temperature =
        clamp(temp, 0.0, 2.0)
end


------------------------------------------------------------
-- Food thermal state
------------------------------------------------------------

local function initializeFoodState(food, cooler)

    local data =
        food:getModData()

    local coolerID =
        tostring(cooler:getID())


    local needsInitialization =
        data.FC_coolerID ~= coolerID
        or data.FC_temperature == nil
        or data.FC_managedAge == nil
        or data.FC_managedFreezingTime == nil


    if needsInitialization then

        data.FC_coolerID =
            coolerID

        data.FC_temperature =
            safeNumber(
                function()
                    return food:getHeat()
                end,
                AMBIENT_TEMP
            )

        data.FC_managedAge =
            safeNumber(
                function()
                    return food:getAge()
                end,
                0.0
            )

        data.FC_managedFreezingTime =
            safeNumber(
                function()
                    return food:getFreezingTime()
                end,
                0.0
            )
    end


    return data
end


local function applyManagedFoodState(food)

    local data =
        food:getModData()


    if data.FC_temperature ~= nil then

        pcall(function()

            food:setHeat(
                clamp(
                    data.FC_temperature,
                    0.0,
                    2.0
                )
            )

        end)
    end


    if data.FC_managedAge ~= nil then

        pcall(function()

            food:setAge(
                math.max(
                    0.0,
                    data.FC_managedAge
                )
            )

        end)
    end


    if data.FC_managedFreezingTime ~= nil then

        pcall(function()

            food:setFreezingTime(
                clamp(
                    data.FC_managedFreezingTime,
                    0.0,
                    100.0
                )
            )

        end)
    end
end


------------------------------------------------------------
-- Time-based food biology
------------------------------------------------------------

local function advanceManagedFoodBiology(
    food,
    foodTemp,
    stepMinutes
)

    local data =
        food:getModData()


    local age =
        safeNumber(
            function()
                return data.FC_managedAge
            end,
            0.0
        )


    local freezingTime =
        safeNumber(
            function()
                return data.FC_managedFreezingTime
            end,
            0.0
        )


    local spoilFactor =
        getSpoilageFactor(foodTemp)


    --------------------------------------------------------
    -- Frozen/thawing food
    --
    -- Our previous control showed that age stays effectively
    -- stationary while freezingTime is still above zero.
    -- For this calibration prototype we preserve that observed
    -- behaviour. Frozen-age behaviour can be refined later.
    --------------------------------------------------------

    if freezingTime > 0.0 then

        local thawFactor =
            getThawFactor(foodTemp)

        local thawRate =
            BASE_THAW_RATE_PER_MINUTE
            * thawFactor


        if thawRate > 0.0 then

            local possibleThaw =
                thawRate
                * stepMinutes


            if possibleThaw >= freezingTime then

                local minutesToFinishThaw =
                    freezingTime
                    / thawRate


                freezingTime =
                    0.0


                local remainingMinutes =
                    stepMinutes
                    - minutesToFinishThaw


                if remainingMinutes > 0.0 then

                    age =
                        age
                        + (
                            remainingMinutes
                            / 1440.0
                            * BASE_AGE_DAYS_PER_GAME_DAY
                            * spoilFactor
                        )
                end

            else

                freezingTime =
                    freezingTime
                    - possibleThaw
            end
        end

    else

        ----------------------------------------------------
        -- Fully thawed food
        ----------------------------------------------------

        age =
            age
            + (
                stepMinutes
                / 1440.0
                * BASE_AGE_DAYS_PER_GAME_DAY
                * spoilFactor
            )
    end


    data.FC_managedAge =
        math.max(
            0.0,
            age
        )


    data.FC_managedFreezingTime =
        clamp(
            freezingTime,
            0.0,
            100.0
        )
end


------------------------------------------------------------
-- Count test contents
------------------------------------------------------------

local function inspectContents(cooler)

    local result = {

        steaks = 0,
        frozenSteaks = 0,
        freshSteaks = 0,
        packs = 0
    }


    local container =
        getCoolerContainer(cooler)


    if not container then
        return result
    end


    local items =
        container:getItems()


    for i = 0, items:size() - 1 do

        local item =
            items:get(i)

        local fullType =
            getFullType(item)


        if fullType == "Base.Coldpack" then

            result.packs =
                result.packs + 1


        elseif fullType == "Base.Steak" then

            result.steaks =
                result.steaks + 1


            local freezingTime =
                safeNumber(
                    function()
                        return item:getFreezingTime()
                    end,
                    0
                )


            if freezingTime > 50 then

                result.frozenSteaks =
                    result.frozenSteaks + 1

            else

                result.freshSteaks =
                    result.freshSteaks + 1
            end
        end
    end


    return result
end


local function inspectSteakContainer(container)

    local result = {
        steaks = 0,
        frozenSteaks = 0,
        freshSteaks = 0
    }

    if not container then
        return result
    end

    local items =
        container:getItems()

    for i = 0, items:size() - 1 do

        local item =
            items:get(i)

        if getFullType(item) == "Base.Steak" then

            result.steaks =
                result.steaks + 1

            local freeze =
                safeNumber(
                    function()
                        return item:getFreezingTime()
                    end,
                    0
                )

            if freeze > 50 then
                result.frozenSteaks =
                    result.frozenSteaks + 1
            else
                result.freshSteaks =
                    result.freshSteaks + 1
            end
        end
    end

    return result
end


------------------------------------------------------------
-- Find named carried coolers
------------------------------------------------------------

local function findCarriedGroups(player)

    local found = {}

    local coolers =
        player:getInventory():getItemsFromType(
            "Cooler",
            true
        )


    if not coolers then
        return found
    end


    for i = 0, coolers:size() - 1 do

        local cooler =
            coolers:get(i)

        local name =
            getItemName(cooler)

        local config =
            GROUPS[name]


        if config
        and config.location == "CARRIED" then

            found[name] =
                cooler
        end
    end


    return found
end


------------------------------------------------------------
-- Find named ground coolers
------------------------------------------------------------

local function findGroundGroups(player)

    local found = {}

    local playerSquare =
        player:getSquare()


    if not playerSquare then
        return found
    end


    local cell =
        getCell()

    local px =
        playerSquare:getX()

    local py =
        playerSquare:getY()

    local pz =
        playerSquare:getZ()


    for x = px - GROUND_SCAN_RADIUS,
            px + GROUND_SCAN_RADIUS do

        for y = py - GROUND_SCAN_RADIUS,
                py + GROUND_SCAN_RADIUS do


            local square =
                cell:getGridSquare(
                    x,
                    y,
                    pz
                )


            if square then

                local worldObjects =
                    safeValue(
                        function()
                            return square:getWorldObjects()
                        end,
                        nil
                    )


                if worldObjects then

                    for i = 0,
                        worldObjects:size() - 1 do


                        local worldObject =
                            worldObjects:get(i)


                        local item =
                            safeValue(
                                function()
                                    return worldObject:getItem()
                                end,
                                nil
                            )


                        if item
                        and getFullType(item)
                            == "Base.Cooler" then


                            local name =
                                getItemName(item)

                            local config =
                                GROUPS[name]


                            if config
                            and config.location
                                == "GROUND" then

                                found[name] =
                                    item
                            end
                        end
                    end
                end
            end
        end
    end


    return found
end


------------------------------------------------------------
-- Find all expected groups
------------------------------------------------------------

local function findGroups(player)

    local result = {}

    local carried =
        findCarriedGroups(player)

    local ground =
        findGroundGroups(player)


    for _, name in ipairs(GROUP_ORDER) do

        if carried[name] then

            result[name] =
                carried[name]

        elseif ground[name] then

            result[name] =
                ground[name]
        end
    end


    return result
end


------------------------------------------------------------
-- Find nearest powered refrigerator
------------------------------------------------------------

local function findNearbyPoweredFridge(player)

    local playerSquare =
        player:getSquare()

    if not playerSquare then
        return nil
    end

    local cell =
        getCell()

    local px =
        playerSquare:getX()

    local py =
        playerSquare:getY()

    local pz =
        playerSquare:getZ()

    local best = nil
    local bestDistanceSquared = nil

    for x = px - FRIDGE_SCAN_RADIUS,
            px + FRIDGE_SCAN_RADIUS do

        for y = py - FRIDGE_SCAN_RADIUS,
                py + FRIDGE_SCAN_RADIUS do

            local square =
                cell:getGridSquare(
                    x,
                    y,
                    pz
                )

            if square then

                local objects =
                    square:getObjects()

                for objectIndex = 0,
                    objects:size() - 1 do

                    local object =
                        objects:get(objectIndex)

                    local count =
                        object:getContainerCount()

                    for containerIndex = 0,
                        count - 1 do

                        local container =
                            object:getContainerByIndex(
                                containerIndex
                            )

                        if container
                        and getContainerType(container) == "fridge" then

                            local powered =
                                safeValue(
                                    function()
                                        return container:isPowered()
                                    end,
                                    false
                                )

                            if powered then

                                local dx = x - px
                                local dy = y - py
                                local distanceSquared =
                                    dx * dx + dy * dy

                                if bestDistanceSquared == nil
                                or distanceSquared < bestDistanceSquared then

                                    bestDistanceSquared =
                                        distanceSquared

                                    best = {
                                        container = container,
                                        x = x,
                                        y = y,
                                        z = pz
                                    }
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
-- Direct player inventory controls
------------------------------------------------------------

local function inspectControls(player)

    local result = {

        steaks = 0,
        frozenSteaks = 0,
        freshSteaks = 0
    }


    local items =
        player:getInventory():getItems()


    for i = 0, items:size() - 1 do

        local item =
            items:get(i)


        if getFullType(item)
            == "Base.Steak" then


            result.steaks =
                result.steaks + 1


            local freeze =
                safeNumber(
                    function()
                        return item:getFreezingTime()
                    end,
                    0
                )


            if freeze > 50 then

                result.frozenSteaks =
                    result.frozenSteaks + 1

            else

                result.freshSteaks =
                    result.freshSteaks + 1
            end
        end
    end


    return result
end


------------------------------------------------------------
-- Is complete test setup ready?
------------------------------------------------------------

local function checkReadiness(player, groups, printStatus)

    local ready = true


    for _, name in ipairs(GROUP_ORDER) do

        local cooler =
            groups[name]

        local config =
            GROUPS[name]


        if not cooler then

            ready = false

            if printStatus then

                print(
                    "[FC-READY]"
                    .. " group=" .. name
                    .. " | status=MISSING"
                    .. " | expectedLocation="
                    .. config.location
                )
            end

        else

            local contents =
                inspectContents(cooler)


            local groupReady =
                contents.steaks == 2
                and contents.freshSteaks == 1
                and contents.frozenSteaks == 1
                and contents.packs
                    == config.packs


            if not groupReady then
                ready = false
            end


            if printStatus then

                print(
                    "[FC-READY]"
                    .. " group=" .. name
                    .. " | status="
                    .. (
                        groupReady
                        and "READY"
                        or "WAITING"
                    )
                    .. " | location="
                    .. config.location
                    .. " | steaks="
                    .. tostring(contents.steaks)
                    .. " | fresh="
                    .. tostring(contents.freshSteaks)
                    .. " | frozen="
                    .. tostring(contents.frozenSteaks)
                    .. " | packs="
                    .. tostring(contents.packs)
                    .. " | expectedPacks="
                    .. tostring(config.packs)
                )
            end
        end
    end


    --------------------------------------------------------
    -- Controls
    --------------------------------------------------------

    local controls =
        inspectControls(player)


    local controlReady =
        controls.steaks == 2
        and controls.freshSteaks == 1
        and controls.frozenSteaks == 1


    if not controlReady then
        ready = false
    end


    if printStatus then

        print(
            "[FC-READY]"
            .. " group=CONTROL"
            .. " | status="
            .. (
                controlReady
                and "READY"
                or "WAITING"
            )
            .. " | steaks="
            .. tostring(controls.steaks)
            .. " | fresh="
            .. tostring(controls.freshSteaks)
            .. " | frozen="
            .. tostring(controls.frozenSteaks)
        )
    end


    --------------------------------------------------------
    -- Powered refrigerator control
    --------------------------------------------------------

    local fridge =
        findNearbyPoweredFridge(player)

    local fridgeReady = false

    if fridge then

        local contents =
            inspectSteakContainer(
                fridge.container
            )

        fridgeReady =
            contents.steaks == 2
            and contents.freshSteaks == 1
            and contents.frozenSteaks == 1

        if printStatus then

            print(
                "[FC-READY]"
                .. " group=FRIDGE"
                .. " | status="
                .. (
                    fridgeReady
                    and "READY"
                    or "WAITING"
                )
                .. " | location="
                .. tostring(fridge.x)
                .. ","
                .. tostring(fridge.y)
                .. ","
                .. tostring(fridge.z)
                .. " | steaks="
                .. tostring(contents.steaks)
                .. " | fresh="
                .. tostring(contents.freshSteaks)
                .. " | frozen="
                .. tostring(contents.frozenSteaks)
            )
        end

    elseif printStatus then

        print(
            "[FC-READY]"
            .. " group=FRIDGE"
            .. " | status=MISSING"
            .. " | expected=powered fridge within "
            .. tostring(FRIDGE_SCAN_RADIUS)
            .. " tiles"
        )
    end

    if not fridgeReady then
        ready = false
    end


    return ready, fridge
end


------------------------------------------------------------
-- Reset thermal state at actual start
------------------------------------------------------------

local function prepareTestStart(groups)

    local nowHours =
        getWorldAgeHours()


    for _, name in ipairs(GROUP_ORDER) do

        local cooler =
            groups[name]


        if cooler then

            local data =
                cooler:getModData()


            data.FC_temperature =
                AMBIENT_TEMP


            data.FC_testGroup =
                name


            data.FC_lastThermalUpdateHours =
                nowHours


            local container =
                getCoolerContainer(cooler)


            if container then

                pcall(function()

                    container:setCustomTemperature(
                        AMBIENT_TEMP
                    )

                end)


                local items =
                    container:getItems()


                for i = 0,
                    items:size() - 1 do


                    local item =
                        items:get(i)


                    if instanceof(item, "Food") then

                        local foodData =
                            item:getModData()


                        foodData.FC_coolerID =
                            nil

                        foodData.FC_temperature =
                            nil

                        foodData.FC_managedAge =
                            nil

                        foodData.FC_managedFreezingTime =
                            nil


                        initializeFoodState(
                            item,
                            cooler
                        )


                        applyManagedFoodState(
                            item
                        )
                    end
                end
            end
        end
    end
end


------------------------------------------------------------
-- Log one food item
------------------------------------------------------------

local function logFood(
    item,
    group,
    location,
    coolerTemp,
    foodTemp,
    phase
)

    local data =
        item:getModData()


    print(
        "[FC-FOOD]"
        .. " phase=" .. phase
        .. " | group=" .. group
        .. " | location=" .. location
        .. " | coolerTemp="
        .. tostring(coolerTemp)
        .. " | item="
        .. getFullType(item)
        .. " | id="
        .. tostring(item:getID())
        .. " | foodTemp="
        .. tostring(foodTemp)
        .. " | age="
        .. tostring(
            safeNumber(
                function()
                    return item:getAge()
                end,
                -1
            )
        )
        .. " | managedAge="
        .. tostring(
            safeNumber(
                function()
                    return data.FC_managedAge
                end,
                -1
            )
        )
        .. " | freeze="
        .. tostring(
            safeNumber(
                function()
                    return item:getFreezingTime()
                end,
                -1
            )
        )
        .. " | managedFreeze="
        .. tostring(
            safeNumber(
                function()
                    return data.FC_managedFreezingTime
                end,
                -1
            )
        )
        .. " | lastAged="
        .. tostring(
            safeNumber(
                function()
                    return item:getLastAged()
                end,
                -1
            )
        )
        .. " | frozen="
        .. tostring(
            safeValue(
                function()
                    return item:isFrozen()
                end,
                "UNAVAILABLE"
            )
        )
        .. " | thawing="
        .. tostring(
            safeValue(
                function()
                    return item:isThawing()
                end,
                "UNAVAILABLE"
            )
        )
    )
end


------------------------------------------------------------
-- Log direct player controls
------------------------------------------------------------

local function logControls(player, phase)

    local items =
        player:getInventory():getItems()


    local nowHours =
        getWorldAgeHours()


    for i = 0, items:size() - 1 do

        local item =
            items:get(i)


        if getFullType(item)
            == "Base.Steak" then


            print(
                "[FC-CONTROL]"
                .. " phase=" .. phase
                .. " | worldHours="
                .. tostring(nowHours)
                .. " | id="
                .. tostring(item:getID())
                .. " | age="
                .. tostring(
                    safeNumber(
                        function()
                            return item:getAge()
                        end,
                        -1
                    )
                )
                .. " | heat="
                .. tostring(
                    safeNumber(
                        function()
                            return item:getHeat()
                        end,
                        -1
                    )
                )
                .. " | freeze="
                .. tostring(
                    safeNumber(
                        function()
                            return item:getFreezingTime()
                        end,
                        -1
                    )
                )
                .. " | lastAged="
                .. tostring(
                    safeNumber(
                        function()
                            return item:getLastAged()
                        end,
                        -1
                    )
                )
                .. " | frozen="
                .. tostring(
                    safeValue(
                        function()
                            return item:isFrozen()
                        end,
                        "UNAVAILABLE"
                    )
                )
                .. " | thawing="
                .. tostring(
                    safeValue(
                        function()
                            return item:isThawing()
                        end,
                        "UNAVAILABLE"
                    )
                )
            )
        end
    end
end


------------------------------------------------------------
-- Vanilla/context diagnostics
------------------------------------------------------------

local function logVanillaFoodContext(
    item,
    group,
    location,
    phase
)

    local nowHours =
        getWorldAgeHours()

    local lastAged =
        safeNumber(
            function()
                return item:getLastAged()
            end,
            nil
        )

    local lastAgedLagHours =
        "UNAVAILABLE"

    if nowHours ~= nil
    and lastAged ~= nil then

        lastAgedLagHours =
            nowHours - lastAged
    end

    local context =
        getItemContext(item)

    print(
        "[FC-VANILLA]"
        .. " phase=" .. phase
        .. " | group=" .. group
        .. " | location=" .. location
        .. " | worldHours="
        .. tostring(nowHours)
        .. " | id="
        .. tostring(item:getID())
        .. " | age="
        .. tostring(
            safeNumber(
                function()
                    return item:getAge()
                end,
                -1
            )
        )
        .. " | heat="
        .. tostring(
            safeNumber(
                function()
                    return item:getHeat()
                end,
                -1
            )
        )
        .. " | freeze="
        .. tostring(
            safeNumber(
                function()
                    return item:getFreezingTime()
                end,
                -1
            )
        )
        .. " | lastAged="
        .. tostring(lastAged)
        .. " | lastAgedLagHours="
        .. tostring(lastAgedLagHours)
        .. " | inPlayerInventory="
        .. tostring(context.inPlayerInventory)
        .. " | outerType="
        .. tostring(context.outerType)
        .. " | outerActive="
        .. tostring(context.outerActive)
        .. " | frozen="
        .. tostring(
            safeValue(
                function()
                    return item:isFrozen()
                end,
                "UNAVAILABLE"
            )
        )
        .. " | thawing="
        .. tostring(
            safeValue(
                function()
                    return item:isThawing()
                end,
                "UNAVAILABLE"
            )
        )
    )
end


local function logPlayerContext(player, phase)

    local inventory =
        player:getInventory()

    local primary =
        safeValue(
            function()
                return player:getPrimaryHandItem()
            end,
            nil
        )

    local secondary =
        safeValue(
            function()
                return player:getSecondaryHandItem()
            end,
            nil
        )

    print(
        "[FC-PLAYER-CONTEXT]"
        .. " phase=" .. phase
        .. " | worldHours="
        .. tostring(getWorldAgeHours())
        .. " | inventoryActive="
        .. tostring(
            getContainerActive(inventory)
        )
        .. " | primaryID="
        .. getOptionalItemID(primary)
        .. " | primaryType="
        .. (
            primary
            and getFullType(primary)
            or "NONE"
        )
        .. " | secondaryID="
        .. getOptionalItemID(secondary)
        .. " | secondaryType="
        .. (
            secondary
            and getFullType(secondary)
            or "NONE"
        )
    )
end


local function logCoolerContext(
    player,
    cooler,
    group,
    location,
    phase
)

    local container =
        getCoolerContainer(cooler)

    local context =
        getItemContext(cooler)

    local primary =
        safeValue(
            function()
                return player:getPrimaryHandItem()
            end,
            nil
        )

    local secondary =
        safeValue(
            function()
                return player:getSecondaryHandItem()
            end,
            nil
        )

    print(
        "[FC-CONTEXT]"
        .. " phase=" .. phase
        .. " | group=" .. group
        .. " | location=" .. location
        .. " | worldHours="
        .. tostring(getWorldAgeHours())
        .. " | id="
        .. tostring(cooler:getID())
        .. " | inPlayerInventory="
        .. tostring(context.inPlayerInventory)
        .. " | outerType="
        .. tostring(context.outerType)
        .. " | outerActive="
        .. tostring(context.outerActive)
        .. " | containerActive="
        .. tostring(
            getContainerActive(container)
        )
        .. " | primaryHand="
        .. tostring(primary == cooler)
        .. " | secondaryHand="
        .. tostring(secondary == cooler)
    )
end


local function logFridgeSnapshot(fridge, phase)

    if not fridge
    or not fridge.container then

        print(
            "[FC-FRIDGE]"
            .. " phase=" .. phase
            .. " | status=MISSING"
        )

        return
    end

    local container =
        fridge.container

    local contents =
        inspectSteakContainer(container)

    print(
        "[FC-FRIDGE]"
        .. " phase=" .. phase
        .. " | worldHours="
        .. tostring(getWorldAgeHours())
        .. " | location="
        .. tostring(fridge.x)
        .. ","
        .. tostring(fridge.y)
        .. ","
        .. tostring(fridge.z)
        .. " | powered="
        .. tostring(
            safeValue(
                function()
                    return container:isPowered()
                end,
                "UNAVAILABLE"
            )
        )
        .. " | containerActive="
        .. tostring(
            getContainerActive(container)
        )
        .. " | temperature="
        .. tostring(
            safeNumber(
                function()
                    return container:getTemprature()
                end,
                -1
            )
        )
        .. " | customTemperature="
        .. tostring(
            safeNumber(
                function()
                    return container:getCustomTemperature()
                end,
                -1
            )
        )
        .. " | steaks="
        .. tostring(contents.steaks)
        .. " | fresh="
        .. tostring(contents.freshSteaks)
        .. " | frozen="
        .. tostring(contents.frozenSteaks)
    )

    local items =
        container:getItems()

    for i = 0, items:size() - 1 do

        local item =
            items:get(i)

        if getFullType(item) == "Base.Steak" then

            logVanillaFoodContext(
                item,
                "FRIDGE",
                "FRIDGE",
                phase
            )
        end
    end
end


local function logDiagnosticSnapshot(
    player,
    groups,
    fridge,
    phase
)

    logPlayerContext(
        player,
        phase
    )

    for _, name in ipairs(GROUP_ORDER) do

        local cooler =
            groups[name]

        if cooler then

            logCoolerContext(
                player,
                cooler,
                name,
                GROUPS[name].location,
                phase
            )

            local container =
                getCoolerContainer(cooler)

            if container then

                local items =
                    container:getItems()

                for i = 0, items:size() - 1 do

                    local item =
                        items:get(i)

                    if getFullType(item) == "Base.Steak" then

                        logVanillaFoodContext(
                            item,
                            name,
                            GROUPS[name].location,
                            phase
                        )
                    end
                end
            end
        end
    end

    local controlItems =
        player:getInventory():getItems()

    for i = 0, controlItems:size() - 1 do

        local item =
            controlItems:get(i)

        if getFullType(item) == "Base.Steak" then

            logVanillaFoodContext(
                item,
                "CONTROL",
                "PLAYER_INVENTORY",
                phase
            )
        end
    end

    logFridgeSnapshot(
        fridge,
        phase
    )
end


------------------------------------------------------------
-- Log starting state of Cooler
------------------------------------------------------------

local function logCoolerSnapshot(
    cooler,
    group,
    location,
    phase
)

    local container =
        getCoolerContainer(cooler)


    if not container then
        return
    end


    local coolerTemp =
        getCoolerTemperature(cooler)


    local contents =
        inspectContents(cooler)


    print(
        "[FC-COOLER]"
        .. " phase=" .. phase
        .. " | group=" .. group
        .. " | location=" .. location
        .. " | id="
        .. tostring(cooler:getID())
        .. " | temp="
        .. tostring(coolerTemp)
        .. " | steaks="
        .. tostring(contents.steaks)
        .. " | packs="
        .. tostring(contents.packs)
    )


    local items =
        container:getItems()


    for i = 0, items:size() - 1 do

        local item =
            items:get(i)


        if getFullType(item)
            == "Base.Coldpack" then


            print(
                "[FC-PACK]"
                .. " phase=" .. phase
                .. " | group=" .. group
                .. " | location=" .. location
                .. " | id="
                .. tostring(item:getID())
                .. " | packTemp="
                .. tostring(
                    getColdpackTemperature(item)
                )
            )


        elseif instanceof(item, "Food") then


            local foodTemp =
                safeNumber(
                    function()
                        return item:getHeat()
                    end,
                    AMBIENT_TEMP
                )


            logFood(
                item,
                group,
                location,
                coolerTemp,
                foodTemp,
                phase
            )
        end
    end
end


------------------------------------------------------------
-- Simulate one Cooler step
------------------------------------------------------------

local function simulateCoolerStep(
    cooler,
    container,
    stepMinutes
)

    local coolerTemp =
        getCoolerTemperature(cooler)


    --------------------------------------------------------
    -- Insulation leak
    --------------------------------------------------------

    local leakRate =
        scaledRate(
            COOLER_LEAK_RATE,
            stepMinutes
        )


    coolerTemp =
        coolerTemp
        + (
            (AMBIENT_TEMP - coolerTemp)
            * leakRate
        )


    local items =
        container:getItems()


    --------------------------------------------------------
    -- Coldpack heat exchange
    --------------------------------------------------------

    local packExchangeRate =
        scaledRate(
            COLDPACK_EXCHANGE_RATE,
            stepMinutes
        )


    for i = 0, items:size() - 1 do

        local item =
            items:get(i)


        if getFullType(item)
            == "Base.Coldpack" then


            local packTemp =
                getColdpackTemperature(item)


            local transfer =
                (coolerTemp - packTemp)
                * packExchangeRate


            coolerTemp =
                coolerTemp
                - (
                    transfer
                    / COOLER_CAPACITY
                )


            packTemp =
                packTemp
                + (
                    transfer
                    / COLDPACK_CAPACITY
                )


            coolerTemp =
                clamp(
                    coolerTemp,
                    0.0,
                    2.0
                )


            packTemp =
                clamp(
                    packTemp,
                    0.0,
                    2.0
                )


            setColdpackTemperature(
                item,
                packTemp
            )
        end
    end


    --------------------------------------------------------
    -- Food heat exchange + time-based biology
    --------------------------------------------------------

    local foodExchangeRate =
        scaledRate(
            FOOD_EXCHANGE_RATE,
            stepMinutes
        )


    for i = 0, items:size() - 1 do

        local item =
            items:get(i)


        if instanceof(item, "Food") then

            local foodData =
                initializeFoodState(
                    item,
                    cooler
                )


            local foodTemp =
                foodData.FC_temperature


            local transfer =
                (coolerTemp - foodTemp)
                * foodExchangeRate


            coolerTemp =
                coolerTemp
                - (
                    transfer
                    / COOLER_CAPACITY
                )


            foodTemp =
                foodTemp
                + (
                    transfer
                    / FOOD_CAPACITY
                )


            coolerTemp =
                clamp(
                    coolerTemp,
                    0.0,
                    2.0
                )


            foodTemp =
                clamp(
                    foodTemp,
                    0.0,
                    2.0
                )


            foodData.FC_temperature =
                foodTemp


            advanceManagedFoodBiology(
                item,
                foodTemp,
                stepMinutes
            )
        end
    end


    setCoolerTemperature(
        cooler,
        coolerTemp
    )
end


------------------------------------------------------------
-- Update one Cooler from elapsed world time
------------------------------------------------------------

local function updateCooler(
    cooler,
    group,
    location,
    doLog
)

    local container =
        getCoolerContainer(cooler)


    if not container then
        return
    end


    local nowHours =
        getWorldAgeHours()


    if nowHours == nil then

        if doLog then

            print(
                "[FC-TIME]"
                .. " group=" .. group
                .. " | status=NO_WORLD_TIME"
            )
        end

        return
    end


    local coolerData =
        cooler:getModData()


    if coolerData.FC_lastThermalUpdateHours == nil then

        coolerData.FC_lastThermalUpdateHours =
            nowHours
    end


    local elapsedMinutes =
        (
            nowHours
            - coolerData.FC_lastThermalUpdateHours
        )
        * 60.0


    if elapsedMinutes < 0.0 then

        -- World time moved backwards, for example after a debug reset.
        -- Re-anchor without applying negative simulation.
        coolerData.FC_lastThermalUpdateHours =
            nowHours

        elapsedMinutes =
            0.0
    end


    local simulatedMinutes =
        0.0

    local remainingMinutes =
        elapsedMinutes


    while remainingMinutes > 0.0001 do

        local stepMinutes =
            chooseStepMinutes(
                remainingMinutes
            )


        simulateCoolerStep(
            cooler,
            container,
            stepMinutes
        )


        simulatedMinutes =
            simulatedMinutes
            + stepMinutes


        remainingMinutes =
            remainingMinutes
            - stepMinutes
    end


    coolerData.FC_lastThermalUpdateHours =
        nowHours


    --------------------------------------------------------
    -- Push authoritative managed state back into vanilla items
    --------------------------------------------------------

    local items =
        container:getItems()


    local packCount = 0
    local foodCount = 0


    for i = 0, items:size() - 1 do

        local item =
            items:get(i)


        if getFullType(item)
            == "Base.Coldpack" then

            packCount =
                packCount + 1


        elseif instanceof(item, "Food") then

            foodCount =
                foodCount + 1


            initializeFoodState(
                item,
                cooler
            )


            applyManagedFoodState(
                item
            )
        end
    end


    local coolerTemp =
        getCoolerTemperature(cooler)


    pcall(function()

        container:setCustomTemperature(
            coolerTemp
        )

    end)


    if simulatedMinutes > 1.5 then

        print(
            "[FC-CATCHUP]"
            .. " group=" .. group
            .. " | location=" .. location
            .. " | minutes="
            .. tostring(simulatedMinutes)
            .. " | worldHours="
            .. tostring(nowHours)
        )
    end


    if doLog then

        for i = 0, items:size() - 1 do

            local item =
                items:get(i)


            if getFullType(item)
                == "Base.Coldpack" then


                print(
                    "[FC-PACK]"
                    .. " phase=RUN"
                    .. " | group="
                    .. group
                    .. " | location="
                    .. location
                    .. " | id="
                    .. tostring(item:getID())
                    .. " | packTemp="
                    .. tostring(
                        getColdpackTemperature(item)
                    )
                )


            elseif instanceof(item, "Food") then

                local foodData =
                    item:getModData()


                logFood(
                    item,
                    group,
                    location,
                    coolerTemp,
                    foodData.FC_temperature,
                    "RUN"
                )
            end
        end


        print(
            "[FC-COOLER]"
            .. " phase=RUN"
            .. " | group=" .. group
            .. " | location=" .. location
            .. " | id="
            .. tostring(cooler:getID())
            .. " | temp="
            .. tostring(coolerTemp)
            .. " | elapsedMinutes="
            .. tostring(elapsedMinutes)
            .. " | food="
            .. tostring(foodCount)
            .. " | packs="
            .. tostring(packCount)
            .. " | spoilFactor="
            .. tostring(
                getSpoilageFactor(
                    coolerTemp
                )
            )
            .. " | thawFactor="
            .. tostring(
                getThawFactor(
                    coolerTemp
                )
            )
        )
    end
end


------------------------------------------------------------
-- Recharge coldpacks in powered freezers
------------------------------------------------------------

local function rechargeNearbyFreezers(player)

    local playerSquare =
        player:getSquare()


    if not playerSquare then
        return
    end


    local cell =
        getCell()


    local px =
        playerSquare:getX()

    local py =
        playerSquare:getY()

    local pz =
        playerSquare:getZ()


    for x = px - FREEZER_SCAN_RADIUS,
            px + FREEZER_SCAN_RADIUS do

        for y = py - FREEZER_SCAN_RADIUS,
                py + FREEZER_SCAN_RADIUS do


            local square =
                cell:getGridSquare(
                    x,
                    y,
                    pz
                )


            if square then

                local objects =
                    square:getObjects()


                for objectIndex = 0,
                    objects:size() - 1 do


                    local object =
                        objects:get(objectIndex)


                    local count =
                        object:getContainerCount()


                    for containerIndex = 0,
                        count - 1 do


                        local container =
                            object:getContainerByIndex(
                                containerIndex
                            )


                        if container
                        and tostring(container:getType())
                            == "freezer" then


                            local powered =
                                safeValue(
                                    function()
                                        return container:isPowered()
                                    end,
                                    false
                                )


                            if powered then

                                local items =
                                    container:getItems()


                                for i = 0,
                                    items:size() - 1 do


                                    local item =
                                        items:get(i)


                                    if getFullType(item)
                                        == "Base.Coldpack" then


                                        local temp =
                                            getColdpackTemperature(
                                                item
                                            )


                                        temp =
                                            temp
                                            + (
                                                (
                                                    FREEZER_TEMP
                                                    - temp
                                                )
                                                * FREEZER_RECHARGE_RATE
                                            )


                                        setColdpackTemperature(
                                            item,
                                            temp
                                        )


                                        print(
                                            "[FC-FREEZER]"
                                            .. " pack="
                                            .. tostring(item:getID())
                                            .. " | temp="
                                            .. tostring(temp)
                                        )
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end


------------------------------------------------------------
-- Start test
------------------------------------------------------------

local function startTest(
    player,
    groups,
    fridge
)

    prepareTestStart(groups)


    TEST_FRIDGE =
        fridge


    TEST_ACTIVE =
        true


    print(
        "=================================================="
    )

    print(
        "[FC-TEST] START"
    )

    print(
        "[FC-TIME]"
        .. " worldHours="
        .. tostring(getWorldAgeHours())
        .. " | baseAgeDaysPerGameDay="
        .. tostring(BASE_AGE_DAYS_PER_GAME_DAY)
        .. " | baseThawPerMinute="
        .. tostring(BASE_THAW_RATE_PER_MINUTE)
        .. " | FoodRotSpeed="
        .. tostring(
            safeValue(
                function()
                    return SandboxVars.FoodRotSpeed
                end,
                "UNKNOWN"
            )
        )
    )

    print(
        "=================================================="
    )


    for _, name in ipairs(GROUP_ORDER) do

        local cooler =
            groups[name]


        if cooler then

            logCoolerSnapshot(
                cooler,
                name,
                GROUPS[name].location,
                "START"
            )
        end
    end


    logControls(
        player,
        "START"
    )


    logDiagnosticSnapshot(
        player,
        groups,
        TEST_FRIDGE,
        "START"
    )
end


------------------------------------------------------------
-- Main tick
------------------------------------------------------------

function FC.tick()

    tickCounter =
        tickCounter + 1


    local player =
        getSpecificPlayer(0)


    if not player then
        return
    end


    local doLog =
        (
            tickCounter
            % LOG_INTERVAL
            == 0
        )


    --------------------------------------------------------
    -- Coldpacks can recharge before test starts
    --------------------------------------------------------

    if doLog then

        rechargeNearbyFreezers(
            player
        )
    end


    local groups =
        findGroups(player)


    --------------------------------------------------------
    -- Waiting for complete setup
    --------------------------------------------------------

    if not TEST_ACTIVE then

        local ready, fridge =
            checkReadiness(
                player,
                groups,
                doLog
            )


        if ready then

            startTest(
                player,
                groups,
                fridge
            )
        end


        return
    end


    --------------------------------------------------------
    -- Running test
    --------------------------------------------------------

    for _, name in ipairs(GROUP_ORDER) do

        local cooler =
            groups[name]


        if cooler then

            updateCooler(
                cooler,
                name,
                GROUPS[name].location,
                doLog
            )

        elseif doLog then

            print(
                "[FC-WARNING]"
                .. " group=" .. name
                .. " | cooler missing during test"
            )
        end
    end


    if doLog then

        logControls(
            player,
            "RUN"
        )
    end


    local doDiagnosticLog =
        (
            tickCounter
            % DIAGNOSTIC_LOG_INTERVAL
            == 0
        )


    if doDiagnosticLog then

        logDiagnosticSnapshot(
            player,
            groups,
            TEST_FRIDGE,
            "RUN"
        )
    end
end


Events.EveryOneMinute.Add(
    FC.tick
)


print(
    "[FC] Functional Coolers Prototype v0.3.0-dev loaded"
    .. " | diagnostics=FRIDGE_CONTEXT"
)