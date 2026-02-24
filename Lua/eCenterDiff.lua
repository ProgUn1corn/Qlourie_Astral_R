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
local clutchRatioSmoother = newTemporalSmoothingNonLinear(16, 6)

--active values
local throttle = 0
local brake = 0
local steer = 0
local speed = 0
local steerRatio = 0
local speedMap = 0
local throttleRatio = 0
local throttleStart = 0
local brakeRatio = 0
local brakeStart = 0
local lbThreshold = 0 --left foot
local lbThrottleGain = 0 --left foot
local lbBrakeGain = 0 --left foot
local coastStart = 0

--passive values
local maxLockCoef = 0

--PEAL values

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
    --get input value
    throttle = electrics.values['throttle_input'] or 0
    brake = electrics.values['brake_input'] or 0
    steer = electrics.values['steering_input'] or 0
    speed = electrics.values.wheelspeed * 3.6 or 0
    
    --steering contribution with countersteer control and speed map
    local lockRange = 0
    local xLockCoef = 0
    local contributionSteer = 0
    local normalSteer = abs(steer) --make value 0 to 1
    local clampSpeed = clamp(speed, 0, 140) --make speed-steer factor only affect 0-140 km/h
    local yaw = obj:getYawAngularVelocity() --left is positive
    
    if yaw > 0.15 then --calculate steering contribution
      if steer * yaw < 0 then
        --contributionSteer = 0
      else
        lockRange = 1 - minLockCoef
        contributionSteer = clamp(lockRange * normalSteer * steerRatio, 0, 1) 
      end
    else
      lockRange = 1 - minLockCoef
      contributionSteer = clamp(lockRange * normalSteer * steerRatio, 0, 1)
    end

    local speedFactor = clamp(1 - 0.9 * (clampSpeed / 140) * (-speedMap / 2000), 0.1, 1)
    xLockCoef = contributionSteer * speedFactor
    --print(xLockCoef)
    --print(speedFactor)

    --Brake and throttle contribution with left foot factor
    local activeMap = "coast"
    local yLockCoef = 0
    local preloadAdj = 0
    local throttleNormalized = 0
    local brakeNormalized = 0

    if throttle <= coastStart and brake <= coastStart then
        activeMap = "coast"
    elseif throttle > brake then
        activeMap = "throttle"
    else
        activeMap = "brake"
    end
   --print(activeMap)
    
    if activeMap == "throttle" then --calculate throttle lock map using torsen (clutch-type)
      if throttleRatio - throttleStart <= 0 then
        yLockCoef = 1
        preloadAdj = 0
      else
        lockRange = 1 - minLockCoef
        throttleNormalized = (throttle - throttleStart) / (throttleRatio - throttleStart)
        local contributionThrottle = lockRange * throttleNormalized + minLockCoef
        yLockCoef = clamp(contributionThrottle - xLockCoef, minLockCoef, 1)
        preloadAdj = 0
      end
    elseif activeMap == "brake" then --calculate brake lock map additionally added with preload
      if brakeRatio - brakeStart <= 0 then
        yLockCoef = 1
        preloadAdj = preload * yLockCoef
      else
        lockRange = 1 - minLockCoef
        brakeNormalized = (brake - brakeStart) / (brakeRatio - brakeStart)
        local contributionBrake = lockRange * brakeNormalized + minLockCoef
        yLockCoef = clamp(contributionBrake - xLockCoef, minLockCoef, 1)
        preloadAdj = preload * yLockCoef - xLockCoef
      end
    elseif activeMap == "coast" then --apply coast map
      lockRange = 1 - minLockCoef
      yLockCoef = minLockCoef
      preloadAdj = preload * minLockCoef  * (1 - xLockCoef)  / finalDrive
    end

    local lbMap = throttle > coastStart and brake > coastStart --left foot
    local lbGain = 0
    local yLockLbReduction = 0
    local preloadLbReduction = 0
    
    if lbMap then 
      local lbInput
      if activeMap == "throttle" then
        lbInput = brake
        lbGain = lbBrakeGain
      elseif activeMap == "brake" then
        lbInput = throttle
        lbGain = lbThrottleGain
      elseif activeMap == "coast" then
        lbInput = nil
        lbGain = nil
      end

      if lbInput and lbGain then
        local lbInputNorm = clamp((lbInput - lbThreshold) / (1 - lbThreshold), 0, 1) 
        yLockLbReduction = lbInputNorm ^ 1.3 * lbGain * 0.4
        preloadLbReduction = lbInputNorm ^ 0.8 * preloadAdj * lbGain
      else
        yLockLbReduction = 0
        preloadLbReduction = 0
      end
      yLockCoef = yLockCoef - yLockLbReduction
      preloadAdj = preloadAdj - preloadLbReduction
    end
    --print(yLockLbReduction)
    --print(preloadLbReduction)

    --sum up X and Y lock factors
    local newLockCoef = clamp(yLockCoef, minLockCoef, 1)
    local newPreload = clamp(preloadAdj, 0, preload)
    --print(newLockCoef)
    --print(newPreload)

    transfercase.speedLimitCoef = 0 -- WHY THIS IS NOT 0 BY DEFAULT?
    local clutchTarget = (handbrake >= hbrelease) and 0 or 1
    local clutchRatio = clutchRatioSmoother:get(clutchTarget, dt)
    clutchRatio = clamp(clutchRatio, 0, 1)
    
    transfercase.lsdLockCoef = newLockCoef * 0.499 * clutchRatio
    transfercase.lsdRevLockCoef = transfercase.lsdLockCoef
    transfercase.diffTorqueSplitA = lerp(0, rearBias, clutchRatio)
    transfercase.diffTorqueSplitB = lerp(1, 1 - rearBias, clutchRatio)
    transfercase.lsdPreload = newPreload * clutchRatio
    --print(transfercase.lsdLockCoef)

  elseif transferType == "Passive" then
    transfercase.speedLimitCoef = 0 -- WHY THIS IS NOT 0 BY DEFAULT?
    local clutchTarget = (handbrake >= hbrelease) and 0 or 1
    local clutchRatio = clutchRatioSmoother:get(clutchTarget, dt)
    clutchRatio = clamp(clutchRatio, 0, 1)

    transfercase.lsdLockCoef = maxLockCoef * clutchRatio
    transfercase.lsdRevLockCoef = minLockCoef * clutchRatio
    transfercase.diffTorqueSplitA = lerp(0, rearBias, clutchRatio)
    transfercase.diffTorqueSplitB = lerp(1, 1 - rearBias, clutchRatio)
    transfercase.lsdPreload = preload * clutchRatio
    --print(transfercase.lsdLockCoef)

  elseif transferType == "PEAL" then
    local clutchTarget = (handbrake >= hbrelease) and 0 or 1 
    local clutchRatio = clutchRatioSmoother:get(clutchTarget, dt)
    clutchRatio = clamp(clutchRatio, 0, 1)
    transfercase.clutchRatio = clutchRatio
    --print(transfercase.clutchRatio)
  end
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
    lbThreshold = jbeamData.lockMap.leftThreshold or 0.10
    lbThrottleGain = jbeamData.lockMap.leftThrottleGain or 1 
    lbBrakeGain = jbeamData.lockMap.leftBrakeGain or 1 
    coastStart = jbeamData.lockMap.coastStart or 0.05
    rearBias = jbeamData.lockMap.rearBias or 0.5
    hbrelease = jbeamData.lockMap.hbRelease or 0.65
    preload = jbeamData.lockMap.preload or 0
    finalDrive = jbeamData.lockMap.finalDrive or 4
    if throttleRatio ~= 0 and throttleRatio - throttleStart <= 0 then
      log("Throttle start point is higher than throttle threshold! Locking center diff...")
    end
    if brakeRatio ~= 0 and brakeRatio - brakeStart <= 0 then
      log("Brake start point is higher than brake threshold! Locking center diff...")
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