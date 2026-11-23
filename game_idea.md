Game concept: DHAKA DEADLINE
Game Design Specification — Version 0.1

> Implementation decisions — 2026-11-15: Windows desktop; Godot with no engine fees or royalties; realistic visuals as an early priority; a small fictional Dhaka-inspired district before verified Farmgate–Karwan Bazar geography. The staged scope in `docs/IMPLEMENTATION_PLAN.md` governs development. The broader feature list below describes the intended game, rather than the first playable milestone.

Tagline: ঢাকার রাস্তায় গাড়ি চালানো সহজ, সময়মতো পৌঁছানোই আসল চ্যালেঞ্জ।

The game I would recommend is a realistic, open-world driving and urban-life simulation set in Dhaka, Bangladesh, where the player's objective is not to drive faster than other vehicles, but to reach a destination on time while dealing with the actual difficulties of the city.

Unlike GTA, Forza, or conventional driving simulators, the primary opponent is not another driver. It is the city itself: traffic congestion, unpredictable road users, blocked intersections, monsoon rain, road conditions, and everyday responsibilities.

Importantly, I would not design it as a game where everything is chaotic all the time. Dhaka changes by neighborhood, time of day, weather, and road type. Capturing those differences will make it believable.

Research supports making mixed traffic, pedestrian movement, roadside obstructions, and waterlogging central features rather than decorative details. Dhaka's traffic also involves safety risks that should have meaningful consequences in the simulation.
The Daily Star+2

1. Visual identity: Dhaka should be recognizable
   Real-world photographic references for the game environment

Mixed urban traffic

Footpaths and street activity

Rickshaws and local streets

The game should capture things that make a street immediately recognizable as Dhaka: Bangla shop signs, colorful buses, decorated rickshaws, green CNG auto-rickshaws, pedestrians waiting to cross, tea stalls, crowded intersections, metro rail structures, and even the particular soundscape of the city.

The experience should feel familiar enough that someone who has lived in Dhaka might recognize not just the location, but the situations.
2. Full gameplay specification
DHAKA DEADLINE
Game Design Document (GDD) — Draft v0.1

Genre: Realistic urban driving, simulation, time-management, decision-making
Setting: Contemporary Dhaka, Bangladesh
Primary mode: Single-player, mission-based driving within an explorable city
Perspective: First-person cockpit and third-person camera
Core objective: Complete everyday journeys within realistic time constraints without compromising safety.

1. Core Game Philosophy
   The central challenge is reaching a destination, not outrunning other vehicles.

Players must anticipate congestion, respond to changing road conditions, choose routes, handle other road users, and make decisions under time pressure.

The game should reward:

- Arriving on time or minimizing unavoidable lateness.
- Driving safely and obeying traffic rules.
- Choosing routes intelligently.
- Understanding Dhaka's road behavior.
- Responding appropriately to unexpected events.
- Managing time without creating danger for others.
  Driving faster should rarely be the most effective solution. Sometimes the correct decision is to wait, take another route, leave earlier, or accept being late.

2. The Game World
   2.1 Geography and road networks
   Use recognizable Dhaka geography, with roads modeled as closely as practical to their real dimensions, connectivity, intersections, and restrictions.

Potential playable districts:
Area	Characteristics
Farmgate–Karwan Bazar	Heavy traffic, buses, metro infrastructure, commercial activity
Dhanmondi	Residential roads, schools, hospitals, shopping areas
Mirpur	Dense residential neighborhoods, busy intersections, mixed road widths
Gulshan–Banani	Office traffic, commercial buildings, controlled access areas
Old Dhaka	Narrow roads, markets, delivery vehicles, pedestrians
Uttara	Wider arterial roads, residential sectors, expressway connections
Motijheel–Paltan	Office-hour demand, commercial traffic, major intersections
Airport Road	High-volume traffic, airport access, passenger pickupsRoad geometry should distinguish between main roads, narrow streets, one-way connections, service lanes, intersections, flyovers, and legal turning points.
2.2 Road and footpath details
Each area should include an appropriate combination of:

