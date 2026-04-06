# Asteroid Mining / Space Shooter Game - TODO List (v2)

**Overall Goal**: Create a satisfying, tense space mining experience with deep resource management, strategic depth, and fair combat feel.

**Last Updated**: April 2026  
**Status Legend**: 
- [ ] Not Started  
- [o] In Progress  
- [x] Completed  
- **Priority**: High / Medium / Low

---

## 1. HUD & UI Enhancements

- [ ] **Add minimap to the HUD**  
  **Priority**: High  
  - Show sector, player ship (center/arrow), asteroids (size-coded), enemies (red), station (green, post-warp)  
  - Circular or rectangular corner placement  
  - Notes: Handle clutter/performance; add color-blind support; consider zoom/layers  

- [ ] **Implement detailed resource HUD**  
  **Priority**: High  
  - Runabout ship: Single "Hold Fullness" bar (total capacity across all resources)  
  - Station: Three separate bars (one per resource type – e.g., Metals, Crystals, Exotics) with color-coding and numeric readouts  
  - Smooth fill animations; show ship cargo vs station storage clearly  

- [ ] **Create docking menu that pops up on successful dock**  
  **Priority**: Medium  
  - Sections: Research queue/progress, production queue/progress, station health bar, stored player ships list  
  - Quick "Undock/Launch" button  
  - Notes: Semi-transparent overlay; keyboard shortcut to reopen; pause or background time option  

---

## 2. Resource System

- [ ] **Implement multi-size asteroid splitting**  
  **Priority**: High  
  - Large → 2-3 Mediums  
  - Medium → 3-4 Smalls  
  - Smalls → destroyed (final resource drop)  
  - Resources drop at every split stage (higher chance on final destruction)  

- [ ] **Add resource pickup variety (Bits vs Chunks)**  
  **Priority**: High  
  - Bits: Small sprites, 1-2 resource units  
  - Chunks: Larger sprites, 4-5 resource units  
  - Visual distinction (size, glow, rotation); tune drop rates per asteroid size  

- [ ] **Define and implement three distinct resource types**  
  **Priority**: High  
  - Tentative: Metals (common/structural), Crystals (energy/tech), Exotics (rare/advanced)  
  - Track separately on station HUD bars  

---

## 3. Tractor Beam Mechanics

- [ ] **Overhaul tractor beam to forward-facing cone**  
  **Priority**: High  
  - 60-90° forward arc; show visual cone/particle field when active  
  - 1.5-2 second lock-on delay with charging sound/visual  
  - Pickup only from front-facing cone + pickup radius  
  - Notes: Prevent omnidirectional vacuum feel  

- [ ] **Add friction control to tractor beam**  
  **Priority**: Medium  
  - While active on asteroids: Apply strong drag to slow/halt tumbling movement  
  - Works on split asteroids with inherited momentum  

---

## 4. Enemy & Combat Balancing

- [ ] **Tune enemy movement, turning, and damage**  
  **Priority**: High  
  - Reduce speed and turn rate (~30-40% initially)  
  - Lower damage output so combat feels fair and skillful  
  - Add hit feedback (visual sparks, screen flash, sounds)  
  - Notes: Tiered enemies (scouts vs gunships); respect momentum/friction  

---

## 5. Station Calling & Docking System

- [ ] **Implement station calling (R key)**  
  **Priority**: High  
  - Opens docking bays visually  
  - Projects "automatic docking" safe zone  
  - 20-30 second timer; auto-close doors after timeout  
  - Re-press R to reopen  
  - Notes: Dramatic visuals/sounds; warning cues  

- [ ] **Add auto-docking behavior**  
  **Priority**: High  
  - Entering docking zone gently pulls ship into station  
  - Works only while zone is active  

---

## 6. Player Life & Death Mechanics

- [ ] **Replace instant death with escape pod**  
  **Priority**: Medium  
  - On ship destruction: Dramatic explosion → eject escape pod (fragile, slow, no weapons/tractor)  
  - Player controls pod; goal = reach station docking zone  
  - Pod destruction = true death + forced reload from save  
  - Notes: Add panic visuals/alarms; consider short timer  

---

## 7. Strategic Sector / Node Map Layer

- [ ] **Implement enemy movement on node map**  
  **Priority**: Medium  
  - Not all nodes start with enemies  
  - Enemies (including "Factory" type) move between nodes over time, updating force size/composition  
  - Factory: Builds ships at visible rate; excess ships form "fleet" and move exploratorily  

- [ ] **Add Navigate button on map**  
  **Priority**: Medium  
  - Allows selecting and traveling to different sectors/nodes  

- [ ] **Add Skip Time button on map**  
  **Priority**: Medium  
  - Advances game clock (fixed increments or slider: 1hr / 6hr / 24hr etc.)  
  - Updates research, production, enemy movements, and time-based systems  
  - Notes: Show preview of changes; consider risk/reward  

---

## Additional Notes & Future Considerations
- **Save System**: Not implemented yet – required for escape pod death reload  
- **Resource Names**: Confirm Metals / Crystals / Exotics or suggest alternatives  
---
