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

local throttle = 0
local brake = 0
local steer = 0
local speed = 0

local lockMap = {}
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

function clamp(value, min, max)
  return math.min(math.max(value, min), max)
end

function printTable(t, indent)
  indent = indent or ""
  for k, v in pairs(t) do
    if type(v) == "table" then
      print(indent .. "[" .. k .. "] => LockMap:")
      printTable(v, indent .. "  ")
    else
      print(indent .. "[" .. k .. "] => " .. tostring(v))
    end
  end
end

local function updateWheelsIntermediate()
  if transferType == "LSD" then 
    --get input value
    throttle = electrics.values['throttle_input'] or 0
    brake = electrics.values['brake_input'] or 0
    steer = electrics.values['steering_input'] or 0
    speed = electrics.values.wheelspeed*3.6 or 0 --m/s to km/h
    local normalSteer = abs(steer) --make value 0 to 1
    local clampSpeed = clamp(speed, 0, 120) --make speed-steer factor only affect 0-120 km/h
    
    --steering contribution with countersteer control
    local yaw = obj:getYawAngularVelocity() --left is positive
    if steer*yaw < 0 then
      xLockCoef = 0
    else
      xLockCoef = clamp(lockRange*normalSteer*steerRatio, 0, 1) --calculate steering contribution
    end

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
      local contributionLfBrake = clamp(lockRange*abs(throttle-brake) + minLockCoef, minLockCoef, 1)
      yLockCoef = clamp(contributionLfBrake, 0, 1)
    end

    --calculate coast map
    if coastFlag == true then
      lockRange = 1 - minLockCoef
      yLockCoef = minLockCoef
    end
    
    --speed map that only affects steering contribution
    local speedFactor = clamp(clampSpeed*(-9/1200) + 1, 0.1, 1)
    --print(speedFactor)

    --sum up X and Y lock factors
    local newLockCoef = clamp(yLockCoef - xLockCoef*speedFactor, 0, 1)
    
    if input.parkingbrake > 0.5 then 
      transfercase.lsdLockCoef = 0
      transfercase.lsdRevLockCoef = 0
      transfercase.diffTorqueSplitA = rearBias
      transfercase.diffTorqueSplitB = 0
      transfercase.lsdPreload = 0
    else
      transfercase.lsdLockCoef = newLockCoef * 0.5
      transfercase.lsdRevLockCoef = transfercase.lsdLockCoef 
      transfercase.diffTorqueSplitA = 1- rearBias
      transfercase.diffTorqueSplitB = rearBias
      transfercase.lsdPreload = 10
    end
  elseif transferType == "Locked" then
    if input.parkingbrake > 0.5 then 
      transfercase.diffTorqueSplitA = 0.5
      transfercase.diffTorqueSplitB = 0
    else
      transfercase.diffTorqueSplitA = 0.5
      transfercase.diffTorqueSplitB = 0.5
    end
  end
  --print(transfercase.diffTorqueSplitA)
end

local function init(jbeamData)
  transfercase = powertrain.getDevice(jbeamData.transfercaseName)
  transferType = jbeamData.type or 0
  
  --get tuning data
  if transfercase and transferType == "LSD" then 
    lockMap = tableFromHeaderTable(jbeamData.lockMap or {})
    minLockCoef = lockMap[1].minLock
    steerRatio = lockMap[1].steerRatio
    throttleRatio = lockMap[1].lockThrottle
    brakeRatio = lockMap[1].lockBrake
    lbLockCoef = lockMap[1].leftLock
    lbThreshold = lockMap[1].leftThreshold
    rearBias = lockMap[1].rearBias
  end
  
  printTable(lockMap)
  M.updateWheelsIntermediate = updateWheelsIntermediate
  M.updateGFX = updateGFX
end

M.init = init
M.reset = reset
M.updateWheelsIntermediate = nil
M.updateGFX = nil

return M