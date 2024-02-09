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
local maxKnee = 0
local throttleRatio = 0
local brakeRatio = 0
local newLockCoef = 0
local rearBias = 0

local function updateWheelsIntermediate()
  
  --get input value
  local throttle = electrics.values['throttle_input']
  local brake = electrics.values['brake_input']
  local steer = electrics.values['steering_input']
  local lockRange = 0

  --get lock range
  maxLockCoef = transfercase.lsdLockCoef
  minLockCoef = transfercase.lsdRevLockCoef
  maxKnee = transfercase.lsdPreload
  throttleRatio = transfercase.diffTorqueSplitA
  brakeRatio = transfercase.diffTorqueSplitB

  if minLockCoef - maxLockCoef < 0 then --make sure min is larger than max
    lockRange = 1
  else
    lockRange = abs(maxLockCoef - minLockCoef) 
  end

  --calculate new lock coef and bias
  local normalSteer = abs(steer) --make value 0 to 1
  local normalThrottle = abs(throttle*throttleRatio*2-brake*brakeRatio*2) --make value 0 to 1
  local contributionThrottle = max(0, min(lockRange*normalThrottle*(1/maxKnee) + minLockCoef, maxLockCoef))
  local contributionSteer = lockRange*normalSteer + minLockCoef
  local lockEffect = max(0, min(contributionThrottle-contributionSteer, lockRange))
  newLockCoef = minLockCoef + lockEffect
  rearBias = 0.556 + normalSteer*0.244

  --apply values to diff
  transfercase.lsdLockCoef = newLockCoef
  transfercase.lsdRevLockCoef = minLockCoef
  transfercase.diffTorqueSplitA = 1 - transfercase.diffTorqueSplitB
  transfercase.diffTorqueSplitB = rearBias
  transfercase.lsdPreload = 20

  --handbrake
  if input.parkingbrake > 0.5 then
    transfercase.lsdLockCoef = 0
  end  
end

local function init(jbeamData)
  transfercase = powertrain.getDevice(jbeamData.transfercaseName)
  M.updateWheelsIntermediate = updateWheelsIntermediate
  M.updateGFX = updateGFX
end

M.init = init
M.updateWheelsIntermediate = nil
M.updateGFX = nil

return M
