
# DHAKA DEADLINE

## Technical Development Specification — Version 0.3

**Accepted decisions (2026-11-15):** Windows desktop, Godot, realistic visuals from the initial prototype, and a small fictional Dhaka-inspired district before a geographically verified corridor. No purchased tools, plugins, asset packs or licenses are required.

**Scope authority:** `docs/IMPLEMENTATION_PLAN.md` defines the first playable milestone and its acceptance criteria. Sections 2–8 below retain the longer-term simulation design and expanded MVP targets. Their P0 labels do not mean that every listed system must ship in the first prototype.

### 1. Technology Stack

| Component                    | Recommended implementation                             |
| ---------------------------- | ------------------------------------------------------ |
| Game engine                  | Godot 4.7.2 stable, Windows x86_64                       |
| Gameplay                     | GDScript scenes and data-driven mission systems       |
| Player vehicle physics       | Custom CharacterBody3D bicycle-model prototype; later suspension/traction validation |
| Large-scale traffic          | Custom route agents and controllers; profile before scaling |
| Road network                 | Custom directed graph with geometry and restrictions   |
| Local vehicle decisions      | State machines, utility scoring and gap acceptance     |
| Pedestrians                  | CharacterBody3D walkers and protected crossing states |
| Environment                  | Modular meshes, MultiMesh batching, later district streaming |
| Vehicle and character models | Blender                                                |
| Textures and materials       | Blender, Krita, original materials and verified CC0 maps |
| Audio                        | Godot audio nodes, original recordings or synthesis    |
| Navigation and ETA           | Custom time-dependent route planner                    |
| Dialogue                     | Data-driven dialogue graphs and subtitle system        |
| Data tools                   | Python, GeoJSON and structured CSV/JSON                |
| Source control               | Local Git; LFS only when asset size justifies it       |
| Automated testing            | Headless Godot tests, scenario probes and JSON reports |

**Engine caution:** Godot documents known limitations in VehicleBody3D for realistic vehicle physics. The initial custom controller provides grounded driving, steering and braking; it is not a validated suspension, drivetrain or tire simulation. Keep handling replaceable and validate it before making realism claims. See https://docs.godotengine.org/en/stable/classes/class_vehiclebody3d.html.

### 2. Simulation Design

#### 2.1 Road representation

Store each road segment with the following fields:

- Unique road and segment identifiers.
- Centerline and edge geometry.
- Width and available driving space.
- Allowed directions and turns.
- Vehicle restrictions.
- Surface and grip properties.
- Sidewalk geometry and pedestrian crossings.
- Bus boarding areas and informal stopping zones.
- Parking and loading areas.
- Nearby obstructions and roadside activity.
- Intersection connectivity.

The same street may offer different usable widths over time because of parked vehicles, stopped buses, hawker carts, and roadworks.

#### 2.2 Agent behavior model

Each AI vehicle has:

**Persistent characteristics:** Vehicle type, dimensions, acceleration, braking, driver aggressiveness, compliance tendency, and perception capability.

**Current state:** Position, speed, route, destination, passenger load where relevant, and intended maneuver.

**Local observations:** Nearby vehicles, pedestrians, road edges, openings, obstacles, traffic signals, and available stopping areas.

**Decisions:** Continue, accelerate, brake, yield, turn, merge, filter, pick up passengers, wait, or change route.

Use a hierarchical decision model:

1. **Strategic layer:** What is the destination, preferred route, and next stop?
2. **Tactical layer:** Should the vehicle merge, overtake, filter, yield, or stop?
3. **Control layer:** What steering, acceleration and braking commands execute the maneuver?

Decisions should be probabilistic where appropriate, but conditioned on the situation and calibrated using observations. Do not assign random wrong-way movements or wheelies without environmental context.

#### 2.3 Traffic bottleneck and queue simulation

Traffic congestion arises from movement and road occupancy.

Each stopped vehicle reserves its physical footprint. Agents approaching the occupied region check whether a valid passage remains.

If none exists, they slow down and join the queue.

When the queue reaches an upstream intersection, entering traffic may be prevented from clearing the junction. A blocked intersection can then affect adjoining roads.

When vehicles depart, following traffic resumes according to reaction time, spacing, and route availability.

Add deadlock detection for software errors and impossible agent configurations, but do not clear genuine traffic congestion using visible vehicle teleportation.

#### 2.4 Simulation performance levels

To simulate crowded streets efficiently:

| Distance from player   | Approach                                         |
| ---------------------- | ------------------------------------------------ |
| Nearby and visible     | Detailed collision-aware movement and animations |
| Intermediate distance  | Simplified agent movement and collision handling |
| Distant or out of view | Lightweight movement on the road graph           |
| Beyond active district | Aggregate traffic demand and boundary flow       |

Keep vehicle identity, route, and position consistent when switching simulation detail.

