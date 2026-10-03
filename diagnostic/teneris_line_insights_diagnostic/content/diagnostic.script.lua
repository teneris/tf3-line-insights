-- Investigation artifact, not the implementation of v0.1.
-- API references and local evidence: docs/research/tf3-local-diagnostic.md.
local function message(text)
    log.message("[LineInsights] " .. text)
end

local function componentTypes()
    if api.engine.ComponentType then return api.engine.ComponentType, "api.engine.ComponentType" end
    if api.type.ComponentType then return api.type.ComponentType, "api.type.ComponentType" end
    error("ComponentType not available")
end

local function getComponent(entity, componentType)
    if not api.engine.entityExists(entity) then return nil end
    return api.engine.getComponent(entity, componentType)
end

local function timeText(types)
    local world = api.engine.util.getWorld()
    local time = getComponent(world, types.GAME_TIME)
    local speed = getComponent(world, types.GAME_SPEED)
    return "gameTime=" .. tostring(time and time.gameTime)
        .. " gameTime0=" .. tostring(time and time.gameTime0)
        .. " updateCount=" .. tostring(time and time.updateCount)
        .. " tickCount=" .. tostring(time and time.tickCount)
        .. " speedup=" .. tostring(speed and speed.speedup)
        .. " millisPerDay=" .. tostring(speed and speed.millisPerDay)
end

local function stopSignature(line)
    local parts = {}
    for index, stop in ipairs(line.stops) do
        parts[#parts + 1] = table.concat({tostring(index), tostring(stop.stationGroup),
            tostring(stop.station), tostring(stop.terminal)}, ":")
    end
    return table.concat(parts, ";")
end

local function measure(lineId, sampleLimit)
    local cpuBegin = os and os.clock and os.clock()
    local types, namespace = componentTypes()
    local line = getComponent(lineId, types.LINE)
    if not line then message("SKIP line=" .. tostring(lineId) .. " reason=line_missing"); return end
    local signature = stopSignature(line)
    local name = getComponent(lineId, types.NAME)
    message("BEGIN line=" .. tostring(lineId) .. " name=" .. tostring(name and name.name)
        .. " componentNamespace=" .. namespace .. " " .. timeText(types))
    local passengerCargo = api.res.cargoTypeRep.getPassengerCargoTypeId()
    for index, stop in ipairs(line.stops) do
        local stopName = getComponent(stop.stationGroup, types.NAME)
        message("STOP tableIndex=" .. tostring(index) .. " stationGroup=" .. tostring(stop.stationGroup)
            .. " name=" .. tostring(stopName and stopName.name) .. " station=" .. tostring(stop.station)
            .. " terminal=" .. tostring(stop.terminal))
    end
    local persons = api.engine.system.simPersonSystem.getSimPersonsForLine(lineId)
    local waiting, onboard, unknown, total, samples = 0, 0, 0, 0, 0
    local byStop, byDestination = {}, {}
    for _, personId in pairs(persons) do
        total = total + 1
        local terminal = getComponent(personId, types.SIM_ENTITY_AT_TERMINAL)
        local vehicle = getComponent(personId, types.SIM_ENTITY_AT_VEHICLE)
        if terminal and terminal.line == lineId then
            waiting = waiting + 1
            byStop[terminal.lineStop0] = (byStop[terminal.lineStop0] or 0) + 1
            local key = tostring(terminal.lineStop0) .. "->" .. tostring(terminal.lineStop1)
            byDestination[key] = (byDestination[key] or 0) + 1
            if samples < sampleLimit then
                samples = samples + 1
                message("WAIT person=" .. tostring(personId) .. " line=" .. tostring(terminal.line)
                    .. " from=" .. tostring(terminal.lineStop0) .. " to=" .. tostring(terminal.lineStop1)
                    .. " arrivalTime=" .. tostring(terminal.arrivalTime) .. " vehicle=" .. tostring(terminal.vehicle))
            end
        elseif vehicle and vehicle.line == lineId then
            onboard = onboard + 1
        else
            unknown = unknown + 1
            if samples < sampleLimit then
                samples = samples + 1
                message("UNASSIGNED person=" .. tostring(personId) .. " reason=no_matching_terminal_or_vehicle")
            end
        end
    end
    for key, count in pairs(byDestination) do
        message("WAIT_OD rawIndices=" .. key .. " count=" .. tostring(count))
    end
    -- Zero-based stop queries are a hypothesis being checked against the raw data.
    for index, _ in ipairs(line.stops) do
        local rawIndex = index - 1
        local ids = api.engine.system.simEntityAtTerminalSystem.getLineStopSimEntities(lineId, rawIndex, passengerCargo)
        local count = api.engine.system.simEntityAtTerminalSystem.getLineStopSimEntitiesCount(lineId, rawIndex, passengerCargo)
        local listCount = 0
        for _ in pairs(ids) do listCount = listCount + 1 end
        message("STOP_COMPARE rawIndex=" .. tostring(rawIndex) .. " fromPersons=" .. tostring(byStop[rawIndex] or 0)
            .. " terminalList=" .. tostring(listCount) .. " terminalCount=" .. tostring(count))
    end
    local vehicles = api.engine.system.transportVehicleSystem.getLineVehicles(lineId)
    local vehicleCount = 0
    for _, vehicleId in pairs(vehicles) do
        vehicleCount = vehicleCount + 1
        local transport = getComponent(vehicleId, types.TRANSPORT_VEHICLE)
        local passengers = api.engine.system.simEntityAtVehicleSystem.getVehicleSimEntitiesCountForCargoType(vehicleId, passengerCargo)
        message("VEHICLE entity=" .. tostring(vehicleId) .. " stopIndex=" .. tostring(transport and transport.stopIndex)
            .. " state=" .. tostring(transport and transport.state) .. " passengers=" .. tostring(passengers))
    end
    local currentLine = getComponent(lineId, types.LINE)
    local valid = currentLine and stopSignature(currentLine) == signature
    message("END line=" .. tostring(lineId) .. " valid=" .. tostring(valid)
        .. " persons=" .. total .. " waiting=" .. waiting .. " onboard=" .. onboard
        .. " unassigned=" .. unknown .. " vehicles=" .. vehicleCount
        .. " lineKind=" .. (total > 0 and "person_usage_observed" or "unknown")
        .. " waitDuration=not_verified sectionOccupancy=unknown " .. timeText(types)
        .. " cpuSeconds=" .. tostring(cpuBegin and (os.clock() - cpuBegin)))
