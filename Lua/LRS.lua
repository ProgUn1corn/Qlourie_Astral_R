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
local LRS
local DSV
local LRSp
local LRSc
local DSVp

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

local function update(dt)
  --print(obj:getBeamVelocity(2807))
  --front and rear separate process
  for i, spring in ipairs(fLoads) do
    local springLoad = obj:getBeamLength(spring.bCid) or 0 --get suspension load
    
    if springLoad >= LRSp then 
      spring.activeFlagLRS = true
    else
      spring.activeFlagLRS = false
    end
    if springLoad <= DSVp then 
      spring.activeFlagDSV = true
    else
      spring.activeFlagDSV = false
    end
    --print(springLoad)
    --print(fLoads[1].activeFlagLRS)
    --print(fLoads[2].activeFlagLRS)

    for i, damper in ipairs(fDampers) do
      if LRS == true then --active LRS
        if fLoads[i].activeFlagLRS == true then 
          damper.newLSRebound = fDamping[2].beamDampRebound
          damper.newHSRebound = damper.newLSRebound
        else
          damper.newLSRebound = damper.orgLSRebound
          damper.newHSRebound = damper.orgHSRebound   
        end
      else
        damper.newLSRebound = damper.orgLSRebound
        damper.newHSRebound = damper.orgHSRebound   
      end

      if DSV == true then --active DSV
        if fLoads[i].activeFlagDSV == true then
          damper.newLSBump = fDamping[2].beamDamp
          damper.newHSBump = fDamping[2].beamDampFast
        else
          damper.newLSBump = damper.orgLSBump
          damper.newHSBump = damper.orgHSBump
        end
      else
        damper.newLSBump = damper.orgLSBump
        damper.newHSBump = damper.orgHSBump
      end

      --apply new damping values
      obj:setBoundedBeamDamp(damper.bCid, damper.newLSBump, damper.newLSRebound, damper.newHSBump, damper.newHSRebound, fDamping[1].beamDampVelocitySplit, fDamping[1].beamDampVelocitySplit) 
      --print(fDampers[1].newLSBump)
      --print(fDampers[1].newHSBump)
      --print((LRSp - springLoad))
      --print(fDampers[1].newHSRebound)
    end     
  end  

  for i, spring in ipairs(rLoads) do
    local springLoad = obj:getBeamLength(spring.bCid) or 0 --get suspension load
    
    if springLoad >= LRSp then 
      spring.activeFlagLRS = true
    else
      spring.activeFlagLRS = false
    end
    if springLoad <= DSVp  then 
      spring.activeFlagDSV = true
    else
      spring.activeFlagDSV = false
    end
    --print(springLoad)
    --print(rLoads[1].activeFlagLRS)
    --print(rLoads[2].activeFlagLRS)

    for i, damper in ipairs(rDampers) do
      if LRS == true then --active LRS
        if rLoads[i].activeFlagLRS == true then 
          --damper.newLSRebound = rDamping[2].beamDampRebound
          damper.newLSRebound = rDamping[2].beamDampRebound
    
          damper.newHSRebound = damper.newLSRebound
        else
          damper.newLSRebound = damper.orgLSRebound
          damper.newHSRebound = damper.orgHSRebound   
        end
      else
        damper.newLSRebound = damper.orgLSRebound
        damper.newHSRebound = damper.orgHSRebound   
      end

      if DSV == true then --active DSV
        if rLoads[i].activeFlagDSV == true then
          damper.newLSBump = rDamping[2].beamDamp
          damper.newHSBump = rDamping[2].beamDampFast
        else
          damper.newLSBump = damper.orgLSBump
          damper.newHSBump = damper.orgHSBump
        end
      else
        damper.newLSBump = damper.orgLSBump
        damper.newHSBump = damper.orgHSBump
      end

      --apply new damping values
      obj:setBoundedBeamDamp(damper.bCid, damper.newLSBump, damper.newLSRebound, damper.newHSBump, damper.newHSRebound, rDamping[1].beamDampVelocitySplit, rDamping[1].beamDampVelocitySplit) 
      --print(rDampers[1].newLSBump)
      --print(rDampers[1].newHSBump)
      --print((LRSp - springLoad))
      --print(rDampers[1].newLSRebound)
    end
  end  
end

local function reset()
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
      activeFlagLRS = false,
      activeFlagDSV = false,
    }
    table.insert(fLoads, fl)
  end

  local rSpring = tableFromHeaderTable(jbeamData.rLoads or {})
  for _, loads in pairs(rSpring) do
    local bCid = beamNameTable[loads.beamName]
    local rl = {
      name = loads.name,
      bCid = bCid,
      activeFlagLRS = false,
      activeFlagDSV = false,
    }
    table.insert(rLoads, rl)
  end
  
  local fLRS = tableFromHeaderTable(jbeamData.fDampers or {}) --call out damper in Jbeam
  for _, damper in pairs(fLRS) do
    local bCid = beamNameTable[damper.beamName]
    local fd = {
      name = damper.name,
      bCid = bCid,
      orgLSBump = fDamping[1].beamDamp,
      orgHSBump = fDamping[1].beamDampFast,
      orgLSRebound = fDamping[1].beamDampRebound,
      orgHSRebound = fDamping[1].beamDampReboundFast,
      newLSBump = fDamping[2].beamDamp,
      newHSBump = fDamping[2].beamDampFast,
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
      orgLSBump = rDamping[1].beamDamp,
      orgHSBump = rDamping[1].beamDampFast,
      orgLSRebound = rDamping[1].beamDampRebound,
      orgHSRebound = rDamping[1].beamDampReboundFast,
      newLSBump = rDamping[2].beamDamp,
      newHSBump = rDamping[2].beamDampFast,
      newLSRebound = rDamping[2].beamDampRebound,
      newHSRebound = rDamping[2].beamDampReboundFast,
    }
    table.insert(rDampers, rd)
  end

  --LRS and DSV active
  if jbeamData.LRS then 
    LRS = jbeamData.LRS
  else
    LRS = false
  end

  if jbeamData.DSV then 
    DSV = jbeamData.DSV
  else
    DSV = false
  end

  --get active point
  LRSp = jbeamData.LRSp or 0
  DSVp = jbeamData.DSVp or 0

  --printTable(fDampers)
  --printTable(fLoads)
  printTable(fDamping)
  
  --printTable(rDampers)
  --printTable(rLoads)
  printTable(rDamping)
end

local function initLastStage()
end

local function reset()
end

M.init = init
M.reset = reset
M.update = update

return M