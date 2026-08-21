# Functional Coolers Test Harness

## Purpose

This is the development and test harness for Functional Coolers. It is test infrastructure and is not part of the Functional Coolers release mod.

## Repository Location

`tools/test-harness/FunctionalCoolersTestHarness/`

## Runtime Deployment Target

`C:\Users\bartk\Zomboid\mods\FunctionalCoolersTestHarness`

## Version and State

- Mod ID: `FunctionalCoolersTestHarness`
- Mod version: `0.3.7`
- Source version: `v0.3.7-dev`
- Setup version: `9`

Bart imported this repository copy from the working runtime harness for FC-003. These identifiers and the behavior below are documented from the imported files; this README does not assert additional runtime validation.

## FC-003 Relevance

The harness prepares the controlled single-player test environment at its fixed test position. Its source locates a nearby powered fridge/freezer, prepares the freezer cohort, creates the named P0, P1, P2, P4, and P1G coolers, adds the NEUTRAL container and test convenience items, waits for the frozen steaks and cold packs to meet its readiness conditions, creates the fresh-steak cohort, and then reports:

```text
[FCTH] status=READY_TO_DISTRIBUTE
```

Bart manually distributes the test items after that point. `CURRENT_TASK.md` remains authoritative for the active FC-003 procedure.

## Release Boundary

This harness must not be packaged with the production Functional Coolers mod.