end

local function probe(current, dt)
    local types = componentTypes()
    local time = getComponent(api.engine.util.getWorld(), types.GAME_TIME)
    if not time then return end
    if not current.probeStart then
        current.probeStart = time.tickCount
        current.probeNext = time.tickCount
        current.probePersons = {}
        for _, person in pairs(api.engine.system.simPersonSystem.getSimPersonsForLine(current.probeLine)) do
            local terminal = getComponent(person, types.SIM_ENTITY_AT_TERMINAL)
            if terminal and terminal.line == current.probeLine and #current.probePersons < 5 then
                current.probePersons[#current.probePersons + 1] = person
            end
        end
    end
    if time.tickCount >= current.probeNext then
        message("TIME_PROBE dt=" .. tostring(dt) .. " " .. timeText(types))
        for _, person in ipairs(current.probePersons) do
            local terminal = getComponent(person, types.SIM_ENTITY_AT_TERMINAL)
            local vehicle = getComponent(person, types.SIM_ENTITY_AT_VEHICLE)
            message("PERSON_PROBE person=" .. person .. " waitingLine=" .. tostring(terminal and terminal.line)
                .. " arrivalTime=" .. tostring(terminal and terminal.arrivalTime)
                .. " onboardLine=" .. tostring(vehicle and vehicle.line)
                .. " vehicle=" .. tostring(vehicle and vehicle.vehicle))
        end
        current.probeNext = time.tickCount + 10
    end
    if time.tickCount - current.probeStart >= current.probeTicks then
        message("PROBE_COMPLETE")
        current.probeTicks = nil
    end
end

function data()
    return {
        update = function(_, state, dt)
            if not state:hasEventSubscriptions() then state:subscribeToEvent("Measure") end
            local current = state:get() or {}
            if not current.ready then
                current.ready = true
                message("READY event=LineInsights/Measure")
                state:set(current)
            end
            if current.queue and #current.queue > 0 then
                local lineId = table.remove(current.queue, 1)
                local ok, err = pcall(measure, lineId, current.sampleLimit or 20)
                if not ok then message("ERROR line=" .. tostring(lineId) .. " " .. tostring(err)) end
                if #current.queue == 0 then message("SCAN_COMPLETE") end
                state:set(current)
            end
            if current.probeTicks then
                local ok, err = pcall(probe, current, dt)
                if not ok then message("PROBE_ERROR " .. tostring(err)); current.probeTicks = nil end
                state:set(current)
            end
        end,
        handleEvent = function(_, state, _src, id, name, param)
            if id ~= "LineInsights" or name ~= "Measure" then return end
            local current = state:get() or {}
            if current.queue and #current.queue > 0 then message("BUSY"); return end
            current.queue = {}
            current.sampleLimit = 20
            if param and param.lineId and param.monitorTicks then
                current.probeLine = param.lineId
                current.probeTicks = math.max(10, math.min(300, param.monitorTicks))
                current.probeStart = nil
            end
            if param and param.lineId then
                current.queue[1] = param.lineId
            else
                for _, lineId in pairs(api.engine.system.lineSystem.getLines()) do
                    current.queue[#current.queue + 1] = lineId
                end
                table.sort(current.queue)
            end
            message("REQUEST lines=" .. tostring(#current.queue))
            if #current.queue == 0 then message("SCAN_COMPLETE") end
            state:set(current)
        end,
    }
end
