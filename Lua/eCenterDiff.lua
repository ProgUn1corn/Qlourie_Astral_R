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
local minLockCoef = 0
local lockRange = 0
local lbLockCoef = 0
local lbThreshold = 0
local throttleRatio = 0
local brakeRatio = 0
local steerRatio = 0
local yLockCoef = 0
local xLockCoef = 0
local rearBias = 0

function clamp(value, min, max)
  return math.min(math.max(value, min), max)
end

local function updateWheelsIntermediate()
  --get input value
  local throttle = electrics.values['throttle_input'] or 0
  local brake = electrics.values['brake_input'] or 0
  local steer = electrics.values['steering_input'] or 0
  local normalSteer = abs(steer) --make value 0 to 1
  
  --calculate steering contribution
  xLockCoef = clamp(lockRange*normalSteer*steerRatio, 0, 1)

  --set different condition flags
  local throttleFlag = 0
  local brakeFlag = 0
  local lbFlag = 0
  local coastFlag = 0
  
  --select different map flags
  if throttle > 0 and brake == 0 then --throttle
    throttleFlag = true
    brakeFlag = false
    lbFlag = false
    coastFlag = false
  end
  
  if throttle == 0 and brake > 0 then --brake
    throttleFlag = false
    brakeFlag = true
    lbFlag = false
    coastFlag = false
  end

  if brake >= lbThreshold and throttle > 0 then --l.foot brake
    throttleFlag = false
    brakeFlag = false
    lbFlag = true
    coastFlag = false
  end

  if throttle == 0 and brake == 0 then --coast
    throttleFlag = false
    brakeFlag = false
    lbFlag = false
    coastFlag = true
  end

  --calculate throttle lock map
  if throttleFlag == true then
    lockRange = 1 - minLockCoef
    local contributionThrottle = clamp(lockRange*throttle*(1/throttleRatio) + minLockCoef, minLockCoef, 1)
    yLockCoef = clamp(contributionThrottle, 0, 1)
  end
  
  --calculate brake lock map
  if brakeFlag == true then
    lockRange = 1 - minLockCoef
    local contributionBrake = clamp(lockRange*brake*(1/brakeRatio) + minLockCoef, minLockCoef, 1)
    yLockCoef = clamp(contributionBrake, 0, 1)
  end

  --calculate left foot brake map
  if lbFlag == true then
    lockRange = lbLockCoef - minLockCoef
    local contributionLfBrake = clamp(lockRange*brake + minLockCoef, minLockCoef, 1)
    yLockCoef = clamp(contributionLfBrake, 0, 1)
  end

  --calculate coast map
  if coastFlag == true then
    lockRange = 1 - minLockCoef
    yLockCoef = minLockCoef
  end
  
  --sum up X and Y lock factors
  local newLockCoef = clamp(yLockCoef - xLockCoef, 0, 1)
  
  --handbrake
  if input.parkingbrake > 0.5 then 
    newLockCoef = 0
  end

  --bias and countersteer control
  local yaw = obj:getYawAngularVelocity() --left is positive
  if steer*yaw < 0 then
    rearBias = 0.5 - normalSteer*steerRatio*0.1
  else
    rearBias = 0.5 + normalSteer*steerRatio*0.25
  end

  --apply values to diff
  transfercase.lsdLockCoef = newLockCoef
  transfercase.lsdRevLockCoef = transfercase.lsdLockCoef
  transfercase.diffTorqueSplitA = 1 - transfercase.diffTorqueSplitB
  transfercase.diffTorqueSplitB = rearBias
  transfercase.lsdPreload = 20
  transfercase.friction = 10
  transfercase.dynamicFriction = 0.0005

  print(transfercase.diffTorqueSplitB)
  --print(transfercase.lsdLockCoef)
  --print(transfercase.lsdPreload)
end

local function init(jbeamData)
  transfercase = powertrain.getDevice(jbeamData.transfercaseName)
 
  --get tuning data
  minLockCoef = transfercase.lsdPreload or 0
  steerRatio = transfercase.diffTorqueSplitA or 0
  throttleRatio = transfercase.lsdLockCoef or 0
  brakeRatio = transfercase.lsdRevLockCoef or 0
  lbLockCoef = transfercase.friction or 0
  lbThreshold = transfercase.dynamicFriction or 0

  M.updateWheelsIntermediate = updateWheelsIntermediate
  M.updateGFX = updateGFX
end

M.init = init
M.reset = nop
M.updateWheelsIntermediate = nil
M.updateGFX = nil

return M
