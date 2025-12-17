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

local transfercase = nil
local preload = 0

--common values
local minLockCoef = 0
local hbrelease = 0
local newPreload = 0
local rearBias = 0
local finalDrive = 0

--active values
local steerRatio = 0
local speedMap = 0
local throttleRatio = 0
local throttleStart = 0
local brakeRatio = 0
local brakeStart = 0
local lbLockCoef = 0  --l.foot
local lbThreshold = 0 --l.foot
local coastStart = 0

--passive values
local maxLockCoef = 0

function clamp(value, min, max)
  return math.min(math.max(value, min), max)
end

local function updateFixedStep(dt)
  --print("THICC")
  --common detecion variables
  local handbrake = 0
  local clutch = 0
  handbrake = electrics.values['parkingbrake_input'] or 0 
  clutch = electrics.values['clutch'] or 0 

  if transferType == "Active" then 
    transfercase.speedLimitCoef = 0 -- WHY THIS IS NOT 0 BY DEFAULT?

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
    local speedFactor = clamp(1 - 0.9 * (clampSpeed / 140) * (speedMap / 2000), 0.1, 1)
    --print(speedFactor)

    --set different condition flags
    local throttleFlag = 0
    local brakeFlag = 0
    local lbFlag = 0
    local coastFlag = 0
    
    --select different map flags
    if throttle >= coastStart and brake <= lbThreshold then --throttle
      throttleFlag = true
      brakeFlag = false
      lbFlag = false
      coastFlag = false
    end
    
    if throttle <= coastStart and brake >= coastStart then --brake
      throttleFlag = false
      brakeFlag = true
      lbFlag = false
      coastFlag = false
    end

    if brake >= lbThreshold and throttle >= coastStart then --l.foot brake
      throttleFlag = false
      brakeFlag = false
      lbFlag = true
      coastFlag = false
    end

    if throttle <= coastStart and brake <= coastStart then --coast
      throttleFlag = false
      brakeFlag = false
      lbFlag = false
      coastFlag = true
    end

    --calculate throttle lock map using torsen (clutch-type)
    if throttleFlag == true then
      if throttleRatio - throttleStart <= 0 then
        yLockCoef = 1
        preloadAdj = 0
      else
        lockRange = 1 - minLockCoef
        throttleNormalized = (throttle - throttleStart) / (throttleRatio - throttleStart)
        local contributionThrottle = lockRange * throttleNormalized + minLockCoef
        yLockCoef = clamp(contributionThrottle - xLockCoef * speedFactor, minLockCoef, 1)
        preloadAdj = 0
      end
    end
    
    --calculate brake lock map additionally added with preload
    if brakeFlag == true then
      if brakeRatio - brakeStart <= 0 then
        yLockCoef = 1
        preloadAdj = preload * yLockCoef
      else
        lockRange = 1 - minLockCoef
        brakeNormalized = (brake - brakeStart) / (brakeRatio - brakeStart)
        local contributionBrake = lockRange * brakeNormalized + minLockCoef
        yLockCoef = clamp(contributionBrake - xLockCoef, minLockCoef, 1)
        preloadAdj = preload * yLockCoef - xLockCoef * speedFactor
      end
    end

    --calculate left foot brake map
    if lbFlag == true then
      lockRange = lbLockCoef - minLockCoef
      local contributionLfBrake = clamp(lockRange * abs(throttle-brake) + minLockCoef, minLockCoef, 1)
      yLockCoef = clamp(contributionLfBrake - xLockCoef * speedFactor, 0, 1)
      if brake >= 0.5 then
        preloadAdj = preload * minLockCoef / (yLockCoef * 2 / lbLockCoef) - xLockCoef * speedFactor
      else
        preloadAdj = 0
      end
    end

    --calculate coast map
    if coastFlag == true then
      lockRange = 1 - minLockCoef
      yLockCoef = minLockCoef
      preloadAdj = preload * minLockCoef  * (1 - xLockCoef)  / finalDrive
    end
    --print(yLockCoef)
    --print(preloadAdj)

    --sum up X and Y lock factors
    local newLockCoef = clamp(yLockCoef, minLockCoef, 1)
    local newPreload = clamp(preloadAdj, 0, preload)
    --print(newLockCoef)
    --print(newPreload)
    
    if handbrake >= hbrelease then 
      transfercase.speedLimitCoef = 0
      transfercase.lsdLockCoef = 0
      transfercase.lsdRevLockCoef = 0
      transfercase.diffTorqueSplitA = 0
      transfercase.diffTorqueSplitB = 1
      transfercase.lsdPreload = 0
    else
      transfercase.lsdLockCoef = newLockCoef * 0.4986
      transfercase.lsdRevLockCoef = transfercase.lsdLockCoef 
      transfercase.diffTorqueSplitA = rearBias
      transfercase.diffTorqueSplitB = 1 - rearBias
      transfercase.lsdPreload = newPreload
    end
    
  elseif transferType == "Passive" then
    transfercase.speedLimitCoef = 0 -- WHY THIS IS NOT 0 BY DEFAULT?

    if handbrake >= hbrelease then 
      transfercase.speedLimitCoef = 0
      transfercase.lsdLockCoef = 0
      transfercase.lsdRevLockCoef = 0
      transfercase.diffTorqueSplitA = 0
      transfercase.diffTorqueSplitB = 1
      transfercase.lsdPreload = 0
      --electrics.values.clutchRatio = 0
    else
      transfercase.lsdLockCoef = maxLockCoef
      transfercase.lsdRevLockCoef = minLockCoef
      transfercase.diffTorqueSplitA = rearBias
      transfercase.diffTorqueSplitB = 1 - rearBias
      transfercase.lsdPreload = preload
    end

  elseif transferType == "PEAL" then
    if handbrake >= hbrelease then 
      transfercase.clutchRatio = 0
    else
      transfercase.clutchRatio = 1
    end
  end
  --print(transfercase.speedLimitCoef)
  --print(transfercase.lsdLockCoef)
