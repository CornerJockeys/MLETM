# MLE TM — S3 To-Do List

> **Planning backlog only.** This file is intentionally separate from the current actionable development list. Items here are ideas, research targets, and future systems discussed for S3 and beyond. Do not treat the order below as implementation priority.

## Product Split

- [ ] Keep **MLE TM** focused on competition, practice, coaching, match operations, eligibility, recorder/submission, scrims, and official-room behavior.
- [ ] Explore an **MLE TM Companion** plugin for league identity / career features that do not need to live in the main competitive plugin.
- [ ] Explore an **MLE TM Prod** plugin for broadcast / stream tooling. The plugin itself should remain available to normal MLE members so community-driven unofficial streams can use the same production overlays; lock only sensitive scouting / research features behind authentication.
- [ ] Research a separate **MLE Events** plugin that can take the rigid structure built for league matches and scrims and generalize it into a more modular event framework.

---

## Cross-Plugin Recruitment / Non-MLE Onboarding

- [ ] Any **official MLE plugin** should recognize when the current Trackmania player is not an MLE member and offer a lightweight league-application prompt.
- [ ] Keep the prompt short and welcoming rather than turning plugin startup into a large advertisement.
- [ ] Briefly explain what MLE is and why a Trackmania player may want to join.
- [ ] Show the current application URL with a direct **Apply to MLE** action where Openplanet permits it.
- [ ] Include the important application prerequisites / league requirements before sending the player to apply, including **Discord membership**, the league's **minimum age requirement**, and other current eligibility requirements.
- [ ] Do not hard-code changeable league requirements, age thresholds, or application URLs into every plugin if they can instead be supplied from one shared configuration / backend source.
- [ ] Use the same canonical MLE-account / player-identity lookup shared by the rest of the ecosystem to decide whether the player is already a member.
- [ ] Do not repeatedly nag non-members every time a window opens or a plugin refreshes; define a sensible dismissal / re-prompt policy.
- [ ] Reuse one common onboarding component / wording across **MLE TM, MLE TM Companion, MLE TM Prod, MLE Events**, and future official MLE plugins where practical.

---

## MLE TM — Practice / Coaching

### Practice Tracker

- [ ] Build a shared `PracticeTracker` foundation rather than separate one-off stat systems.
- [ ] Track session and total practice time.
- [ ] Track attempts / finishes.
- [ ] Track completion percentage.
- [ ] Track respawns and respawn percentage.
- [ ] Track checkpoint times when reliably available.
- [ ] Track checkpoint speed when reliably available.
- [ ] Avoid assuming continuous live speed telemetry exists until proven.
- [ ] Prefer objective terminology such as **Respawns** and **Speed Loss** rather than trying to infer a generic "Crash" statistic.
- [ ] Build checkpoint / segment monitoring that can identify where a player respawns most often.
- [ ] Compare checkpoint / segment performance against relevant top players from the player's league when the necessary reference data exists.
- [ ] Treat speed as an important target alongside time. Final time alone does not explain where speed was built or lost.
- [ ] Investigate useful checkpoint-speed targets as a practical fallback if continuous speed analysis is unavailable.

### Practice Presets / HUD

- [ ] Revisit session stats as part of configurable practice presets rather than permanently bloating the leaderboard.
- [ ] Build a dedicated practice / target menu separate from the core leaderboard.
- [ ] Allow players to configure which practice information is shown during a session.
- [ ] Consider presets such as Minimal / Standard / Practice after the underlying systems exist.

### Pinned Targets / Rivals

- [ ] Add a player-target / rival system as its own menu rather than a permanent leaderboard addition.
- [ ] Allow players to pin a specific MLE player as a practice target.
- [ ] Allow relevant target data / ghost access to follow that pinned player where useful.
- [ ] If the proposed **Rivals Week** concept is approved for next season, allow players to pin members of their designated rival team directly from the pinned-target system.
- [ ] Keep Rivals Week integration conditional until the league format itself is approved.

### Ghost Manager / Presets

- [ ] Add ghost presets such as Next Position, Team Best, MLE #1, Pinned Player, etc.
- [ ] Keep ghost-management UI mostly hidden so presets do not make the leaderboard visually unstable.
- [ ] Prefer a full menu item or a compact dropdown / popout at the bottom of the leaderboard.
- [ ] Consider showing ghost controls only while the player is actively hovering / interacting with ghost UI.

