# Qlourie_Astral_R
My personal BeamNG mod project with some simple Lua codes.

It comes from Automation, I made the car in Automation and rewrote almost everything's Jbeam by myself so the physics are completely new. The project started at about 2022/7, and this Github repo is created at 2024/1/16.

[2022/07/24](https://www.bilibili.com/video/BV17S4y1E7BH/)
[2022/08/23](https://www.bilibili.com/video/BV1ea41157pe/)

# What Is It
This mod is inspired by the World Rally Championship (WRC). While the vanilla game features the Vivace, it doesn’t fully adhere to the actual WRC regulations concerning aspects such as weight and the center differential, and real WRC bodykits. My goal is to craft a WRC car that complies with the 2017-2021 WRC regulations and to simulate the physics with as realistic as possible. At the very least, the suspension system will offer a more authentic feel compared to rally cars in the game.

![Astral_R](Docs/2.jpg)

# How to Use This Repo
## What's in this repo?
This repo contains engine sound files, all Jbeam files, and Lua files. I will create engine sound with FMOD, update Jbeam files when something is refined, and start to write lua codes for active center differential, launch control and potentially new detection method for LRS.
## How to make it your mod?
I'm not very familiar with Github, but I know Github can't store empty folders, so maybe it's not the best idea to upload everything because there are lot's of empty folders. The reason I'm using Github is tracking of Jbeam edits and Lua writing. 

However you can update yourself if there's something you want to, manually download files and the folder structure should look like this:

**Configs: BeamNG Userdata\version\mods\unpacked\un1corn_qlourie_astral_r\vehicles\qlourie_astral_r\files**

**Jbeam: BeamNG Userdata\version\mods\unpacked\un1corn_qlourie_astral_r\vehicles\qlourie_astral_r\body and engine\files**

**Lua: BeamNG Userdata\version\mods\unpacked\un1corn_qlourie_astral_r\vehicles\qlourie_astral_r\Lua\files**

**Engine Sound: BeamNG Userdata\version\mods\unpacked\un1corn_qlourie_astral_r\art\sound\blends and engine and shift\files**

Alternatively, you can download releases for pre-release test, and eventually I will upload to BeamNG's mod repo for free.

# Things to Remind
I have a main work and it's quite busy, so I can't take my time fully on this project. As experimenting and testing Jbeam properties are quite heavy work, there are some imperfections. Also, I've found it's not worth to dig deeper with Automation model as there are tons of hassle with opacity map and mesh overlap, this mod will be at where it is. I'm not planning to make the model more detailed or get Jbeam revamped.

However I'm really looking forward to build a new car from the ground up. I'm learning sketching and I plan to make a new car in Blender, at that time it will have it's road counterpart and Rally4, Rally2 variant. I'm really looking forward to it.

2024/01/20: I have rebuilt front bumper mesh and opacity map, so probably I will make a Rally2 variant.

Also some fiction brands and sponsors! There is actually now in the mod but I'm planning to make my own original sponsors.
![Astral_R](Docs/1.jpg)

# Features
## Chassis
- Modified chassis for better stability and rigidity, also slightly moved suspension mounting points
- 2.565m wheelbase and 1.875m track width
- 1190KG without crew and spare wheel
- 1360KG with driver and co-driver and one spare wheel
- Rollcage installed for maximum safety
- Separated parts from Automation model for better deformation and animation
## Engine and Transmission
- 380HP at 6500RPM, 430Nm at 5000-6000RPM
- 2.5 bar anti-lag turbocharger
- 6 speed sequential transmission
- Front and rear adjustable final ratio
- Fully adjustable gear ratios
- Top speed 201 km/h
- Front and rear adjustable LSD
- Active center differential in response to steering and throttle input (**WIP**)
- Steering wheel and pedal shifter animation
## Suspension
- Front and rear MacPherson Strut suspension
- Reinforced front and rear subframe for stronger rigidity
- Extra long suspension arms for better FVSA length, optimized FVSA for less camber change
- Calculated suspension geometry for optimal performance, minimized bump steer and toe steer
- 540 degree steering wheel
- 8:1 quick steering ratio with maximum wheel angle of 33 degree
- 300mm gravel brake disc, 370mm tarmac brake disc
- Front and rear ducted brake
## Damper and Spring
- Dampers developed with **CTM Racing Suspension**
- 800mm gravel damper length, 600mm tarmac damper length
- Independently modelled mesh with flexbody help to enhances animations
- over 320mm of travel on gravel damper
- HS (High Speed) and LS (Low Speed) bump, rebound, hydraulic bump stop, 3+1 WAY adjustable
- 32 levels of HS and LS bump, 32 levels of rebound, 16 levels or hydraulic bump stop adjustment
- Bump velocity threshold (knee point) is moved in response to changes in fast and slow bump settings, providing a more accurate representation of real-world damper tuning
- Progressive damping with increased damping during fast bump events, enhancing absorption of significant impacts in rallying
- LRS (Load Release System) implemented for faster wheel extension when no load is applied to the wheel (**need refinement**)
- Spring rates:

  Gravel: 17.5 to 40N/m, incremental difference of 2.5 N/m

  Tarmac: 30.0 to 65N/m, incremental difference of 2.5 N/m

  Helper: 2.0N/m
## Tyres
- 20KG per tarmac wheel and 25kg per gravel wheel, node weight calculated based on the rim weight limit as specified by WRC regulations
- 205/65 R15 gravel wheels, 235/40 R18 tarmac wheels
- Wheel beam properties are tested and modified
## Aerodynamics
- Front and rear independent aerodynamics
- Front lip and rear diffuser react to ground clearance change
- Body aerodynamic designs are reflected with triangles for downforce generation
- Two layer WRC style rear wing with winglet attached
- Rear wing endplate aerodynamics for better control when sliding
- Total about 400kg of downforce at 200km/h
## Misc
- 25KG ballast for center of gravity adjustment
- Driver weight included in racing seat part
- Rally light for better vision at night events (about 7kg, also act as ballast)
- Spare wheel selection for weight accuracy
- Troll driver's model, hands moving with steering wheel LOL

![Astral_R](Docs/3.jpg)

# Existing Problems (that are mostly not going to be fixed)
- Due to insufficient chassis Jbeam noding, in rare cases you may encounter chassis vibration.
- All colors and materials are none adjustable, the color theme is fixed. (You can manually adjust in Material Editor though, but it's not RGB image so no simple way to change color)
  
  (202401/20: I tried to make a proper skin but UV is so messed that it's basically impossible to make it clean. Automation now has a feature to export decal as skin, but I have changed so much things to an extend that it's not worth to go back to Automation.)
- Due to the way Automation exports (when I exported), all decals and skins are actual models instead of decal image. This means the skin and decal will sometimes clip through car model. Also, it will take more space to load
- The opacity maps are not high resolution enough so there are jagged edges around the place where opacity map applies
- Meshes are still Automation level so it may not be compatible to a full fledged mod
- Flexbody animations are not perfect, especially around engine and transmission, it just works but it's not accurate
