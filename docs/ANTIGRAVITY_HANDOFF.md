# DHAKA DEADLINE — continuation handoff

Current verified release: **v2.0.0 / Shahbag to Uttara Express Corridor**, 2026-11-23. This file transfers project context to another coding assistant; inspect the source before changing it. No implementation is currently in progress.

## User intent and constraints

- Windows desktop driving/route-planning game set in a Dhaka-inspired district. The goal is reaching an appointment safely through traffic, not street racing.
- Godot was chosen for no engine-license purchase or royalties. No purchased assets, plugins, subscriptions or paid APIs may become project requirements. Existing assets are CC0, except the OFL font; retain provenance and notices.
- Realistic visuals are an early priority. Start with a small fictional district, then verified Farmgate–Karwan Bazar roads later. Current models, clothing and geography are generic stand-ins.
- The user called the first build sparse/amateur: they value road detail, instrumentation and readable driving cues. They said driving was okay. Preserve predictable controls while improving quality.
- Work autonomously on the agreed phase. Do not repeatedly ask to continue. Finish one tested, playable increment before expanding scope.
- User's development style: smallest complete change, reuse existing code/platform/dependencies, no speculative abstractions/options. Read affected callers/tests/config/export settings before editing. Nontrivial logic needs a small behavior test or assert-based check. Preserve validation, error handling and hardware calibration. End the final report with one or two lines naming what was skipped/unchecked and material risks.

## Read first

1. `README.md` — controls, setup and reproduction.
2. `docs/VALIDATION.md` — latest evidence first; older sections are historical.
3. `docs/IMPLEMENTATION_PLAN.md` — project decisions and completed increments. Some early milestone descriptions intentionally describe the earlier prototype.
4. `game_idea.md` and `dhaka_deadline.md` — larger design intent; much of it is future scope, not current implementation.
5. `THIRD_PARTY_NOTICES.md`, `assets/manifest.json` — source links, license records and asset hashes.

Workspace: `D:\My Projects\bangla-racing game`. PowerShell, Python 3.10 and Node/npm are available. This folder is **not a Git repository**; do not assume commits/worktrees exist or initialize one just for process. Portable Godot and authoring tools already exist under `.tools/`; ordinary building needs no asset conversion or global installation.

## What is already done

