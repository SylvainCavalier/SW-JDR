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
- `/transactions/new` — shop / purchases → `transactions#new`
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