**Initial engineering targets:** Approximately 60–120 actively simulated nearby vehicles, with additional distant traffic represented more cheaply. Actual limits must be established through profiling.

Use independent update rates where appropriate: high-frequency vehicle control and collision handling, lower-frequency route planning, and interpolated visual movement.

#### 2.5 Determinism and reproducibility

Development builds must support:

- Repeatable scenario seeds.
- Logged agent maneuvers.
- Recorded collision and congestion events.
- A traffic visualization/debugging interface.
- Scenario replay for investigating bugs.

This is essential. When an intersection gets stuck, developers must be able to reproduce why.

### 3. Geographic Data Pipeline

**Step 1 — Select a reference period.**
Choose a specific period of contemporary Dhaka as the baseline so that roads, restrictions, and visible construction are internally consistent.

**Step 2 — Build a road map.**
Start from appropriately licensed map data and manually verify topology, widths, dividers, directions, crossing locations, and connecting streets.

**Step 3 — Collect field references.**
Capture street-level references from legal, licensed video and photography, public documentation, or locally collected material.

**Step 4 — Observe behavior.**
Measure queue lengths, turning behavior, passenger stops, vehicle classes, gaps, traffic volumes, and pedestrian movement at selected intersections.

**Step 5 — Calibrate simulation.**
Tune agent behavior to reproduce observed traffic patterns.

**Step 6 — Validate locally.**
Ask people who regularly drive or travel in the modeled area to evaluate the road geometry, traffic behavior, dialogue, and overall authenticity.

When collecting new video, use responsible filming practices and avoid unnecessarily retaining identifiable faces or registration details.

### 4. Content and Asset Requirements

#### 4.1 Road and infrastructure assets

- Main road surfaces, narrow side streets, concrete roads and patched asphalt.
- Lane markings, medians, dividers, curbs and uneven footpaths.
- Road signs, directional signs and traffic signals.
- Intersection islands and roundabout elements.
- Bus stops, passenger waiting points and barriers.
- Potholes, speed breakers, drains and manholes.
- Utility poles, wiring, electrical boxes and streetlights.
- Roadworks, barricades and temporary diversions.
- Metro pillars, elevated tracks and station entrances.
- Parking areas, boundary walls and building entrances.

#### 4.2 Vehicle assets

**Required traffic families:**

- Private car and sedan variants.
- Public bus variants.
- CNG auto-rickshaw.
- Pedal rickshaw.
- Electric rickshaw or "Tesla".
- Motorcycle.
- Delivery van and pickup.
- Utility or service vehicle.

Each needs appropriate dimensions, collision geometry, materials, sounds, wheels and animations.

Playable vehicles also require detailed controls, interiors or driver viewpoints, and handling calibration.

#### 4.3 Buildings and street commerce

Use modular buildings for the majority of the district and bespoke models for recognizable landmarks.

Asset families include:

- Residential buildings and apartment blocks.
- Commercial offices.
- Markets and shopping frontages.
- Restaurants, pharmacies and grocery shops.
- Tea stalls and street-food carts.
- Fruit and vegetable stalls.
- Clothing and garment stalls.
- Signboards, shutters, awnings and advertisements.
- Sidewalk seating, delivery goods, crates and temporary structures.

Use fictional commercial brands or obtain permission for protected designs where necessary. Do not rely on arbitrary screenshots or copyrighted photographs as production textures.

#### 4.4 Pedestrians

Initial target:

- 12–20 reusable character base appearances.
- Clothing and accessory variations.
- Standing, walking, waiting, crossing, shopping, carrying and boarding animations.
- Reaction animations for close vehicle interactions.
- Appropriate age and mobility diversity.

Create variation through modular clothing, accessories, body shapes, and animations rather than making every character individually.

#### 4.5 Audio and dialogue

Initial target:

- Separate horn profiles for major vehicle classes.
- Engine and movement sounds.
- Rickshaw bells and electric-vehicle sounds.
- Rain and wet-road sounds.
- Traffic police whistles.
- Street-vendor and market ambience.
- Approximately 80–150 contextual dialogue lines.
- Four to six recurring speaking roles.

Record original Bangla voice acting and maintain subtitle files for localization.

### 5. MVP Backlog

**Priority definitions:**
P0 = required for the expanded MVP, after the smaller first playable milestone.
P1 = required for the intended first commercial-quality release.
P2 = later expansion.

