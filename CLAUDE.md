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
