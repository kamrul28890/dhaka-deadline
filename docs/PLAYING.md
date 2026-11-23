# DHAKA DEADLINE — Windows prototype

Run `DhakaDeadline.exe`. Keep `DhakaDeadline.pck` in the same folder. No engine installation, account or license purchase is required. The executable is unsigned.

Choose a route and press Start Journey. Keep left, obey the signals and drive to the gold office marker. Stop in the marked bay for two seconds. Your interview is at 09:30; the mission starts at 09:24, with a clock advancing three times faster than real time. Late arrival is allowed. A pedestrian collision stops the journey.

The lower-left cluster shows speed in km/h, D/N/R motion direction, longitudinal acceleration in m/s², throttle/brake input and the handbrake indicator. Follow the mint arrows on the road and the next-turn card above the car. Red/amber approach warnings appear above the mission card. The gold office marker and STOP bay identify the arrival location. Route guidance follows the two authored routes; it is not a general route planner.

WASD or arrow keys: drive and brake. Q: reverse. Space: handbrake. C: cycle chase, bonnet and right-hand-drive cabin views. V: cycle vehicle (Sedan / Green CNG 3-wheeler). H: horn. L: headlights. K: wipers. M: map. T: reroute / switch route choice. R: recover the car with a time penalty. Escape: pause. F3: diagnostics.

Version 0.4 improves junction traffic: vehicles wait for exit space and conflicting movements, yield on right turns and finish clearing after entry. Long-waiting turns receive a courtesy gap after committed traffic passes. Keep junction exits clear; the player can physically hold up traffic. Detailed sedan and tree models, animated wheels, steering and brake lights remain from v0.3. Mirrors do not show live traffic behind you. Driving physics, bus/CNG/pedestrian models, architecture and traffic calibration still need work.

Version 0.5 replaces bus/CNG boxes and capsule people with detailed generic models, animated wheels/steering, brake lights, boarding doors and walking/idle poses. The starting bus-stop block has textured storefronts, Bangla signs, weathered walls, paved forecourts, shop props and a bench. Vehicle dimensions are adapted to the current collision footprints. These are visual stand-ins, not verified replicas of Dhaka vehicles, residents or buildings; much of the surrounding district remains prototype geometry.

Version 0.6 enhances driving feel and audio while keeping predictable keyboard controls:
- Suspension dynamics: physical pitch squat on acceleration, forward dive on braking, tactile collision rebound, body roll in cornering, and road texture micro-vibration.
- Steering feel: caster self-centering return when rolling forward.
- Audio overhaul: synthetic 4-cylinder engine loop with 4-speed transmission RPM pitch and throttle load dynamics, road tire rolling noise scaling with speed, tire screech on hard braking/handbrake/corner scrub, collision impact thud, dual-tone horn, 3D diesel bus and CNG auto-rickshaw engine loops, contextual traffic horns, and a soft ambient Dhaka city soundscape.
- HUD driving feedback: dynamic TRACTION SLIP indicator alongside P HANDBRAKE. Telemetry, arrivalbay, pause and recovery contracts remain preserved.

Version 0.7 introduces believable mixed-traffic dynamics and bus bay merging:
- Vehicle class profiles: CNG three-wheelers have snappy launch acceleration (2.6 m/s²), tighter headway cushions, and authentic curb-hugging lateral positioning; City buses feature heavy diesel inertia (0.95 m/s² acceleration, 3.6 m/s² braking) and larger safety headway buffers; Private sedans retain balanced cruising.
- Bus stop bay behavior: the bus pulls laterally into the marked boarding bay during approach and dwell, and checks blind spots / approaching traffic before merging back into the travel lane. Traffic queues cleanly behind without deadlocks or collisions.