- Broken asphalt, patched surfaces, potholes, speed breakers, and road markings.
- Open or covered drains, utility covers, roadside dust, and construction barricades.
- Footpaths with different widths, heights, access ramps, obstructions, and surface conditions.
- Tea stalls, street vendors, roadside food carts, small shops, and market entrances.
- Parked motorcycles, delivery vehicles, loading activities, and passenger pickup points.
- Bengali signboards, advertisements, streetlights, traffic signals, and overhead electrical wires.
- Metro stations, flyover pillars, bus stops, pedestrian bridges, trees, and boundary walls.
  Objects should affect driving where appropriate. A parked delivery van might reduce road capacity, while a vendor cart or construction barrier may obstruct a pedestrian route.

Not every road should contain every obstacle.
2.3 Dynamic environment
The city should operate under different conditions:

Time: Early morning, office rush, midday, school dismissal, evening rush, and late night.

Weather: Clear skies, light rain, thunderstorms, monsoon downpours, waterlogging, reduced visibility, and occasional winter fog.

Activity: School opening and closing, market deliveries, office arrivals, Friday activity patterns, religious gatherings, and permitted public events.

Different conditions should change traffic demand and pedestrian activity instead of merely changing lighting and scenery.
3. Vehicle Simulation
3.1 Vehicle categories
Vehicle	Distinctive simulated behavior
Private cars	Varied acceleration, following distance, parking and turning
Public buses	Wide turning radius, passenger stops, merging and lane changes
CNG auto-rickshaws	Small turning radius, compact maneuvering, passenger pickup
Cycle rickshaws	Slower acceleration, narrower roads, frequent stops and turns
Motorcycles	Filtering through suitable gaps and changing lateral position
Delivery vans and pickups	Loading and unloading, limited visibility, larger turning space
Trucks and covered vans	Heavy braking, restricted access, time-dependent appearances
Bicycles	Low-speed movement, limited visibility in dense traffic
Emergency vehicles	Audio/visual warnings and requests for clear passageAdd locally appropriate vehicle appearances, registrations, signage, and sound profiles.
3.2 Driving mechanics
The initial playable vehicle is a right-hand-drive private car operating on the left side of the road.

The player can control acceleration, braking, steering, indicators, headlights, horn, reverse gear, parking brake, windshield wipers, and mirrors.

Vehicle handling should account for acceleration, tire grip, turning radius, braking distance, wet roads, and low-speed maneuvering.

Difficulty settings may simplify transmission and controls, but should not remove the core traffic challenge.
4. Traffic Intelligence — The Most Important System
Traffic must be simulated rather than created through random obstacles.
4.1 Traffic generation
Vehicle density changes by:

- Road segment and direction.
- Time of day and day of week.
- Nearby schools, offices, markets, and transport hubs.
- Weather and road conditions.
- Temporary incidents, blocked lanes, and construction.
- Congestion on connected roads.
  Queues should form because of traffic demand and limited road capacity. Congestion must propagate to neighboring intersections when vehicles cannot exit.
  4.2 Individual driver behavior
  AI-controlled drivers should have different behavioral profiles, including cautious, typical, impatient, and professionally experienced.

Behavior profiles affect following distance, willingness to merge, gap acceptance, response to signals, and reaction to the player's horn.

Every road user should follow a destination and navigation plan. A bus should not randomly cut across several lanes without a reason to reach its next stop or turn.
4.3 Intersection simulation
Intersections must account for:

- Traffic lights and their timing.
- Traffic police manually controlling vehicle flows.
- Turning vehicles waiting for safe gaps.
- Vehicles blocking intersections.
- Pedestrians crossing.
- Roadside buses picking up passengers.
- Spillback from the next intersection.
- Temporary traffic diversions.
  A traffic police officer may override a functioning signal. The player must respond to the actual instruction.
  4.4 Dynamic traffic incidents
  Events can include a disabled vehicle, stalled bus, minor collision, road repair, flooded street, blocked turning lane, or temporary police diversion.