---

## MLE TM — Coaching Replay System

### Team Coaching Packages

- [ ] Allow players to import teammate practice replays / ghosts acquired outside the plugin.
- [ ] Limit coaching-package use to players from the authorized team / club.
- [ ] Authenticate package access through club membership / club identity rather than visible club-tag text.
- [ ] Do **not** bundle private team coaching assets directly inside the public `.op` package.
- [ ] Initial distribution model: teammates share replay + coaching sidecar files themselves, then the player imports them locally.
- [ ] Revisit encryption only if real abuse / leakage proves the current model insufficient. Do not add DRM complexity preemptively for a for-fun league.

### Coaching Sidecar / Timeline

- [ ] Create a replay-linked coaching sidecar file generated by the plugin.
- [ ] Bind the sidecar to the intended replay using replay identity / hash information so notes cannot be accidentally paired with the wrong replay.
- [ ] Store timed text popups.
- [ ] Store timed telestration / drawing data.
- [ ] Allow coaching events without requiring text.
- [ ] Build in-game authoring and editing so players can create coaching files while watching their replay.
- [ ] Allow authors to choose when each popup / drawing appears and how long it remains visible.
- [ ] Allow preview / edit / delete of coaching events before export.

### Telestration

- [ ] Support Epic Pen-style visual coaching overlays.
- [ ] Support arrows.
- [ ] Support circles.
- [ ] Support boxes / highlighted regions if useful.
- [ ] Support freehand strokes.
- [ ] Store telestration as vector / normalized screen-space data rather than screenshots.
- [ ] Lock coaching replay playback to the **authored camera** so screen-space drawings remain aligned.
- [ ] Do **not** attempt camera-relative reprojection or other high-complexity camera-aware telestration unless a future use case clearly justifies it.

### Replay Playback Control — Research Only

- [ ] Research whether Trackmania / Openplanet exposes a supported way for MLE TM to programmatically pause, resume, or change replay speed.
- [ ] Research whether Ghost++ ever exposes playback-control functions suitable for integrations.
- [ ] Keep automatic pause / slow-motion / resume **shelved** until real programmatic control is proven.
- [ ] Do not add UX that merely tells the player to manually pause or slow the replay; that would make the coaching feature feel unfinished.

---

## MLE TM — Official Match / League Operations

### Official Match Context

- [ ] Determine how MLE TM should recognize and enter an official-match state.
- [ ] Surface useful official-match context without turning it into a large permanent HUD.
- [ ] Potential match-state information: teams, division, match number, current map, authentication state, roster eligibility, club validation, recorder readiness, submission state.
- [ ] Decide how this integrates with readiness, recorder, verifier/parser flow, and future backend systems before implementation.

### Recorder / Match Capture

- [ ] Treat the **recorder** as the plugin-side member of the recorder / verifier / parser pipeline; verifier and parser remain backend systems rather than plugin features.
- [ ] Rework the existing recorder concept for the final MLE TM plugin architecture instead of leaving it as an external / reference-only system.
- [ ] Detect the start of official competitive play reliably enough to avoid recording lobby activity or other pre-match noise as match data.
- [ ] Exclude lobby / non-official rounds from the submitted match payload.
- [ ] Capture the authoritative round / player / team data needed by the future verifier and parser.
- [ ] Preserve enough raw match data for backend verification rather than performing irreversible calculations only inside the plugin.
- [ ] Integrate recorder readiness / armed state into the official-match context and pre-match validation flow.
- [ ] Keep spectators / casters from interfering with player readiness or recorder participation logic.
- [ ] Support the league's mixed PC / console reality by allowing plugin-recorded data to work alongside whatever server / club / replay validation sources are available.
- [ ] At match completion, present a clear review / **Submit? Yes / No** flow rather than silently sending questionable data.
- [ ] Show submission success / failure state and preserve a safe retry path when backend submission fails.
- [ ] Preserve a manual replay / match-data upload fallback for situations where automated capture or APIs fail during the match.
- [ ] Define the recorder-to-backend payload contract before coupling the plugin tightly to a specific verifier / parser implementation.

