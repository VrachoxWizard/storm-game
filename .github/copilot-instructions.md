# Copilot Agent Instructions

Refer to [AGENTS.md](AGENTS.md) for full project context, architecture, and code conventions.

## Quick Reference

- **Engine**: Godot 4.x with GDScript only
- **Design Spec**: `docs/superpowers/specs/2026-09-05-operation-storm-shooter-design.md`
- **Architecture**: `docs/ARCHITECTURE.md`
- **Conventions**: `docs/CONVENTIONS.md`

## Key Rules

- Use GDScript only — no C# files
- Use Godot 4 APIs (CharacterBody2D, @export, @onready, etc.)
- Follow snake_case for variables/functions, PascalCase for classes/nodes
- Always add type hints to function signatures
- Keep scripts under 300 lines