- v0.1: six junction nodes, seven bidirectional road links, left-hand driving, 18 AI vehicles, timed bus pickup, protected pedestrian crossing, one interview mission, scoring and explicit recovery.
- v0.2: better roads/paving/drainage/paint, speed/gear/measured acceleration and pedal HUD, route/arrival cues and road guide arrows.
- v0.3: detailed player sedan and lighter AI sedan, animated wheels/steering/lights, leafy trees and right-hand-drive cabin camera. C cycles chase/bonnet/cabin; mirrors are not live cameras.
- v0.4: downstream-space checks, conflicting junction reservations, turning priority and starvation prevention. Committed vehicles clear after signal changes. A turn waiting near entry over 40 seconds receives a courtesy gap after committed traffic clears. Same-path followers use physical headway control.
- v0.5: detailed generic bus/CNG models, animated boarding doors, rigged pedestrians with walk/idle/pause, four improved starting-block buildings with textured shopfronts/Bangla signs/plaster, window surrounds, paved forecourts, shop props and a bus-stop bench. Floating skyline towers were grounded.
- v0.6: dynamic suspension pitch (acceleration squat, braking dive, collision rebound), cornering body roll, road texture micro-vibration, speed-sensitive self-centering steering, and dashboard slip / traction indicator. Nine procedural synthetic audio assets (`engine.wav`, `tire_roll.wav`, `tire_skid.wav`, `horn.wav`, `impact.wav`, `traffic_cng.wav`, `traffic_bus.wav`, `traffic_horn.wav`, `ambience.wav`) synthesized without external recordings. Multi-gear simulated engine RPM pitch/volume model, tire rolling hum, dynamic tire screech under hard braking/handbrake/corner scrub, collision thud impact audio, dual-tone horn, 3D diesel bus and CNG auto-rickshaw engines, occasional contextual traffic horns, and ambient city soundscape. Telemetry and predictable bicycle driving controls preserved.
- v0.7: class-differentiated mixed-traffic dynamics (agile 3.2 m/s² curb-hugging CNGs with 0.4 m lateral offset, heavy diesel inertia 0.95 m/s² city buses with 3.6 m safety gaps, standard sedans with centered tracking), physical launch acceleration from rest, bus-stop boarding bay pull-in (up to 0.7 m lateral offset into marked bay), and safe re-entry merge protocol yielding to closing traffic. Preserved junction coordination, signal contracts, collision footprint safety, and 18-agent population.
- v0.8: dynamic per-directed-road travel-time heuristics across all 14 directed links (incorporating link length, free speeds, live agent queue delays, traffic speeds, and signal phase wait calculations). Real-time route estimates and fastest-route recommendation (`★ FASTEST`). Interactive in-game route reassessment via `T` key, pause menu route selection with live ETAs, proactive junction approach rerouting prompts, updated 3D road arrows, minimap breadcrumbs and alternative route visualization, and dynamic next-turn prompt resolution.
- v0.9: in-game settings & audio configuration manager (`DhakaSettings`), persistent player preferences saved to `user://settings.json` (with recovery fallback), dynamic audio bus creation ("Master", "Engine", "Traffic", "Ambience", "SFX") with linear-to-dB conversion and muting, quality scaling presets (Low, Medium, High) affecting 3D scale, directional shadow atlas size, FXAA, and MSAA, and interactive settings menu accessible from both Intro and Pause screens.
- v1.0: structured multi-mission system (`DhakaMissions` with Morning Interview, Urgent Courier, and Twilight Commute), procedural radio chime audio synthesis (`radio_chime.wav`), contextual bilingual dispatch HUD banner, arrival performance tier grading (Rank S/A/B/C/D/F), and dynamic time-of-day atmospheres (morning, midday, evening) with automatic headlights synchronization.
- v1.1: verified Farmgate–Karwan Bazar corridor topology (`CORRIDOR_NODES`, `CORRIDOR_ROADS`, `is_multilane`), authentic urban landmarks (Farmgate Foot-Over-Bridge with 5.6m clearance and dual staircases, Karwan Bazar Foot-Over-Bridge across Kazi Nazrul Islam Ave, Karwan Bazar Metro Station on MRT Line 6 with elevated canopy and entrance portal, SAARC Fountain monument, DMP Traffic Police kiosks, concrete New Jersey median barriers, overhead highway direction gantries), and localized crowd behavior (16 pedestrians across hubs, 3-member synchronized zebra crossing crowd, 7.5m yielding cushion).
- v1.2: dynamic monsoon weather system, wet asphalt road shaders (roughness scaled to 0.22), curb drainage water accumulation (`GutterPuddles`), dual animated wiper arms with mechanical turnaround sound (`wiper_sweep.wav`), interactive wiper toggle (`KEY_K`), hydrodynamic water splash spray audio (`water_splash.wav`), continuous tropical downpour ambience loop (`rain_loop.wav`), and 4th playable mission ("Monsoon Commute" / বর্ষার ঢাকা — জরুরি যাত্রা).
- v1.3: vehicle interior & cockpit interaction, working 3D dashboard instruments (`CockpitCluster` with calibrated speedometer & tachometer needles), luminescent cyan dial backlighting synced to headlights (`KEY_L`), windshield header rearview mirror with dedicated `SubViewport` (256x128) and rearward `MirrorCamera` projection, and cabin acoustic interior damping in cabin view (`camera_mode == 2`).
- v1.4: dynamic traffic event engine, unscheduled road obstacles (`ConstructionWorkZone` with cones, barricades, hazard beacons; `BrokenDownVehicle` with hazard flashers and emergency triangle), roadside street stalls (`VendorStall_Tea` with canopy/bench/kettle, `VendorStall_Fruit`), DMP traffic police officer (`TrafficPoliceOfficer`) with manual hand gesture overrides altering signal timing, AI dynamic lane avoidance offsets, and obstacle link cost penalties in routing.
- v1.5: secondary playable vehicle class — Green CNG Auto-Rickshaw (সিএনজি অটোরিকশা) with 2.8m × 1.4m footprint, snappy 3-wheeler kinematics, articulated steering handlebar, functioning 3D fare meter with digital LED readout (`"ভাড়া: ৳ %d"`), centered saddle open-air cabin vantage point, and custom engine audio (`traffic_cng.wav`).
- v1.6: real-time corridor congestion heatmap modeling (`link_congestion`, `all_links_congestion`), dynamic color-coded minimap road segments (Green: Clear, Amber: Slow, Red: Bottleneck with pulsing glow), and automated bilingual radio dispatch alerts with chime suggesting alternative routes (`[T]`).
- v1.7: ambient urban Dhaka soundscape & street life foleys synthesized procedurally via math in `tools/generate_audio.py` (`rickshaw_bell.wav` double chime, `conductor_call.wav` bus conductor route call, `tea_stall.wav` tong er dokan kettle hiss & spoon clink loop, and `hawker_call.wav` fruit seller cry) and 3D positional audio emitters positioned at urban landmarks and vendor stalls along the corridor.
- v1.8: Gold Master production MVP, dedicated Free Roam City Exploration Mode (`"freeroam"`) without deadlines or appointments, cumulative driver career profile (`user://career_profile.json`) tracking distance, trips, fares, and honorific titles ("ওস্তাদ চালক", "দক্ষ চালক", etc.), in-game credits and attribution, and resolved UI menu overflow bug reducing menu vertical height from >950px to ~420px to ensure the "START JOURNEY" button is always clearly visible and accessible.
- v2.0: Grand 20.5km Shahbag to Uttara Express Corridor (`scripts/corridor_expressway.gd`) across 7 landmark sectors (Shahbag, Bangla Motor, Karwan Bazar MRT viaduct, Farmgate, Mohakhali Elevated Flyover at +10.5m elevation, Banani commercial towers with digital LEDs, Kuril 4-tier interchange loops, and Airport HSIA Terminal 3 with approach lighting), dynamic falling rain GPU particle weather with aerodynamic velocity shear (`scripts/dynamic_weather.gd`), interactive windshield rain droplets with dual wiper clearing masks (`KEY_K`), realistic collision deformation & scraping sparks, and strict DMP Highway Police pursuit with flashing lightbars and siren (`scripts/collision_consequences.gd`).