Version 0.8 introduces dynamic per-directed-road travel-time heuristics and in-game route reassessment:
- Dynamic link cost modeling: travel times across all 14 directed road links are calculated in real time using corridor physical lengths, free-flow speeds (10 m/s arterial, 8 m/s market link), live vehicle queue counts (2.8s per queued car), and exact signal phase time-to-green calculations.
- Fastest-route recommendation: the HUD and route selection menus dynamically evaluate all mission branches and identify the fastest route with a `★ FASTEST` badge.
- In-game route reassessment: press `T` during driving to switch between North Road and Market Link, or reassess routes from the Pause menu with live ETAs. Road guide arrows, minimap breadcrumbs, and next-turn prompts update immediately. Approaching junction W, proactive HUD prompts notify the driver when an alternative route is significantly faster.

Version 0.9 adds in-game graphics and audio settings, persistent configuration, and performance scaling presets:
- Settings menu: accessible from both the Main Menu and Pause menu, providing one-click cycling for quality presets (Low, Medium, High), display mode (Windowed / Fullscreen), resolutions (1280x720, 1600x900, 1920x1080), shadow quality, and anti-aliasing (FXAA, MSAA 2X).
- Audio mixer channels: independent volume adjustment across 5 dedicated buses (Master, Engine, Traffic, Ambience, and SFX) with decibel scaling and mute at 0%.
- Persistent configuration: saves cleanly to `user://settings.json` on disk and automatically restores settings on boot with fallback recovery for missing or corrupted files.

Version 1.0 adds multi-mission progression, contextual narrative audio feedback, and arrival performance grading:
- Three distinct playable missions selectable from the main menu:
  1. Morning Interview (09:24 start, 09:30 target) — balanced morning rush to Karwan Bazar Tech office.
  2. Urgent Courier (02:16 start, 02:20 target) — high-urgency express document run with tight 85s deadline.
  3. Twilight Commute (06:47 start, 06:55 target) — dusk rush hour with warm evening lighting and headlights.
- Radio dispatch & contextual narrative: procedural radio chime (`radio_chime.wav`) and top-center bilingual dispatch banner displaying real-time situational cues from control (trip start, red light guidance, junction clearing, route advice, countdown warnings, and arrival bay cues).
- Performance Tier Grading: comprehensive end-of-journey scorecard awarding Grade Rank (S: Master Driver / ওস্তাদ চালক, A: Professional / দক্ষ চালক, B: Careful Driver / সতর্ক চালক, C: Rushed Driver / তাড়াহুড়ো চালক, D: Imprudent / বেপরোয়া, F: Failed / ব্যর্থ) with detailed safety, punctuality, compliance, and overall ratings.
- Time-of-day dynamic atmosphere: morning sunshine, bright midday glare, and warm dusk lighting automatically configured per mission with synchronized 3D directional light energy, sun angle, and fog color.

Version 1.5 introduces a second fully playable vehicle class — the Green CNG Auto-Rickshaw (সিএনজি অটোরিকশা):
- Agile 3-wheeler dynamics: 2.8m × 1.4m footprint, snappy low-end acceleration (4.2 m/s²), high maneuverability in tight jams, and 60 km/h top speed.
- Articulated handlebar steering and functioning 3D digital fare meter (`"ভাড়া: ৳ %d"`).
- Open-air cabin driver vantage point with centered saddle position and custom engine audio.
- Toggle between vehicles with `V` or select from the mission menu.

Version 1.6 introduces real-time traffic congestion heatmaps and dynamic dispatch radio alerts:
- Minimap heatmap: color-coded road links (Green: Clear, Amber: Slowing, Red: Bottleneck with pulsing glow) showing live corridor queues at a glance.
- Bilingual radio dispatch alerts: automated control room chime and alerts when approaching heavy queues with instant `[T]` alternative route recommendations.

