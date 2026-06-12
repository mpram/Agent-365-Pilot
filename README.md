# 🤖 Agent 365 Pilot

A hands-on, end-to-end pilot that takes you from **building two AI agents** to **governing and publishing them as enterprise-ready agents** with Microsoft Agent 365.

## Synopsis

This pilot follows two fictional agents through their full lifecycle:

- **Wildpaws Trail Guide** — an adventure-travel concierge built in **Microsoft Copilot Studio**.
- **Sous Snark** — a passive-aggressive sous-chef agent built in **Microsoft Foundry (Azure AI Foundry)**.

You'll build each agent, give it real capabilities (web search, REST tools, code execution, connected sub-agents), then put on your **AI Admin** hat to secure and govern them with **Microsoft Entra** (Conditional Access, custom security attributes, sponsorship lifecycle workflows) and finally **publish them through Microsoft Agent 365** with governance applied at activation time.

By the end you'll understand how agents are created, how **Entra Agent IDs and blueprints** work, and how to apply consistent governance and compliance controls before agents reach your organization.

## Chapters

| # | Chapter | What you'll do |
|---|---------|----------------|
| 1 | [Copilot Studio Agent](Chapter%201%20Copilot%20Studio%20Agent/COPILOT-STUDIO-WALKTHROUGH.md) | Build **Wildpaws Trail Guide** in Copilot Studio — add knowledge, web search, REST API tools, and a connected sub-agent, then deploy it for your organization. |
| 2 | [AI Foundry Agent](Chapter%202%20AI%20Foundry%20Agent/Azure-AI-Foundry-Walkthrough.md) | Build **Sous Snark** in Microsoft Foundry with Bing grounding, Code Interpreter, and custom tools. |
| 3 | [Entra Setup](Chapter%203%20Entra%20Setup/Conditional-Access-for-Agents.md) | Configure Entra for Agent 365 — Conditional Access (Report-only), custom security attributes, and sponsorship-change lifecycle workflows for the agent identities. |
| 4 | [Agent 365](Chapter%204%20Agent%20365/Agent-365-Custom-Template.md) | Apply the Entra governance (CA policy + security attributes) while **publishing** both pilot agents through the Agent 365 admin experience. |

## Who this is for

- **Makers / developers** building agents in Copilot Studio and Microsoft Foundry (Chapters 1–2).
- **AI Admins / security teams** governing agent identities and publishing them at enterprise scale (Chapters 3–4).

> Work through the chapters in order — Chapters 3 and 4 build directly on the two agents created in Chapters 1 and 2.
