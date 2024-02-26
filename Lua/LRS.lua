-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt
local M = {}
M.type = "auxilliary"

local abs = math.abs
local min = math.min
local max = math.max

--local gMass = {}
local fDamping = {}
local rDamping = {}
local fLoads = {}
local rLoads = {}
local fDampers = {}
local rDampers = {}

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

function clamp(value, min, max)
  return math.min(math.max(value, min), max)
end

local function updateWheelsIntermediate()
  --front and rear separate process
  for i, spring in ipairs(fLoads) do
    local springLoad = obj:getBeamStress(spring.bCid) or 0 --get suspension load
    if springLoad >= 0.648 then 
      spring.activeFlag = true
    else
      spring.activeFlag = false
    end
    --print(obj:getBeamStress(fLoads[1].bCid))
  end  

  for i, damperF in ipairs(fDampers) do
    if fLoads[i].activeFlag == true then --active LRS
      damperF.newLSRebound = clamp(fDamping[2].beamDampRebound, 1000, 2500)
      damperF.newHSRebound = clamp(fDamping[2].beamDampReboundFast, 1000, 2500)
    else
      damperF.newLSRebound = damperF.orgLSRebound
      damperF.newHSRebound = damperF.orgHSRebound
    end
    --print(fLoads[1].activeFlag)
    --print(fLoads[2].activeFlag)
    
    --apply new rebound
    obj:setBoundedBeamDamp(damperF.bCid, fDamping[1].beamDamp, damperF.newLSRebound, fDamping[1].beamDampFast, damperF.newHSRebound, fDamping[1].beamDampVelocitySplit, fDamping[1].beamDampVelocitySplitRebound) 
    --print(fDampers[1].newLSRebound)
    --print(fDampers[2].newLSRebound)
  end
  
  for i, spring in ipairs(rLoads) do
    local springLoad = obj:getBeamStress(spring.bCid) or 0 --get suspension load
    if springLoad >= 0.648 then 
      spring.activeFlag = true
    else
      spring.activeFlag = false
    end
    --print(obj:getBeamStress(rLoads[1].bCid))
  end  

  for i, damperR in ipairs(rDampers) do
    if rLoads[i].activeFlag == true then --active LRS
      damperR.newLSRebound = clamp(rDamping[2].beamDampRebound, 1000, 2500)
      damperR.newHSRebound = clamp(rDamping[2].beamDampReboundFast, 1000, 2500)
    else
      damperR.newLSRebound = damperR.orgLSRebound
      damperR.newHSRebound = damperR.orgHSRebound
    end
    --print(rLoads[1].activeFlag)
    --print(rLoads[2].activeFlag)
    
    --apply new rebound
    obj:setBoundedBeamDamp(damperR.bCid, rDamping[1].beamDamp, damperR.newLSRebound, rDamping[1].beamDampFast, damperR.newHSRebound, rDamping[1].beamDampVelocitySplit, rDamping[1].beamDampVelocitySplitRebound) 
    --print(rDampers[1].newHSRebound)
    --print(rDampers[2].newHSRebound)
  end
end

local function init(jbeamData)
  local beamNameTable = {}
  for _, b in pairs(v.data.beams) do -- store beam that has name into a table
    if b.name then
      beamNameTable[b.name] = b.cid
    end
  end
  
  --call out damping values in Jbeam
  fDamping = tableFromHeaderTable(jbeamData.fDamping or {}) 
  rDamping = tableFromHeaderTable(jbeamData.rDamping or {})
  
  fLoads = {}
  rLoads = {}
  fDampers = {}
  rDampers = {}

  --front and rear separate process
  local fSpring = tableFromHeaderTable(jbeamData.fLoads or {}) --call out spring load in Jbeam
  for _, loads in pairs(fSpring) do
    local bCid = beamNameTable[loads.beamName]
    local fl = {
      name = loads.name,
      bCid = bCid,
      activeFlag = false
    }
    table.insert(fLoads, fl)
  end

  local rSpring = tableFromHeaderTable(jbeamData.rLoads or {})
  for _, loads in pairs(rSpring) do
    local bCid = beamNameTable[loads.beamName]
    local rl = {
      name = loads.name,
      bCid = bCid,
      activeFlag = false
    }
    table.insert(rLoads, rl)
  end
  
  local fLRS = tableFromHeaderTable(jbeamData.fDampers or {}) --call out damper in Jbeam
  for _, damper in pairs(fLRS) do
    local bCid = beamNameTable[damper.beamName]
    local fd = {
      name = damper.name,
      bCid = bCid,
      orgLSRebound = fDamping[1].beamDampRebound,
      orgHSRebound = fDamping[1].beamDampReboundFast,
      newLSRebound = fDamping[2].beamDampRebound,
      newHSRebound = fDamping[2].beamDampReboundFast,
    }
    table.insert(fDampers, fd)
  end

  local rLRS = tableFromHeaderTable(jbeamData.rDampers or {})
  for _, damper in pairs(rLRS) do
    local bCid = beamNameTable[damper.beamName]
    local rd = {
      name = damper.name,
      bCid = bCid,
      orgLSRebound = rDamping[1].beamDampRebound,
      orgHSRebound = rDamping[1].beamDampReboundFast,
      newLSRebound = rDamping[2].beamDampRebound,
      newHSRebound = rDamping[2].beamDampReboundFast,
    }
    table.insert(rDampers, rd)
  end
  
  --print(fDampers[1].bCid)
  --printTable(fDampers)
  --printTable(fLoads)
  --printTable(fDamping)
  
  --printTable(rDampers)
  --printTable(rLoads)
  --printTable(rDamping)

  M.updateWheelsIntermediate = updateWheelsIntermediate
  M.updateGFX = updateGFX
end

local function initLastStage()
end

local function reset()
end

M.init = init
M.reset = reset
M.initLastStage = initLastStage
M.updateWheelsIntermediate = nil
M.updateGFX = nil

return M