Version 2.0 introduces the Grand 20.5km Shahbag to Uttara Express Corridor:
- Complete Continuous Highway Track: drive along the full 20.5km elevated express corridor through 7 iconic sectors: Shahbag, Bangla Motor / Karwan Bazar (overhead MRT Line 6 viaduct), Farmgate / Bijoy Sarani, Mohakhali Elevated Flyover (+10.5m deck elevation), Banani / Kakoli commercial strip, Kuril 4-tier interchange loops, and Hazrat Shahjalal International Airport Terminal 3 / Uttara.
- Dynamic Animated Falling Rain & Windshield Physics: GPU rain particle emitter with speed-dependent aerodynamic velocity shear (rain streaks tilt back at high speed), pavement impact splashes, and interactive windshield rain droplets with dual wiper clearing masks (`KEY_K`).
- Realistic Collision Deformation & Scraping Sparks: physical bumper/hood mesh denting along impact normal, physical spark bursts and screech audio (`metal_scrape.wav`) when scraping concrete barriers, steering tie-rod alignment drift, and radiator steam smoke leak (`radiator_steam.wav`) capping engine power.
- Strict DMP Highway Police Pursuit: reckless high-speed impacts trigger police alerts; DMP Highway Patrol pickup spawns with flashing red/blue LED lightbars and wailing sirens (`police_siren.wav`), chasing and intercepting violators with civil repair costs and traffic fines deducted from career profile.

Version 1.8 introduces the Gold Master Production MVP features:
- Free Roam City Exploration Mode: drive freely throughout the Farmgate–Karwan Bazar corridor at your own leisure with no timer, no deadline, and no appointment pressure. Full traffic, pedestrians, transit hubs, and street audio are active.
- Driver Career Profile: persistent career statistics saved to `user://career_profile.json`, tracking your lifetime distance driven, completed journeys, free roam runs, passenger fares earned, and driver honorific titles from "শিক্ষানবিস চালক" (Novice) to "ওস্তাদ চালক" (Master Driver). View anytime from Intro, Pause, or Results menus.
- Optimized Menu Layout: compact 2-column mission selector and horizontal control bars ensure that the "START JOURNEY" button is always clearly visible and accessible on all screen resolutions without getting cut off.
- In-game Credits: attribution screen detailing procedural audio, 3D assets, open-source typography, and engine provenance.

Version 1.7 introduces ambient urban Dhaka soundscapes and 3D street life foleys:
- Procedural math synthesis of authentic Dhaka audio: cycle rickshaw double bell chimes (*টুং টুং!*), bus conductor route calls (*"ফার্মগেট! ডাইরেক্ট!"*), tea stall kettle hissing and spoon clinking (*টং এর চায়ের কেতলি*), and fresh fruit / coconut hawker cries (*"মিষ্টি ডাব! তাজা ফল!"*).
- 3D positional emitters at roadside stalls and transit hubs with natural distance falloff, fully controllable via the in-game Ambience volume slider.

Version 1.4 introduces the dynamic traffic event engine, unscheduled road obstacles, street stalls, and DMP traffic police manual overrides:
- Road obstacles & work zones: construction zone with traffic cones, caution barricade, and hazard beacon; broken-down delivery van with blinking emergency flashers and warning triangle.
- AI obstacle avoidance: vehicles and cars dynamically steer around lane constrictions with smooth lateral offsets.
- Sidewalk street vendors: authentic roadside tea stall (টং এর দোকান) with canopy, wooden bench, kettle, biscuit jars, and fruit/coconut cart.
- DMP traffic police officer: stationed at western junction with hand gesture signaling (`stop`, `wave`) and manual traffic signal override capability.

Version 1.3 adds vehicle interior interaction, working 3D dashboard instruments, cabin backlighting, and a live rearview mirror projection system:
- 3D analog speedometer (km/h) and tachometer (RPM load) needles deflecting dynamically in cabin view (`C` key).
- Instrument cluster backlighting with luminescent cyan dial markings synced with headlights (`L` key).
- Windshield-mounted rearview mirror displaying a real-time 3D camera reflection of trailing traffic and the road behind.
- Cabin acoustic interior damping attenuating exterior traffic and monsoon rain noise when seated inside.

