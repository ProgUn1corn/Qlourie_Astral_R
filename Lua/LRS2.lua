-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}
M.type = "auxilliary"

local abs = math.abs
local min = math.min
local max = math.max

--front
local dampers = {}
local dampersLookup = {}
local dampingGroups = {}

function clamp(value, min, max)
  return math.min(math.max(value, min), max)
end

function printTable(t, indent)
  indent = indent or ""
  for k, v in pairs(t) do
    if type(v) == "table" then
      print(indent .. "[" .. k .. "] => Table:")
      printTable(v, indent .. "  ")
    else
      print(indent .. "[" .. k .. "] => " .. tostring(v))
    end
  end
end

function applyLRS(damper, mode)
  local d = damper.damping and damper.damping[mode]
  if not d then 
    log("W", "applyLRS", "No damping data for damper " .. tostring(damper.name) .. " in mode: " .. tostring(mode)) 
    return 
  end
  if damper.damperCid then
    obj:setBoundedBeamDamp(
      damper.damperCid, 
      d.LSBump, 
      d.LSRebound,
      d.HSBump, 
      d.HSRebound, 
      d.velocityBump, 
      d.velocityRebound
    ) 
  end
end

local function update(dt) 
  for _, damper in ipairs(dampers) do
    local loadLength = obj:getBeamLength(damper.loadCid)
    --print(loadLength)
    if loadLength >= damper.LRSp then
      applyLRS(damper, "active")
      --print("YEEEEEEEEEEEEEEEEESSSSSSSSSSSSS")
    else
      applyLRS(damper, "normal")
      --print("NOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO")
    end
  end
end

local function reset()
end

local function init(jbeamData)
  local beamNameLookup = {}
  for _, b in pairs(v.data.beams) do
    if b.name then
      beamNameLookup[b.name] = b.cid
    end
  end
  
  --construct dampers table
  local dampersTable = tableFromHeaderTable(jbeamData.dampers or {})
  for _, damperData in pairs(dampersTable) do
    local cid = beamNameLookup[damperData.beamName]
    if cid then
      local damper = {
        name = damperData.name,
        damperCid = cid,
        activeFlag = false
      }
      table.insert(dampers, damper)
      dampersLookup[damper.name] = damper
    else 
      log("E", "LRS", "Invalid damper beam: "..tostring(damperData.beamName)) 
    end
  end

  --inject loads table
  local loadsTable = tableFromHeaderTable(jbeamData.loads or {})
  for _, loadData in pairs(loadsTable) do
    local cid = beamNameLookup[loadData.beamName]
    local damper = dampersLookup[loadData.name]
    if cid and damper then
      damper.loadCid = cid
      if loadData.LRSp then
        damper.LRSp = loadData.LRSp
      end
      if loadData.DSVp then
        damper.DSVp = loadData.DSVp
      end
    elseif not damper then
      log("E", "LRS", "No matching damper for load '"..tostring(loadData.name).."'")
    elseif not cid then
      log("E", "LRS", "Invalid load beam: "..tostring(loadData.beamName)) 
    end
  end

  --construct damping table
  local LRSGroups = tableFromHeaderTable(jbeamData.damping or {})
  for _, dampingData in pairs(LRSGroups) do
    local name = dampingData.name
    local mode = tonumber(dampingData.active) == 1 and "active" or "normal"
    dampingGroups[dampingData.name] = dampingGroups[dampingData.name] or {}
    dampingGroups[dampingData.name][mode] = {
      LSBump = dampingData.beamDamp,
      HSBump = dampingData.beamDampFast,
      LSRebound = dampingData.beamDampRebound,
      HSRebound = dampingData.beamDampReboundFast,
      velocityBump = dampingData.beamDampVelocitySplit,
      velocityRebound = dampingData.beamDampVelocitySplitRebound,
    }
  end

  --inject damping table
  for _, damper in ipairs(dampers) do
    local damping = dampingGroups[damper.name]
    if damping then
      damper.damping = {
        normal = damping.normal or {},
        active = damping.active or {}
      }
    else
      log("W", "LRS", "No damping data for damper: " .. tostring(damper.name))
    end
  end

  --Fvck LUA
  if dampers[1] == dampersLookup["FR"] then
    print("YEEEEEEEEEEEEEEESSSSSSSSSSSSSSSS")
  end
  
  --printTable(dampersLookup)
  printTable(dampingGroups)
end


local function reset()
end

M.init = init
M.reset = reset
M.update = update
M.applyLRS = applyLRS

return M