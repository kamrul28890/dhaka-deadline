# DHAKA DEADLINE

A Windows 3D driving prototype about reaching an appointment through Dhaka-inspired traffic. Made with Godot; no purchased tools or licenses are needed.

**Play:** double-click `Play.cmd` in the project folder, or `build/v2.0/DhakaDeadline.exe`. For a portable copy, extract `build/v2.0/DhakaDeadline-Windows.zip` and run `DhakaDeadline.exe`. Keep the adjacent `.pck` file with the executable. v1.8, v1.7, v1.6, v1.5, v1.4, v1.3, v1.2, v1.1, v1.0, v0.9, v0.8, v0.7, v0.6, v0.5, v0.4 and v0.3 remain in their versioned build folders, and v0.2 in `build/`. Windows may flag an unsigned locally built executable; this build has no purchased code-signing certificate.

**Edit:** double-click `OpenEditor.cmd`, or open `project.godot` in Godot 4.7.2. The `.tools` folder contains a locally downloaded, checksum-verified engine; it is not installed system-wide.

## Play the interview mission

Select North Road or Market Link, then Start Journey. Follow the minimap to the gold office marker on the eastern road. Brake to a stop inside the marked bay and remain there for two seconds. Keep left and obey traffic signals. A bus pickup, junction queues and a pedestrian crossing affect the trip. You can still finish after the appointment time.

Guidance follows two authored routes; it is not a general route planner. ETA ranges use a simple simulation heuristic, not real Dhaka travel estimates. The starting district is fictional. Driving physics, traffic and much of the environment remain prototypes; see the [development plan](docs/IMPLEMENTATION_PLAN.md).

| Control | Action |
|---|---|
| W / Up | Accelerate |
| S / Down | Brake |
| A D / Left Right | Steer |
| Q | Reverse |
| Space | Handbrake |
| C | Chase / bonnet / right-hand-drive cabin camera |
| V | Cycle vehicle: Sedan / Green CNG 3-wheeler |
| H | Horn |
| L | Headlights |
| K | Wipers (monsoon rain) |
| M | Minimap |
| T | Reroute / switch route choice |
| R | Recover car; adds a time penalty |
| Escape | Pause / resume |
| F3 | Traffic diagnostics |

## Reproduce the build

From PowerShell in this folder:

```powershell
python tools/setup_runtime.py
python tools/generate_audio.py
powershell -ExecutionPolicy Bypass -File tools/build.ps1
```

Setup downloads the official Godot 4.7.2 Windows editor and only the Windows release member of its export-template archive. It verifies the editor against official SHA512 sums, template extraction against ZIP CRC, and downloaded assets against the provider's checksums. Generated geometry and synthetic audio are original to this project.

Run the checks:

```powershell
$engine = '.\.tools\godot\Godot_v4.7.2-stable_win64_console.exe'
& $engine --headless --path . --fixed-fps 60 --script tests/test_systems.gd
& $engine --headless --path . --fixed-fps 60 --script tests/test_driving_feedback.gd
& $engine --headless --path . --fixed-fps 60 --script tests/test_vehicle_models.gd
& $engine --headless --path . --fixed-fps 60 --script tests/test_junctions.gd
& $engine --headless --path . --fixed-fps 60 --script tests/test_street_art.gd
& $engine --headless --path . --fixed-fps 60 --script tests/test_driving_feel_audio.gd
& $engine --headless --path . --fixed-fps 60 --script tests/test_mixed_traffic.gd
& $engine --headless --path . --fixed-fps 60 --script tests/test_dynamic_routing.gd
& $engine --headless --path . --fixed-fps 60 --script tests/test_settings.gd
& $engine --headless --path . --fixed-fps 60 --script tests/test_traffic_stability.gd
& $engine --headless --path . --fixed-fps 60 -- --smoke
& $engine --headless --path . --fixed-fps 60 -- --autodrive
& $engine --path . -- --gallery
```

The headless scenarios advance simulated time faster than wall time. Their speed is not a rendering benchmark. Scenario reports and screenshots go in `artifacts/`. Last-journey scores are written to Godot's `user://last_journey.json` (normally `%APPDATA%\Godot\app_userdata\Dhaka Deadline`).

After building, `python tools/verify_build.py` runs the driving and traffic probes against the exported executable and verifies the ZIP contents against the build folder. Exported diagnostic captures go under `user://artifacts/`.

No accounts, online service, telemetry or multiplayer are part of gameplay. Asset setup needs internet; the built game runs locally. This repository has not been published.

Version 0.2 adds an instrument cluster (speed, D/N/R direction, measured longitudinal acceleration and pedal bars), turn-by-turn cues for the two authored routes, mint road-guide arrows, prominent red/amber warnings and a visible office marker. Roads now have non-overlapping junction surfaces, stop lines, direction arrows, marked shoulders and bus bay, paving and drainage details. Car handling remains unchanged. Arrival still requires a two-second stop; acceleration values are measured from the controller rather than a full drivetrain simulation.

Version 0.3 replaces the sedan and tree placeholders with CC0 models. The player car has a detailed cabin and body; traffic uses a lighter model. Wheels roll with actual travel, front wheels steer, brake lights respond to braking, and L also illuminates the modeled headlight lenses. C cycles through chase, bonnet and right-hand-drive cabin views. Mirrors are reflective art surfaces, not live rear-view cameras. Bus, CNG and pedestrian models remain placeholders.