end

local function init(jbeamData)
  transfercase = powertrain.getDevice(jbeamData.transfercaseName)
  transferType = jbeamData.type or 0
  
  --get tuning data for active
  if transfercase and transferType == "Active" then 
    minLockCoef = jbeamData.lockMap.minLock or 0.1
    steerRatio = jbeamData.lockMap.steerRatio or 1
    speedMap = jbeamData.lockMap.speedMap or 0
    throttleRatio = jbeamData.lockMap.lockThrottle or 0.8 
    throttleStart = jbeamData.lockMap.lockThrottleStart or 0.25 
    brakeRatio = jbeamData.lockMap.lockBrake or 0.8
    brakeStart = jbeamData.lockMap.lockBrakeStart or 0.25
    lbLockCoef = jbeamData.lockMap.leftLock or 0.8
    lbThreshold = jbeamData.lockMap.leftThreshold or 0.25
    coastStart = jbeamData.lockMap.coastStart or 0.05
    rearBias = jbeamData.lockMap.rearBias or 0.5
    hbrelease = jbeamData.lockMap.hbRelease or 0.65
    preload = jbeamData.lockMap.preload or 0
    finalDrive = jbeamData.lockMap.finalDrive or 4
    if throttleRatio ~= 0 and throttleRatio - throttleStart <= 0 then
      print("Throttle start point is higher than throttle threshold! Locking center diff...")
    end
    if brakeRatio ~= 0 and brakeRatio - brakeStart <= 0 then
      print("Brake start point is higher than brake threshold! Locking center diff...")
    end
  end

  --get tuning data for passive
  if transfercase and transferType == "Passive" then 
    maxLockCoef = jbeamData.lockMap.lock or 0.25
    minLockCoef = jbeamData.lockMap.revLock or 0.25
    preload = jbeamData.lockMap.preload or 0
    rearBias = jbeamData.lockMap.rearBias or 0.5
    hbrelease = jbeamData.lockMap.hbRelease or 0.65
  end

  --get tuning data for PEAL
  if transfercase and transferType == "PEAL" then 
    hbrelease = jbeamData.hbRelease or 0.65
  end
end

M.init = init
M.updateFixedStep = updateFixedStep

return M