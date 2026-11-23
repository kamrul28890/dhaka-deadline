# DHAKA DEADLINE — implementation plan

Decisions recorded 2026-11-15. Target: Windows desktop. Engine: Godot. Visual direction: realistic lighting, materials, proportions and street detail, with placeholder geometry progressively replaced by authored models. Geography: fictional Dhaka-inspired test district first; verified Farmgate–Karwan Bazar later.

## Budget and tools

No purchased license, plugin, asset pack, cloud service, subscription or paid API is required to develop and run this prototype. Godot is MIT licensed and has no engine royalties. Blender and Krita are the planned free art tools. Python and PowerShell handle local setup and packaging. External content is limited initially to CC0 surfaces/sky and an OFL font; keep their source links and license notices.

Sources: [Godot](https://godotengine.org/license/), [Blender](https://www.blender.org/about/license/), [Krita](https://krita.org/en/about/license/), [Poly Haven](https://polyhaven.com/license). Distribution storefront fees, if a storefront is chosen later, are outside this local Windows build plan.

## Milestone 1 — first playable district

Deliver a portable Windows executable with one private car, left-hand driving, chase and bonnet cameras, and a small connected district. The network has six junction nodes, seven bidirectional road links (about 940 metres of centerline), two signal-controlled junctions, a northern route and a market link. This is a fictional layout, not a reconstruction or calibrated model of real Dhaka traffic.

Traffic starts with 18 vehicles in total: private cars, one bus and CNGs, with route following, following distances, signal stops, physical queues and a timed bus pickup. Sidewalk walkers and one protected pedestrian crossing establish basic yielding. A missed deadline permits late completion; a pedestrian collision stops the journey without graphic effects.

The interview mission starts at 09:24 with a 09:30 appointment. The game clock advances three minutes per real minute, leaving a two-minute real-time appointment window. The car must stop near the marked office bay for two seconds. Scoring separates safety, punctuality and compliance. Recovery is explicit and adds a 15-second real-time penalty.

Visual work begins now: PBR asphalt, photographic sky illumination, warm daylight and haze, shadows, reflective paint/glass, modeled road edges, shop shutters and Bangla signage, utility cables, tea stall, bus shelter and elevated metro structure. The car, people, trees and buildings remain authored procedural placeholders. This is a visual foundation for realism, not finished photorealistic art.

### Acceptance

- The Windows build starts without installing Godot or buying anything.
- Keyboard driving, braking, reverse, camera switching and pause work.
- The player can drive to the office and receive a results screen.
- An automated input-driven trip can complete without collisions or red-light violations.
- A repeatable two-minute traffic scenario exercises both green axes and all-red crossings, creates queues, completes bus boarding and releases the bus.
- Agent positions remain finite and grounded; traffic continues moving without hidden repositioning.
- The intro, gameplay, pause and results screens are rendered and visually inspected.
- External asset provenance and required engine/font notices accompany the build.

## Milestone 2 — believable mixed traffic

Improve intersection reservations, turning priority, downstream capacity checks and route choice. Add distinct cycle/electric rickshaw behavior, then motorcycles and safe filtering. Implement the expanded specification's competing bus stops, side-by-side stops and street obstructions as isolated reproducible scenarios. Record agent events and player inputs; a fixed seed alone is not a deterministic replay system.

Replace the aggregate queue-based ETA heuristic with travel-time costs per directed road edge, calibrated from simulated traversals. Add debug overlays for occupancy, planned trajectories and stop reasons. Expand sustained stability runs before increasing population.

## Milestone 3 — realistic art and handling

Author a right-hand-drive interior, detailed sedan/bus/CNG models, wheels, mirrors and animation. Replace simple building blocks and tree crowns with modular geometry, trim sheets and optimized vegetation. Add real concrete/plaster material sets, weathering, shop interiors and appropriate signage density. Establish a reference board from owned or appropriately licensed material.

Prototype suspension, traction, wet-road braking, steering response and collision behavior; select a controller based on measured results. Add rain only after dry-weather driving is stable. Profile rendering, shadows, CPU agent updates and memory on the development PC. The previous 1080p/60 FPS target is an aim, not a measured guarantee.

## Milestone 4 — verified corridor and expanded MVP

Choose a reference period, verify road topology and rights for map data, and reconstruct a small Farmgate–Karwan Bazar corridor. Maintain map-data attribution/license obligations. Calibrate traffic with observations and local feedback. Expand to three missions, contextual Bangla audio and saving/loading. Add the second playable vehicle only after the car, traffic and mission systems are stable.

## Deferred from the first milestone

Whole-city streaming, MassEntity/World Partition/Chaos (Unreal-specific), multiplayer, full cockpit simulation, manual police overrides, six fully distinct AI vehicle classes, 80–150 voiced lines, 12–20 detailed people, dynamic weather and unrestricted city exploration. Their design intent remains in the concept document.

## Evidence and limits

### Dynamic monsoon weather, wet asphalt shaders, puddle accumulation, dual wipers, and cabin rain pass — v1.2

Goal: deliver dynamic monsoon weather system, wet road asphalt shaders, curb drainage puddle reflections, dual animated wiper arms, and atmospheric rain audio while strictly preserving predictable bicycle driving controls, 18-agent traffic dynamics, bus bay merge protocols, dynamic routing, settings persistence, multi-mission progression, and corridor landmarks.

Scope: monsoon weather system (`scripts/district.gd`), procedural downpour, wiper, and water splash audio synthesis in `tools/generate_audio.py`, dual wiper arm modeling and oscillation physics in `scripts/player_car.gd`, wiper toggle input (`KEY_K`) and dashboard indicator in `scripts/hud.gd`, 4th playable mission ("Monsoon Commute") in `scripts/mission_manager.gd`, automated integration test suite in `tests/test_monsoon_weather.gd` (33 checks), sustained 36,000-step traffic stability validation, versioned Windows package under `build/v1.2/`, and launcher priority update in `Play.cmd`.

- [x] Back up touched v1.1 source, config, and portable build ZIP under `artifacts/before-v1.2/`.
- [x] Author automated integration test suite `tests/test_monsoon_weather.gd` (33 checks) covering audio streams, 4th mission in registry, weather states in district, rain precipitation volume, wet asphalt roughness <= 0.35, curb gutter puddles, wiper arm modeling & physical sweep animation, audio bus routing to "Ambience" and "SFX", water splash triggering, and actor groundedness.
- [x] Synthesize three original procedural audio WAV assets via Python math synthesis (`tools/generate_audio.py`): seamless tropical rain loop (`rain_loop.wav`), mechanical wiper sweep (`wiper_sweep.wav`), and hydrodynamic water displacement splash (`water_splash.wav`).
- [x] Implement dynamic weather states in `scripts/district.gd` (`set_weather("monsoon")` vs `set_weather("clear")`), multimesh rain precipitation volume (`RainVolume`), reflective curb drainage puddles (`GutterPuddles`), dynamic asphalt roughness scaling (0.94 dry to 0.22 wet), and overcast sky/mist fog lighting.
- [x] Implement dual wiper arms (`wiper_L` and `wiper_R`) in `scripts/player_car.gd` with physical oscillating sweep animation, mechanical turnaround sound playback, speed-triggered hydrodynamic splash audio, and toggle actions.
- [x] Add Mission 04 "Monsoon Commute" (বর্ষার ঢাকা — জরুরি যাত্রা) to `scripts/mission_manager.gd` with contextual downpour narrative dispatch cues.
- [x] Connect `KEY_K` input action and HUD dashboard WIPERS indicator in `scripts/hud.gd`.
- [x] Run full test suite across all 12 test suites (**311 total passing checks**, 0 failures) and 36,000-step traffic stability simulation (0 contact frames, 10 completed crossings, 53.48s max wait, >= 1,787.38m travel across all 18 vehicles).
- [x] Build and verify `build/v1.2/DhakaDeadline.exe` and `DhakaDeadline-Windows.zip`. Standalone autodrive (116.63s, 0 collisions) and smoke tests pass with 100% hash and ZIP CRC parity.
- [x] Capture inspected native renders at 1600×900: `artifacts/v1.2-gameplay.png`, `v1.2-cabin.png`, `v1.2-pause.png`, `v1.2-junction.png`, `v1.2-results.png`, `v1.2-street-detail.png`, `v1.2-bus-detail.png`, `v1.2-cng-detail.png`, `v1.2-fob-detail.png`, `v1.2-metro-station.png`, `v1.2-saarc-fountain.png`, `v1.2-crossing-crowd.png`, `v1.2-first-look.png`.
- [x] Update `Play.cmd` to prefer v1.2 while retaining v1.1, v1.0, v0.9, v0.8, v0.7, v0.6, v0.5, v0.4, v0.3, and v0.2.

Completed in v1.2.0: 311 passing checks, 0 contact frames in 10-minute stability simulation, 116.63s clean autodrive arrival, verified ZIP parity. See `VALIDATION.md` for full evidence.

### Farmgate–Karwan Bazar corridor topology, urban landmarks, and localized pedestrian crowd pass — v1.1

Goal: establish verified Farmgate–Karwan Bazar corridor topology, authentic Dhaka urban landmarks (Farmgate FOB, Karwan Bazar FOB, Metro Station canopy/portal, SAARC Fountain, DMP police kiosks, concrete median barriers, highway direction gantries), and localized crowd behavior while preserving traffic arbitration and multi-mission progression.

Scope: corridor topology and multilane classification in `scripts/road_network.gd`, urban landmarks and median barriers in `scripts/district.gd`, 16-agent pedestrian population with synchronized crossing crowd and yielding cushions in `scripts/main.gd`, automated integration test suite in `tests/test_corridor_landmarks.gd` (42 checks), sustained 36,000-step traffic stability validation, versioned Windows package under `build/v1.1/`, and launcher priority update in `Play.cmd`.

- [x] Back up touched source and build ZIP under `artifacts/before-v1.1/`.
- [x] Author automated integration test suite `tests/test_corridor_landmarks.gd` (42 checks).
- [x] Implement corridor topology (`CORRIDOR_NODES`, `CORRIDOR_ROADS`, `is_multilane`) in `scripts/road_network.gd`.
- [x] Implement 3D landmarks (Farmgate FOB, Karwan Bazar FOB, MRT Line 6 station canopy and portal, SAARC Fountain, DMP police kiosks, concrete New Jersey median barriers, overhead directional gantries) in `scripts/district.gd`.
- [x] Implement localized crowd behaviors in `scripts/main.gd`: 16 pedestrians across hubs, 3-member synchronized zebra crossing crowd, 7.5m yielding cushion.
- [x] Run full test suite across all 11 test suites (278 total passing checks) and 36,000-step traffic stability simulation.
- [x] Build and verify `build/v1.1/DhakaDeadline.exe` and `DhakaDeadline-Windows.zip`.
- [x] Capture native gallery renders.
- [x] Update `Play.cmd` to prefer v1.1.

Completed in v1.1.0: 278 passing checks, 0 contact frames in 10-minute stability simulation, verified ZIP parity. See `VALIDATION.md` for full evidence.

### Multi-mission progression, narrative polish, and production release validation pass — v1.0

Goal: deliver production milestone v1.0 featuring structured multi-mission selection (Morning Interview, Urgent Delivery, Twilight Commute), procedural radio chime and contextual bilingual dispatch messages, performance tier grading (Rank S/A/B/C/D/F), and dynamic time-of-day atmospheres while strictly preserving predictable bicycle driving controls, class-differentiated traffic dynamics, 18-agent junction coordination, signal contracts, and settings persistence.

Scope: mission manager (`scripts/mission_manager.gd`), procedural radio chime synthesis in `tools/generate_audio.py`, HUD mission selection and dispatch banner in `scripts/hud.gd`, performance grading scorecard in `scripts/hud.gd` and `scripts/main.gd`, dynamic lighting atmospheres in `scripts/district.gd`, automated integration test suite in `tests/test_missions.gd` (20 checks), sustained 36,000-step traffic stability validation, versioned Windows package under `build/v1.0/`, and launcher priority update in `Play.cmd`.

- [x] Back up touched v0.9 source, config, and portable build ZIP under `artifacts/before-v1.0/`.
- [x] Author automated integration test suite `tests/test_missions.gd` (20 checks) covering mission data registry, fallback handling, score and grade calculation (Ranks S/A/B/C/D/F), narrative cues, radio chime stream integrity, specific mission timelines, atmosphere application, headlights control, and HUD integration.
- [x] Implement `DhakaMissions` in `scripts/mission_manager.gd`: manages three distinct missions (Morning Interview, Urgent Courier, Twilight Commute), scoring and performance grading logic, and contextual Bengali/English narrative dispatch cues.
- [x] Synthesize procedural `radio_chime.wav` in `tools/generate_audio.py` using pure mathematical sine wave synthesis without external recordings or dependencies.
- [x] Implement dynamic atmosphere in `scripts/district.gd` (`set_atmosphere`, `update_destination`), dynamically adjusting sun angle, light color, energy, and fog for morning, midday, and evening conditions.
- [x] Connect mission selection, radio chime audio playback, narrative cues, and scoring calculation in `scripts/main.gd`.
- [x] Add mission selector buttons in `show_intro()`, bilingual radio dispatch banner, dynamic mission clock, and comprehensive performance tier scorecard (Rank S/A/B/C/D/F) in `scripts/hud.gd`.
- [x] Run full test suite across all 10 test suites (**236 total passing checks**, 0 failures) and 36,000-step traffic stability simulation (0 contact frames, 10 completed crossings, 54.32s max wait, >= 1,769.7m travel).
- [x] Build and verify `build/v1.0/DhakaDeadline.exe` and `DhakaDeadline-Windows.zip`. Standalone autodrive (116.65s, 0 collisions) and smoke tests pass with 100% hash and ZIP CRC parity.
- [x] Capture inspected native renders at 1600×900: `artifacts/v1.0-gameplay.png`, `v1.0-cabin.png`, `v1.0-pause.png`, `v1.0-junction.png`, `v1.0-results.png`, `v1.0-street-detail.png`, `v1.0-bus-detail.png`, `v1.0-cng-detail.png`, `v1.0-first-look.png`.
- [x] Update `Play.cmd` to prefer v1.0 while retaining v0.9, v0.8, v0.7, v0.6, v0.5, v0.4, v0.3, and v0.2.

Completed in v1.0.0: 236 passing checks, 0 contact frames in 10-minute stability simulation, 116.65s clean autodrive arrival, verified ZIP parity. See `VALIDATION.md` for full evidence.

### Graphics and audio settings, persistent configuration, and performance tuning pass — v0.9

Goal: introduce comprehensive in-game configuration management for graphics quality (presets, resolution, display mode, shadows, MSAA/FXAA) and audio bus volumes (Master, Engine, Traffic, Ambience, SFX), persist settings safely to `user://settings.json`, and provide Low/Medium/High quality scaling presets while strictly preserving bicycle driving controls, class-differentiated traffic dynamics, 18-agent junction arbitration, signal contracts, and native Windows export parity.

Scope: configuration manager (`scripts/settings_manager.gd`), dynamic AudioServer bus creation and routing, graphics quality scaling, UI integration in `scripts/hud.gd` for intro and pause menus, automated integration test suite in `tests/test_settings.gd` (33 checks), sustained 36,000-step traffic stability validation, versioned Windows package under `build/v0.9/`, and launcher priority update in `Play.cmd`.

- [x] Back up touched v0.8 source, config, and portable build ZIP under `artifacts/before-settings/`.
- [x] Author automated integration test suite `tests/test_settings.gd` (33 checks) covering default dictionaries, save/load round-tripping, corrupt file recovery, partial key merging, audio bus routing and linear-to-dB scaling, quality preset application, viewport rendering properties, and HUD menu buttons.
- [x] Implement `DhakaSettings` in `scripts/settings_manager.gd`: manages graphic settings (preset, mode, resolution, shadows, msaa, fxaa, scale_3d), audio bus volumes, safe JSON persistence to `user://settings.json` (fallback `res://artifacts/settings.json`), dynamic AudioServer bus layout, and viewport quality preset adjustments.
- [x] Connect audio bus routing in `scripts/main.gd` (Ambience), `scripts/player_car.gd` (Engine, SFX for horn/tires/impact), and `scripts/traffic_car.gd` (Traffic).
- [x] Implement interactive Settings & Quality menu in `scripts/hud.gd` accessible from both Main Menu and Pause Menu with cycling controls and Save & Back persistence.
- [x] Run full test suite (216 total passing checks across 9 test suites) and 36,000-step traffic stability run (0 contact frames, 10 completed crossings, 54.32s max wait, >= 1,769.7m travel).
- [x] Build and verify `build/v0.9/DhakaDeadline.exe` and `DhakaDeadline-Windows.zip`. Standalone autodrive (116.65s, 0 collisions) and smoke tests pass.
- [x] Capture inspected native renders at 1600×900: `artifacts/v0.9-gameplay.png`, `v0.9-cabin.png`, `v0.9-pause.png`, `v0.9-junction.png`, `v0.9-results.png`, `v0.9-street-detail.png`, `v0.9-bus-detail.png`, `v0.9-cng-detail.png`, `v0.9-first-look.png`.
- [x] Update `Play.cmd` to prefer v0.9 while retaining v0.8, v0.7, v0.6, v0.5, v0.4, v0.3, and v0.2.

Completed in v0.9.0: 216 passing checks, 0 contact frames in 10-minute stability simulation, 116.65s clean autodrive arrival, verified ZIP parity. See `VALIDATION.md` for full evidence.

### Dynamic per-directed-road travel times and route reassessment pass — v0.8

Goal: establish per-directed-road travel-time cost heuristics across all network links based on physical length, free speeds, live vehicle queues, and signal phase cycles; provide real-time route evaluation, fastest-route recommendations, and interactive in-game route reassessment with synchronized 3D road arrows, minimap breadcrumbs, and next-turn prompts.

Scope: per-directed link geometry and travel time calculations in `scripts/road_network.gd`, live queue and signal delay tracking, dynamic route estimation and recommendation logic, interactive in-game route reassessment (`T` key and pause menu) in `scripts/main.gd` and `scripts/hud.gd`, minimap alternative path and breadcrumb rendering, automated integration test suite in `tests/test_dynamic_routing.gd`, sustained 36,000-step traffic stability validation, versioned Windows package under `build/v0.8/`, and launcher priority update in `Play.cmd`.

- [x] Back up touched v0.7 source, config, and portable build ZIP under `artifacts/before-dynamic-routing/`.
- [x] Author automated integration test suite `tests/test_dynamic_routing.gd` (23 checks) covering directed edge enumeration, free-flow traversal times, queue delays, signal wait calculations, dynamic route estimates, congestion rerouting, dynamic route switching, and turn prompt resolution.
- [x] Implement directed link enumeration (`directed_edges`), link travel time cost modeling (`link_cost`), and dynamic route evaluation (`dynamic_route_estimates`) in `scripts/road_network.gd`.
- [x] Add dynamic route switching (`switch_route`, `toggle_route`) and `KEY_T` input handling in `scripts/main.gd`.
- [x] Add fastest route indicator (`★ FASTEST`), in-game pause menu route reassessment controls, proactive junction approach rerouting prompts, and minimap breadcrumb dots in `scripts/hud.gd`.
- [x] Run full test suite (183 total passing checks across 8 suites) and 36,000-step traffic stability run (0 contact frames, 10 completed crossings, 54.32s max wait, >= 1,769.7m travel).
- [x] Build and verify `build/v0.8/DhakaDeadline.exe` and `DhakaDeadline-Windows.zip`. Standalone autodrive (116.65s, 0 collisions) and smoke tests pass.
- [x] Capture inspected native renders at 1600×900: `artifacts/v0.8-gameplay.png`, `v0.8-cabin.png`, `v0.8-pause.png`, `v0.8-junction.png`, `v0.8-results.png`, `v0.8-street-detail.png`, `v0.8-bus-detail.png`, `v0.8-cng-detail.png`.
- [x] Update `Play.cmd` to prefer v0.8 while retaining v0.7, v0.6, v0.5, v0.4, v0.3, and v0.2.

Completed in v0.8.0: 183 passing checks, 0 contact frames in 10-minute stability simulation, 116.65s clean autodrive arrival, verified ZIP parity. See `VALIDATION.md` for full evidence.

### Believable mixed-traffic dynamics and bus bay merging pass — v0.7

Goal: establish distinct physical dynamics, lane-positioning biases, and bus-stop pull-in / re-entry merging behavior for different vehicle classes (buses, CNG three-wheelers, private cars) while preserving the 18-agent population, junction coordination, signal contracts, collision footprint safety, pedestrian crossing priority, and predictable player interaction.

Scope: class-differentiated kinematics (`accel_rate`, `brake_rate`, `cruise_speed`, `min_gap`, `lateral_bias`) in `scripts/traffic_car.gd`, physical launch acceleration from rest, bus-stop pull-in into the marked boarding bay, re-entry merge safety gap checking against closing traffic, automated integration tests in `tests/test_mixed_traffic.gd`, sustained 36,000-step traffic stability validation, versioned Windows package under `build/v0.7/`, and launcher priority update in `Play.cmd`.

- [x] Back up touched v0.6 source, config, and portable build ZIP under `artifacts/before-mixed-traffic/`.
- [x] Author automated integration test suite `tests/test_mixed_traffic.gd` (14 checks) covering class parameters, physical launch from rest, bus bay pull-in offset, and re-entry merge yielding to approaching traffic.
- [x] Implement vehicle class kinematics in `traffic_car.gd`: agile CNGs (3.2 m/s² accel, 7.5 m/s² brake, 8.5 m/s speed, 1.8 m gap, 0.4 m curb offset), heavy diesel buses (0.95 m/s² accel, 4.0 m/s² brake, 8.0 m/s speed, 3.6 m buffer), and standard sedans (2.2 m/s² accel, 5.5 m/s² brake, 10.5 m/s speed, 2.4 m gap).
- [x] Implement physical launch from complete stops adhering to class acceleration limits.
- [x] Implement smooth bus-stop bay pull-in (up to 0.7 m lateral offset) during boarding deceleration and dwell.
- [x] Implement safe re-entry merge protocol upon dwell completion, checking for approaching traffic (>7.0 m clear gap) before rejoining the main lane centerline.
- [x] Run full test suite (160 total passing checks) and 36,000-step traffic stability run (0 contact frames, 10 completed crossings, 54.32s max wait, >= 1,769.7m travel).
- [x] Build and verify `build/v0.7/DhakaDeadline.exe` and `DhakaDeadline-Windows.zip`. Standalone autodrive (116.65s, 0 collisions) and smoke tests pass.
- [x] Capture inspected native renders at 1600×900: `artifacts/v0.7-gameplay.png`, `v0.7-cabin.png`, `v0.7-pause.png`, `v0.7-junction.png`, `v0.7-results.png`, `v0.7-street-detail.png`, `v0.7-bus-detail.png`, `v0.7-cng-detail.png`.
- [x] Update `Play.cmd` to prefer v0.7 while retaining v0.6, v0.5, v0.4, v0.3, and v0.2.

Completed in v0.7.0: 160 passing checks, 0 contact frames in 10-minute stability simulation, 116.65s clean autodrive arrival, verified ZIP parity. See `VALIDATION.md` for full evidence.

### Driving feel and audio pass — v0.6

Goal: improve driving sensation, suspension feedback and audio immersion while strictly preserving predictable keyboard driving controls and existing mission contracts. Use purely procedural/synthetic local audio generation without paid assets or external dependencies.

Scope: suspension pitch/roll dynamics and road vibration in `scripts/player_car.gd`, speed-sensitive steering return, multi-gear simulated engine audio and load dynamics, tire rolling and screech audio, collision impact response, 3D traffic engines and horns in `scripts/traffic_car.gd`, ambient city soundscape in `scripts/main.gd`, dashboard slip indicator in `scripts/hud.gd`, synthetic audio generator in `tools/generate_audio.py`, automated integration test suite in `tests/test_driving_feel_audio.gd`, versioned Windows package under `build/v0.6/`, and launcher update in `Play.cmd`.

- [x] Back up touched v0.5 source, config, and portable build ZIP under `artifacts/before-driving-feel/`.
- [x] Synthesize nine original procedural audio WAV assets via Python math synthesis (`tools/generate_audio.py`): engine, tire roll, tire skid, horn, collision impact, traffic CNG, traffic bus, traffic horn, and city ambience.
- [x] Author automated test suite `tests/test_driving_feel_audio.gd` (36 checks); verify failing red tests on chassis pitch/roll and audio setup prior to implementation.
- [x] Implement smoothed suspension pitch (squat on acceleration, dive on braking, impact rebound) and cornering roll in `player_car.gd`. Retain strict cabin camera seat coordinate locking.
- [x] Implement multi-gear simulated RPM engine pitch and throttle load dynamics, speed-scaling tire rolling sound, dynamic tire skid audio on hard braking/handbrake/corner scrub, and collision impact sound.
- [x] Add positional 3D audio to traffic vehicles (diesel bus, puttering CNG, cars, contextual horns) and ambient city soundscape.
- [x] Add truthful `TRACTION SLIP` indicator to the HUD dashboard during tire scrub or heavy braking.
- [x] Run full test suite (146 total passing checks) and 36,000-step traffic stability run (0 contact frames, 10 completed crossings, 56.32s max wait).
- [x] Build and verify `build/v0.6/DhakaDeadline.exe` and `DhakaDeadline-Windows.zip`. Standalone autodrive and smoke tests pass.
- [x] Capture inspected native renders at 1600×900: `artifacts/v0.6-gameplay.png`, `v0.6-cabin.png`, `v0.6-pause.png`, `v0.6-junction.png`, `v0.6-results.png`.
- [x] Update `Play.cmd` to prefer v0.6 while retaining v0.5, v0.4, v0.3, and v0.2.

Completed in v0.6.0: 146 passing checks, 0 contact frames in 10-minute stability simulation, 106.67s clean autodrive arrival, verified ZIP parity. See `VALIDATION.md` for full evidence.

### Starting-block visual pass — v0.5

Goal: establish one visibly improved starting block (west road around the bus stop and tea stall), with recognizable bus/CNG models and animated pedestrians. Reuse licensed CC0 assets and the existing Godot model-conversion pipeline; keep the road graph, vehicle footprints, traffic rules, mission and driving controls. Adapt a generic three-wheeler and city bus rather than claiming replicas of specific Dhaka vehicles. Alternatives: expanding detail everywhere would dilute this pass; authoring every model from scratch adds work already covered by reusable free assets.

Scope: model preparation/provenance and included GLBs, the existing vehicle visual/helper and their moving/parked callers, pedestrian visuals in `main.gd`, west-block storefront dressing/materials in `district.gd`, regression checks, player docs and a separate v0.5 Windows package. No new gameplay dependency, population increase, rain, new mission, map expansion or saved-data format.

- [x] Back up touched v0.4 source/config and retain its portable build.
- [x] Download checksum-verified bus, people, shopfront/props and three-wheeler; convert unsupported GLB extensions with the existing tools, record source/conversion hashes and licenses. Check import and geometry/animation before use.
- [x] Write and observe failing integration checks for replacing bus/CNG visuals, animation and instance isolation, pedestrian walking/idle/pause, preserved physics footprints, and street dressing clear of driving/crossing space.
- [x] Reuse vehicle animation with model-specific wheel/steering settings; replace pedestrian capsules visually while keeping their collision and protected crossing behavior. Upgrade the selected block's shopfronts, wall materials and small props without blocking sidewalks or sightlines.
- [x] Run all existing and new checks, native driving/traffic probes and the sustained traffic scenario. Inspect actual rendered close-ups and street/cabin views, checking clipping, glass, signs, scale and animation.
- [x] Review the whole change once, fix material findings, build/verify v0.5 and record measured results and limits. Keep v0.4 intact and update `Play.cmd` only for a verified package.

Ruling: execute inline in the existing non-git workspace with targeted backups — the user authorized starting the recommended visual pass; a new repository/worktree or extra approval round adds no product value. Detailed pedestrians are generic stand-ins; local clothing, faces, vehicle liveries and architecture still require reference/calibration.

Completed in v0.5.0: 110 passing checks, native journey/traffic probes, ZIP integrity/parity and inspected native renders. The final ten-minute run has no vehicle contacts and a 56.32-second maximum wait. Source assets and their embedded textures/hashes were independently checked; the whole-change review found no major issues. v0.4 remains unchanged. See `VALIDATION.md` for evidence and remaining visual/performance limits.

### Junction flow pass

Keep the current Godot controller, authored left-hand paths and 18-agent population. Add movement-aware junction entry: verify exit space, give opposing through traffic priority over right turns, reserve conflicting paths until the vehicle's rear clears, and allow compatible opposing straight movements together. Physical player occupancy must also block AI entry. Use the existing network helper and manager rather than a new traffic framework. Exclusive single-car junctions would unnecessarily stop compatible traffic; unrestricted local following cannot detect crossing conflicts.

Scope reaches `road_network.gd`, spawning and junction decisions in `main.gd`, traffic-agent state and speed limits, focused regression scenarios, a sustained traffic run, player instructions and versioned Windows packaging. Preserve driving, art, mission data and the v0.3 executable. No rerouting, extra vehicle classes, geography expansion or purchased dependencies in this pass. Validate blocked-exit release, right-turn yielding, compatible flow, clearance after signal changes and sustained movement before building v0.4. Long-run evidence required a courtesy gap for a turn waiting near entry over 40 seconds, after committed traffic clears, to avoid starvation by an opposing convoy.

Completed as the v0.4 junction-flow increment: 87 passing checks, a ten-minute stability run with no vehicle contacts, clean standalone driving/traffic probes, native rendered QA and ZIP integrity/file-parity checks. v0.3 remains intact. This completes the junction increment, not all of milestone 2: route choice, distinct mixed-traffic classes, observed calibration and expanded scenarios remain.

### Vehicle and foliage pass

Replace the procedural sedan with a verified CC0 model: detailed player model and lighter traffic variant, preserving existing collision dimensions and driving response. Animate wheels and steering, connect the model's brake/headlight lenses to actual vehicle state, and add a right-hand-drive cabin view using the modeled interior. Replace round tree crowns with a leafy CC0 tree. Reuse the existing vehicle entry point and street locations; preserve HUD, navigation and mission behavior.

Scope reaches model download/conversion and provenance, the geometry helper and its player/traffic callers, visual animation, the C camera cycle and player help, tree dressing, model integration checks, all existing tests, Windows export and rendered QA. No gameplay dependency or engine change. The selected art is generic and does not establish verified Dhaka geography or botanical accuracy.

Completed in v0.3.0: full-detail player sedan (LOD0), lighter traffic sedan (LOD2), leafy trees, wheel/steering/light feedback and a right-hand-drive cabin camera. Independent review found wheel-axis, steering-column-axis and moving-camera errors; regressions were reproduced and fixed. The 70 checks and standalone export probes pass. v0.3 is under `build/v0.3/`; v0.2 remains in `build/` so the running old version was not overwritten.

### Gold Master Production MVP & Free Roam City Exploration pass — v1.8.0

Delivers the final Gold Master production release and completes the 18-phase master roadmap:
- Dedicated Free Roam City Exploration Mode: unrestricted driving across the Farmgate–Karwan Bazar corridor without deadlines or appointments, with full traffic simulation, pedestrian crossings, working signals, street foleys, and radio dispatch chatter.
- Cumulative Driver Career Profile (`user://career_profile.json`): persistent tracking of lifetime distance driven, completed missions, free roam runs, passenger fares earned, safety scores, and dynamic Bengali driver honorific titles ("ওস্তাদ চালক", "দক্ষ চালক", etc.) with corrupted profile recovery fallback.
- Screen Coverage & Menu UI Layout Fix: resolved major screen coverage issue where stacked mission and vehicle options exceeded 950px vertical height; re-architected menu layout into compact 2-column GridContainer and horizontal button pairs (~420px height) ensuring the "START JOURNEY" button is always clearly visible and clickable.
- In-Game Production Credits & Attribution: comprehensive credits screen documenting engine provenance, procedural audio math algorithms, CC0 assets, open-source typography (Hind Siliguri OFL), and development roadmap history.
- Verified with 409 passing checks across all 18 test suites, 10-minute collision-free traffic stability, standalone Windows export under `build/v1.8/`, and 19 native 1600x900 gallery renders.

### Ambient urban Dhaka soundscape and street life foleys pass — v1.7.0

Introduces procedural mathematical synthesis of 4 authentic Dhaka urban audio assets (`rickshaw_bell.wav` double chime, `conductor_call.wav` bus conductor route call, `tea_stall.wav` tong er dokan kettle hiss & spoon clink loop, and `hawker_call.wav` fruit seller cry) and 3D positional audio emitters positioned at urban landmarks and vendor stalls along the corridor. Verified with 397 passing checks across 17 test suites, 10-minute collision-free traffic stability, standalone Windows export under `build/v1.7/`, and 19 native 1600x900 gallery renders.

### Real-time traffic congestion heatmap and dynamic dispatch radio pass — v1.6.0

Introduces real-time corridor congestion modeling (`link_congestion`, `all_links_congestion`), dynamic color-coded minimap road segments (Green: Clear, Amber: Slow, Red: Bottleneck with pulsing glow), and automated bilingual radio dispatch alerts with chime suggesting alternative routes (`[T]`). Verified with 375 passing checks across 16 test suites, clean standalone Windows packaging under `build/v1.6/`, and native 1600x900 gallery renders.

### Secondary playable vehicle class — Green CNG Auto-Rickshaw pass — v1.5.0

Introduces a second fully playable vehicle class: the iconic Dhaka Green CNG Three-Wheeler (সিএনজি অটোরিকশা) with 2.8m × 1.4m footprint, snappy 3-wheeler kinematics, articulated steering handlebar, functioning 3D fare meter with digital LED readout (`"ভাড়া: ৳ %d"`), centered saddle open-air cabin vantage point, and custom engine audio. Verified with 361 passing checks across 15 test suites, clean standalone Windows packaging under `build/v1.5/`, and native 1600x900 gallery renders.

### Dynamic traffic events and obstacles pass — v1.4.0

Introduces dynamic road obstacles (construction work zones with cones, barricades, hazard beacons; broken-down delivery vehicle with blinking hazard flashers and warning triangle), sidewalk street stalls (tong er dokan tea stall, fresh fruit/coconut cart), DMP traffic police manual hand gesture overrides, and AI dynamic obstacle avoidance with smooth lateral offsets. Verified with 349 passing checks across 14 test suites, clean standalone Windows packaging, and 19 native 1600x900 gallery renders.

### Cockpit interior and mirror pass — v1.3.0

Introduces interactive vehicle interior elements, functional 3D dashboard instruments (`CockpitCluster` with calibrated speedometer & tachometer needles), luminescent cyan backlighting synced to headlights (`KEY_L`), windshield header rearview mirror with dedicated `SubViewport` (256x128) and rearward `MirrorCamera` projection, and cabin acoustic interior damping in cabin view (`camera_mode == 2`). Verified with 329 passing checks across 13 test suites, clean standalone Windows packaging, and 15 native 1600x900 gallery renders.

### Monsoon weather and wiper pass — v1.2.0

Introduces dynamic monsoon weather system, wet asphalt road shaders, curb drainage puddles (`GutterPuddles`), dual animated wiper arms with mechanical turnaround audio (`wiper_sweep.wav`), interactive wiper toggle (`KEY_K`), hydrodynamic water splash spray audio (`water_splash.wav`), downpour ambience (`rain_loop.wav`), and 4th playable mission ("Monsoon Commute"). Verified with 311 passing checks across 12 test suites.

### Current pass — 2026-11-22

User feedback: the first build lacks detail and basic driving feedback. Scope is the existing road surfaces and street details, readable speed/gear/acceleration and pedal feedback, turn/stop guidance, a world-space route guide and a clear arrival marker. Keep the driving response and current road graph. Touch points: `district.gd` and existing geometry helpers; player telemetry; shared route calculations consumed by HUD, minimap and world cues; mission start; regression tests, Windows export and player instructions. No new dependency, paid asset, geography expansion or saved-data format change.

Check input-derived telemetry and route/arrival cues with small headless tests, inspect rendered views while driving and at two window sizes, then rebuild and verify the standalone Windows package. Procedural art remains a limitation; this pass does not claim to finish realistic traffic, a cockpit or vehicle physics.

Completed in v0.2.0: road/sidewalk dressing, dashboard instrumentation, authored turn guidance, road guide arrows and arrival marker. Review fixes included missed-turn detection, correct recovery-arrow orientation, alignment with lane offsets, and marking the actual bus boarding position. Validation details are in `VALIDATION.md`.

`artifacts/` holds local screenshots and machine-readable checks. `docs/VALIDATION.md` records the verified milestone state. The current tests exercise a small set of fixed scenarios; they do not establish general traffic realism, absence of all deadlocks, real-world ETA accuracy or complete deterministic replay.
