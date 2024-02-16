-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt
local M = {}
M.type = "auxilliary"

local abs = math.abs
local min = math.min
local max = math.max

local gMass = {}
local dampers = {}
local orgLSRebound = 0
local orgHSRebound = 0
local newLSRebound = 0
local newHSRebound = 0


function clamp(value, min, max)
  return math.min(math.max(value, min), max)
end

local function updateWheelsIntermediate()
  local restMassLengthR = obj:getBeamLength(gMass[1].bCid)
  local restMassLengthL = obj:getBeamLength(gMass[2].bCid)

  if restMassLengthR > 0.25 then
    obj:setBoundedBeamDamp(dampers[1].bCid, 1500, 1600, 5000, 1600, 0.65, 0.55)
  end

  if restMassLengthL > 0.25 then
    obj:setBoundedBeamDamp(dampers[2].bCid, 1500, 1600, 5000, 1600, 0.65, 0.55)
  end
  --print(restMassLength)
  --for _, v in ipairs(damper) do
  --end
end

local function init(jbeamData)
  local beamNameTable = {}
  for _, b in pairs(v.data.beams) do -- store beam that has name into a table
    if b.name then
      beamNameTable[b.name] = b.cid
    end
  end

  dampers = {}
  local shock = tableFromHeaderTable(jbeamData.dampers or {}) --call out damper in Jbeam
  for _, damperData in pairs(shock) do --store LRS
    local bCid = beamNameTable[damperData.beamName]
    local d = {
      name = damperData.name,
      bCid = bCid,
    }
    table.insert(dampers, d)
  end
  
  
  gMass = {}
  local LRS = tableFromHeaderTable(jbeamData.gmass or {}) --call out LRS in Jbeam
  for _, damperData in pairs(LRS) do --store LRS
    local bCid = beamNameTable[damperData.beamName]
    local l = {
      name = damperData.name,
      bCid = bCid,
      initialBeamLength = obj:getBeamRestLength(beamNameTable[damperData.beamName]),
    }
    table.insert(gMass, l)
  end

  --print(dampers[1].name)
  --print(dampers[2].name)
  --print(gMass[1].name)
  --print(gMass[1].name)

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
