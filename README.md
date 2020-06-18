# Droptune

Droptune is a collection of small Lua libraries which interface well
with each other:

- `tiny` (from htts://github.com/bakpakin/tiny-ecs, with some slight changes)
- `prototype`, a simple object library with auto-type-name-detect features for debugging
- `entity`, entity/component types designed to interact nicely with tiny-ecs and the prototype module
- `agent`, a simple pushdown automaton implementation for tracking state changes and simple AI
- `scene`, a simple game scene manager, implemented using the prototype module