These incidents should be believable, location-dependent, and relatively infrequent.

A route that is normally faster may become slower because of one incident.

Important design principle: AI should not deliberately create unavoidable crashes or impossible traffic situations simply to make the game difficult.
5. Pedestrians and Street Life
Pedestrians need their own simulation system.

NPC categories may include students, office workers, shoppers, street vendors, delivery workers, older adults, children accompanied by adults, and people with mobility limitations.

Different pedestrian behaviors:

- Waiting at crossings.
- Crossing at marked or unmarked locations.
- Walking around obstacles on footpaths.
- Waiting for buses or CNGs.
- Entering and leaving shops.
- Carrying groceries, umbrellas, bags, and parcels.
- Approaching stopped vehicles.
- Walking along streets without usable footpaths.
  Pedestrians should react to vehicle proximity, sounds, visibility, and available crossing gaps.

Pedestrians are not targets or moving obstacles to be hit. The player should face significant consequences for dangerous driving, with appropriate non-graphic handling of collisions.
6. Core Gameplay Loop
Step 1 — Receive a task.
The player receives a destination, purpose, appointment time, and relevant instructions.

Step 2 — Plan the journey.
The navigation interface provides alternative routes, estimated arrival-time ranges, and known disruptions.

Step 3 — Drive.
The player manages traffic, intersections, hazards, and time pressure.

Step 4 — Adapt.
New information may require changing routes, communicating a delay, or choosing a different pickup/drop-off location.

Step 5 — Arrive and complete the task.
The player must find an appropriate stopping or parking location and complete any required handoff.

Step 6 — Receive feedback.
The game evaluates punctuality, safety, driving decisions, vehicle condition, and mission completion.
7. Mission System
Mission	Objective	Main challenge
Office Interview	Reach an office before the interview	Rush-hour congestion and parking
Hospital Appointment	Take a family member to a hospital	Time pressure and safe passenger transport
School Drop-off	Arrive before the school gate closes	School-zone traffic and pedestrians
Airport Drop-off	Reach the terminal before check-in closes	Variable travel time and terminal access
Wedding Invitation	Deliver family members to an event	Evening congestion and passenger instructions
Parcel Delivery	Complete multiple deliveries	Route planning and legal stopping locations
Monsoon Journey	Reach an office in heavy rain	Flooded road sections and detours
Railway Station Pickup	Collect a passenger arriving by train	Arrival changes, waiting areas and parking
Market Errand	Visit several shops before closing	Crowded streets, loading and parking
Return Home	Complete a familiar evening commute	Repeated journeys with changing conditionsA mission does not necessarily end immediately when its deadline passes. The story can change: an appointment is rescheduled, a customer complains, or the player completes the journey late with a reduced score.
8. Time Management and Scoring
Every mission has three main performance dimensions:

Punctuality: Did the player arrive within the required time window?

Safety: Did the player avoid crashes, dangerous maneuvers, and pedestrian conflicts?

Compliance: Did the player follow traffic signals, lawful routes, and stopping or parking restrictions?

Secondary measures include fuel consumption, vehicle damage, and passenger satisfaction.

A high-speed journey that causes a collision or serious traffic violation should not be considered a success.

ETA predictions should be uncertain rather than unrealistically exact. For example:

- Destination: Karwan Bazar
- Appointment: 9:30 AM
- Current time: 9:02 AM
- Estimated journey: 18–32 minutes
- Arrival risk: Moderate
  Road incidents and route choices update this estimate.

The player should be able to learn from repeated trips. Some congestion is unavoidable, but improved route planning, departure timing, and driving skill can improve outcomes.
9. Dialogue and Human Interaction
Use natural Bangla dialogue, with English code-switching where appropriate. Characters should speak differently depending on their role, age, personality, and situation.

