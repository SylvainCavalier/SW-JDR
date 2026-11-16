# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

SW-JDR is a Ruby on Rails 7.1 web application for managing a Star Wars Jedi RPG campaign. It handles player characters, pets, spaceships, combat, genetics/cloning, and game master (MJ) tools.

**Tech Stack:** Ruby 3.1.2, Rails 7.1.4, PostgreSQL, Hotwire (Turbo + Stimulus), Bootstrap 5.2, Cloudinary, ActionCable

## Common Commands

```bash
# Development
bin/rails server              # Start server on port 3000
bin/rails console             # Rails console
bin/rails db:migrate          # Run migrations
bin/rails db:seed             # Load seed data

# Testing
bin/rails test                # Run all tests (parallel)
bin/rails test test/models/user_test.rb           # Run single test file
bin/rails test test/models/user_test.rb:42        # Run single test at line

# Code Quality
bundle exec rubocop           # Lint (120 char max line length)

# Setup
bin/setup                     # Full setup (bundle, db:prepare, clear logs)
```

## Features

Functional inventory of what the app does, grouped by domain. Routes are in `config/routes.rb`; the Page Map below maps route → controller → view.

### Character sheet (PJ)
- **Progression** — caracs (`user_caracs`), skills (`user_skills`), race, class (`classe_perso`); XP granted by the MJ then spent to raise skills (`spend_xp`, `update_skills`); avatar upload; free-text notes.
- **Health** — HP down to -20; status auto-derived from HP ("En forme" / "Inconscient" / "Agonisant" / "Mort") without overwriting special statuses; permanent HP purchase (`purchase_hp`); MJ-granted `hp_bonus`; temporary max-HP bonus from HQ dormitories.
- **Shields** — standard shield + Echani shield: toggle, recharge.
- **Medipack & care** — heal self or another player, heal objects, patches (equip/use), injections (equip/deactivate), implants (equip/unequip).
- **Inventory & equipment** — 7 slots (`config/initializers/equipment_slots.rb`); buy, sell, give items to another player; catalog in `config/catalogs/inventory_objects.yml`.
- **Credits** — transfer between players and to the HQ (`transactions#create`), broadcast live.
- **Dice** — dice roller and group luck roll (`users#dice`, `group_luck_roll`).
- **Settings** — account, password, per-player display settings.

### Spheros (combat drones)
Per-player drones in three categories (`attaque` / `protection` / `survie`) × 3 quality levels; HP, shield, medipacks and default skills auto-assigned on creation. Actions: activate/deactivate, transfer to another player, attack, protect, three repair paths (`repair`, `repair_broken`, `repair_kit`), recharge, use/refill medipacks (max 5). Created and edited by the MJ (`/mj/sphero`).

### Pets (companions)
Creatures in four categories (animal / droïde / bio-armure / humanoïde) with stats, skills, statuses, shield, hunger, age and two damage profiles. Associate/dissociate with a player (one active pet per player), heal, recharge shield, perform actions costing `pet_action_points` (granted by the MJ), assign to HQ buildings or ship crews, graveyard for dead pets, MJ edit page.

### Apprentices (Jedi training)
One apprentice per player, backed by a force-sensitive humanoid Pet. Tracks side (-100 dark ↔ +100 light), speciality (Commun / Gardien / Consulaire / Sentinelle), midi-chlorians (5000–20000, hidden until the MJ reveals them), dark side points and fatigue (0–100). Training (`train`) spends fatigue — doubled for Force skills (Contrôle / Sens / Altération), never available for "Résistance Corporelle" — with success and fatigue cost modified by the midi-chlorian tier and a random talent draw. Lightsaber with the seven saber forms. Abandon an apprentice; MJ page for fatigue restore, full rest, caracs/skills/stats/saber edits and midi-chlorian reveal.

### Ships
Fleet shared by the group, one active ship at a time. Per ship: inventory (`ship_objects`), docking/undocking of smaller ships (capacity-checked), hull/HP-max and sensor upgrades plus generic upgrades (`config/initializers/ship_upgrades.rb`), weapons (buy / install / uninstall / sell, damage and aim upgrades), launchers and ammunition, turrets, special equipment, crew assignment (users and pets via `crew_members`), and repair (repair kits, astromech droid deployment; damage causes in `config/initializers/ship_damage_causes.rb`). MJ ship editor at `/mj/vaisseaux`.

### Ground combat
Real-time combat assistant shared by players and MJ. Add PJs, pets and ad-hoc enemies to the tracker; edit HP / shield / Echani shield; apply statuses; highlight the acting participant; increment/decrement the turn counter; heal enemies; remove participants. Live sync over Turbo Streams via `CombatBroadcaster`.

