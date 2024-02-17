-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt
local M = {}
M.type = "auxilliary"

local abs = math.abs
local min = math.min
local max = math.max

--local gMass = {}
local dampers = {}
local damping = {}
local loads = {}
local activeFlag = 0


function clamp(value, min, max)
  return math.min(math.max(value, min), max)
end

local function updateWheelsIntermediate()
  for i, spring in ipairs(loads) do
    --get suspension load
    local springLoad = clamp(0-obj:getBeamStress(spring.bCid),0,9999) or 0
    if springLoad <= 1500 then 
      spring.activeFlag = true
    else
      spring.activeFlag = false
    end
  end  

  for i, damper in ipairs(dampers) do
    if loads[i].activeFlag == true then
      damper.newLSRebound = damping[2].beamDampRebound
      damper.newHSRebound = damping[2].beamDampReboundFast
    else
      damper.newLSRebound = damper.orgLSRebound
      damper.newHSRebound = damper.orgHSRebound
    end
    --print(loads[1].activeFlag)

    --apply new rebound
    obj:setBoundedBeamDamp(damper.bCid, damping[1].beamDamp, damper.newLSRebound, damping[1].beamDampFast, damper.newHSRebound, damping[1].beamDampVelocitySplit, damping[1].beamDampVelocitySplitRebound) 
  end
  --print(dampers[1].newHSRebound)
  --print(dampers[2].newHSRebound)
end


local function init(jbeamData)
  local beamNameTable = {}
  for _, b in pairs(v.data.beams) do -- store beam that has name into a table
    if b.name then
      beamNameTable[b.name] = b.cid
    end
  end

  loads = {}
  dampers = {}
  damping = {}

  local spring = tableFromHeaderTable(jbeamData.loads or {}) --call out spring load in Jbeam
  for _, load in pairs(spring) do
    local bCid = beamNameTable[load.beamName]
    local l = {
      name = load.name,
      bCid = bCid,
      activeFlag = false
    }
    table.insert(loads, l)
  end
  
  local LRS = tableFromHeaderTable(jbeamData.dampers or {}) --call out damper in Jbeam
  damping = tableFromHeaderTable(jbeamData.damping or {}) --call out damping values in Jbeam
  for _, damper in pairs(LRS) do
    local bCid = beamNameTable[damper.beamName]
    local d = {
      name = damper.name,
      bCid = bCid,
      orgLSRebound = damping[1].beamDampRebound,
      orgHSRebound = damping[1].beamDampReboundFast,
      newLSRebound = damping[2].beamDampRebound,
      newHSRebound = damping[2].beamDampReboundFast,
    }
    table.insert(dampers, d)
  end
  
  --print(orgLSRebound)
  --print(loads[1].bCid)
  --print(loads[2].bCid)

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