Dialogue should respond to gameplay events.

Situation A — Running late

Passenger: “ভাই, আর কতক্ষণ লাগবে? আমার তো সাড়ে নয়টায় অ্যাপয়েন্টমেন্ট।”

Driver: “সামনের মোড়টা একদম আটকে আছে। দেখি অন্য রাস্তা দিয়ে যাওয়া যায় কি না।”

Passenger: “একটু দেখে যান। দেরি হলে আবার নতুন করে সিরিয়াল নিতে হবে।”

Situation B — Bus suddenly stopping

Bus helper: “ফার্মগেট! কারওয়ান বাজার! নামবেন, নামবেন!”

Nearby driver: “ভাই, বাসটা মাঝরাস্তায় থামাইল কেন?”

Situation C — Motorcycle requesting space

Motorcyclist: “ভাই, একটু সাইড দেন!”

Situation D — Police diversion

Traffic police: “এই রাস্তা বন্ধ। সামনে রাস্তার কাজ চলছে, বাম দিক দিয়ে যান।”

Player dialogue choice: “স্যার, কারওয়ান বাজার যাওয়ার রাস্তা কোনটা?”

Traffic police: “সামনের মোড় থেকে ঘুরে যান। এই দিক দিয়ে যেতে পারবেন না।”

Situation E — Parking

Security guard: “ভাই, গেটের সামনে গাড়ি রাখা যাবে না। একটু সামনে পার্ক করেন।”

Situation F — Family phone call

Family member: “কোথায় তুমি? সবাই তো রেডি হয়ে বসে আছে।”

Player choices:

1. “আর দশ-পনেরো মিনিট লাগতে পারে।”
2. “জ্যাম আছে। পৌঁছেই ফোন দিচ্ছি।”
3. “মনে হয় দেরি হবে, তোমরা আগে যাও।”
   Player dialogue should reflect actual route conditions. Responses can influence passenger patience, mission outcomes, or future interactions.

Dialogue should be recorded by Bangla-speaking voice actors where feasible, with subtitles and optional English translations.
10. Sound Design
The ambient audio environment is as important as visual realism.

Include traffic horns with different sound profiles, engine idling, bus brakes, rickshaw bells, motorcycle sounds, rain striking the windshield, shop activity, conversations, street vendors, police whistles, and local announcement systems.

Sound should change by district, weather, time, and vehicle proximity.

Avoid a constant wall of honking. Quiet residential streets, early mornings, and late-night roads should sound different from busy commercial intersections.
11. Navigation System
The in-game navigation should support:

- Multiple possible routes.
- Distance, estimated duration and expected delay.
- Road restrictions and legal turns.
- Roadworks and known temporary blockages.
- Time-dependent congestion.
- Recalculation when the player takes a different route.
- Uncertainty in arrival-time estimates.
  Players should be able to choose between route strategies such as shortest distance, shortest expected time, and less complex driving.

The shortest route must not automatically be the fastest route.
12. Game Modes
Story Mode: A character's everyday life in Dhaka, with recurring destinations, relationships, responsibilities, and consequences.

Daily Challenge: One realistic trip with an origin, destination, deadline, and dynamically generated traffic conditions.

Free Drive: Explore available streets without a mission deadline.

Professional Driver (future expansion): Work as a delivery driver, chauffeur, or another transport professional, with occupation-specific objectives.

Hardcore Simulation: Minimal driving assistance, realistic waiting, advanced vehicle controls, and stricter penalties.
13. Expanded Minimum Viable Product (after the first playable milestone)
The first version should be a small, believable part of Dhaka rather than a large but inaccurate city.

Recommended pilot area: Farmgate–Karwan Bazar, including selected connecting streets.

Initial scope:

