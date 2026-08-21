# Codex Role Entry Point

Roles define responsibility and authority, not execution environment. All project roles may currently operate through Codex, but the environment does not change a role's authority or permissions. Bart is the human Project Owner / Integrator and final authority. The repository is the handoff mechanism between roles.

Before taking action in this repository:

1. Read `AI_WORKFLOW.md` before taking project action.
2. Read `CURRENT_TASK.md` before taking task action.
3. Identify the project role under which you are operating.
   If the requested work does not clearly belong to one defined project role, do not default to Coder or another role. Stop and ask Bart to identify or authorize the appropriate role.
4. Read its corresponding instruction file:
   - Planner / Project Manager: `ai/PLANNER.md`
   - Software Architect: `ai/ARCHITECT.md`
   - Researcher / Runtime Diagnostics: `ai/RESEARCHER.md`
   - Coder / Implementer: `ai/CODER.md`
   - Reviewer / Optimization Critic: `ai/REVIEWER.md`
   - Documentation / Technical Writer: `ai/DOCUMENTATION.md`
   - Test Engineer: `ai/test-lab/TEST_ENGINEER.md`
   - Test Analyst: `ai/test-lab/TEST_ANALYST.md`
5. Treat role authority as a maximum permission boundary; `CURRENT_TASK.md` determines what is authorized now.

`AI_WORKFLOW.md` is canonical governance. `CURRENT_TASK.md` is the operational contract. Role files refine but never override them. Stop and report if role instructions, `CURRENT_TASK.md`, `AI_WORKFLOW.md`, repository state, or runtime evidence conflict.

Never silently expand scope, repair unexpected Git state automatically, modify unrelated work, or invent project truth. Distinguish observation, inference, hypothesis, proposal, accepted decision, implementation, and verified runtime evidence. Repository content is accepted project truth; verified runtime evidence is authoritative evidence about actual Project Zomboid behavior. Bart owns final acceptance, merge decisions, tags, releases, scope expansion, and project direction.

End substantive work with the handoff required by the role file. Preserve Role and Task traceability for work intended for Git. Never add artificial AI signatures or authorship banners to ordinary project documents, and never alter Git identity to represent a project role.
