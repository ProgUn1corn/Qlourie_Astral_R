-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt
local M = {}
M.type = "auxilliary"
M.relevantDevice = "transfercase"

local abs = math.abs
local min = math.min
local max = math.max
local clamp = math.clamp

local transfercase = nil
local maxLockCoef = 0
local minLockCoef = 0
local maxKnee = 0
local throttleRatio = 0
local brakeRatio = 0
local newLockCoef = 0
local newPreload = 0
local rearBias = 0

function clamp(value, min, max)
  return math.min(math.max(value, min), max)
end

local function updateWheelsIntermediate()
  --get input value
  local throttle = electrics.values['throttle_input'] or 0
  local brake = electrics.values['brake_input'] or 0
  local steer = electrics.values['steering_input'] or 0
  local lockRange = 0
  
  if maxLockCoef - minLockCoef < 0 then --make sure min is larger than max
    lockRange = 1
  else
    lockRange = abs(maxLockCoef - minLockCoef) 
  end

  --calculate new lock coef and bias
  local normalSteer = abs(steer) --make value 0 to 1
  local normalThrottle = clamp(abs(throttle*throttleRatio*2-brake*brakeRatio*2), 0, 1) --make value 0 to 1
  local contributionThrottle = clamp(lockRange*normalThrottle*(1/maxKnee) + minLockCoef, minLockCoef, maxLockCoef)
  local contributionSteer = lockRange*normalSteer + minLockCoef
  newLockCoef = clamp(contributionThrottle-(contributionSteer/2) + minLockCoef, 0, maxLockCoef)
  rearBias = 0.556 + normalSteer*0.244
  newPreload = 20
  
  if input.parkingbrake > 0.5 then --handbrake
    transfercase.lsdLockCoef = 0
    transfercase.lsdRevLockCoef = 0
  end

  --countersteer bias controll
  local yaw = obj:getYawAngularVelocity() --left is positive
  if steer*yaw < 0 then
    rearBias = 0.5 - normalSteer*0.2
  end

  --apply values to diff
  transfercase.lsdLockCoef = newLockCoef
  transfercase.lsdRevLockCoef = transfercase.lsdLockCoef
  transfercase.diffTorqueSplitA = 1 - transfercase.diffTorqueSplitB
  transfercase.diffTorqueSplitB = rearBias
  transfercase.lsdPreload = newPreload

  --print(transfercase.diffTorqueSplitB)
  --print(transfercase.lsdLockCoef)
  --print(transfercase.lsdPreload)
end

local function updateGFX(dt)
  
end

local function init(jbeamData)
  transfercase = powertrain.getDevice(jbeamData.transfercaseName)
 
  --get lock range
  maxLockCoef = transfercase.lsdLockCoef
  minLockCoef = transfercase.lsdRevLockCoef
  maxKnee = transfercase.lsdPreload
  throttleRatio = transfercase.diffTorqueSplitA
  brakeRatio = transfercase.diffTorqueSplitB

  M.updateWheelsIntermediate = updateWheelsIntermediate
  M.updateGFX = updateGFX
end

M.init = init
M.reset = nop
M.updateWheelsIntermediate = nil
M.updateGFX = nil

return M