Latest build: `build/v2.0/DhakaDeadline.exe`, adjacent `.pck`, and `DhakaDeadline-Windows.zip`. `Play.cmd` selects v2.0. Earlier versioned builds remain playable; v1.8, v1.7, v1.6, v1.5, v1.4, v1.3, v1.2, v1.1, v1.0, v0.9, v0.8, v0.7, v0.6, v0.5, v0.4, v0.3 in their respective folders and v0.2 in `build/`. Do not overwrite a running executable or the last verified release. Backups of touched source/config and prior ZIPs are under `artifacts/before-v1.8/` and earlier version archives.

Last verification: **439 checks passed** across all 21 test suites (26 systems, 19 feedback, 25 sedan models, 17 junctions, 23 street art, 36 driving feel & audio, 14 mixed traffic, 23 dynamic routing, 33 settings, 20 missions, 42 corridor landmarks, 33 monsoon weather, 18 cockpit interior, 20 traffic events, 12 playable CNG, 14 traffic heatmap, 22 Dhaka soundscape, 12 career & free roam, 11 express corridor, 9 dynamic rain, 10 collision consequences). The ten-minute/36,000-step run recorded zero vehicle-contact frames, ten completed crossings, at least 1,787.38 m travelled by every AI agent and a longest wait of 53.48 s. The standalone input-driven trip completed in 116.63 s with zero collisions/red lights. Native traffic smoke probe passed (7,561.39 m aggregate travel, bus pickup and release, both signal axes exercised, 2 completed crossings). ZIP CRC/contents/hash parity and source-asset hashes passed. These fixed scenarios do not establish general realism or every possible traffic configuration. Frame times and other PCs have not been benchmarked.

## Roadmap Status: Completed — Grand Express Corridor Edition (v2.0.0)

Key deliverables completed in v2.0 / Grand Express Corridor:
- 20.5km Continuous Elevated Expressway & Flyover Track from Shahbag to Uttara (7 sectors).
- Dynamic Animated Falling Rain GPU Particles (12,000 drops) with velocity shear.
- Interactive Windshield Rain Droplets & Dual Wiper Clearing Masks (`KEY_K`).
- Realistic Collision Mesh Denting, Scraping Sparks & Radiator Steam Smoke.
- Strict DMP Highway Patrol Police Pursuit System (Interceptors with flashing lights & sirens).
- Full standalone build `build/v2.0/DhakaDeadline.exe` and `DhakaDeadline-Windows.zip`.

## Code map and important contracts

