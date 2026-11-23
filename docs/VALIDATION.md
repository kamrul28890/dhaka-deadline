# First playable validation — 2026-11-15

## Shahbag to Uttara 20.5km Express Corridor, Dynamic Weather Particles & Strict Police pass — 2026-11-23

Version 2.0.0 marks a massive architectural leap, introducing the full 20.5km continuous Shahbag-to-Uttara elevated expressway corridor, dynamic falling rain GPU particles with velocity shear, interactive windshield droplets with active wipers, realistic collision deformation & scraping sparks, and strict DMP Highway Police pursuit:
- Continuous 20.5km Arterial Corridor (`scripts/corridor_expressway.gd`):
  - Spans 7 iconic real-world sectors:
    1. Shahbag Gateway & Institutional Strip (National Museum, BSMMU, InterContinental).
    2. Bangla Motor & Karwan Bazar Metro Spine (Overhead MRT Line 6 viaduct, CA Bhaban, PetroBangla).
    3. Farmgate & Bijoy Sarani Gateway (Military Museum, Ananda Cinema).
    4. Mohakhali Elevated Flyover (soaring at +10.5m elevation above transit terminal & rail crossing).
    5. Banani & Kakoli Commercial Strip (corporate glass towers, neon digital billboards).
    6. Kuril 4-Tier Spaghetti Interchange & Khilkhet (overhead loops, Radisson Blu, open expressway).
    7. Airport & Uttara Terminal Plaza (HSIA Terminal 3 wavy facade, landing approach lights, low-flying airliner).
  - Continuous physical roadway deck with tarmac friction, double-sided New Jersey crash barriers with collision, central median divider, overhead bilingual green highway gantries, and highway lighting poles.
- Dynamic Animated Falling Rain & Windshield Physics (`scripts/dynamic_weather.gd`):
  - 3D GPU Particle Emitter: 12,000 velocity-stretched falling raindrops with real-time aerodynamic velocity shear (rain tilts backward as vehicle speeds up along -Z).
  - Ground impact splash micro-particles bouncing on asphalt surface.
  - Interactive windshield rain droplet shader: water droplets bead and stream back under wind drag; dual wiper blades (`KEY_K`) actively sweep clear view masks in real-time.
  - Weather state machine supporting `clear`, `drizzle` (3,500 particles), and `monsoon` (12,000 particles).
- Collision Realism, Scraping Sparks & Strict DMP Highway Police (`scripts/collision_consequences.gd`):
  - Impact-impulse vertex denting: crumples front bumper/hood nodes along collision normal.
  - Scraping sparks: lateral barrier grinding triggers bright yellow-orange spark particle bursts with gravity and bounce, accompanied by abrasive metal scraping audio (`metal_scrape.wav`).
  - Mechanical damage penalties: persistent steering tie-rod alignment drift (requires counter-steering) and radiator breach emitting boiling steam smoke (`radiator_steam.wav`) with 45% engine power capping.
  - Strict DMP Highway Police Pursuit: reckless collisions trigger emergency radio dispatch; DMP Highway Patrol pickup spawns with flashing red/blue LED lightbars and wailing siren (`police_siren.wav`), pursuing the player vehicle.
  - Civil repair costs and traffic fines automatically deducted in Taka from `user://career_profile.json`.
- Verified: **439 passing checks** across all 21 test suites (26 systems, 19 driving-feedback, 25 vehicle models, 17 junctions, 23 street art, 36 driving feel & audio, 14 mixed traffic, 23 dynamic routing, 33 settings, 20 missions, 42 corridor landmarks, 33 monsoon weather, 18 cockpit interior, 20 traffic events, 12 playable CNG, 14 traffic heatmap, 22 Dhaka soundscape, 12 career & free roam, 11 express corridor, 9 dynamic rain, 10 collision consequences). Clean Godot asset import and release export.
- 10-minute / 36,000-step traffic stability simulation (`tests/test_traffic_stability.gd`): 0 vehicle-contact frames, 10 completed pedestrian crossings, 53.48s max wait, >= 1,787.38m travel across all 18 vehicles (`artifacts/traffic-stability.json`).
- Exported Windows package verification: `python tools/verify_build.py` passed with zero errors or warnings. Autodrive completed in 116.63 seconds with 0 collisions and 0 red lights; traffic smoke probe passed with 18 agents, 7,561.39m travel, bus pickup and release, both signal axes exercised, 2 completed crossings. ZIP CRC integrity, exact eight-file contents, and file hashes matched the build folder.
- Native Windows gallery renders at 1600×900: `artifacts/v2.0-gameplay.png`, `v2.0-cabin.png`, `v2.0-pause.png`, `v2.0-junction.png`, `v2.0-results.png`, `v2.0-street-detail.png`, `v2.0-bus-detail.png`, `v2.0-cng-detail.png`, `v2.0-fob-detail.png`, `v2.0-metro-station.png`, `v2.0-saarc-fountain.png`, `v2.0-crossing-crowd.png`, `v2.0-first-look.png`, `v2.0-monsoon-rain.png`, `v2.0-monsoon-cabin.png`, `v2.0-tea-stall.png`, `v2.0-traffic-police.png`, `v2.0-road-work.png`, `v2.0-breakdown-detail.png`.
- Build: `build/v2.0/DhakaDeadline.exe` and `DhakaDeadline-Windows.zip`; `Play.cmd` selects v2.0. Prior versioned builds (v1.8, v1.7, v1.6, v1.5, v1.4, v1.3, v1.2, v1.1, v1.0, v0.9, v0.8, v0.7, v0.6, v0.5, v0.4, v0.3, v0.2) and backup source under `artifacts/before-v1.8/` remain intact.

## Gold Master Production MVP & Free Roam City Exploration pass — 2026-11-23

Version 1.8.0 marks the completion of the 18-phase master roadmap, delivering the final Gold Master production release:
- Dedicated Free Roam City Exploration Mode (`"freeroam"`):
  - Unrestricted exploration across the entire Farmgate–Karwan Bazar transit corridor without countdown deadlines, clock pressure, or appointment requirements.
  - Active traffic simulation, pedestrian crossings, working signals, street foleys, and radio dispatch chatter remain fully operational.
  - Integrated into HUD with prominent "FREE ROAM / মুক্ত ভ্রমণ" launcher button and live exploration HUD telemetry with trip odometer.
- Cumulative Driver Career Profile (`scripts/career_manager.gd`):
  - Tracks lifetime stats saved persistently to `user://career_profile.json` (total distance driven in km, missions completed, free roam trips, total driving time, fares earned in Taka, safety rating, and collision counters).
  - Calculates dynamic driver honorific titles based on career progress:
    - `"শিক্ষানবিস চালক"` (Novice Driver)
    - `"সতর্ক চালক"` (Careful Driver)
    - `"দক্ষ চালক"` (Skilled Driver)
    - `"পেশাদার চালক"` (Professional Driver)
    - `"ওস্তাদ চালক"` (Master Driver)
  - Dedicated interactive career profile screen accessible from Intro, Pause, and Journey Results menus.
  - Robust corruption recovery falling back gracefully to clean default profiles.
- Screen Coverage & Menu UI Layout Fix:
  - Fixed major UI overflow bug where stacked mission and vehicle buttons exceeded 950px in vertical height, pushing the "START JOURNEY" button off the screen.
  - Re-architected menu layout in `scripts/hud.gd` to use a compact 2-column `GridContainer` for missions, side-by-side horizontal button pairs for vehicle and route choices, reducing total vertical height from >950px to ~420px.
  - Positioned menu cleanly at `Vector2(38, 25)` so all mission options and the critical "START JOURNEY →" button remain immediately visible, uncluttered, and clickable at all resolutions (1280x720, 1600x900, 1920x1080).
- Production Master Credits & Attribution:
  - In-game credits screen (`show_credits()`) accessible from Intro and Pause menus documenting full engine provenance, procedural audio algorithms, CC0 assets, open-source typography (Hind Siliguri OFL), and development roadmap history.
