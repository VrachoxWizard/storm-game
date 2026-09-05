# Gemini / Antigravity Agent Instructions

Refer to [AGENTS.md](../AGENTS.md) for full project context, architecture, and code conventions.

## Quick Reference

- **Engine**: Godot 4.x with GDScript only
- **Design Spec**: `docs/superpowers/specs/2026-09-05-operation-storm-shooter-design.md`
- **Architecture**: `docs/ARCHITECTURE.md`
- **Conventions**: `docs/CONVENTIONS.md`

## Workflow

1. Always read the design spec before implementing gameplay features
2. Follow GDScript conventions in `docs/CONVENTIONS.md`
3. Use Godot 4 APIs (NOT Godot 3)
4. Prefer signals over direct node references for cross-system communication
5. Keep scripts under 300 lines
