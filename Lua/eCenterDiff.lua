-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}
M.type = "auxilliary"
M.relevantDevice = "transfercase"

local abs = math.abs
local min = math.min
local max = math.max

local transfercase = nil
local maxLockCoef = 0
local minLockCoef = 0
local newLockCoef = 0
local oldLockCoef = 0
local rearBias = 0

local function updateWheelsIntermediate()
  if transfercase then --get input value
    local throttle = electrics.values['throttle_input']
    local brake = electrics.values['brake_input']
    local steer = electrics.values['steering_input']
    
    --get lock range
    maxLockCoef = transfercase.lsdLockCoef
    minLockCoef = transfercase.lsdRevLockCoef
    if minLockCoef - maxLockCoef < 0 then --make sure min is larger than max
      local lockRange = 1
    else
      local lockRange = abs(maxLockCoef - minLockCoef) 
    end
    
    --calculate new lock coef and bias
    local normalSteer = abs(steer) --make value 0 to 1
    local normalThrottle = abs(throttle-brake) --make value 0 to 1
    local contributionThrottle = lockRange*normalThrottle + minLockCoef
    local contributionSteer = lockRange*normalSteer + minLockCoef
    local lockEffect = max(0,min(contributionThrottle-contributionSteer,lockRange))
    newLockCoef = minLockCoef + lockEffect
    rearBias = 0.5 + normalSteer*0.2

    --apply values to diff
    transfercase.lsdLockCoef = newLockCoef
    transfercase.lsdRevLockCoef = minLockCoef
    transfercase.diffTorqueSplitA = rearBias
    transfercase.diffTorqueSplitB = 1 - rearBias
  end
end

local function init(jbeamData)
  transfercase = powertrain.getDevice(jbeamData.transfercaseName)
  if transfercase then
    oldLockCoef = transfercase.lsdLockCoef
    M.updateWheelsIntermediate = updateWheelsIntermediate
    M.updateGFX = updateGFX
  end
end

M.init = init
M.updateWheelsIntermediate = nil
M.updateGFX = nil

return M