- Verified: **409 passing checks** across all 18 test suites (26 systems, 19 driving-feedback, 25 vehicle models, 17 junctions, 23 street art, 36 driving feel & audio, 14 mixed traffic, 23 dynamic routing, 33 settings, 20 missions, 42 corridor landmarks, 33 monsoon weather, 18 cockpit interior, 20 traffic events, 12 playable CNG, 14 traffic heatmap, 22 Dhaka soundscape, 12 career & free roam). Clean Godot asset import and release export.
- 10-minute / 36,000-step traffic stability simulation (`tests/test_traffic_stability.gd`): 0 vehicle-contact frames, 10 completed pedestrian crossings, 53.48s max wait, >= 1,787.38m travel across all 18 vehicles (`artifacts/traffic-stability.json`).
- Exported Windows package verification: `python tools/verify_build.py` passed with zero errors or warnings. Autodrive completed in 116.63 seconds with 0 collisions and 0 red lights; traffic smoke probe passed with 18 agents, 7,561.39m travel, bus pickup and release, both signal axes exercised, 2 completed crossings. ZIP CRC integrity, exact eight-file contents, and file hashes matched the build folder.
- Native Windows gallery renders at 1600×900: `artifacts/v1.8-gameplay.png`, `v1.8-cabin.png`, `v1.8-pause.png`, `v1.8-junction.png`, `v1.8-results.png`, `v1.8-street-detail.png`, `v1.8-bus-detail.png`, `v1.8-cng-detail.png`, `v1.8-fob-detail.png`, `v1.8-metro-station.png`, `v1.8-saarc-fountain.png`, `v1.8-crossing-crowd.png`, `v1.8-first-look.png`, `v1.8-monsoon-rain.png`, `v1.8-monsoon-cabin.png`, `v1.8-tea-stall.png`, `v1.8-traffic-police.png`, `v1.8-road-work.png`, `v1.8-breakdown-detail.png`.
- Build: `build/v1.8/DhakaDeadline.exe` and `DhakaDeadline-Windows.zip`; `Play.cmd` selects v1.8. Prior versioned builds (v1.7, v1.6, v1.5, v1.4, v1.3, v1.2, v1.1, v1.0, v0.9, v0.8, v0.7, v0.6, v0.5, v0.4, v0.3, v0.2) and backup source under `artifacts/before-v1.8/` remain intact.

## Ambient Urban Dhaka Soundscape & Street Life Foleys pass — 2026-11-23

Version 1.7.0 introduces a rich, authentic Dhaka ambient soundscape and 3D street life foley audio system synthesized entirely through procedural mathematical algorithms without external recordings, paid assets, or third-party dependencies:
- Procedural Mathematical Sound Synthesis (`tools/generate_audio.py`):
  - Cycle Rickshaw Bell (`assets/audio/rickshaw_bell.wav`): 0.8s dual metallic strike (*টুং টুং!*) synthesized via modal resonance frequencies (2150 Hz, 3420 Hz, 4610 Hz, 6450 Hz) with exponential brass damping and high-frequency strike ping transients.
  - Bus Conductor Route Call (`assets/audio/conductor_call.wav`): 1.4s vocal formant projection capturing the classic Dhaka bus conductor route announcement (*"ফার্মগেট! ডাইরেক্ট! ফার্মগেট!"*) with vocal cord pulses, vibrato modulation, and distinct vowel formants (F1: 680 Hz, F2: 1350 Hz, F3: 2450 Hz).
  - Tong er Dokan Tea Stall Foley (`assets/audio/tea_stall.wav`): 1.2s seamless loop of boiling aluminum kettle steam hiss, vapor bubbling rumble, and metallic spoon clinks against tea glasses (*টং এর চায়ের কেতলি*).
  - Fruit & Green Coconut Hawker Call (`assets/audio/hawker_call.wav`): 1.1s melodic street vendor cry (*"মিষ্টি ডাব! তাজা ফল!"*) capturing authentic street seller cadences with harmonic vocal resonances.
- Positional 3D Street Life Audio Emitters (`scripts/district.gd`):
  - `foley_tea_stall`: Attached to `VendorStall_Tea` at `Vector3(-100.5, 1.2, 48.0)`, looping continuously on the `"Ambience"` audio bus with 28.0m spatial falloff.
  - `foley_conductor`: Stationed at the Farmgate transit hub / bus shelter at `Vector3(-94.0, 1.5, -12.0)`, calling passengers periodically every 16 to 32 seconds (`max_distance = 36.0m`).
  - `foley_rickshaw_bell`: Stationed along the zebra crossing and cycle rickshaw corridor at `Vector3(-93.2, 1.2, 15.0)`, chiming periodically every 10 to 22 seconds (`max_distance = 32.0m`).
  - `foley_hawker`: Stationed at `VendorStall_Fruit` at `Vector3(-85.5, 1.2, 62.0)`, calling out every 18 to 36 seconds (`max_distance = 28.0m`).
  - All emitters route through the `"Ambience"` audio bus, fully honoring in-game audio volume sliders and settings persistence.
- Verified: **397 passing checks** across all 17 test suites (26 systems, 19 driving-feedback, 25 vehicle models, 17 junctions, 23 street art, 36 driving feel & audio, 14 mixed traffic, 23 dynamic routing, 33 settings, 20 missions, 42 corridor landmarks, 33 monsoon weather, 18 cockpit interior, 20 traffic events, 12 playable CNG, 14 traffic heatmap, 22 Dhaka soundscape). Clean Godot asset import and release export.
- 10-minute / 36,000-step traffic stability simulation (`tests/test_traffic_stability.gd`): 0 vehicle-contact frames, 10 completed pedestrian crossings, 53.48s max wait, >= 1,787.38m travel across all 18 vehicles (`artifacts/traffic-stability.json`).
- Exported Windows package verification: `python tools/verify_build.py` passed with zero errors or warnings. Autodrive completed in 116.63 seconds with 0 collisions and 0 red lights; traffic smoke probe passed with 18 agents, 7,561.39m travel, bus pickup and release, both signal axes exercised, 2 completed crossings. ZIP CRC integrity, exact eight-file contents, and file hashes matched the build folder.
- Native Windows gallery renders at 1600×900: `artifacts/v1.7-gameplay.png`, `v1.7-cabin.png`, `v1.7-pause.png`, `v1.7-junction.png`, `v1.7-results.png`, `v1.7-street-detail.png`, `v1.7-bus-detail.png`, `v1.7-cng-detail.png`, `v1.7-fob-detail.png`, `v1.7-metro-station.png`, `v1.7-saarc-fountain.png`, `v1.7-crossing-crowd.png`, `v1.7-first-look.png`, `v1.7-monsoon-rain.png`, `v1.7-monsoon-cabin.png`, `v1.7-tea-stall.png`, `v1.7-traffic-police.png`, `v1.7-road-work.png`, `v1.7-breakdown-detail.png`.
- Build: `build/v1.7/DhakaDeadline.exe` and `DhakaDeadline-Windows.zip`; `Play.cmd` selects v1.7. Prior versioned builds (v1.6, v1.5, v1.4, v1.3, v1.2, v1.1, v1.0, v0.9, v0.8, v0.7, v0.6, v0.5, v0.4, v0.3, v0.2) and backup source under `artifacts/before-v1.7/` remain intact.

## Real-time Traffic Congestion Heatmap & Dynamic Dispatch Radio pass — 2026-11-23

Version 1.6.0 introduces real-time traffic congestion heatmap visualization on the minimap and dynamic bilingual dispatch radio alerts for traffic bottlenecks:
- Dynamic Link Congestion Evaluation (`scripts/road_network.gd`):
  - `link_congestion(from_node, to_node, traffic_agents, signal_context)`: calculates physical queue counts, traversal times, and classifies corridors into three clear congestion tiers:
    - Green (`Color("2fe695")`): Clear / Free-flowing (< 2 queued vehicles).
    - Amber (`Color("f59e0b")`): Moderate Slowing (2 to 3 queued vehicles).
    - Red (`Color("ef4444")`): Heavy Congestion / Bottleneck (>= 4 queued vehicles or active road obstacle).
  - `all_links_congestion`: aggregates bidirectional corridor occupancy across the entire Dhaka road network.
- Live Minimap Congestion Heatmap (`scripts/hud.gd`):
  - Upgrades minimap corridor rendering to display color-coded link states dynamically.
  - Pulsing glow animation for heavy congestion bottlenecks.
  - Minimap traffic status legend (Clear, Slow, Bottleneck).
