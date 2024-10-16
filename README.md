# Qlourie Astral R
My personal BeamNG mod project with some simple Lua codes.

It comes from Automation, I made the car in Automation and rewrote almost everything's Jbeam by myself so the physics are completely new. The project started at about 2022/7, and this Github repo is created at 2024/1/16.

[2022/07/24](https://www.bilibili.com/video/BV17S4y1E7BH/)
[2022/08/23](https://www.bilibili.com/video/BV1ea41157pe/)

# What Is It
This mod is inspired by the World Rally Championship (WRC). While the vanilla game features the Vivace, it doesn’t fully adhere to the actual WRC regulations concerning aspects such as weight and the center differential, suspension design and WRC aero bodykits. My goal is to craft a WRC car that complies with the 2017-2021 WRC regulations and to simulate the physics with as realistic as possible. This car will participate BRC, BeamNG Rally Championship. At the very least, the suspension system will offer a more authentic feel compared to rally cars in the game.
![Astral_R](Docs/BRC/21.jpg)
![Astral_R](Docs/BRC/4.jpg)
![Astral_R](Docs/BRC/32.jpg)
![Astral_R](Docs/BRC/6.jpg)

Also, there are Rally2 variant and WorldRX RX1 variant, since they share some similarities.
![Astral_R](Docs/Rally2/3.jpg)
![Astral_R](Docs/Rally2/20.jpg)
![Astral_R](Docs/RX1/12.jpg)

# How to Use This Repo
## What's in this repo?
This repo contains engine sound files, all Jbeam files, and Lua files. I will create engine sound with FMOD, update Jbeam files when something is refined, and start to write lua codes for active center differential, launch control and potentially new detection method for LRS.

At the time of 2024/3/21: 

LRS detection is done

Active Center Differential is done

Launch control is BeamNG's vanilla but changed brake trigger to handbrake

## How to make it your mod?
I'm not very familiar with Github, but I know Github can't store empty folders, so maybe it's not the best idea to upload everything because there are lot's of empty folders. The reason I'm using Github is tracking of Jbeam edits and Lua writing. 

However you can update yourself if there's something you want to, manually download files and the folder structure should look like this:

**Configs: BeamNG Userdata\version\mods\unpacked\un1corn_qlourie_astral_r\vehicles\qlourie_astral_r\files**

**Jbeam: BeamNG Userdata\version\mods\unpacked\un1corn_qlourie_astral_r\vehicles\qlourie_astral_r\body and engine\files**

**Lua: BeamNG Userdata\version\mods\unpacked\un1corn_qlourie_astral_r\vehicles\qlourie_astral_r\Lua\files**

**Engine Sound: BeamNG Userdata\version\mods\unpacked\un1corn_qlourie_astral_r\art\sound\blends and engine and shift\files**

Alternatively, you can download releases for pre-release test, and eventually I will upload to BeamNG's mod repo for free.

# Things to Remind
I have a main work and it's quite busy, so I can't take my time fully on this project. As experimenting and testing Jbeam properties are quite heavy work, there are some imperfections. Also, I've found it's not worth to dig deeper with Automation model as there are tons of hassle with opacity map and mesh overlap, this mod will be at where it is. I'm not planning to make the model more detailed or get whole Jbeam design revamped.

However I'm really looking forward to build a new car from the ground up. I'm learning sketching and I plan to make a new car in Blender, at that time it will have it's road counterpart also Rally4, Rally2 variant. I'm really looking forward to it.

Also some fictional lore friendly brands and sponsors! There is actually now in the mod by Automation modders but I'm planning to make my own original sponsors.
![Astral_R](Docs/BRC/9.jpg)
![Astral_R](Docs/BRC/17.jpg)
![Astral_R](Docs/Rally2/4.jpg)

# Features
## Chassis
- Modified chassis for better stability and rigidity, also slightly moved suspension mounting points
- Rollcage installed for maximum safety
- Separated parts from Automation model for better deformation and animation
## Engine and Transmission
- H4DPA 1.6l inline 4, 83.3x73.3, DOHC, direct injection
- H4DPF 2.0l inline 4, 87.8x82.5, DOHC, direct injection
- Realistic engine curve referenced from telemetry of other games
- Top speed around 200 km/h within regulation
- Turbo restrictor and ECU setting for different variant
- Active center differential for BRC variant which respond to throttle, brake, steering inputs and wheel speed
## Suspension
- Front and rear MacPherson Strut suspension
- Reinforced front and rear subframe for stronger rigidity
- Extra long suspension arms for better FVSA length, optimized FVSA for less camber gain
- Calculated suspension geometry for optimal bump steer and toe steer performance
- Front caster adjustable
- Anti-roll bar mounting point adjustable with 3 fixed stiffness ARBs
- 540 degree steering wheel lock
- 10:1, 9:1, 8:1 steering ratio selectable for different driving styles
## Damper and Spring
- Dampers developed with **CTM Racing Suspension**
- Around 800mm gravel damper length, 600mm tarmac damper length
- Fixed damper length, damper length not adjustable for consistent droop travel
- Inverted strut design, 46mm piston diameter, 18mm shaft diameter for better strength
- Spring perch preload adjustment
- Pressurized mono-tube dampers that naturally have a force to push the piston out when no load is applied
- Individually tested spring length when spawning for better spring simulation
- Springs are selected as parts instead of tuning
- Bump velocity threshold (knee point) is moved in response to changes in bump settings, providing a more accurate representation of real-world damper tuning
- Biased to progressive damping with increased damping during HS bump events, enhancing performance and stability to significant impacts in rallying
- LRS (Load Release System): Release rebound damping when wheel load below a set threshold is detected, allowing even higher rebound damping setting with faster wheel contact and all power to the ground. Rebound damping is lowered according to how much force the internal detection mass have. The damping curve is returned to normal is wheel load is above threshold
- DSV (Direction Sensing Valve): Detect the direction of force to the damper, when the force is from the ground like road surface, the damper will remain unchanged for consistency; when the force is from above like landing a jump, the valve will close and add additional damping to brace impact
- HBS (Hydraulic Bump Stop): Additional damping valve that will active at around from the last 60mm of damper travel, the valve is closed to generate a siginificant amount of damping force, up to 24KN of damping force at 2m/s. Smoother ride quality when riding on bump stop and better impact absorption. Rubber bump stop is still installed on HBS model for protection
- HRS (Hydraulic Rebound Stop): A large amount of damping force would generate when the damper is near full droop to stop the damper from extending. Smoother ride quality and extension dynamics compare to rubber rebond stop. Rubber rebound stop is still installed on HRS model for protection
-  Independently modelled suspension mesh instead of Automation one, with flexbody help node to enhances animations

## Misc
- Ballast for center of gravity adjustment (needed to meet minimum running weight regulations)
- Driver weight included in racing seat part
- Rally light for better vision at night events (about 7kg, also act as ballast)
- Up to 2 Spare wheel selection for weight accuracy
![Astral_R](Docs/BRC/28.jpg)
![Astral_R](Docs/BRC/22.jpg)
![Astral_R](Docs/BRC/24.jpg)

# BRC (Formerly WRC and now Rally1)
The pinnacle rallying class which now is anticipating BRC.
![Astral_R](Docs/BRC/1.jpg)
![Astral_R](Docs/BRC/5.jpg)
![Astral_R](Docs/BRC/27.jpg)
![Astral_R](Docs/BRC/11.jpg)
![Astral_R](Docs/BRC/19.jpg)
## Chassis
- Lightweight chassis
- 1190KG minimum measured with only one spare
- 1360KG minimum with driver and co-driver and one spare
- ~1390KG tarmac running weight, ~1415kg gravel running weight (Running weight includes fuel and tools like in real life)
- ~50/50 weight distribution for optimal chassis dynamics
- 4105mm long, 1875mm track width, 2535mm wheelbase
![Astral_R](Docs/BRC/8.jpg)
## Engine and Transmission
- H4DPA with WRC ECU and modification
- 2.5 bar anti-lag turbocharger, 36mm turbo restrictor
- Over 380HP at 6000RPM, 450Nm at 5500RPM (within the 3.1kg/hp regulation)
- 6 speed sequential transmission, paddle shifter
- Adjustable gear ratios
- Top speed 200 km/h (ratio specific)
- Front and rear adjustable mechanical LSD
- 2 homologated active center differential in response to steering and throttle input. Power bias 46/54 for gravel and 36/64 for tarmac. Hydraulic handbrake disengage mechanism
![Astral_R](Docs/BRC/14.jpg)
## Suspension
- 300mm gravel brake disc, 370mm tarmac brake disc
- Adjustable brake bias
- Front and rear selectable ducted brake
![Astral_R](Docs/BRC/29.jpg)
## Damper and Spring
- CTM Racing mono-tube MSR85 and MSR65 3+1Way dampers
- Over 300mm of travel on MSR85, around 220mm of travel on MSR65
- MSR85: LRS, DSV, HBS, HRS, LRS open factor adjustable, HBS damping adjustable
- MSR65: LRS, DSV, HBS, HRS, LRS open factor adjustable, HBS damping adjustable
- HS (High Speed) and LS (Low Speed) bump, rebound, hydraulic bump stop, 3+1 WAY adjustable
- 64 levels of LS bump, 64 levels of rebound, 32 levels of HS bump and 16 levels of hydraulic bump stop adjustment
- Spring rates:
  
  Gravel: 17.5 to 30.0N/mm front, 15.0 to 27.5N/mm rear, incremental difference of 2.5N/mm
![Astral_R](Docs/BRC/25.jpg)
  Tarmac: 35.0 to 60.0N/mm front, 30.0 to 55.0N/mm rear, incremental difference of 5.0N/mm
![Astral_R](Docs/BRC/12.jpg)
  Helper: 2.8N/mm
## Tyres
- 20KG per tarmac wheel and 25kg per gravel wheel
- Node weight calculated based on the rim weight limit (8.6kg and 8.9kg) as specified by WRC regulations
- 205/65 R15 gravel wheels, 235/40 R18 tarmac wheels
- Wheel beam properties are tested and modified to get best performance
![Astral_R](Docs/BRC/13.jpg)
## Aerodynamics
- Front and rear independent aerodynamics
- Front lip and rear diffuser react to ground clearance change
- Two layer WRC style rear wing with winglet attached, 50mm higher than frontal projection and 40mm longer than rear bumper side projection
- Rear wing endplate aerodynamics for better control when sliding
- Total about 390kg of downforce at 200km/h, balance at around 46:54
![Astral_R](Docs/BRC/16.jpg)

# Rally2 (Formerly R5)
The most popular class around the world. 
![Astral_R](Docs/Rally2/1.jpg)
![Astral_R](Docs/Rally2/28.jpg)
![Astral_R](Docs/Rally2/12.jpg)
![Astral_R](Docs/Rally2/11.jpg)
![Astral_R](Docs/Rally2/7.jpg)
## Chassis
- Lightweight chassis (heavier than BRC)
- 1230KG minimum measured with only one spare
- 1390KG minimum with driver and co-driver and one spare wheel 
- ~1420KG tarmac running weight, ~1445kg gravel running weight (Running weight includes fuel and tools like in real life)
- ~52/48 weight distribution for optimal chassis dynamics
- 3985mm long, 1820mm track width, 2535mm wheelbase
- Safari kit including bullbar and snorkel allowed since 2021
![Astral_R](Docs/Rally2/24.png)
## Engine and Transmission
- H4DPA with Rally2 ECU and modification
- 2.5 bar anti-lag turbocharger, 32mm turbo restrictor
- 290HP at 5000RPM, 438Nm at 4500RPM (within the 4.2kg/hp regulation)
- 5 speed sequential transmission, stick shifter
- Adjustable gear ratios
- Top speed 187 km/h (ratio specific)
- Front and rear adjustable mechanical LSD
- Splitshaft transfer case with hydraulic handbrake disengage mechanism
![Astral_R](Docs/Rally2/2.jpg)
## Suspension
- 300mm gravel brake disc, 355mm tarmac brake disc
- Adjustable brake bias
- Front and rear selectable ducted brake
![Astral_R](Docs/Rally2/21.jpg)
## Damper and Spring
- CTM Racing mono-tube MSR80, MSR60 3Way dampers
- Around 310mm of travel on MSR80, around 210mm of travel on MSR60
- MSR80: LRS, HBS, HRS, LRS open factor adjustable,
- MSR60: LRS, HRS, LRS open factor adjustable
- HS (High Speed) and LS (Low Speed) bump, rebound, 3WAY adjustable
- 56 levels of LS bump, 56 levels of rebound, 28 levels of HS bump adjustment
- Spring rates:
  
  Gravel: 19.0 to 29.0N/mm front, 16.0 to 26.0N/mm rear, incremental difference of 2.5N/mm
![Astral_R](Docs/Rally2/16.jpg)
  Tarmac: 38.0 to 58.0N/mm front, 33.0 to 53.0N/mm rear, incremental difference of 5.0N/mm
![Astral_R](Docs/Rally2/5.jpg)
  Safari: 15.5N/mm front, 11.5N/mm rear
![Astral_R](Docs/Rally2/23.png)
  Helper: 2.8N/mm
## Tyres
- 205/65 R15 gravel wheels, 235/40 R18 tarmac wheels
- Wheel beam properties are tested and modified, a little bit less performance than BRC wheels and lower strength
![Astral_R](Docs/Rally2/18.jpg)
## Aerodynamics
- Front and rear independent aerodynamics
- Front lip react to ground clearance change
- One layer Rally2 style rear wing, within the frontal projection of the car
- Total about 130kg of downforce at 200km/h, balance at around 48:52
![Astral_R](Docs/Rally2/14.jpg)

# RX1 (Formerly RX Supercar)
The rallycross beast converted from Rally2.
![Astral_R](Docs/RX1/1.jpg)
![Astral_R](Docs/RX1/7.jpg)
![Astral_R](Docs/RX1/9.jpg)
![Astral_R](Docs/RX1/2.jpg)
![Astral_R](Docs/RX1/5.jpg)
## Chassis
- Rally2 chassis with weight reduction
- 1300KG minimum with driver and fuel, no matter running weight
- ~52/48 weight distribution for optimal chassis dynamics
- 4043mm long, 1850mm track width, 2535mm wheelbase
![Astral_R](Docs/RX1/11.jpg)
## Engine and Transmission
- H4DPF with WRX ECU adn modification
- 3.4 bar anti-lag turbocharger, 45mm turbo restrictor
- 600HP at 6000RPM, 820Nm at 4500RPM, without restrictor over 1000HP and 1500Nm
- 5 speed sequential transmission, stick shifter
- Adjustable gear ratios
- Top speed 203 km/h (ratio specific)
- Front and rear adjustable mechanical LSD
- Mechanical center LSD with maximum power bias of 30/70, hydraulic handbrake disengage mechanism
![Astral_R](Docs/RX1/10.jpg)
## Suspension
- 355mm brake disc
- Adjustable brake bias
- Front and rear selectable ducted brake
![Astral_R](Docs/RX1/8.jpg)
## Damper and Spring
- CTM Racing mono-tube MRX80 3Way damper
- Around 300mm of travel
- MRX80: LRS, HBS, LRS open factor adjustable
- HS (High Speed) and LS (Low Speed) bump, LS rebound, 3WAY adjustable
- 40 levels of LS bump, 40 levels of LS rebound, 32 levels of HS bump adjustment
- Spring rates:

  RX: 36.0N/mm, 40.0N/mm, 44.0N/mm front, 32.0N/mm, 36.0N/mm, 40.0N/mm rear
  ![Astral_R](Docs/RX1/4.jpg)
  Helper: 2.0/m
## Tyres
- 225/640 R17 RX wheels
- Wheel beam properties are tested and modified, biased to sliding performance
![Astral_R](Docs/RX1/3.jpg)
## Aerodynamics
- Front and rear independent aerodynamics
- Front lip react to ground clearance change
- Aero geared to anti-diving when jumping instead of high speed downforce
- Two layer RX style rear wing, within the frontal projection and within the projection of the car seen from above, within the size regulations
- Total about 200kg of downforce at 200km/h, balance at around 52:48
![Astral_R](Docs/RX1/6.jpg)


# Existing Problems (that are mostly not going to be fixed)
- Due to insufficient chassis Jbeam noding, in rare cases you may encounter chassis vibration.
- All colors and materials are none adjustable, the color theme is fixed. (You can manually adjust in Material Editor though, but it's not RGB image so no simple way to change color)
- Due to the way Automation exports (when I exported), all decals and skins are actual models instead of decal image. This means the skin and decal will sometimes clip through car model. Also, it will take more space to load
- Also because of UV is messed, sometimes there are messed up textures due to modified mesh.
- Meshes are still Automation level so it may not be comparable to a full fledged mod
- Flexbody animations are not perfect, especially around engine and transmission, it just works but it's not accurate

 # Gallery 
![Astral_R](Docs/BRC/7.jpg)
![Astral_R](Docs/Rally2/8.jpg)
![Astral_R](Docs/BRC/26.jpg)
![Astral_R](Docs/BRC/2.jpg)
![Astral_R](Docs/Rally2/6.jpg)
![Astral_R](Docs/BRC/33.jpg)
![Astral_R](Docs/BRC/30.jpg)
![Astral_R](Docs/Rally2/19.jpg)
![Astral_R](Docs/BRC/20.jpg)
![Astral_R](Docs/Rally2/9.jpg)
![Astral_R](Docs/BRC/15.jpg)
![Astral_R](Docs/Rally2/17.jpg)
![Astral_R](Docs/BRC/35.jpg)
![Astral_R](Docs/BRC/23.jpg)
![Astral_R](Docs/Rally2/15.jpg)
![Astral_R](Docs/BRC/10.jpg)
![Astral_R](Docs/BRC/3.jpg)
![Astral_R](Docs/Rally2/13.jpg)
![Astral_R](Docs/Rally2/10.jpg)
![Astral_R](Docs/BRC/34.jpg)
![Astral_R](Docs/BRC/18.jpg)
![Astral_R](Docs/BRC/31.jpg)