### Space combat
Turn-based ship combat implementing chapter 4 of the rules, shared live by players and MJ (one Turbo stream per user, since the board is rendered according to each viewer's rights). Same page for both at `/space_combat` and `/mj/space_combat`.
- **Setup** — add player ships, create enemy ships on the fly (stats, weapons, scale, missile-interception level, stealth), initiative from the ship's Speed + pilot's Piloting.
- **Positions** — the five relative positions (`ship_combat_positions`) via opposed Piloting rolls, thruster boost (opposed Speed) to break off when pursued, blind spot for a small ship against a big one, MJ override, SVG diagram + matrix.
- **Shooting** — `SpaceCombatAttack` resolves the whole shot: aim roll (weapon + gunner's skill, +1D when pursuing) vs the target's space-evasion, damage minus hull and shields, ammunition, face-to-face duel, ion and piercing weapon effects, decisive hits (D12 table), small-vs-big thresholds with automatic turrets, missiles that cannot miss a capital ship.
- **Crew** — reuses `crew_members`: only the crew (or the MJ) can act on a ship; emergency repair (kit or components, applied at the start of the next turn), captain's Command bonus, radar operator's detection of stealth ships.
- **Turn upkeep** — cumulative -1D defensive malus, shield recharge, repairs, astrogation countdown, depressurization countdown, automatic turn advance once every ship has played.
- **Escape** — flee manoeuvre (opposed Piloting then Speed against every enemy) and hyperspace jump after astrogation.
- Rules live in `app/services/space_combat_rules.rb` (pure functions), dice lookups in `app/services/space_combat_stats.rb`. State in `space_combat_states`, `space_combat_participants`, `space_combat_actions`.

### Headquarter (base)
Shared base with its own credits and inventory. Buildings from `config/catalogs/buildings.yml` with levels, per-level properties, assigned pets and a chief pet; some levels grant temporary max-HP bonuses (dormitories → players, animal refuge → pets). Defenses purchased from `config/catalogs/defenses.yml`. Personnel management, observation page, credits transfer.

### Science
- **Crafting** — recipes in `config/catalogs/craft_recipes.yml` (+ `config/initializers/craft_recipes.rb`); dice-based success roll that consumes ingredients from inventory (`attempt_craft`, `attempt_transfer`).
- **Bestiary** — creature catalog with detail pages.
- **Genetics / cloning** — gene research (`recherche_gene`) feeding a personal gene pool (`user_genes`); embryo creation from `config/catalogs/creature_types.yml`; trait application with probability preview (`calculate_probabilities`, `apply_traits`), capped per skill and per damage value; gestation in up to 3 tubes, with acceleration and cloning; birth converts the embryo into a Pet (`origin_embryo`); embryo recycling; per-player `genetic_statistics`.
- Player-facing pages are gated to the **Bio-savant** class; the MJ advances or completes gestations from `/mj/science`.

### Holonews (internal messaging)
Not a news feed: in-app messages addressed to one player or the whole team, with an optional image, per-user read tracking (`holonew_reads`), an unread counter on the home page, and a Web Push notification on creation.

### Wine cellar
Drink catalog (`config/catalogs/drinks.yml`) with per-player discovered drinks; add/remove bottles from inventory. Gated to the **Mercenaire** class; the MJ unlocks drinks from `/mj/unlock_drink`.

### Goods crates
Per-player trade goods: content, quantity, origin planet, price per crate.

### Pazaak (mini-game)
Real-time multiplayer card game: menu, custom side-deck editor, lobby with presence pings and invitations, live games over ActionCable with per-player Turbo streams, abandon, and per-player stats.

### MJ tools
Dashboard at `/mj`: set and reset skill points, grant study points and XP, set max HP and apply HP bonuses, edit caracs, set statuses (players and pets), inflict damage (players, pets, spheros), stray bullets, global health reset, give and create inventory objects, unlock drinks, fix pets and grant pet action points, sphero CRUD, gestation management, apprentice management, ship editor, plus the MJ side of both combat assistants.

### Cross-cutting
- **Auth & roles** — Devise with `username` as the authentication key; `Group` separates PJ from MJ and gates every MJ action. Some features are additionally gated by `classe_perso` (Bio-savant, Mercenaire).
- **Real-time** — ActionCable + Turbo Streams for combat, XP, credits and Pazaak.
- **PWA & push** — manifest and service worker (`pwa_controller`), Web Push subscriptions (`subscriptions`, `config/initializers/webpush.rb`).
- **Images** — Cloudinary + ActiveStorage for avatars, pets, ships, HQ and holonews.
- **Game data** — YAML catalogs in `config/catalogs/` (races, classes, skills, statuses, inventory objects, buildings, defenses, drinks, ship upgrades, craft recipes, creature types, apprentice).

### Present but not wired up
`chatouille_controller.rb`, `app/views/chatouille/` and `config/catalogs/chatouille.yml` implement a religion-management mini-game (resources, Kessar events, doctrine, buildings, marketing, politics, accounting), but **no route points to it** — it is unreachable unless routes are added.

## Architecture

### Domain Model Structure

The codebase models a complex RPG system with interconnected entities:

- **User** - Player character with inventory, skills, HP, status effects
- **Ship** - Spaceships with weapons (`ship_weapons`), crews, upgrades, combat stats
- **Pet** - Companion creatures with stats, skills, evolution paths
- **Apprentice** - Jedi training system with special skills and progression
- **Embryo/Gene** - Genetic breeding and cloning system
- **PazaakGame** - Real-time multiplayer card game via ActionCable
- **Combat** - Turn-based combat with participants and statuses

### Controller Organization

Large controllers handle feature domains:
- `mj_controller.rb` - Game Master admin dashboard (extensive player/game management)
- `science_controller.rb` - Genetics lab and breeding system
- `ships_controller.rb` - Spaceship management
- `combat_controller.rb` - Combat system
- `users_controller.rb` - Player character management

### Frontend Architecture

- **Stimulus controllers** in `app/javascript/controllers/` (60+ controllers)
- **ActionCable channels** for real-time features (Pazaak lobby, game sync)
- **SCSS** with Bootstrap 5 in `app/assets/stylesheets/`

### Page Map

Main pages, with their route → controller#action → primary view. Use this to locate where a feature lives when adding/modifying functionality.

**Player-facing pages**
- `/` — home → `pages#home` → `views/pages/home.html.erb`
- `/team` — team roster → `pages#team` → `views/pages/team.html.erb`
- `/rules` — rules reference → `pages#rules`
- `/combat` — ground combat assistant → `combat#index` → `views/pages/combat.html.erb`
- `/space_combat` — space combat assistant → `space_combat#index` → `views/space_combat/index.html.erb`
- `/users/:id` — player character profile → `users#show` (sub-pages: `health_management`, `medipack`, `healobjects`, `sphero`, `dice`, `edit_notes`, `settings`)
- `/headquarter` — base / HQ → `headquarter#show` (sub-pages: `inventory`, `observation`, `credits`, `buildings`, `personnel`, `defenses`)
- `/headquarter/credits` + `transfer_credits` — credits transfer page
- `/transactions/new` — credits transfer to another player or to the HQ → `transactions#new`
- `/ships`, `/ships/:id`, `/ships/:id/{inventory,improve,crew,repair}` — spaceships → `ships_controller`
- `/pets`, `/pets/graveyard` — companions → `pets_controller`
- `/apprentices` — Jedi apprentices → `apprentices_controller`
- `/holonews` — **internal messaging system** (not a news feed) → `holonews_controller`
- `/science` + sub-pages (`crafts`, `bestiaire`, `genetique`, `labo`, `cultiver`, `traits`, `gestation`, `stats`, `players`) → `science_controller`
- `/wine_cellar` — wine cellar → `wine_cellar_controller`
- `/pazaak` — Pazaak mini-game (menus, lobbies, deck, stats, games) → `pazaak/*` namespace

**MJ (Game Master) pages**
- `/mj` — MJ dashboard → `pages#mj`
- `/mj/{fixer-points, donner_xp, fixer_pv_max, fixer_statut, infliger_degats, balles_perdues, unlock_drink, fix_pets, sphero, science, apprentices, vaisseaux}` → `mj_controller`
- `donner_objet` (give item) → `mj_controller`
- `/mj/combat` and `/mj/space_combat` — shared combat assistants with MJ controls

### Controller Concerns

Shared controller helpers live in `app/controllers/concerns/`:
- `combat_broadcaster.rb` — exposes `broadcast_combat_assistant_update(participant, field)`. Diffuse une mise à jour de PV / bouclier / bouclier Échani d'un participant (User, Pet, Enemy) vers le canal Turbo `combat_updates`, lu par l'assistant de combat (`views/pages/combat.html.erb`). À utiliser **après tout changement de `hp_current`, `shield_current` ou `echani_shield_current`** opéré en dehors de l'action `combat#update_player_stat` (qui le fait déjà), pour que les autres clients voient le changement en temps réel. Inclus dans `UsersController`, `MjController`, `CombatController`. `field` accepte `"hp_current"`, `"shield_current"`, `"echani_shield_current"`.

### Configuration Initializers

Game-specific configs in `config/initializers/`:
- `craft_recipes.rb` - Crafting system recipes
- `equipment_slots.rb` - Character equipment slots
- `ship_damage_causes.rb` - Ship damage types
- `ship_upgrades.rb` - Available ship upgrades

### Database

125+ tables including: `users`, `ships`, `ship_weapons`, `pets`, `apprentices`, `embryos`, `genes`, `pazaak_games`, `inventory_objects`, `skills`, `caracs`, `statuses`, `buildings`, `combats`

## Key Patterns

- **MJ (Maître du Jeu)** = Game Master with admin powers
- **Real-time sync** via ActionCable with Enhanced PostgreSQL adapter
- **SimpleForm** for form building with Bootstrap integration
- **Cloudinary** for image storage (avatars, ship images)
- **Bullet gem** enabled in dev for N+1 detection

## Language Notes

French-influenced naming throughout:
- "mj" = maître du jeu (game master)
- "carac" = caractéristique (characteristic/stat)
- "chatouille" = tickle (mini-game name)

## Life Dashboard

Projet du life-dashboard : `sw-jdr` (`/historyupdate` envoie chaque session au journal de bord de ce projet).
