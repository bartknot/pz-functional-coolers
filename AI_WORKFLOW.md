# AI Development Workflow

Roles define responsibility and authority, not execution environment.

A role may later operate through normal ChatGPT, ChatGPT Work, Codex, or another approved environment. Not every role is assumed to be a separate Codex agent. The repository is the handoff mechanism between roles and environments.

## Roles and Responsibilities

### Project Owner / Integrator

- Bart is the human repository owner and project lead.
- "Bart" always refers to the human user directing this project, never to an AI role or agent.
- Bart is the final authority for project direction.
- Owns final acceptance.
- Owns merge decisions.
- Owns tags and releases.
- Owns project direction.
- Owns scope expansion.
- May override or revise prior project decisions explicitly.

### Planner / Project Manager

- Owns task sequencing.
- Owns task scope.
- Owns the roadmap and project status.
- Owns `CURRENT_TASK.md`.
- Determines which specialist role should handle work.
- Does not own system architecture.
- Does not implement production code.
- May not silently expand an accepted task.
- Requires Bart's acceptance for scope expansion.

### Software Architect

- Owns system architecture.
- Owns state ownership design.
- Owns the persistence model.
- Owns module boundaries.
- Owns the context model.
- Owns simulation lifecycle design.
- Owns multiplayer structure.
- Records or proposes architectural decisions.
- Does not implement production code.
- Must not treat an architectural assumption as a runtime fact.

### Researcher / Runtime Diagnostics

- Owns empirical Project Zomboid investigation.
- Owns runtime evidence.
- Owns API findings.
- Owns log analysis.
- Owns cross-test conclusions.
- Distinguishes observation from inference.
- Treats verified runtime evidence as outranking undocumented assumptions about Project Zomboid behavior.
- Does not silently redefine architecture when runtime evidence contradicts it.
- Reports contradictions so the accepted project model can be revised explicitly.

### Coder / Implementer

- Implements only the explicitly approved task.
- May modify only files permitted by `CURRENT_TASK.md`.
- Does not redefine requirements.
- Does not expand scope.
- Does not make architectural changes without explicit acceptance.
- Stops when implementation requires an unresolved design or runtime assumption.
- May inspect Git state and diffs.
- Does not self-merge or self-tag.

### Reviewer / Optimization Critic

- Performs independent review.
- Does not implement fixes.
- Challenges correctness, maintainability, performance, architecture compliance, and hidden assumptions.
- Reports findings using these classifications:
  - `BLOCKER`
  - `HIGH`
  - `MEDIUM`
  - `LOW`
  - `OBSERVATION`
  - `QUESTION`
- Distinguishes required fixes from optional improvements.

### Documentation / Technical Writer

- Owns reader-facing documentation.
- Does not create technical truth.
- Derives documentation from accepted canonical repository information.
- May identify inconsistencies or missing information.
- Reports gaps rather than inventing an answer.

### Test Lab

The Test Lab is a separate functional role/workspace, but it uses the same `pz-functional-coolers` Git repository and history. It is not a separate product repository.

#### Test Engineer

- Owns the test harness.
- Owns deterministic test setup.
- Owns test tooling.
- Owns test-specific instrumentation.
- May later write under explicitly approved test/tooling paths.

#### Test Analyst

- Owns detailed experiment protocols.
- Owns experiment-level interpretation.
- Distinguishes valid, invalid, and inconclusive experiments.
- Does not generalize beyond the available evidence.

Production source under `42/` may only be changed by the Test Lab when `CURRENT_TASK.md` explicitly authorizes that production change.

## Authority and Evidence Model

- The repository contains the accepted project truth.
- Verified runtime evidence is authoritative evidence about actual Project Zomboid behavior.
- Reproducible runtime evidence outranks undocumented assumptions.
- A single experiment may be valid, invalid, or inconclusive and must be classified before its observations are generalized.
- If runtime evidence contradicts an assumption recorded in the repository, the contradiction must be reported.
- Runtime evidence does not silently rewrite accepted architecture, requirements, or scope.
- Accepted project documentation must subsequently be updated through the appropriate role and review process.
- Conversation history, memory, or an AI's prior statement is not authoritative when it conflicts with the repository or verified runtime evidence.

## Core Governance Rules

- Repository is truth.
- Runtime outranks assumption.
- Planner owns scope and sequencing.
- Architect owns system design.
- Researcher owns evidence.
- Coder owns implementation.
- Reviewer owns independent criticism.
- Documentation owns reader-facing documentation.
- Test Lab owns reproducible experiment execution and test tooling.
- Bart owns acceptance, merge, tags, releases, and project direction.
- One active implementation task at a time.
- One uncertainty per experiment where practical.
- No silent scope expansion.
- No self-merge.
- No self-tagging.
- No self-release.
- No architectural change without explicit acceptance.
- No runtime conclusion without evidence.
- No production change without traceable motivation.
- No undocumented assumption should be treated as an established Project Zomboid runtime fact.
- Unexpected repository state must never be repaired automatically by reset, checkout, clean, rebase, force-push, or deletion of unrelated work.
- Git inspection is allowed when required for the task.
- Creating branches, worktrees, commits, or pushes requires explicit authorization from `CURRENT_TASK.md` or Bart.
- History-rewriting operations such as force-push, reset of accepted work, or rebase of shared history require explicit authorization from Bart.

## Stop-and-Report Conditions

An AI must stop and report rather than continue when:

- Requested work is outside `CURRENT_TASK.md` scope.
- Required work belongs to another role.
- Canonical repository documents conflict.
- Runtime evidence contradicts an accepted architectural assumption.
- Unexpected unrelated working-tree changes are present.
- Repository state differs unexpectedly from the task's assumed starting point.
- An API assumption is unvalidated and has architectural consequences.
- Completion would require changing acceptance criteria.
- Completion would require modifying files outside Allowed Changes.
- The task reveals multiple separable problems whose resolution would materially expand the accepted scope.
- Project state is ambiguous enough that continuing would risk creating a second source of truth.
- The task requires a Git write operation that has not been explicitly authorized.

## `CURRENT_TASK.md` Authority

`CURRENT_TASK.md` is the operational contract for the currently active task. It should normally contain:

- ID
- Status
- Objective
- Why
- Evidence / current state
- Preconditions
- Architecture constraints
- Allowed changes
- Acceptance criteria
- Test procedure
- Out of scope
- Known risks

A role definition grants general responsibility, but `CURRENT_TASK.md` defines what is authorized now.

If the two conflict, stop and report rather than choosing an interpretation silently.
