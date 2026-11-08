
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

## Running Godot
- `godot` is on the PATH. Never hardcode the binary path.
- Validate from the project root, in this order:
  ```bash
  godot --headless --path . res://tests/check_scripts.tscn
  godot --headless --path . res://tests/unit_tests.tscn
  godot --headless --path . res://tests/sfx_tests.tscn
  godot --headless --fixed-fps 60 --path . res://tests/flow_test.tscn
  godot --headless --fixed-fps 60 --path . res://tests/playthrough.tscn -- --class=warrior
  ```
- Run only the steps the change can affect, and always `check_scripts` after editing scripts.
- Renders need a window: add `--display-driver x11 --disable-vsync`, because with a locked screen Godot hangs on vsync.
- `--headless` uses the Dummy audio driver, so it cannot measure sound.

## Workflow
- Analyze before implementing.
- Present an implementation plan for complex features.
- Make small, incremental changes.
- Preserve existing functionality.
- Explain architectural decisions.

## Agents
- The main session (Opus xhigh) decides, plans and reviews. It does not implement.
- Delegate implementation to `gameplay-developer` or `rpg-systems` (Sonnet high) without asking first.
  This standing instruction counts as the user asking for those agents.
- Edit directly only when the change is a few lines in a file already in context.
- Use `game-architect` and `qa-tester` (Opus xhigh) and `art-director` (Sonnet xhigh) only for real decisions and validation.
  Never send them routine edits or exploration.
- Do not pass a `model` override to these agents: their frontmatter sets it.
- Give each agent one narrow task: the files involved, what stays out of scope and the acceptance criteria.
  Pass decisions already made, so it does not re-derive them.
