-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt
local M = {}
M.type = "auxilliary"

local tMap = nil
local throttle = nil
local newThrottle = nil

--throttle map slope
local a = nil  --a is alpha to linear
local k = nil  --k is slope of log curve

local function calculateThrottleMap(x, y, z)
  return (1 - y) * ((math.log(1 + z * x)) / (math.log(1 + z))) + (y * x)
end

local function updateWheelsIntermediate(dt) 
  --get input value
  throttle = electrics.values['throttle_input'] or 0

  --digressive map
  if tMap == 1 then
    a = 0.18
    k = 6.6 
    newThrottle = calculateThrottleMap(throttle, a, k)
  end

  --digressive + linear map
  if tMap == 2 then
    a = 0.35
    k = 3.7
    newThrottle = calculateThrottleMap(throttle, a, k)
  end
  
  --progressive map (used in really precise situations)
  if tMap == 3 then
    a =  0.4
    k = -0.68
    newThrottle = calculateThrottleMap(throttle, a, k)
  end

  --apply throttle map
  electrics.values.throttle = newThrottle 
  print(newThrottle)
end

local function init(jbeamData)
  --get map number
  tMap = (jbeamData.tMap) or nil
  --print(tMap)
  M.updateWheelsIntermediate = updateWheelsIntermediate
end

M.init = init
M.reset = reset
M.updateWheelsIntermediate = nil

return M