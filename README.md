# Personal Blip System

A standalone FiveM resource for creating and managing persistent map blips with a modern NUI interface.

## Features

- Create, edit, and delete personal map blips
- Blips persist across server restarts (JSON storage)
- Share blips with nearby players
- Modern glassmorphic NUI interface
- Human-readable sprite and color selectors

## Requirements

- FiveM Server
- oxmysql (for future database migration - currently uses JSON)

## Installation

1. Download or clone this resource into your server's `resources` folder
2. Build the NUI (see below)
3. Add `ensure personalblips` to your `server.cfg`
4. Restart your server or run `refresh` followed by `start personalblips`

## Usage

- Type `/blips` in-game to open the blip management interface
- Create new blips with custom names, sprites, colors, and scales
- Edit or delete existing blips from the dashboard
- Share blips with nearby players (within 10 meters)

## Configuration

Edit `config.lua` to customize:

- `DefaultSprite` - Default blip icon (default: 1)
- `DefaultColor` - Default blip color (default: 0)
- `DefaultScale` - Default blip scale (default: 0.8)
- `DefaultShortRange` - Whether blips are short-range only (default: false)
- `ShareDistance` - Maximum distance for sharing blips (default: 10.0)

## Data Storage

Blips are stored in `blips.json` with player accounts starting at ID 1000. Each player is identified by their license identifier.

## Support

For issues or feature requests, please open an issue on the repository.

## Screenshots
<img width="2560" height="1440" alt="FiveM_GTAProcess_rsleQxihvi" src="https://github.com/user-attachments/assets/46add71c-d613-4bc2-b40a-440177a8028d" />
<img width="2560" height="1440" alt="FiveM_GTAProcess_JrviVM5l8I" src="https://github.com/user-attachments/assets/db2b7747-9fec-4283-965b-c5dbe2a99be0" />

