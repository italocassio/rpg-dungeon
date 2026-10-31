
# Godot Game Development Guidelines

## Engine
- Godot Engine 4.x
- GDScript 2.0
- Use typed GDScript whenever possible.
- Follow Godot official conventions.

## Architecture
- Use scenes as reusable game components.
- Prefer composition over deep inheritance.
- Use signals for communication between independent nodes.
- Use Autoloads only for truly global systems.
- Keep gameplay logic separated from UI logic.
- Use Resources for reusable configuration and game data.

## Code Quality
- Write clean, modular and maintainable code.
- Avoid unnecessary dependencies between scenes.
- Use descriptive variable and function names.
- Avoid monolithic scripts.
- Add comments only when they clarify complex logic.
- Always validate node references and scene dependencies.

## Gameplay
- Separate player controller, enemies, weapons
  and game systems.
- Use state machines for complex character behavior.
- Keep balancing values configurable.
- Use delta for frame-independent movement.

## Testing
- Validate scripts using Godot headless mode.
- Check for parser errors after modifications.
- Test gameplay interactions.
- Never assume a feature works without validation.

## Workflow
- Analyze before implementing.
- Present an implementation plan for complex features.
- Make small, incremental changes.
- Preserve existing functionality.
- Explain architectural decisions.