| ID     | Feature                                  | Priority | Completion condition                                         |
| ------ | ---------------------------------------- | -------- | ------------------------------------------------------------ |
| MAP-01 | Accurate road graybox                    | P0       | Continuous drivable and walkable prototype network           |
| VEH-01 | Private car physics                      | P0       | Stable steering, braking, collision and cockpit controls     |
| TRA-01 | Basic agent spawning                     | P0       | Traffic follows valid connected routes                       |
| TRA-02 | Mixed lateral movement                   | P0       | Vehicles choose valid gaps instead of rigid lanes            |
| TRA-03 | Bus stopping and competition             | P0       | Competing pickups can create realistic queues                |
| TRA-04 | Rickshaw crossing and wrong-way behavior | P0       | Route-dependent crossing and interaction with other vehicles |
| TRA-05 | Motorcycle filtering                     | P0       | Riders navigate or abandon narrow-gap maneuvers              |
| TRA-06 | Passenger-stop lane blockage             | P0       | Simultaneous stops cause and release upstream queues         |
| PED-01 | Pedestrian and crossing AI               | P0       | Pedestrians cross, wait, yield and reroute                   |
| ENV-01 | Hawker and sidewalk obstruction          | P0       | Footpath occupancy changes pedestrian movement               |
| NAV-01 | Navigation and ETA                       | P0       | Dynamic rerouting and time-dependent estimates               |
| MIS-01 | Deadline mission system                  | P0       | Arrival time, compliance and outcomes recorded               |
| VEH-02 | Playable electric rickshaw               | P0       | Distinct controls, handling and collision behavior           |
| ENV-02 | Local environmental assets               | P0       | District recognizably represents Dhaka                       |
| AUD-01 | Contextual Bangla audio                  | P0       | Dialogue triggers match events                               |
| QA-01  | Scenario replay and performance tools    | P0       | Developers can reproduce simulation defects                  |
| WEA-01 | Rain, grip and visibility                | P1       | Wet roads change driving and perception                      |
| NAR-01 | Branching narrative                      | P1       | Player decisions affect recurring character interactions     |
| VEH-03 | Additional playable vehicles             | P2       | Motorcycle, CNG and bus player modes                         |
| MAP-02 | Expand to adjacent districts             | P2       | Existing navigation and traffic systems scale                |

### 6. MVP Acceptance Tests

**Test A — Bus competition**

Two buses approach a passenger pickup area. Depending on passenger demand and driver behavior, they may attempt to reach the same boarding position. They must respond to road capacity, may create a queue, and must eventually depart.

**Test B — Side-by-side stopping**

Multiple passenger vehicles stop in adjacent usable road spaces. Traffic behind them must slow or stop. When they depart, the resulting congestion must dissipate without forced repositioning.

**Test C — Rickshaw crossing**

An electric rickshaw attempts to cross a road or reverse direction. Nearby agents must respond to its movement, and the maneuver must resolve without impossible overlapping geometry.

**Test D — Motorcycle filtering**

A motorcycle uses a gap between vehicles. If the gap closes, the rider must brake or abandon the attempt. Sudden maneuvers should be physically possible and uncommon enough to remain believable.

**Test E — Hawker obstruction**

A vendor cart occupies part of the walking space. Pedestrian flow changes. Some pedestrians may move closer to traffic, increasing the need for careful driving.

**Test F — Deadline mission**

The player repeats the same journey under different traffic conditions. Arrival time should vary due to actual simulated congestion and player decisions, not arbitrary post-processing of travel time.

**Test G — Simulation stability**

No persistent AI overlap, unexplained vehicle teleportation, repeatable deadlock, or unrecoverable pathfinding failure is acceptable in normal play.

**Test H — Realism review**

Local drivers review recordings and compare vehicle behavior, queue formation and journey times with observed reality. Their feedback informs calibration.

### 7. Performance and Quality Targets

Initial PC quality target:

- 1920 × 1080 resolution.
- 60 FPS target on an RTX 3060-class development reference machine.
- Adjustable graphics and crowd density.
- Reliable keyboard, mouse and controller support.
- Configurable steering-wheel support after MVP.
- No avoidable frame-time spikes when new traffic agents appear.
- Mission saving and loading at safe simulation states.

These are design targets rather than measured performance guarantees.

For strict simulation, avoid visible shortcuts such as vehicles passing through one another, instantly disappearing from queues, or changing lanes without sufficient physical space.

### 8. Risks and Development Controls

**Highest risk: Traffic AI.**
Build the five defining behaviors in a graybox before investing heavily in final graphics.

**High risk: Performance.**
Use detailed local simulation and lighter distant agents. Profile from the beginning.

**High risk: Geographic fidelity.**
Use verified road geometry and field references; do not confuse map accuracy with accurate street-level behavior.

**High risk: Vehicle variety.**
Build a reusable vehicle controller and data model, then specialize physics and controls for each vehicle type.

**High risk: Scope expansion.**
Do not add the whole of Dhaka, multiplayer, or numerous playable vehicles before the first district works convincingly.

**High risk: Scripted artificiality.**
Favor reusable behavioral rules and observation-based calibration over hundreds of hard-coded traffic incidents.