- One private car.
- One continuous playable road network, approximately 2–3 km along the main corridor with connecting roads.
- Five or more functional intersections.
- Private cars, buses, CNGs, rickshaws, motorcycles, and pedestrians.
- Traffic signals and at least one manually controlled intersection.
- Two weather settings: clear and rainy.
- Three mission types: office commute, appointment, and delivery.
- First-person and third-person driving.
- Basic Bangla NPC dialogue.
- Dynamic traffic congestion and navigation.
- Arrival-time and driving-safety scoring.
  The MVP should demonstrate that driving through the city is engaging even without racing or exaggerated incidents.

14. Technology and Simulation Architecture
    Selected engine: Godot 4, using GDScript initially, for a Windows-first 3D simulation. Use Blender and Krita for original art, original or CC0 audio, and a provenance manifest for external assets. The implementation specification and staged development plan define the selected architecture.

Core subsystems:

1. Road graph: Road geometry, intersections, allowed turns, parking zones, and vehicle restrictions.
2. Traffic simulation: Agent destinations, route choice, intersection coordination, queue formation, and traffic demand.
3. Pedestrian simulation: Walking networks, crossings, destinations, and collision avoidance.
4. Vehicle physics: Handling, collisions, braking, and weather effects.
5. Event system: Roadworks, breakdowns, rain, temporary restrictions, and mission triggers.
6. Mission and scoring system: Appointments, deadlines, actions, penalties, and outcomes.
7. Dialogue system: Context-aware interactions with recorded voice lines.
8. Navigation system: Route alternatives, traffic estimates, and rerouting.
   OpenStreetMap can provide a starting point for road geometry, subject to licensing and manual correction. Street imagery, site observation, public transport data, and local driving footage can support reference collection where usage rights permit.

A real map does not automatically give accurate traffic behavior; traffic counts, field observations, and repeated gameplay testing will be necessary.
15. Gameplay Design Risks
Risk: Realistic traffic becomes boring.
Mitigation: Maintain meaningful navigation decisions, provide a time-compression option for extended stationary waits, and vary mission contexts without artificial hazards.

Risk: Traffic AI becomes unrealistic or deadlocks.
Mitigation: Prototype intersections and mixed vehicle interactions before expanding the map.

Risk: The world feels like a generic city with Bengali signs.
Mitigation: Build geographically recognizable street layouts, neighborhood-specific assets, and accurate street-level behavior.

Risk: Too many features delay release.
Mitigation: Start with one corridor, one vehicle, a limited set of AI road users, and three repeatable missions.

Risk: The player is punished for situations beyond their control.
Mitigation: Use realistic arrival-time distributions and provide meaningful partial success, rescheduling, or alternate outcomes.
16. Expanded MVP Acceptance Criteria
The first playable version is successful when:

- A player familiar with the modeled area can recognize its major road structure and street character.
- At least six vehicle categories behave differently and plausibly.
- Traffic congestion develops naturally from vehicle demand and intersection capacity.
- A player can choose between genuinely different routes.
- Rain changes driving conditions and, where modeled, road accessibility.
- Pedestrians and other road users react safely to the player's vehicle.
- The same mission can produce different experiences because of time, traffic, weather, and player decisions.
- Reaching a deadline requires planning and competent driving, not high-speed racing.
  Overall design objective: Make the player feel the tension, familiarity, complexity, and occasional humor of everyday travel in Dhaka while rewarding patient, intelligent, and safe driving.

3. One example of how a mission would play
   MISSION 01
   ইন্টারভিউ আছে আজ!
   Get to your job interview on time.

Prototype

CURRENT TIME
8:45 AM

INTERVIEW
9:30 AM

EST. TRAVEL
28–45m

The player has to choose a route.

Main road28–45 minWide roads, but significant bus and intersection congestionThrough connecting streets32–43 minNarrower roads, pedestrians, rickshaws and tricky turns

Possible event: A bus stops near an intersection, causing a queue. The player may wait or legally reroute when an alternative becomes available.

Illustrative mission design, not live Dhaka traffic estimates.

This is where the game becomes interesting: two players can take different routes, make different decisions, and experience different outcomes without either of them racing.
