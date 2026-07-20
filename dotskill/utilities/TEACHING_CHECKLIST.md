# Teaching Checklist

## Topic: Amazon Bedrock AgentCore

## Session Goal

- [ ] The learner can state what AgentCore is and why it matters for building agentic applications.

## Problem Understanding

- [ ] The learner can describe what problem AgentCore solves (why not just call an LLM directly).
- [ ] The learner can explain the gap between a "model" and an "agent" that needs infrastructure.
- [ ] The learner can identify the core building blocks/components of AgentCore.
- [ ] The learner can explain how AgentCore relates to frameworks like LangGraph/Strands/CrewAI (it's runtime/infra, not a framework replacement).
- [ ] The learner can name relevant edge cases/failure modes (session state, long-running tasks, identity/auth, tool execution).

## Solution Understanding

- [ ] The learner can describe how AgentCore Runtime executes agents.
- [ ] The learner can explain AgentCore Memory (short-term vs long-term).
- [ ] The learner can explain AgentCore Identity (auth for agents/tools).
- [ ] The learner can explain AgentCore Gateway (turning APIs/Lambdas into agent tools, MCP).
- [ ] The learner can explain AgentCore Observability/tracing.
- [ ] The learner can explain AgentCore Browser/Code Interpreter tools (built-in tools).
- [ ] The learner can trace end-to-end how a request flows through an AgentCore-hosted agent.

## Broader Context

- [ ] The learner can explain why this matters for production agent apps vs a prototype notebook.
- [ ] The learner can connect this to a reusable principle about agent infra (separation of model/orchestration/runtime/tools).

## Verification

- [ ] The learner has answered open-ended questions correctly.
- [ ] The learner has answered at least one quiz or scenario question correctly.
- [ ] The learner has corrected at least one misconception or gap, if any were found.
- [ ] The learner has demonstrated end-to-end understanding without prompting.
