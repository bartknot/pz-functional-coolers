# Functional Coolers Project Charter

## Project Identity

Functional Coolers is a Project Zomboid Build 42 mod developed in the `pz-functional-coolers` repository. Its production mod ID is `FunctionalCoolers`.

## Project Objectives

Functional Coolers has two durable development objectives:

1. Develop Functional Coolers itself as the product described by this Charter.
2. Use the project as a practical testbed for developing and validating a reusable AI-assisted development workflow intended for larger and more complex future projects.

The workflow-testbed objective may justify deliberate process experiments whose value extends beyond the size of this mod, but it does not authorize any particular governance, tooling, or automation change. Workflow mechanisms must address an observed problem or test a plausible hypothesis, and their value must be evaluated through use. Simplification or removal is a valid improvement; formality by itself is not value.

## Product Purpose

Functional Coolers makes the vanilla `Base.Cooler` function as an insulated thermal container. Gameplay behavior should emerge from a thermodynamic model rather than fixed preservation bonuses.

The product direction is that:

- Cold contents remain cold longer and warm contents remain warm longer.
- `Base.Coldpack` acts as a reusable thermal cold source.
- Multiple cold packs interact through the model rather than pack-count bonus rules.
- Cold and frozen food participates as thermal mass.
- Movement between supported contexts changes the environment around a Cooler without resetting its thermal state.

The central design principle is:

> The Cooler is the thermodynamic system. Its location is a changing boundary condition.

## Development Philosophy

> Vanilla first, model first, precedent later.

Development should begin by investigating what Project Zomboid already exposes and does at runtime. Where vanilla behavior is usable, the project should integrate with it. Where it is insufficient, the project should prefer one coherent model over unrelated special-case bonuses. Earlier mod precedents may inform later work, but they do not replace direct investigation or model coherence.

Runtime evidence and model design remain distinct: verified runtime behavior constrains the project, while accepted architecture determines how the product responds to that behavior.

## Product Principles

- Preserve physical state across supported inventory, ground, nested-container, and future vehicle contexts.
- Treat insulation, thermal capacity, conductance, heat exchange, and time as model concerns rather than arbitrary preservation modifiers.
- Allow cold sources, cold food, warm food, and future heat sources to participate in the same thermal logic.
- Support persistent and unattended simulation so elapsed time can be reconciled when a Cooler becomes active again.
- Keep player-facing feedback useful and understandable without exposing meaningless internal scales.
- Preserve a vanilla-compatible feel and avoid unnecessary micromanagement.

## Long-Term Directions

The following are accepted directions, not current implementation requirements:

- A general thermodynamic-container model.
- Persistent and unattended simulation, including save/load behavior.
- Vehicle contexts and context-independent state continuity.
- Multiplayer with an appropriate authoritative simulation structure.
- Insulation upgrades.
- A period-appropriate 12V thermoelectric/Peltier upgrade.
- Warm-water bottles or heat packs and warm-food use cases.
- Phase transitions and latent heat.
- Useful player-facing Cooler and cold-pack thermal feedback.

Individual mechanics, APIs, balance, architecture, and implementation still require separately accepted tasks and evidence where applicable.

## 1993 Technology Constraint

Future technology and upgrades must remain plausible for Project Zomboid's 1993 setting. A future DIY electrical Cooler may use period-appropriate 12V thermoelectric technology with realistic limitations, but it must not present the performance of a modern premium portable freezer.

## Test Infrastructure Boundary

The Functional Coolers Test Harness is development infrastructure stored at `tools/test-harness/FunctionalCoolersTestHarness/`. It supports reproducible investigation and calibration but is not production Functional Coolers content and must not ship with the release mod.