Version 1.2 introduces dynamic monsoon weather, wet road shaders, curb drainage puddles, dual wiper arms, and cabin rain atmosphere:
- Dynamic monsoon weather system: selectable as Mission 04 "Monsoon Commute" (বর্ষার ঢাকা — জরুরি যাত্রা) at 04:38 PM with torrential rain and low overcast visibility.
- Wet road asphalt shader: realistic road surface sheen with specular roughness dropping to 0.22 and curb drainage gutter water accumulation (`GutterPuddles`).
- Dual animated wiper arms: physically sweep across the windshield with mechanical turnaround audio (`wiper_sweep.wav`), toggled via `K` key with dashboard status feedback.
- Audio atmosphere: hydrodynamic water splash audio (`water_splash.wav`) triggered at speed (>6.0 m/s) in rain, and continuous tropical downpour ambience loop (`rain_loop.wav`).

Version 1.1 establishes the verified Farmgate–Karwan Bazar corridor topology, environmental landmarks, and localized pedestrian crowd behaviors:
- Topographical corridor layout: formally identifies the Farmgate hub (Ananda Cinema, Green Road link, Indira Road) and Karwan Bazar hub (Roundabout, SAARC Fountain, Pan Pacific Sonargaon) connected via Kazi Nazrul Islam Avenue and Panthapath Link.
- Localized urban landmarks:
  1. Farmgate Foot-Over-Bridge (ফার্মগেট পদচারী সেতু): authentic steel-truss pedestrian overbridge spanning the western arterial with 5.6m traffic clearance, dual sidewalk stair towers, and bilingual directional signboards.
  2. Karwan Bazar Foot-Over-Bridge (কারওয়ান বাজার পদচারী সেতু): overhead pedestrian crossing across Kazi Nazrul Islam Avenue.
  3. Karwan Bazar Metro Station (MRT Line 6): elevated station platform canopy structure and sidewalk entrance pavilion portal with escalators and Bengali transit branding.
  4. SAARC Fountain Monument (সার্ক ফোয়ারা): tiered circular fountain monument at the Karwan Bazar South intersection with brass spire cluster and landscaped perimeter.
  5. DMP Traffic Police Kiosks: characteristic Dhaka Metropolitan Police hexagonal traffic boxes at major junctions.
  6. Multi-lane highway infrastructure: concrete New Jersey median crash barriers and dashed lane dividing markings along Kazi Nazrul Islam Avenue, plus high-clearance overhead directional highway gantries.
- Localized pedestrian crowd behaviors:
  1. Coordinated zebra crossing crowd: three pedestrians cross synchronously in a tight, realistic group during all-red signals.
  2. Transit & landmark sidewalk crowds: 16 pedestrians distributed across transit stops, foot-over-bridge approaches, and market storefronts.
  3. Localized driver yielding: oncoming vehicles decelerate progressively and yield a comfortable 7.5m cushion before the crossing crowd, safely resuming once clear.
  4. Multi-lane lane differentiation: cars utilize inner overtaking lanes while buses and curb-hugging CNGs operate in outer margins.

This is a fictional Dhaka-inspired district with 18 traffic agents, a bus pickup, signals, basic pedestrians and one interview mission. Maps and travel estimates do not represent actual Dhaka roads or traffic. Rain, functional cockpit instruments, detailed mixed-traffic behavior and verified real geography are later milestones.

The game runs locally and does not transmit gameplay data. Scores are stored in Godot's user-data folder, normally `%APPDATA%\Godot\app_userdata\Dhaka Deadline`.

See `THIRD_PARTY_NOTICES.md`, `Godot-LICENSE.txt`, `Godot-COPYRIGHT.txt` and `OFL.txt` for engine, CC0 asset and font notices.
