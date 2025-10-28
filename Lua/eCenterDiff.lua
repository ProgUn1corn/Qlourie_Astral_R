-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt
local M = {}
M.type = "auxilliary"
M.relevantDevice = "transfercase"

--math
local abs = math.abs
local min = math.min
local max = math.max
local clamp = math.clamp

local lockMap = {}
local transfercase = nil
local preload = 0

--common values
local minLockCoef = 0
local hbrelease = 0
local newPreload = 0
local rearBias = 0

--active values
local steerRatio = 0
local speedMap = 0
local throttleRatio = 0
local throttleStart = 0
local brakeRatio = 0
local brakeStart = 0
local lbLockCoef = 0  --l.foot
local lbThreshold = 0 --l.foot

--passive values
local maxLockCoef = 0

function clamp(value, min, max)
  return math.min(math.max(value, min), max)
end

local function updateWheelsIntermediate(dt)
  --print("THICC")
  --common detecion variables
  local handbrake = 0
  local clutch = 0
  handbrake = electrics.values['parkingbrake_input'] or 0 
  clutch = electrics.values['clutch'] or 0 

  if transferType == "Active" then 
    local throttle = 0
    local brake = 0
    local steer = 0
    local speed = 0
    --get input value
    throttle = electrics.values['throttle_input'] or 0
    brake = electrics.values['brake_input'] or 0
    steer = electrics.values['steering_input'] or 0
    speed = electrics.values.wheelspeed*3.6 or 0 --m/s to km/h
    local normalSteer = abs(steer) --make value 0 to 1
    local clampSpeed = clamp(speed, 0, 140) --make speed-steer factor only affect 0-140 km/h

    local yLockCoef = 0
    local xLockCoef = 0
    local preloadAdj = 0
    local lockRange = 0
    local throttleNormalized = 0
    local brakeNormalized = 0

    --steering contribution with countersteer control
    local yaw = obj:getYawAngularVelocity() --left is positive
    if yaw > 0.15 then 
      if steer * yaw < 0 then
        xLockCoef = 0
      else
        lockRange = 1 - minLockCoef
        xLockCoef = clamp(lockRange * normalSteer * steerRatio, 0, 1) --calculate steering contribution
      end
    else
      lockRange = 1 - minLockCoef
      xLockCoef = clamp(lockRange * normalSteer * steerRatio, 0, 1)
    end
    --print(xLockCoef)

    --speed map that only affects steering contribution
    local speedFactor = clamp(clampSpeed * (-9 / speedMap) + 1, 0.1, 1)
    --print(speedFactor)

    --set different condition flags
    local throttleFlag = 0
    local brakeFlag = 0
    local lbFlag = 0
    local coastFlag = 0
    
    --select different map flags
    if throttle > 0 and brake <= lbThreshold then --throttle
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

    --calculate throttle lock map using torsen
    if throttleFlag == true then
      if throttleRatio - throttleStart <= 0 then
        yLockCoef = 1
        preloadAdj = 0
      else
        lockRange = 1 - minLockCoef
        throttleNormalized = (throttle - throttleStart) / (throttleRatio - throttleStart)
        local contributionThrottle = lockRange * throttleNormalized + minLockCoef
        yLockCoef = clamp(contributionThrottle, minLockCoef, 1)
        preloadAdj = 0
      end
    end
    
    --calculate brake lock map using preload
    if brakeFlag == true then
      if brakeRatio - brakeStart <= 0 then
        yLockCoef = 1
        preloadAdj = preload * yLockCoef
      else
        lockRange = 1 - minLockCoef
        brakeNormalized = (brake - brakeStart) / (brakeRatio - brakeStart)
        local contributionBrake = lockRange * brakeNormalized + minLockCoef
        yLockCoef = clamp(contributionBrake, minLockCoef, 1)
        preloadAdj = preload * yLockCoef
      end
    end

    --calculate left foot brake map
    if lbFlag == true then
      lockRange = lbLockCoef - minLockCoef
      local contributionLfBrake = clamp(lockRange * abs(throttle-brake) + minLockCoef, minLockCoef, 1)
      yLockCoef = clamp(contributionLfBrake, 0, 1)
      preloadAdj = preload * minLockCoef / (yLockCoef / lbLockCoef)
    end

    --calculate coast map
    if coastFlag == true then
      lockRange = 1 - minLockCoef
      yLockCoef = minLockCoef
      preloadAdj = preload * minLockCoef * minLockCoef * (1 - xLockCoef * speedFactor) 
    end
    --print(yLockCoef)
    --print(preloadAdj)

    --sum up X and Y lock factors
    local newLockCoef = clamp(yLockCoef - xLockCoef * speedFactor, minLockCoef, 1)
    local newPreload = clamp(preloadAdj, 0, preload)
    --print(newLockCoef)
    --print(newPreload)
    
    if handbrake >= hbrelease then 
      transfercase.lsdLockCoef = 0
      transfercase.lsdRevLockCoef = 0
      transfercase.diffTorqueSplitA = 0
      transfercase.diffTorqueSplitB = 1
      transfercase.lsdPreload = 0
    else
      transfercase.lsdLockCoef = newLockCoef * 0.486
      transfercase.lsdRevLockCoef = transfercase.lsdLockCoef 
      transfercase.diffTorqueSplitA = rearBias
      transfercase.diffTorqueSplitB = 1 - rearBias
      transfercase.lsdPreload = newPreload
    end
  elseif transferType == "Passive" then
    if handbrake >= hbrelease then 
      transfercase.lsdLockCoef = 0
      transfercase.lsdRevLockCoef = 0
      transfercase.diffTorqueSplitA = 0
      transfercase.diffTorqueSplitB = 1
      transfercase.lsdPreload = 0
    else
      transfercase.lsdLockCoef = maxLockCoef
      transfercase.lsdRevLockCoef = minLockCoef
      transfercase.diffTorqueSplitA = rearBias
      transfercase.diffTorqueSplitB = 1 - rearBias
      transfercase.lsdPreload = preload
    end
  end
  --print(transfercase.lsdPreload)
  --print(transfercase.lsdLockCoef)