### Match Room Authentication / Quick Join

- [ ] Continue research into hashed / player-attributable access for official league rooms.
- [ ] Prove that Openplanet / Trackmania can launch a player directly into the correct league room, not just load an individual map.
- [ ] If room joining is proven, provide a contextual **Join Match** action for the player's authorized room.
- [ ] Avoid exposing room passwords directly if the backend / plugin can handle authorization and joining transparently.

### Player Eligibility / Self-Check

- [ ] Build a player-facing MLE status / eligibility check.
- [ ] Validate account linkage.
- [ ] Validate roster status.
- [ ] Validate team / division.
- [ ] Validate club membership.
- [ ] Validate required plugin version.
- [ ] Validate recorder / match-readiness dependencies where applicable.
- [ ] Show useful failure reasons instead of only green / red indicators.
- [ ] Expose the same underlying validation state to franchise staff outside the game through backend / admin tooling.
- [ ] Keep eligibility in core **MLE TM** because it is operationally critical, but also surface the same eligibility status on player cards in **MLE TM Companion**.

### Replay Library — Later

- [ ] Revisit an MLE replay library after higher-priority systems are established.
- [ ] Potential contextual replay categories: Team Best, Division Best, MLE Best, previous PB, teammate PBs, official match runs.
- [ ] Keep this as a future enhancement rather than immediate S3 implementation work.

---

## MLE Events — Research / Modular Event Framework

- [ ] Research an **MLE Events** plugin rather than forcing every non-league event through the rigid league-match / scrim flows.
- [ ] Identify which match/scrim systems can be generalized into reusable event modules without weakening the stricter official-league workflows.
- [ ] Explore configurable event definitions for participation, room access, map pools, match structure, result capture, and event-specific rules.
- [ ] Preserve the ability for league matches and scrims to remain opinionated / tightly controlled while Events uses the same lower-level building blocks more flexibly.
- [ ] Determine how Events should interact with the backend, room authentication, recorder/submission pipeline, and future event titles / player-card rewards.

---

## MLE TM Companion — Player Identity / League Life

### Player Cards

- [ ] Build player cards in the Companion plugin rather than the core MLE TM plugin.
- [ ] Show MLE identity / career information appropriate to the card system.
- [ ] Surface the player's current MLE eligibility state on their card using the same underlying validation source as core MLE TM.
- [ ] Develop a player **rank / card tier** based on medal performance across current MLE maps.
- [ ] Exact rank formula remains TBD. Current concept: achieving a defined medal level across the MLE map pool upgrades the card treatment (example: Silver across all current MLE maps -> Silver-tinted card).
- [ ] Explore Bronze / Silver / Gold / Author / Warrior / Champion card treatments where appropriate.
- [ ] Keep card rank separate from player titles.

### Player Titles

- [ ] Add earnable player titles.
- [ ] Include obvious championship titles such as **Season X Champion**.
- [ ] Add event-specific titles.
- [ ] Add milestone / award / veteran titles where appropriate.
- [ ] Allow players to choose which earned title is displayed.
- [ ] Allow selected titles to have intentionally defined text colors / visual treatments.
- [ ] Do not make title color a completely free-form RGB cosmetic if that destroys title meaning / hierarchy.

### Legacy / Season-of-Entry Stamps

- [ ] Keep possible season-era rename on the radar:
  - original Alpha season -> **Pre-Alpha**
  - current S1 -> **Alpha**
  - current S2 -> **Beta**
  - current S3 -> potentially becomes the first "true" numbered season / new S1
- [ ] **No decision has been made on the season renaming yet.** Treat this as a design / branding question only.
- [ ] If the rename happens, give Pre-Alpha, Alpha, and Beta participants distinct stylized stamps on their player cards.
- [ ] Make all three legacy-era stamps visually different from one another.
- [ ] If the rename happens, also create an **S1** stamp for members of the first newly numbered season.
- [ ] Generalize the concept into a permanent **season-of-entry stamp** for every player: a player who first joins in Season 8 would permanently own a Season 8 stamp, etc.
- [ ] Preserve early-era / early-season stamps as permanent prestige and retention items even after those seasons are long past.

### Seasonal / Collectible Cards