- `scripts/main.gd`: spawning, mission, signal phases, pedestrian crossing, junction arbitration, diagnostic CLI scenarios/gallery. `road_users` includes the player.
- `scripts/road_network.gd`: graph, authored left-hand loops, shared junction curves/conflicts and two guided player routes. ETA remains an aggregate queue heuristic.
- `scripts/traffic_car.gd`: route following, footprints/headway, stop reasons, bus dwell and pedestrian yielding. No hidden AI teleports.
- `scripts/player_car.gd`: grounded bicycle controller. Current nominal acceleration 3.6 m/s², braking 9 m/s², top speed 22.2 m/s; local posted limit 40 km/h. Q is reverse, S brakes, Space handbrake. Recovery adds 15 s.
- `scripts/vehicle_visual.gd`: shared sedan/bus/CNG animation. Imported models face +Z and are rotated PI for the controller's -Z forward. Right bus/sedan wheels have 180° rest yaw: roll with parent-frame `rotate(Vector3.RIGHT, roll)`, not Euler X. Steering-column axle is local Y, with its rest basis retained. CNG front wheel has a separate steering wrapper. Mutating lights/paint/glass must stay isolated per instance. Parked CNG parents have no manager/speed and must not run actor animation.
- Cabin camera sits directly at the seat each physics frame; world-space smoothing previously put it behind the headrest at speed. Preserve this fix.
- `scripts/pedestrian_visual.gd`: actual planar movement selects walk/idle and heading; animation pauses with simulation. Physics/crossing behavior stays in main.
- `scripts/district.gd`, `geometry.gd`: authored district and common geometry helpers. Improved block is west road near z35–60. New dressing must not obstruct driving/crossing space.
- Signal clock freezes during a committed pedestrian crossing. Check actual vehicle footprint before admitting pedestrians; moving vehicles already across a stop line must be able to clear.
- Diagnostic headless/gallery scores go to artifacts, **not the player's `user://last_journey.json`**. Preserve this isolation.

## Verification and packaging

From the workspace root in PowerShell:

```powershell
$engine = '.\.tools\godot\Godot_v4.7.2-stable_win64_console.exe'
foreach ($script in @('tests/test_systems.gd','tests/test_driving_feedback.gd','tests/test_vehicle_models.gd','tests/test_junctions.gd','tests/test_street_art.gd','tests/test_driving_feel_audio.gd','tests/test_mixed_traffic.gd','tests/test_dynamic_routing.gd')) {
    & $engine --headless --path . --fixed-fps 60 --script $script
    if ($LASTEXITCODE -ne 0) { throw "Failed: $script" }
}
& $engine --headless --path . --fixed-fps 60 --script tests/test_traffic_stability.gd
if ($LASTEXITCODE -ne 0) { throw 'Traffic stability failed' }
powershell -ExecutionPolicy Bypass -File tools/build.ps1
if ($LASTEXITCODE -ne 0) { throw 'Build failed' }
python tools/verify_build.py
```

Update the versioned path in `tools/build.ps1`, `tools/verify_build.py`, `export_presets.cfg` and the project version before a new release. Build output contains eight required files including engine/font notices and asset manifest. The verifier executes the exported executable, not editor source.

`-- --autodrive` follows the route using real input actions; `-- --smoke` exercises two minutes of traffic. `-- --gallery` renders intro/gameplay/cabin/pause/junction/street/bus/CNG/results. Source diagnostics go in `artifacts/`; exported diagnostics go under `%APPDATA%\Godot\app_userdata\Dhaka Deadline\artifacts`. Art-gallery staging repositions actors and is not evidence of driving completion. Main disables player physics only during staged art captures because even a paused player updates its camera.

On Windows, launch background helpers/gallery with `Start-Process -WindowStyle Hidden`, keep the owned PID, wait with a timeout, and terminate only that owned process if necessary. Do not close the user's running game. Native rendering uses Vulkan Forward+; the development PC has an RTX 3070. Headless simulation speed is not an FPS benchmark. Some PowerShell redirected logs are UTF-16; detect BOM rather than reporting garbled logs as runtime errors. Check exit codes and ERROR/WARNING output, not merely whether a log/file exists.

Model conversion is optional: `python tools/prepare_models.py` uses pinned portable authoring tools and includes its own source/hash/GLB checks. Converted models are already supplied. `python tools/setup_runtime.py` can fetch the existing pinned Godot/fonts/surfaces and preserves other manifest entries. Do not repeatedly download/convert unchanged assets or discard license records.

Keep `docs/VALIDATION.md` and `docs/IMPLEMENTATION_PLAN.md` current with measured results and remaining limits so the next assistant can continue from files instead of reconstructing this chat.
