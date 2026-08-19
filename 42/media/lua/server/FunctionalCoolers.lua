local FC = {}

------------------------------------------------------------
-- FUNCTIONAL COOLERS
-- Calibration Prototype v0.2
--
-- Testopstelling:
--
-- CONTROL:
--   1 verse steak
--   1 frozen steak
--   direct in player inventory
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
local GROUND_SCAN_RADIUS = 10

local LOG_INTERVAL = 10

local TEST_ACTIVE = false
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


    local continuous =
        data.FC_coolerID == coolerID
        and data.FC_lastSeenTick
            == (tickCounter - 1)
        and data.FC_temperature ~= nil


    if not continuous then

        data.FC_coolerID =
            coolerID

        data.FC_temperature =
            safeNumber(
                function()
                    return food:getHeat()
                end,
                AMBIENT_TEMP
            )

        data.FC_lastAge =
            safeNumber(
                function()
                    return food:getAge()
                end,
                nil
            )

        data.FC_lastFreezingTime =
            safeNumber(
                function()
                    return food:getFreezingTime()
                end,
                nil
            )
    end


    data.FC_lastSeenTick =
        tickCounter


    return data.FC_temperature
end


local function setFoodThermalTemperature(food, temp)

    temp =
        clamp(temp, 0.0, 2.0)

    local data =
        food:getModData()

    data.FC_temperature =
        temp


    pcall(function()

        food:setHeat(temp)

    end)
end


------------------------------------------------------------
-- Correct food age
------------------------------------------------------------

local function correctFoodAge(food, foodTemp)

    local data =
        food:getModData()


    local currentAge =
        safeNumber(
            function()
                return food:getAge()
            end,
            nil
        )


    if currentAge == nil then
        return
    end


    if data.FC_lastAge == nil then

        data.FC_lastAge =
            currentAge

        return
    end


    local previousAge =
        data.FC_lastAge


    local vanillaDelta =
        currentAge - previousAge


    if vanillaDelta <= 0 then

        data.FC_lastAge =
            currentAge

        return
    end


    if vanillaDelta > 1.0 then

        data.FC_lastAge =
            currentAge

        return
    end


    local factor =
        getSpoilageFactor(foodTemp)


    local correctedAge =
        previousAge
        + (vanillaDelta * factor)


    pcall(function()

        food:setAge(correctedAge)

    end)


    data.FC_lastAge =
        correctedAge
end


------------------------------------------------------------
-- Correct thawing
------------------------------------------------------------

local function correctFoodFreezing(food, foodTemp)

    local data =
        food:getModData()


    local current =
        safeNumber(
            function()
                return food:getFreezingTime()
            end,
            nil
        )


    if current == nil then
        return
    end


    if data.FC_lastFreezingTime == nil then

        data.FC_lastFreezingTime =
            current

        return
    end


    local previous =
        data.FC_lastFreezingTime


    if current < previous then

        local vanillaThaw =
            previous - current


        local thawFactor =
            getThawFactor(foodTemp)


        local corrected =
            previous
            - (
                vanillaThaw
                * thawFactor
            )


        corrected =
            clamp(
                corrected,
                0.0,
                100.0
            )


        pcall(function()

            food:setFreezingTime(
                corrected
            )

        end)


        data.FC_lastFreezingTime =
            corrected

    else

        data.FC_lastFreezingTime =
            current
    end
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


    return ready
end


------------------------------------------------------------
-- Reset thermal state at actual start
------------------------------------------------------------

local function prepareTestStart(groups)

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

                        foodData.FC_lastAge =
                            nil

                        foodData.FC_lastFreezingTime =
                            nil

                        foodData.FC_lastSeenTick =
                            nil
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
        .. " | freeze="
        .. tostring(
            safeNumber(
                function()
                    return item:getFreezingTime()
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


    for i = 0, items:size() - 1 do

        local item =
            items:get(i)


        if getFullType(item)
            == "Base.Steak" then


            print(
                "[FC-CONTROL]"
                .. " phase=" .. phase
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
-- Update one Cooler
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


    local coolerTemp =
        getCoolerTemperature(cooler)


    --------------------------------------------------------
    -- Insulation leak
    --------------------------------------------------------

    coolerTemp =
        coolerTemp
        + (
            (AMBIENT_TEMP - coolerTemp)
            * COOLER_LEAK_RATE
        )


    local items =
        container:getItems()


    local packCount = 0
    local foodCount = 0


    --------------------------------------------------------
    -- Coldpack heat exchange
    --------------------------------------------------------

    for i = 0, items:size() - 1 do

        local item =
            items:get(i)


        if getFullType(item)
            == "Base.Coldpack" then


            packCount =
                packCount + 1


            local packTemp =
                getColdpackTemperature(item)


            local transfer =
                (coolerTemp - packTemp)
                * COLDPACK_EXCHANGE_RATE


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


            if doLog then

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
                    .. tostring(packTemp)
                )
            end
        end
    end


    --------------------------------------------------------
    -- Food heat exchange
    --------------------------------------------------------

    for i = 0, items:size() - 1 do

        local item =
            items:get(i)


        if instanceof(item, "Food") then

            foodCount =
                foodCount + 1


            local foodTemp =
                initializeFoodState(
                    item,
                    cooler
                )


            local transfer =
                (coolerTemp - foodTemp)
                * FOOD_EXCHANGE_RATE


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


            setFoodThermalTemperature(
                item,
                foodTemp
            )


            correctFoodAge(
                item,
                foodTemp
            )


            correctFoodFreezing(
                item,
                foodTemp
            )


            if doLog then

                logFood(
                    item,
                    group,
                    location,
                    coolerTemp,
                    foodTemp,
                    "RUN"
                )
            end
        end
    end


    setCoolerTemperature(
        cooler,
        coolerTemp
    )


    pcall(function()

        container:setCustomTemperature(
            coolerTemp
        )

    end)


    if doLog then

        print(
            "[FC-COOLER]"
            .. " phase=RUN"
            .. " | group=" .. group
            .. " | location=" .. location
            .. " | id="
            .. tostring(cooler:getID())
            .. " | temp="
            .. tostring(coolerTemp)
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
    groups
)

    prepareTestStart(groups)


    TEST_ACTIVE =
        true


    print(
        "=================================================="
    )

    print(
        "[FC-TEST] START"
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

        local ready =
            checkReadiness(
                player,
                groups,
                doLog
            )


        if ready then

            startTest(
                player,
                groups
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
end


Events.EveryOneMinute.Add(
    FC.tick
)


print(
    "[FC] Functional Coolers Calibration Prototype v0.2 loaded."
)