- [ ] Explore a TMCard-style collectible card system inside the Companion plugin.
- [ ] Consider allowing players to collect cards beyond their currently displayed card.
- [ ] Build **seasonal player cards for completed seasons only**; do not expose a collectible seasonal card for the season that is still in progress.
- [ ] Generate / finalize a player's seasonal card at the **end of the season**, after their season results and identity are settled.
- [ ] Use the following preseason to reveal / distribute the previous season's card set, creating a recurring preseason hype cycle for the TMCard-style community.
- [ ] Seasonal cards should preserve a player's team / division / rank / title / season identity at the end of that season.
- [ ] Treat completed seasonal cards as historical collectibles rather than a live reflection of the player's current card.
- [ ] Evaluate backend impact before committing to the final storage / delivery model.
- [ ] Prefer immutable static / cached season snapshots or generated card metadata so historical seasons do not create unnecessary live backend load.
- [ ] Determine whether rendered card art itself should be cached / generated once or whether Companion should render immutable card data client-side.

### Career / History / Accomplishments

- [ ] Add career / historical information to the Companion player-card ecosystem.
- [ ] Add meaningful MLE accomplishments / milestones rather than generic Trackmania achievements.
- [ ] Potential examples: first official map, first top-half placement, first team-best run, first Author medal, large PB improvements, maps-played milestones, playoff appearances, season-best placement.
- [ ] Incorporate MLE records / historical achievements into player cards where appropriate.

### Team Hub

- [ ] Explore a Companion team hub rather than putting team-profile niceties in the core plugin.
- [ ] Potential data: roster, salary distribution, team PBs, team bests, recent improvements, coaching-pack access, team statistics.
- [ ] Keep this as a league-life / identity feature rather than core competitive HUD functionality.

### League Benchmarking

- [ ] Add league / division / team percentile and benchmark views to Companion rather than core MLE TM.
- [ ] Potential examples: league median, top 25%, top 10%, team percentile, division percentile.
- [ ] Extend benchmarking to checkpoint / speed data only if the practice-data model supports it reliably.

---

## MLE TM Prod — Broadcast / Production

- [ ] Build broadcast / stream tooling in a separate **MLE TM Prod** plugin.
- [ ] Keep the base Prod plugin and normal production overlays available to regular MLE members so community-driven unofficial streams are supported and encouraged.
- [ ] Do not require official production-team membership merely to use standard overlays / presentation tools.
- [ ] Add production-friendly roster / stat cards, score / match overlays, historical records, season context, and other non-sensitive broadcast presentation where useful.
- [ ] Add team-vs-team map comparison data for broadcasts where appropriate.
- [ ] Potential examples: top-three average time, map advantage / edge, roster comparisons, historical matchup context.
- [ ] Separate **presentation data** from **scouting / research data**.
- [ ] Lock sensitive scouting research, derived opponent analysis, or other information that should not be universally available behind authentication / authorization.
- [ ] Design backend permissions around feature sensitivity rather than around whether someone is an official MLE production member.
- [ ] Determine which scouting roles should be allowed to access authenticated research features before implementing those endpoints.

---

## Explicitly Out of Scope / Rejected for Now

- [x] Do not build a separate MLE map browser / launcher that duplicates Clubs. Clubs already handle map discovery and launching well enough, and a separate main-menu workflow would be tedious.
- [x] Do not add generic map author / map-info UI just for feature count.
- [x] Do not expose sensitive team-vs-team scouting research as a normal league-wide player feature; if it exists in MLE TM Prod, keep it behind appropriate authentication while leaving normal stream overlays public.
- [x] Do not build camera-aware telestration reprojection for V1.
- [x] Do not ship private team replay / coaching packages inside the public plugin archive.
- [x] Do not implement replay pause / slow-motion prompts until playback can be controlled programmatically.

---

## Design Principle

The long-term split should remain:

- **MLE TM:** helps players **play, practice, compete, and participate in official league operations**.
- **MLE TM Companion:** helps players **belong to the league, track their career, collect prestige items, and show identity**.
- **MLE TM Prod:** gives the community **broadcast / stream presentation tools**, while authentication protects only the scouting / research features that should not be universally available.
- **MLE Events:** explores how to make the league's event tooling **modular and reusable** without weakening the rigid systems required for official league matches and scrims.
