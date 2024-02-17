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
local orgLSRebound = 0
local orgHSRebound = 0
local newLSRebound = 0
local newHSRebound = 0


function clamp(value, min, max)
  return math.min(math.max(value, min), max)
end

local function updateWheelsIntermediate()
  for _, spring in ipairs(loads) do
    --get suspension load
    local springLoad = clamp(0-obj:getBeamStress(spring.bCid),0,9999) or 0
    activeFlag = false
    if springLoad <= 1500 then 
      activeFlag = true
      newLSRebound = damping[2].beamDampRebound
      newHSRebound = damping[2].beamDampReboundFast
    else
      activeFlag = false
      newLSRebound = orgLSRebound
      newHSRebound = orgHSRebound
    end
    --print(activeFlag)
  end
  
  for _, damper in ipairs(dampers) do
    --apply new rebound
    if activeFlag == true then
      obj:setBoundedBeamDamp(damper.bCid, damping[1].beamDamp, newLSRebound, damping[1].beamDampFast, newHSRebound, damping[1].beamDampVelocitySplit, damping[1].beamDampVelocitySplitRebound)
    else
      obj:setBoundedBeamDamp(damper.bCid, damping[1].beamDamp, orgLSRebound, damping[1].beamDampFast, orgHSRebound, damping[1].beamDampVelocitySplit, damping[1].beamDampVelocitySplitRebound)
    end
  end
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
    }
    table.insert(loads, l)
  end
  
  local LRS = tableFromHeaderTable(jbeamData.dampers or {}) --call out damper in Jbeam
  for _, damper in pairs(LRS) do
    local bCid = beamNameTable[damper.beamName]
    local d = {
      name = damper.name,
      bCid = bCid,
    }
    table.insert(dampers, d)
  end
  
  damping = tableFromHeaderTable(jbeamData.damping or {}) --call out damping values in Jbeam
  orgLSRebound = damping[1].beamDampRebound
  orgHSRebound = damping[1].beamDampReboundFast

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