The converted GLB models are included, so normal editing/building needs no model-conversion tools. To regenerate them, run `python tools/prepare_models.py` on Windows with Node.js/npm available. It downloads pinned, checksum-verified CC0 sources and converts their mesh/texture compression using glTF Transform 4.5.1 and portable KTX-Software 4.4.2. Authoring tools remain under `.tools/`; no global installation or gameplay dependency is added. Model provenance and conversion details are recorded in `assets/manifest.json`.

See [third-party notices](THIRD_PARTY_NOTICES.md), the [design](game_idea.md), [technical specification](dhaka_deadline.md) and [validation](docs/VALIDATION.md).

Version 0.4 adds junction entry coordination. AI waits for downstream room, yields across conflicting paths, and keeps clearing once committed. Opposing straight movements and same-path followers can proceed together. A turn waiting over 40 seconds gets a courtesy gap after committed traffic clears. Signal and player occupancy are rechecked before entry; blocking a junction can still create a real queue. These rules are authored prototype behavior, not calibrated Dhaka traffic.

Version 0.5 improves the starting west-road block around the bus stop: textured shopfronts with fictional Bangla signs, weathered plaster, window frames, paved forecourts, small shop props and a bench. Detailed bus and three-wheeler models replace the boxes, with moving wheels, steering, brake lights and bus boarding doors. Rigged pedestrians walk and idle with actual movement and freeze when paused. Generic source models are adapted to the established physics footprints; they are not exact replicas of local vehicles or people. The road graph, 18-agent population and driving controller remain unchanged. The gallery also captures street, bus and CNG close-ups.

Version 0.6 enhances driving feel and audio while keeping predictable keyboard controls. Physical suspension pitch responds to acceleration (rear squat) and braking (forward dive) with impact rebound on collisions; body roll reacts to cornering lateral acceleration and micro road vibration adds surface texture. Steering self-centers naturally when rolling forward. Audio is overhauled with a synthesized 4-cylinder engine loop featuring 4-speed transmission RPM pitch and throttle load modulation, road tire rolling hum scaling with speed, dynamic tire screech under hard braking/handbrake/corner scrub, collision impact thud, dual-tone horn, 3D diesel bus and CNG auto-rickshaw engines, occasional contextual traffic horns, and a gentle ambient city soundscape. The dashboard adds a TRACTION SLIP indicator. Telemetry, navigation, arrival and traffic safety contracts remain fully preserved.

Version 0.7 introduces class-differentiated traffic dynamics (agile 3.2 m/s² curb-hugging CNGs with 0.4 m lateral offset, heavy diesel inertia 0.95 m/s² city buses with 3.6 m safety gaps, standard sedans with centered tracking), physical launch acceleration from rest, bus-stop boarding bay pull-in (up to 0.7 m lateral offset into marked bay), and safe re-entry merge protocol yielding to closing traffic. Junction coordination, signal contracts, collision footprint safety, and 18-agent population remain preserved.

Version 0.8 introduces dynamic per-directed-road travel-time heuristics across all 14 directed links (incorporating link length, free speeds, live agent queue delays, traffic speeds, and signal phase wait calculations). Real-time route estimates and fastest-route recommendation (`★ FASTEST`). Interactive in-game route reassessment via `T` key, pause menu route selection with live ETAs, proactive junction approach rerouting prompts, updated 3D road arrows, minimap breadcrumbs and alternative route visualization, and dynamic next-turn prompt resolution.

Version 0.9 introduces comprehensive in-game configuration management, quality presets, and persistent configuration saving. The `DhakaSettings` configuration manager cleanly saves and loads player preferences to `user://settings.json`, manages audio bus routing ("Master", "Engine", "Traffic", "Ambience", "SFX") with linear-to-dB conversion and muting, and applies Low, Medium, and High quality presets dynamically adjusting 3D resolution scale, shadow atlas resolution, MSAA, and FXAA. Settings are accessible from both the Main Menu and Pause Menu via an interactive cycling UI.

Version 1.0 delivers the full production milestone, introducing structured multi-mission selection (Morning Interview, Urgent Courier, and Twilight Commute), procedural radio chime audio synthesis (`radio_chime.wav`), contextual bilingual dispatch HUD banner, arrival performance tier grading (Rank S/A/B/C/D/F), and dynamic time-of-day atmospheres (morning, midday, evening) with automatic headlights synchronization. All existing driving controls, 18-agent traffic dynamics, bus bay merging, dynamic routing, and persistent settings remain fully preserved.

Version 2.0 introduces the 20.5 km Grand Shahbag-to-Uttara Expressway Corridor (`scripts/corridor_expressway.gd`), dynamic animated monsoon rain and interactive windshield wipers (`scripts/dynamic_weather.gd`), and realistic collision consequences with DMP highway police pursuit (`scripts/collision_consequences.gd`). The corridor spans 7 authentic Dhaka sectors (Shahbag, Bangla Motor/Karwan Bazar MRT viaduct, Farmgate/Bijoy Sarani, Mohakhali Elevated Flyover, Banani/Kakoli, Kuril Interchange, and HSIA Terminal 3/Uttara) with physical barriers, bilingual gantries, and airport approach lighting. Weather features 12,000 falling rain GPU particles with velocity shear and windshield droplet shaders cleared by wiper key `K`. Collisions dynamically dent vehicle meshes, trigger sparking and radiator steam caps, and summon DMP highway patrol pursuit.