end

local function init(jbeamData)
  transfercase = powertrain.getDevice(jbeamData.transfercaseName)
  transferType = jbeamData.type or 0
  
  --get tuning data for active
  if transfercase and transferType == "Active" then 
    lockMap = tableFromHeaderTable(jbeamData.lockMap or {})
    minLockCoef = lockMap[1].minLock or 0
    steerRatio = lockMap[1].steerRatio or 0
    speedMap = lockMap[1].speedMap or 0
    throttleRatio = lockMap[1].lockThrottle or 0 
    throttleStart = lockMap[1].lockThrottleStart or 0 
    brakeRatio = lockMap[1].lockBrake or 0
    brakeStart = lockMap[1].lockBrakeStart or 0
    lbLockCoef = lockMap[1].leftLock or 0
    lbThreshold = lockMap[1].leftThreshold or 0
    rearBias = lockMap[1].rearBias or 0
    hbrelease = lockMap[1].hbRelease or 0
    preload = lockMap[1].preload or 0
    if throttleRatio ~= 0 and throttleRatio - throttleStart <= 0 then
      print("Throttle start point is higher than throttle threshold! Locking center diff...")
    end
    if brakeRatio ~= 0 and brakeRatio - brakeStart <= 0 then
      print("Brake start point is higher than brake threshold! Locking center diff...")
    end
  end
  

  --get tuning data for passive
  if transfercase and transferType == "Passive" then 
    lockMap = tableFromHeaderTable(jbeamData.lockMap or {})
    maxLockCoef = lockMap[1].lock or 0
    minLockCoef = lockMap[1].revLock or 0
    preload = lockMap[1].preload or 0
    rearBias = lockMap[1].rearBias or 0
    hbrelease = lockMap[1].hbRelease or 0
  end
  --print(rearBias)
  --printTable(lockMap)
  M.updateWheelsIntermediate = updateWheelsIntermediate
end

M.init = init
M.reset = reset
M.updateWheelsIntermediate = nil

return M