- Dynamic Radio Dispatch & Reroute Guidance (`scripts/main.gd`):
  - Automatically detects when approaching a congested corridor and triggers a bilingual radio dispatch with procedural chime:
    - Bengali: *"সতর্কতা: [সড়ক] তীব্র যানজট! বিকল্প রুট ব্যবহার করতে [T] চাপুন।"*
    - English: *"ALERT: Heavy queue on [Corridor]! Press [T] for [Alternative]."*
  - Anti-spam cooldown timer (24s) to ensure realistic dispatch frequency.
- Verified: **375 passing checks** across 16 test suites, clean 10-minute traffic stability simulation, and verified Windows package under `build/v1.6/`.

## Secondary Playable Vehicle Class — Green CNG Auto-Rickshaw (সিএনজি অটোরিকশা) pass — 2026-11-23

Version 1.5.0 introduces a second fully playable vehicle class — the iconic Dhaka Green CNG Three-Wheeler (সিএনজি অটোরিকশা) — featuring distinct three-wheeler physics, handlebar steering articulation, functioning fare meter, and open-air cabin vantage point:
- Playable Green CNG Auto-Rickshaw (`scripts/player_car.gd`):
  - Dynamic vehicle type switching (`set_vehicle_type("cng")` vs `"car"`) via `KEY_V` in-game or selection in the main menu.
  - Authentic compact footprint: 2.8m length × 1.4m width, 1.8m wheelbase (compared to sedan's 4.35m × 1.85m).
  - Agile 3-wheeler handling: snappy acceleration (4.2 m/s²), agile low-speed turning, and 60 km/h top speed (16.5 m/s).
  - Articulated Steering Handlebar (`Handlebar`): rotates dynamically with player steering inputs.
  - Functioning 3D Fare Meter (`FareMeter`): mounted on the cabin dash with green luminescent digital readout (`"ভাড়া: ৳ %d"`), calculating authentic Dhaka fares (40 Tk base + 12 Tk/km + waiting time).
  - Open-Air Saddle Vantage Point: centered saddle driver camera position in cabin mode (`camera_mode == 2`), bypassing cabin acoustic damping to reflect the open-air three-wheeler experience.
  - Custom 3D engine audio: puttering 4-stroke CNG engine loop (`assets/audio/traffic_cng.wav`).
- HUD Vehicle Selection & Dashboard Badge (`scripts/hud.gd`):
  - Intro menu vehicle selector buttons for Private Sedan vs Green CNG.
  - Dashboard telemetry vehicle class badge (`CNG 3W` vs `SEDAN`) and live fare meter display (`FARE: ৳ %d`).
- Verified: **361 passing checks** across 15 test suites, clean 10-minute traffic stability simulation, and verified Windows package under `build/v1.5/`.

## Dynamic traffic event engine, unscheduled road obstacles, street vendors/stalls, and police manual override pass — 2026-11-22

Version 1.4.0 introduces the dynamic traffic event engine, unscheduled road obstacles (construction work zones and broken-down vehicles), sidewalk street vendors (tea and coconut/fruit stalls), DMP traffic police manual hand gesture overrides, and dynamic obstacle lane avoidance while preserving bicycle driving controls, 18-agent traffic contracts, bus bay merge protocols, monsoon weather shaders, working cockpit instruments, and multi-mission progression:
- Dynamic Traffic Event Engine (`scripts/main.gd`, `scripts/road_network.gd`):
  - Dynamic obstacle registry (`register_traffic_obstacle`, `unregister_traffic_obstacle`, `get_active_obstacles`).
  - Active work zone (`ConstructionWorkZone` at `Vector3(-20.0, 0, -106.2)`) featuring 4 high-visibility orange cones (`TrafficCone`), striped road barricade (`RoadBarricade`) with bilingual caution banner, and pulsating amber hazard beacon (`HazardBeacon`).
  - Broken-down delivery vehicle (`BrokenDownVehicle` at `Vector3(-96.5, 0, -25.0)`) on the outer corridor shoulder with active hazard blinkers (`hazard_flashers_active = true`) and red reflective emergency warning triangle (`WarningTriangle`).
  - Dynamic routing link cost integration: road links with active obstacles incur dynamic obstacle delay penalties (+3.5s), allowing the route reassessment engine to proactively recommend unobstructed routes.
- Street Vendors & Roadside Stalls (`scripts/district.gd`):
  - Authentic roadside tea stall (`VendorStall_Tea` / টং এর দোকান): wooden framework, corrugated blue tarp canopy (`Canopy`), roadside wooden bench (`Bench`), aluminum kettle, tea glasses, biscuit jars, and Bengali signboard (`"মামার স্পেশাল চা ও বিস্কুট"` / `"MAMA'S SPECIAL TEA"`).
  - Fresh fruit & green coconut cart (`VendorStall_Fruit`): spoked-wheel wooden cart loaded with fresh green coconuts (কাঁচা ডাব), fruit crates, and sign (`"মিষ্টি ডাব ও তাজা ফল"` / `"FRESH COCONUTS & FRUITS"`).
- DMP Traffic Police Manual Hand Gesture Override (`scripts/traffic_police_officer.gd`, `scripts/main.gd`):
  - Stationed DMP traffic police officer (`TrafficPoliceOfficer`) on raised octagonal traffic island at the western junction (`Vector3(-98.0, 0.25, 5.0)`).
  - Authentic uniform: dark navy trousers, white uniform shirt, high-visibility neon yellow-green safety vest (`Color("c6ff00")`) with silver reflective stripes, white peaked service cap with black visor, and articulated signaling arms (`ArmLeft`, `ArmRight`) with white gloves and yellow traffic baton.
  - Interactive manual override (`set_police_override(active, forced_axis)`): alters traffic signal priority directly via officer gesture states (`"stop"`, `"wave"`, `"idle"`) while guaranteeing smooth restoration upon release.
- AI Traffic Obstacle Avoidance (`scripts/traffic_car.gd`):
  - Traffic agents continuously scan upcoming lane obstacles and compute smooth lateral bypass offsets (`avoidance_offset = move_toward(...)`) to glide around lane restrictions with speed modulation (5.0 m/s) without deadlocks or collisions.
- Verified: **349 passing checks** across all 14 test suites (26 systems, 19 driving-feedback, 25 vehicle models, 17 junctions, 23 street art, 36 driving feel & audio, 14 mixed traffic, 23 dynamic routing, 33 settings, 20 missions, 42 corridor landmarks, 33 monsoon weather, 18 cockpit interior, 20 traffic events). Clean Godot asset import and release export.
- 10-minute / 36,000-step traffic stability simulation (`tests/test_traffic_stability.gd`): 0 vehicle-contact frames, 10 completed pedestrian crossings, 53.48s max wait, >= 1,787.38m travel across all 18 vehicles (`artifacts/traffic-stability.json`).
- Exported Windows package verification: `python tools/verify_build.py` passed with zero errors or warnings. Autodrive completed in 116.63 seconds with 0 collisions and 0 red lights; traffic smoke probe passed with 18 agents, 7,561.39m travel, bus pickup and release, both signal axes exercised, 2 completed crossings. ZIP CRC integrity, exact eight-file contents, and file hashes matched the build folder.
- Native Windows gallery renders at 1600×900: `artifacts/v1.4-gameplay.png`, `v1.4-cabin.png`, `v1.4-pause.png`, `v1.4-junction.png`, `v1.4-results.png`, `v1.4-street-detail.png`, `v1.4-bus-detail.png`, `v1.4-cng-detail.png`, `v1.4-fob-detail.png`, `v1.4-metro-station.png`, `v1.4-saarc-fountain.png`, `v1.4-crossing-crowd.png`, `v1.4-first-look.png`, `v1.4-monsoon-rain.png`, `v1.4-monsoon-cabin.png`, `v1.4-tea-stall.png`, `v1.4-traffic-police.png`, `v1.4-road-work.png`, `v1.4-breakdown-detail.png`.
- Build: `build/v1.4/DhakaDeadline.exe` and `DhakaDeadline-Windows.zip`; `Play.cmd` selects v1.4. Prior versioned builds (v1.3, v1.2, v1.1, v1.0, v0.9, v0.8, v0.7, v0.6, v0.5, v0.4, v0.3, v0.2) and backup source under `artifacts/before-v1.4/` remain intact.

## Vehicle interior & cockpit interaction, working 3D dashboard instruments, cabin lighting, and rearview mirror pass — 2026-11-22

Version 1.3.0 introduces an interactive vehicle interior, functional 3D dashboard instruments, instrument cluster backlighting, an active rearview mirror camera projection system, and cabin acoustic interior damping while preserving bicycle driving controls, 18-agent traffic contracts, bus bay merge protocols, monsoon weather shaders, and multi-mission progression:
- Cockpit Interior & Instrument Cluster (`scripts/player_car.gd`):
  - Modeled binnacle cluster housing with dual analog dials: Speedometer (0 to 120 km/h calibrated sweep over 220° arc) and Tachometer (0 to 7000 RPM calibrated sweep with redline markings).
  - Dynamic analog needles: `speedo_needle` rotating smoothly with vehicle speed (km/h); `tacho_needle` deflecting dynamically with simulated engine RPM and throttle load.
  - Luminescent cyan instrument cluster backlighting (`cluster_material` with `Color("2fe6c8") * 1.5` emission) automatically synced to vehicle headlights (`set_headlights(enabled)` / `KEY_L`).
  - Steering column and three-spoke steering wheel articulation properly aligned in front of driver's seated vantage.
- Working Rearview Mirror System (`scripts/player_car.gd`):
  - Windshield header-mounted rearview mirror housing with beveled frame.
  - Dedicated `SubViewport` (256x128) and rearward-facing `MirrorCamera` (`rotation.y = PI`, 65° FOV) delivering real-time reflection of trailing traffic, following cars, and rear corridor roadway.
  - Viewport-textured unshaded quad screen material providing crisp, performant real-time rearview projection.
- Cabin Acoustic Interior Damping (`scripts/player_car.gd`, `scripts/main.gd`):
  - Contextual interior sound attenuation active in cabin camera mode (`camera_mode == 2`, `cabin_acoustic_damping == true`).
  - Attenuates exterior city ambience (-28 dB) and tropical monsoon rain downpour (-22 dB) to deliver authentic cabin sound isolation.
- Verified: **329 passing checks** across all 13 test suites (26 systems, 19 driving-feedback, 25 vehicle models, 17 junctions, 23 street art, 36 driving feel & audio, 14 mixed traffic, 23 dynamic routing, 33 settings, 20 missions, 42 corridor landmarks, 33 monsoon weather, 18 cockpit interior). Clean Godot asset import and release export.
- 10-minute / 36,000-step traffic stability simulation (`tests/test_traffic_stability.gd`): 0 vehicle-contact frames, 10 completed pedestrian crossings, 53.48s max wait, >= 1,787.38m travel across all 18 vehicles (`artifacts/traffic-stability.json`).
- Exported Windows package verification: `python tools/verify_build.py` passed with zero errors or warnings. Autodrive completed in 116.63 seconds with 0 collisions and 0 red lights; traffic smoke probe passed with 18 agents, 7,561.40m travel, bus pickup and release, both signal axes exercised, 2 completed crossings. ZIP CRC integrity, exact eight-file contents, and file hashes matched the build folder.
- Native Windows gallery renders at 1600×900: `artifacts/v1.3-gameplay.png`, `v1.3-cabin.png`, `v1.3-pause.png`, `v1.3-junction.png`, `v1.3-results.png`, `v1.3-street-detail.png`, `v1.3-bus-detail.png`, `v1.3-cng-detail.png`, `v1.3-fob-detail.png`, `v1.3-metro-station.png`, `v1.3-saarc-fountain.png`, `v1.3-crossing-crowd.png`, `v1.3-first-look.png`, `v1.3-monsoon-rain.png`, `v1.3-monsoon-cabin.png`.
- Build: `build/v1.3/DhakaDeadline.exe` and `DhakaDeadline-Windows.zip`; `Play.cmd` selects v1.3. Prior versioned builds (v1.2, v1.1, v1.0, v0.9, v0.8, v0.7, v0.6, v0.5, v0.4, v0.3, v0.2) and backup source under `artifacts/before-v1.3/` remain intact.

## Dynamic monsoon weather, wet asphalt shaders, puddle accumulation, dual wipers, and cabin rain pass — 2026-11-22

Version 1.2.0 introduces a comprehensive dynamic monsoon weather system, realistic wet road shaders, curb drainage puddle accumulation, dual animated wiper arms, and cabin rain ambience while strictly preserving predictable bicycle driving controls, 18-agent traffic contracts, bus bay merge protocols, dynamic routing, settings persistence, multi-mission progression, and corridor landmarks:
- Monsoon Weather System (`scripts/district.gd`):
  - Dynamic weather states (`set_weather("monsoon")` vs `set_weather("clear")`).
  - Precipitation particle volume (`RainVolume`): 240 multimesh rain streak instances falling with natural forward wind slant.
  - Specular wet asphalt: dynamically scales road asphalt roughness from 0.94 (dry) down to 0.22 (wet sheen) to simulate road surface saturation.
  - Curb drainage water accumulation (`GutterPuddles`): reflective water sheet volumes along curb drainage gutters with high specular reflectivity (roughness 0.04, metallic 0.20).
  - Overcast monsoon atmosphere: dense rain mist fog (density 0.0035, slate-grey fog color `Color("70787a")`), dim directional sun illumination (energy 0.55).
- Player Car Wipers & Cabin Rain Atmosphere (`scripts/player_car.gd`, `scripts/main.gd`):
  - Dual modeled wiper arms (`wiper_L` and `wiper_R`) attached at the cowl/windshield base with authentic raked pivot orientation.
  - Oscillating wiper sweep animation across 72° arc with mechanical turnaround sound cues (`assets/audio/wiper_sweep.wav`).
  - Interactive wiper toggle mapped to `KEY_K` with dashboard HUD status display (`WIPERS [K] ON / OFF`).
  - Hydrodynamic water splash spray sound (`assets/audio/water_splash.wav`) triggered dynamically under wet conditions when vehicle speed > 6.0 m/s.
  - Continuous tropical downpour ambience loop (`assets/audio/rain_loop.wav`) routed to the dedicated "Ambience" audio bus.
- Playable 4th Mission: "Monsoon Commute" (বর্ষার ঢাকা — জরুরি যাত্রা):
  - Added to `DhakaMissions` registry (id `"monsoon"`, start time 04:38 PM, 150s deadline, torrential downpour conditions).
  - Contextual weather-specific radio dispatch notifications for standing water, low visibility, and slippery braking buffers.
- Verified: **311 passing checks** across all 12 test suites (26 systems, 19 driving-feedback, 25 vehicle models, 17 junctions, 23 street art, 36 driving feel & audio, 14 mixed traffic, 23 dynamic routing, 33 settings, 20 missions, 42 corridor landmarks, 33 monsoon weather). Clean Godot asset import and release export.
- 10-minute / 36,000-step traffic stability simulation (`tests/test_traffic_stability.gd`): 0 vehicle-contact frames, 10 completed pedestrian crossings, 53.48s max wait, >= 1,787.38m travel across all 18 vehicles (`artifacts/traffic-stability.json`).
- Exported Windows package verification: `python tools/verify_build.py` passed with zero errors or warnings. Autodrive completed in 116.63 seconds with 0 collisions and 0 red lights; traffic smoke probe passed with 18 agents, 7,561.40m travel, bus pickup and release, both signal axes exercised, 2 completed crossings. ZIP CRC integrity, exact eight-file contents, and file hashes matched the build folder.
- Native Windows gallery renders at 1600×900: `artifacts/v1.2-gameplay.png`, `v1.2-cabin.png`, `v1.2-pause.png`, `v1.2-junction.png`, `v1.2-results.png`, `v1.2-street-detail.png`, `v1.2-bus-detail.png`, `v1.2-cng-detail.png`, `v1.2-fob-detail.png`, `v1.2-metro-station.png`, `v1.2-saarc-fountain.png`, `v1.2-crossing-crowd.png`, `v1.2-first-look.png`.
- Build: `build/v1.2/DhakaDeadline.exe` and `DhakaDeadline-Windows.zip`; `Play.cmd` selects v1.2. Prior versioned builds (v1.1, v1.0, v0.9, v0.8, v0.7, v0.6, v0.5, v0.4, v0.3, v0.2) and backup source under `artifacts/before-v1.2/` remain intact.

## Farmgate–Karwan Bazar corridor topology, urban landmarks, and localized pedestrian crowd pass — 2026-11-22

Version 1.1.0 introduces the verified Farmgate–Karwan Bazar corridor topology, prominent Dhaka urban architectural landmarks, and localized pedestrian crowd behaviors while preserving 18-agent traffic dynamics, bus bay merging, dynamic routing, and multi-mission progression:
- Topographical corridor layout (`scripts/road_network.gd`):
  - Formally identifies Farmgate hub nodes (`NW`, `W`, `SW`) and Karwan Bazar hub nodes (`NE`, `E`, `SE`).
  - Classifies Kazi Nazrul Islam Avenue as a multi-lane metro arterial (`is_multilane`) and Panthapath connector as standard single-lane.
- Localized urban landmarks (`scripts/district.gd`):
  - Farmgate Foot-Over-Bridge: 5.6m clearance, dual sidewalk staircases, bilingual signage.
  - Karwan Bazar Foot-Over-Bridge across Kazi Nazrul Islam Avenue.
  - Karwan Bazar Metro Station: elevated platform canopy on MRT Line 6 viaduct, sidewalk entrance portal with Bengali transit branding.
  - SAARC Fountain Monument: tiered circular fountain with 7-spire cluster and perimeter water pool.
  - DMP Traffic Police kiosks: hexagonal watch posts at major intersections.
  - Concrete New Jersey median barriers separating opposing multi-lane corridor flows.
  - Overhead bilingual highway direction gantries.
- Localized crowd behaviors (`scripts/main.gd`):
  - 16 pedestrians across hubs, 3-member synchronized zebra crossing crowd, 7.5m driver yielding cushion.

## Multi-mission progression, narrative polish, and production release validation pass — 2026-11-22

Version 1.0.0 delivers the full production milestone, introducing multi-mission progression, contextual narrative audio feedback, dynamic time-of-day atmospheres, and an arrival performance tier grading system while strictly preserving predictable bicycle driving controls, class-differentiated traffic dynamics, 18-agent junction arbitration, signal contracts, and settings manager persistence:
- DhakaMissions system (`scripts/mission_manager.gd`):
  - Three distinct playable assignments selectable directly from the main menu:
    1. **Morning Interview (09:24 AM)**: 09:30 AM appointment (120s deadline), balanced morning rush traffic, clear sunny morning atmosphere.
    2. **Urgent File Delivery (02:16 PM)**: 02:20 PM courier cutoff (85s tight deadline), high-urgency express delivery, bright midday glare.
    3. **Twilight Commute (06:47 PM)**: 06:55 PM transit dropoff (140s deadline), dusk rush hour traffic, warm golden-amber dusk lighting, automatic headlights activation.
- Contextual Radio & Dispatch Narrative:
  - Procedural two-tone radio chime (`assets/audio/radio_chime.wav`: 880 Hz to 1320 Hz) synthesized with zero external recordings.
  - Bilingual top-center dispatch HUD banner presenting situational notifications from control: trip start, red signal compliance reminder, junction clearance reassurance, proactive alternative corridor recommendations, urgency countdown prompts (<20s), and arrival bay approach instructions.
- Performance Tier Grading System:
  - Comprehensive end-of-trip scorecard awarding letter ranks:
    - **Rank S (ওস্তাদ চালক / MASTER DRIVER)**: Flawless run with zero collisions, zero red lights, on-time arrival, and overall score >= 95.
    - **Rank A (দক্ষ চালক / PROFESSIONAL)**: High efficiency and punctual delivery (score >= 80).
    - **Rank B (সতর্ক চালক / CAREFUL DRIVER)**: Safe arrival with minor traffic delays or minor scrape (score >= 65).
    - **Rank C (তাড়াহুড়ো চালক / RUSHED DRIVER)**: Arrived late or multiple minor infractions (score >= 50).
    - **Rank D (বেপরোয়া চালক / IMPRUDENT)**: Poor road compliance or multiple collisions.
    - **Rank F (ব্যর্থ / MISSION FAILED)**: Critical safety compromise (pedestrian collision).
  - Detailed score breakdown across Safety (35%), Punctuality (35%), and Compliance (30%).
- Time-of-Day Dynamic Atmospheres (`scripts/district.gd`):
  - Synchronized WorldEnvironment tonemap exposure, fog color, sun angle, and directional light color/energy dynamically applied per mission.
  - Player car automatic headlight synchronization for evening/dusk conditions.
- Verified: **236 passing checks** across all 10 test suites (26 systems, 19 driving-feedback, 25 vehicle models, 17 junctions, 23 street art, 36 driving feel & audio, 14 mixed traffic, 23 dynamic routing, 33 settings, 20 missions). Clean Godot asset import and release export.
- 10-minute / 36,000-step traffic stability simulation (`tests/test_traffic_stability.gd`): 0 vehicle-contact frames, 10 completed pedestrian crossings, 54.32s max wait, >= 1,769.7m travel across all 18 vehicles (`artifacts/traffic-stability.json`).
- Exported Windows package verification: `python tools/verify_build.py` passed with zero errors or warnings. Autodrive completed in 116.65 seconds with 0 collisions and 0 red lights (`artifacts/exported-autodrive.log`); traffic smoke probe passed with 18 agents, 7,546.22m travel, bus pickup and release, both signal axes exercised, 2 completed crossings (`artifacts/exported-smoke.log`). ZIP CRC integrity, exact eight-file contents, and file hashes matched the build folder (`artifacts/export-verification.json`).
- Inspected native Windows renders at 1600×900: `artifacts/v1.0-gameplay.png`, `v1.0-cabin.png`, `v1.0-pause.png`, `v1.0-junction.png`, `v1.0-results.png`, `v1.0-street-detail.png`, `v1.0-bus-detail.png`, `v1.0-cng-detail.png`, `v1.0-first-look.png`.
- Build: `build/v1.0/DhakaDeadline.exe` and `DhakaDeadline-Windows.zip`; `Play.cmd` selects v1.0. Prior versioned builds (v0.9, v0.8, v0.7, v0.6, v0.5, v0.4, v0.3, v0.2) and backup source under `artifacts/before-v1.0/` remain intact.
- Practical limits: missions utilize the established 6-node / 7-link fictional district layout rather than a full scale Dhaka map; traffic densities are configured via 18 coordinated actors rather than unbounded procedural spawning.

## Graphics and audio settings, persistent configuration, and performance tuning pass — 2026-11-22

Version 0.9.0 introduces comprehensive in-game configuration management, quality presets, and persistent configuration saving while strictly preserving predictable bicycle driving controls, class-differentiated traffic dynamics, 18-agent junction arbitration, and signal contracts:
- DhakaSettings configuration manager (`scripts/settings_manager.gd`):
  - Manages graphical parameters (quality preset, display mode, resolution, shadow atlas size, MSAA 3D, FXAA, 3D resolution scale) and audio bus volumes (Master, Engine, Traffic, Ambience, SFX).
  - Resilient persistence: cleanly serializes to and loads from `user://settings.json` (with sandbox fallback to `res://artifacts/settings.json`), with automated corrupt-file recovery, default fallback, and partial-key merging.
  - Dynamic audio buses: dynamically creates "Engine", "Traffic", "Ambience", and "SFX" audio buses routed into "Master" with proper linear-to-decibel scaling and 0% muting.
  - Quality scaling presets:
    - **Low**: 75% 3D resolution scale, directional shadows disabled (size 0), MSAA disabled, FXAA disabled.
    - **Medium**: 100% 3D resolution scale, medium directional shadow atlas (2048), FXAA enabled, MSAA disabled.
    - **High**: 100% 3D resolution scale, high directional shadow atlas (4096), FXAA enabled, 2X MSAA 3D enabled.
- Interactive Settings & Quality UI (`scripts/hud.gd`):
  - Accessible from both the Main Menu (`show_intro()`) and Pause Menu (`show_pause()`) via a new "Settings & Quality" button.
  - Clean cycling buttons for Quality Preset, Display Mode, Resolution, and individual volume channels (Master, Engine, Traffic, Ambience, SFX) in 10% steps.
  - "Save & Back" button persists configuration to disk and returns to the calling menu smoothly.
- Audio bus integration:
  - `scripts/main.gd`: configures buses on boot, connects ambience player to "Ambience" bus.
  - `scripts/player_car.gd`: assigns engine sound to "Engine", horn, tire roll, skid, and collision impact sounds to "SFX".
  - `scripts/traffic_car.gd`: assigns diesel/CNG engine loops and contextual horns to "Traffic".
- Verified: **216 passing checks** across 9 test suites (26 systems, 19 driving-feedback, 25 vehicle models, 17 junctions, 23 street art, 36 driving feel & audio, 14 mixed traffic, 23 dynamic routing, 33 settings).
- 10-minute / 36,000-step traffic stability simulation (`tests/test_traffic_stability.gd`): 0 vehicle-contact frames, 10 completed pedestrian crossings, 54.32s max wait, >= 1,769.7m travel across all 18 vehicles.
- Exported Windows package verification: `python tools/verify_build.py` passed with zero errors or warnings. Autodrive completed in 116.65 seconds with 0 collisions and 0 red lights (`artifacts/exported-autodrive.log`); traffic smoke probe passed with 18 agents, 7,546.22m travel, bus pickup and release, both signal axes exercised, 2 completed crossings (`artifacts/exported-smoke.log`). ZIP CRC integrity, exact eight-file contents, and file hashes matched the build folder (`artifacts/export-verification.json`).
- Inspected native Windows renders at 1600×900: `artifacts/v0.9-gameplay.png`, `v0.9-cabin.png`, `v0.9-pause.png`, `v0.9-junction.png`, `v0.9-results.png`, `v0.9-street-detail.png`, `v0.9-bus-detail.png`, `v0.9-cng-detail.png`, `v0.9-first-look.png`.
- Build: `build/v0.9/DhakaDeadline.exe` and `DhakaDeadline-Windows.zip`; `Play.cmd` selects v0.9. Prior versioned builds (v0.8, v0.7, v0.6, v0.5, v0.4, v0.3, v0.2) and backup source under `artifacts/before-settings/` remain intact.
- Practical limits: settings UI cycles presets via button clicks rather than continuous sliders or drag controls; resolution switching in windowed mode resizes the window while fullscreen uses current display resolution; headless mode bypasses display server window manipulation.

## Dynamic per-directed-road travel times and route reassessment pass — 2026-11-22

Version 0.8.0 advances route guidance from static coarse queue heuristics to dynamic per-directed-road link travel-time calculations and interactive in-game route reassessment while strictly preserving bicycle driving controls, class-differentiated traffic dynamics, and mission contracts:
- Per-directed-link travel time model:
  - 14 directed road links (`SW <-> W`, `W <-> NW`, `NW <-> NE`, `NE <-> E`, `E <-> SE`, `SE <-> SW`, `W <-> E`) with authored corridor geometry and speed limits (10.0 m/s arterial loops, 8.0 m/s market link).
  - Live congestion & queue tracking: detects agent vehicle positions and velocities projecting onto each directed corridor, calculating queued vehicle delay (2.8s per vehicle clearing delay) and reducing traversal speed based on observed traffic velocities.
  - Intersection approach signal wait: computes exact time-to-green at junctions W and E based on approach corridor axis ("NS" vs "EW"), 40-second signal cycle phase, and pedestrian crossing freeze.
- Dynamic route estimates & recommendations:
  - Real-time route evaluation (`dynamic_route_estimates`) calculates remaining distance, travel time, queue count, and signal wait for "north" and "middle" branches from the vehicle's live position, identifying bottleneck links and tagging the recommended fastest route.
  - Route selection UI displays `★ FASTEST` tags dynamically on the intro screen and pause menu.
- Interactive in-game route reassessment:
  - The driver can press `T` at any time to alternate between North Road and Market Link.
  - Pause menu (`ESC`) features live route reassessment buttons displaying real-time ETA minutes, queue counts, and fastest recommendation tags.
  - Proactive junction suggestions: approaching junction W, if the alternative branch is faster by > 8 seconds, the HUD status banner prompts the driver (e.g. `MARKET LINK FASTER BY 18 SEC — PRESS [T] TO SWITCH`).
  - Seamless visual updates: switching routes immediately refreshes the 3D green guide arrows on the road (`district.show_route`), updates the minimap path and breadcrumb dots, and refreshes the navigation panel turn prompt (`cue`).
  - Missed-turn recovery: overshooting the market link turn at junction W prompts a "return" cue on Market Link, but switching to North Road seamlessly converts the prompt to continuing straight toward the northern junction without penalty.
- Verified: **183 passing checks** across 8 test suites (26 systems, 19 driving-feedback, 25 vehicle models, 17 junctions, 23 street art, 36 driving feel & audio, 14 mixed traffic, 23 dynamic routing). Clean Godot asset import and release export.
- A fresh 36,000-step stability run covering 599.98 simulated seconds recorded zero vehicle-contact frames, ten completed pedestrian crossings, a longest wait of 54.32 seconds, and at least 1,769.7 metres travelled by every traffic agent (`artifacts/traffic-stability.json`).
- Exported Windows package verification: `python tools/verify_build.py` passed with zero errors or warnings. The native exported executable completed the autonomous input-driven mission in 116.65 seconds with zero collisions and zero red-light violations (`artifacts/exported-autodrive.log`); the standalone two-minute traffic smoke probe passed with 18 agents, 7,546.22 metres aggregate travel, bus pickup and release, both green axes, and two completed pedestrian crossings (`artifacts/exported-smoke.log`). ZIP CRC integrity, exact eight-file contents, and file hashes matched the build folder (`artifacts/export-verification.json`).
- Inspected native Windows renders at 1600×900: `artifacts/v0.8-gameplay.png`, `v0.8-cabin.png`, `v0.8-pause.png`, `v0.8-junction.png`, `v0.8-results.png`, `v0.8-street-detail.png`, `v0.8-bus-detail.png`, `v0.8-cng-detail.png`.
- Build: `build/v0.8/DhakaDeadline.exe` and `DhakaDeadline-Windows.zip`; `Play.cmd` selects v0.8. Prior versioned builds (v0.7, v0.6, v0.5, v0.4, v0.3, v0.2) and backup source under `artifacts/before-dynamic-routing/` remain intact.
- Practical limits: route reassessment operates across the authored network links rather than dynamic open-world graph generation; AI traffic follows fixed loop schedules rather than dynamic rerouting based on congestion; HUD route prompt evaluates primary alternative branches.

## Believable mixed-traffic dynamics and bus bay merging pass — 2026-11-22

Version 0.7.0 introduces class-differentiated traffic dynamics, lane-positioning biases, and bus-stop pull-in / re-entry merging behavior while strictly maintaining the 18-agent population, junction arbitration, signal contracts, collision footprint safety, and predictable player interaction:
- Class-specific vehicle dynamics:
  1. `CNG` three-wheelers: agile and nimble acceleration (3.2 m/s²), responsive braking (7.5 m/s²), 8.5 m/s cruise speed, compact 1.8 m safety gap, and natural curb-hugging lateral bias (0.4 m inward offset toward the road shoulder).
  2. `Bus`: heavy diesel inertia with slow acceleration (0.95 m/s²), extended braking distance (4.0 m/s²), 8.0 m/s cruise speed, and generous 3.6 m safety buffer.
  3. `Car`: balanced sedan dynamics (2.2 m/s² acceleration, 5.5 m/s² braking, 10.5 m/s cruise speed, 2.4 m safety gap, centered lateral positioning).
- Physical launch from rest: traffic agents smoothly accelerate from complete stops adhering to their class inertia rather than snapping instantly to cruise speeds.
- Bus-stop pull-in and re-entry merging:
  - During passenger boarding deceleration, the city bus smoothly veers laterally (up to 0.7 m) into the marked bus-stop bay alongside the western road shelter.
  - While boarding, the bus holds its bay offset and displays animated front passenger doors.
  - Upon dwell expiration, before pulling back out into the main lane, the bus executes a re-entry merge protocol: it monitors approaching traffic from behind in the corridor and yields until an adequate headway gap (>7.0 m) is clear, merging smoothly back to lane centerline without causing queue deadlocks or clipping rear vehicles.
- Verified: **160 passing checks** across 7 test suites (26 systems, 19 driving-feedback, 25 vehicle models, 17 junctions, 23 street art, 36 driving feel & audio, 14 mixed traffic). Clean Godot asset import and release export.
- A fresh 36,000-step stability run covering 599.98 simulated seconds recorded zero vehicle-contact frames, ten completed pedestrian crossings, a longest wait of 54.32 seconds, and at least 1,769.7 metres travelled by every traffic agent (`artifacts/traffic-stability.json`).
- Exported Windows package verification: `python tools/verify_build.py` passed with zero errors or warnings. The native exported executable completed the autonomous input-driven mission in 116.65 seconds with zero collisions and zero red-light violations (`artifacts/exported-autodrive.log`); the standalone two-minute traffic smoke probe passed with 18 agents, 7,546.22 metres aggregate travel, bus pickup and release, both green axes, and two completed pedestrian crossings (`artifacts/exported-smoke.log`). ZIP CRC integrity, exact eight-file contents, and file hashes matched the build folder (`artifacts/export-verification.json`).
- Inspected native Windows renders at 1600×900: `artifacts/v0.7-gameplay.png`, `v0.7-cabin.png`, `v0.7-pause.png`, `v0.7-junction.png`, `v0.7-results.png`, `v0.7-street-detail.png`, `v0.7-bus-detail.png`, `v0.7-cng-detail.png`.
- Build: `build/v0.7/DhakaDeadline.exe` and `DhakaDeadline-Windows.zip`; `Play.cmd` selects v0.7. Prior versioned builds (v0.6, v0.5, v0.4, v0.3, v0.2) and backup source under `artifacts/before-mixed-traffic/` remain intact.
- Practical limits: traffic agents follow authored left-hand route splines rather than dynamic freeform lane weaving; lateral curb bias and bus bay pull-in use continuous offset interpolation rather than non-holonomic Ackerman path planning; traffic volume is fixed at 18 agents without dynamic spawning or despawning.

## Driving feel and audio pass — 2026-11-22

Version 0.6.0 enhances physical driving feedback, instrumentation cues, and audio atmosphere while strictly preserving predictable keyboard driving controls and existing mission/traffic contracts:
- Suspension dynamics: physical pitch squat on acceleration (front raises, rear dips), forward pitch dive on heavy braking, tactile collision rebound, dynamic body roll responding to lateral turning acceleration, and subtle high-frequency road texture vibration at speed.
- Steering response: natural caster self-centering return when rolling forward, preserving the grounded bicycle controller without altering turn radii.
- Audio overhaul: nine original synthetic procedural audio assets generated via Python math synthesis (`tools/generate_audio.py`), using zero external recordings, paid assets, or external libraries:
  1. `engine.wav`: 4-stroke 4-cylinder engine combustion loop with simulated 4-speed transmission gear ratios, dynamic RPM pitch scale, and throttle load volume boost.
  2. `tire_roll.wav`: asphalt road rolling texture scaling smoothly in volume and pitch with vehicle speed.
  3. `tire_skid.wav`: high-friction tire scrub/screech activating under hard braking (acceleration < -5.0 m/s²), handbrake slides, or high-speed corner scrub.
  4. `horn.wav`: crisp dual-tone car horn (415 Hz + 495 Hz).
  5. `impact.wav`: low-frequency collision thud with body impact crunch.
  6. `traffic_cng.wav`: distinctive 45 Hz 2-stroke/4-stroke engine putter for moving CNG three-wheelers.
  7. `traffic_bus.wav`: deep 25 Hz heavy diesel combustion chug for the city bus.
  8. `traffic_horn.wav`: short staccato chirp horn triggered contextually by traffic vehicles near queues or signals.
  9. `ambience.wav`: gentle, seamless stereo city soundscape with low-frequency urban rumble and breeze.
- Dashboard feedback: truthful `TRACTION SLIP` amber indicator active during tire slip or hard deceleration alongside `P HANDBRAKE`.
- Verified: **146 passing checks** (26 systems, 19 feedback, 25 vehicle models, 17 junctions, 23 street art, 36 driving feel & audio). Clean Godot asset import and release export.
- A fresh 36,000-step stability run covering 599.98 simulated seconds recorded zero vehicle-contact frames, ten completed pedestrian crossings, a longest wait of 56.32 seconds, and at least 1,592 metres travelled by every traffic agent (`artifacts/traffic-stability.json`).
- Exported Windows package verification: `python tools/verify_build.py` passed with zero errors or warnings. The native exported executable completed the autonomous input-driven mission in 106.67 seconds with zero collisions and zero red-light violations (`artifacts/exported-autodrive.log`); the standalone two-minute traffic smoke probe passed with 18 agents, 7,535.58 metres aggregate travel, bus pickup and release, both green axes, and two completed pedestrian crossings (`artifacts/exported-smoke.log`). ZIP CRC integrity, exact eight-file contents, and file hashes matched the build folder (`artifacts/export-verification.json`).
- Inspected native Windows renders at 1600×900: `artifacts/v0.6-gameplay.png`, `v0.6-cabin.png`, `v0.6-pause.png`, `v0.6-junction.png`, `v0.6-results.png`, `v0.6-street-detail.png`, `v0.6-bus-detail.png`, `v0.6-cng-detail.png`.
- Build: `build/v0.6/DhakaDeadline.exe` and `DhakaDeadline-Windows.zip`; `Play.cmd` selects v0.6. Prior versioned builds (v0.5, v0.4, v0.3, v0.2) and backup source under `artifacts/before-driving-feel/` remain intact.
- Practical limits: procedural audio uses algorithmic synthesis rather than binaural field recordings; suspension is a smoothed kinematic body tilt rather than a simulated 14-DOF spring-damper suspension; traffic honking is rate-limited and proximity-based rather than a complete social driver behavior model. Visuals outside the starting block remain prototype geometry.

## Starting-block visual pass — 2026-11-22

Version 0.5.0 replaces the bus/CNG boxes with detailed generic CC0 models and capsule people with two rigged pedestrian variants. Shared vehicle visuals animate wheels and steering, isolate light materials and open/close the bus's front boarding doors during actual passenger dwell. Pedestrian walk/idle clips follow planar velocity and pause with the simulation. Parked CNGs reuse the same model. The existing player sedan, 18-agent population, collision footprints, road graph, driving response and mission remain.

Four west-road buildings around the starting bus-stop block have textured shopfronts with fictional Bangla signs, weathered plaster, window surrounds, shop props and paved forecourts. The shelter has a bench. Street props and new forecourt/bench collision stay outside driving lanes and the protected crossing. Background towers were corrected to meet the ground. Much of the wider district remains simple procedural architecture.

Verified: 110 passing checks (87 existing + 23 street-art checks), clean Godot import/export, and a fresh 36,000-step stability run covering 599.98 simulated seconds. That run recorded zero vehicle-contact frames, ten completed pedestrian crossings, a longest wait of 56.32 seconds and at least 1,592 metres travelled by every traffic agent. The final native executable completed its input-driven mission in 106.67 seconds with zero collisions/red-light violations; the standalone two-minute traffic probe also passed. ZIP CRC, exact eight-file contents and file hashes match the build folder. Final logs have no errors/warnings. Python setup/conversion scripts compile; model conversion was executed and all 19 included asset hashes verified.

Native Windows renders at 1600×900 were inspected for gameplay/cabin continuity and street, bus and CNG detail: `artifacts/v0.5-gameplay.png`, `v0.5-street-detail.png`, `v0.5-bus-detail.png`, `v0.5-cng-detail.png`. Gallery staging is diagnostic and separate from the input-driven journey proof. A fresh read-only review found no P1/P2 issues and independently checked the 23 art tests, asset hashes, embedded textures, bounds and captures.

Build: `build/v0.5/DhakaDeadline.exe` and its portable ZIP; `Play.cmd` selects v0.5. The v0.4 ZIP still matches the backup under `artifacts/before-street-art/`. The new models/materials are CC0; source links, adaptations and source/converted hashes are recorded in `THIRD_PARTY_NOTICES.md` and `assets/manifest.json`. No license purchase, account or gameplay dependency was added.

Limits: bus/three-wheeler shapes are fitted generic stand-ins, pedestrians are not locally authored residents, and the block is not a verified reconstruction of Dhaka. Clothing, vehicle liveries/drivers, more varied/open shop interiors and the wider district need further art work. This pass did not benchmark frame times or test other PCs. Visual realism and traffic calibration remain work in progress.

## Junction flow pass — 2026-11-22

Version 0.4.0 coordinates traffic using the existing authored junction curves. Entry requires downstream space; conflicting movements wait, compatible opposing straight movements can proceed together, and same-path followers retain physical headway control. Vehicles committed past the stop line clear through signal changes. Before entry, reservations recheck signals and player occupancy, including sideways vehicle footprints. A turn stopped near the entry for over 40 seconds receives a courtesy gap once existing commitments clear; this is a prototype fairness rule, not locally calibrated driver behavior.

The final 87 checks pass: 26 system, 19 driving-feedback, 25 vehicle-model and 17 junction checks. Failing regressions first reproduced blocked-exit entry, reciprocal turning stalls, pre-line reservation errors and player-occupancy gaps. A sustained run exposed starvation by an opposing convoy; admission fairness and same-path following were corrected rather than repositioning stuck vehicles.

The final 36,000-step run covered 599.98 simulated seconds with finite, grounded positions, zero vehicle-contact frames and ten completed pedestrian crossings. Every traffic agent travelled at least 1,592 metres; the longest continuous wait was 56.32 seconds. `tests/test_traffic_stability.gd` exits nonzero for contacts, waits over 90 seconds, insufficient individual progression or failed crossings. Evidence: `artifacts/traffic-stability.json` and `artifacts/traffic-stability-final.log`.

The final exported input-driven trip completed in 106.67 simulated seconds with zero collisions and zero red-light violations. The standalone two-minute traffic probe passed with 18 agents, 7,536 aggregate metres travelled, bus boarding/release, both green axes, two completed pedestrian crossings and a longest observed wait of 50.03 seconds. ZIP CRC, exact eight-file contents and hashes matched the build folder. Final export/probe logs contain no errors or warnings. Gameplay and junction renders were visually inspected at 1600×900 (`artifacts/v0.4-gameplay.png`, `artifacts/v0.4-junction.png`); the final courtesy-distance correction changes no art or UI.

Build: `build/v0.4/DhakaDeadline.exe` and `DhakaDeadline-Windows.zip`; `Play.cmd` selects v0.4. The v0.3 ZIP still matches its pre-change SHA256 backup. No new dependency, asset purchase or license requirement was introduced. Traffic tests use the fixed authored population and do not certify every density, player obstruction or new road layout. Genuine queues remain possible. Art, bus/CNG/pedestrian models, live mirrors, real-world calibration and other-PC performance remain outside this pass.

## Vehicle and foliage pass — 2026-11-22

Version 0.3.0 adds a CC0 sedan with a modeled cabin, mirrors, wheels, lamps and body details. The player uses the provider's LOD0 and traffic uses LOD2. The car is fitted to the existing collision footprint; driving response and traffic routes remain unchanged. Leafy CC0 tree meshes replace the round crowns. Source and converted-file hashes and license links are in `assets/manifest.json`.

The C cycle now includes a right-hand-drive cabin view. Glass was adapted from unsupported transmission materials to alpha glazing. Steering position, wheel/steering animation and per-car light materials have regression checks. Review found right-wheel roll direction, steering-wheel axle and camera-lag errors; each was reproduced by a failing check, corrected, then checked again. The cabin camera stays at its seat position at cruising speed.

Verified: 26 system checks + 19 driving-feedback checks + 25 model checks = 70 passing checks. The final native Windows driving probe completed in 95.9 simulated seconds with zero collisions/red lights. The two-minute traffic scenario and ZIP integrity/file-parity checks passed. Final logs had no errors/warnings. The native exterior and cabin renders were visually inspected at 1600×900; see `artifacts/v0.3-gameplay.png` and `artifacts/v0.3-cabin.png`. The screenshot gallery changes position for layout views; it is separate from the input-driven journey proof.

Build: `build/v0.3/DhakaDeadline.exe` and its portable ZIP. The previous v0.2 ZIP remains unchanged, verified against the backup under `artifacts/before-models/`. The launcher selects v0.3 when present. Converted models are included; the game needs no converter, download or authoring tool to run.

Limits: bus/CNG/pedestrian models and advanced traffic remain unfinished. Mirrors are reflective model surfaces, not live rear-view cameras. The cabin has no functional modeled instruments; the existing HUD remains the driving readout. This pass did not benchmark other GPUs or certify geographic/botanical fidelity.

## Road and driving-feedback pass — 2026-11-22

Version 0.2.0 keeps the driving response and road graph while adding a larger instrument cluster, speed/gear/motion feedback, measured longitudinal acceleration, pedal bars and a handbrake cue. Shared authored routes now drive the minimap, road arrows and next-turn card. Wrong-way, off-route, missed-turn and arrival cues have regression checks. Diagnostic runs now write scores to their artifact folder, separate from the player's last journey.

Roads have separate junction surfaces rather than overlapping road meshes, direction arrows, stop lines, marked shoulders and bus boarding space, textured paving, drainage grates and utility covers. Buildings have additional balconies, rails and downpipes. No new dependency or third-party asset was added.

Verification: 26 existing system checks plus 19 feedback checks passed. New behavior was first observed failing, including the missed-turn and recovery-arrow findings from an independent read-only review, then fixed and checked again. Native renders were inspected at 1600×900 and 1280×720 while accelerating, at a red approach, paused and at arrival. See `artifacts/polish-*-gameplay.png`, `polish-*-junction.png` and `polish-*-results.png`.

The standalone Windows driving/traffic probes and ZIP integrity/file-parity checks are recorded in `artifacts/export-verification.json`. These are fixed scenarios, not a general reliability or graphics-performance guarantee. Detailed vehicle/pedestrian models, a full cockpit, map expansion and advanced traffic remain outside this pass. The prior Windows ZIP and touched source files were retained under `artifacts/before-polish/`.

The earlier milestone evidence below remains historical.

Engine: official Godot 4.7.2 stable (ed1daf0bf), Windows x86_64. Rendered with Vulkan Forward+ on the local RTX 3070. Tests ran locally; no online deployment or publication was performed.

## Verified

| Check | Result |
|---|---|
| Headless system checks | 26 checks passed; no warnings/errors in the final run |
| Exported Windows driving probe | Reached the office and completed the mission in 95.9 simulated real-time seconds; 0 collisions, 0 red-light violations |
| Exported Windows traffic scenario | 7,200 physics steps; 119.98 seconds of simulation; 18 agents |
| Traffic progression | 11,501 metres of aggregate vehicle travel; finite, grounded positions |
| Bus pickup | Boarding happened and the bus subsequently resumed driving |
| Signals and crossing | Both green axes and all-red were exercised; one pedestrian crossing completed, with another active at the end |
| Queues | Peak 11 waiting vehicles; longest observed individual wait 44.83 seconds |
| Native graphical export | Intro, driving HUD, pause and arrival/results rendered and visually inspected |
| Portable ZIP | CRC integrity passed; exact contents and hashes matched the exported files, including required notices |

The input-driven probe uses the real acceleration, braking and steering actions. It does not reposition the car during its journey. The separate screenshot gallery places the player in the arrival bay to inspect the results layout; gallery placement is not evidence of driving completion.

## Evidence

- `artifacts/systems.log`: final 26-check result.
- `artifacts/exported-autodrive.log`: native executable driving probe.
- `artifacts/exported-smoke.log`: native executable traffic probe.
- `artifacts/export-verification.json`: machine-readable results, ZIP checksum and contents.
- `artifacts/exported-gallery.log`: graphical runtime and screenshot paths.
- `artifacts/exported-first-look.png`, `exported-gameplay.png`, `exported-pause.png`, `exported-results.png`: inspected renders.

Reproduce the package checks with `python tools/verify_build.py` after building. The scenario seed is 646301. A fixed seed does not guarantee identical floating-point results across machines or constitute a complete input replay system.

## Practical limits

This verifies the first playable milestone, not the complete design document. Traffic tests cover a small fixed scenario; they do not prove that every route or density is free of deadlocks. Route guidance is a suggested line and a queue-based ETA heuristic, not a complete navigation system. Passing tests does not establish real Dhaka traffic fidelity.

Lighting, PBR asphalt, shadows, haze, signage and street details establish the visual direction. Vehicle meshes, people, vegetation and buildings remain procedural prototype art. Driving uses a custom grounded bicycle model; suspension, tire slip, drivetrain realism, cockpit instruments, rain, gamepad/wheel controls and verified real geography remain future work.

No sustained frame-time benchmark or broad hardware compatibility certification was conducted. Headless test speed is not a frame-rate measurement. The Windows executable is unsigned and uses the Forward+ renderer; low-end GPU fallback/quality settings are not implemented yet.
