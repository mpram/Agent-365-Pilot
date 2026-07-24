# 🤖 Agent 365 Pilot

A hands-on, end-to-end pilot that takes you from **building two AI agents** to **governing and publishing them as enterprise-ready agents** with Microsoft Agent 365.

> [!CAUTION]
> ⚠️ **Pick your scenario.** Start with the **Copilot Studio Agent** and/or the **AI Foundry Agent** from there you can select which chapters to pilot.

## Synopsis

This pilot follows two fictional agents through their full lifecycle:

- **Wildpaws Trail Guide** an adventure-travel concierge built in **Microsoft Copilot Studio**.
- **Sous Snark** a passive-aggressive sous-chef agent built in **Microsoft Foundry (Azure AI Foundry)**.

You'll build each agent, give it real capabilities (web search, REST tools, code execution, connected sub-agents), then put on your **AI Admin** hat to secure and govern them. Through this journey you'll learn how the Identity team applies guardrails to agents, how the SOC team triages incidents where agent identities are compromised, and how to onboard third-party agents.

## Chapters

| # | Chapter | What you'll do | Video | Length (mm:ss) |
|---|---------|----------------|-------|----------------|
| 1 | [Copilot Studio Agent](Chapter%201%20Copilot%20Studio%20Agent/COPILOT-STUDIO-WALKTHROUGH.md) | Build **Wildpaws Trail Guide** in Copilot Studio add knowledge, web search, REST API tools, and a connected sub-agent, then deploy it for your organization. | **Part 1:** [Watch](https://youtu.be/cJQHdQHyJx8)<br>**Part 2:** [Watch](https://youtu.be/s11V1YkLdK4) | **Part 1:** 17:48<br>**Part 2:** 2:00 |
| 2 | [AI Foundry Agent](Chapter%202%20AI%20Foundry%20Agent/Azure-AI-Foundry-Walkthrough.md) | Build **Sous Snark** in Microsoft Foundry with Bing grounding, Code Interpreter, and custom tools. | [Watch](https://youtu.be/y1Gpzx7D9Po) | 16:06 |
| 3 | [Agent Identities](Chapter%203%20Entra%20Setup/Agents%20Identities.md) | Acting as an **Identity Admin**, you will apply guardrails for agent identities; these guardrails will be leveraged by the AI Admin. Configure Entra for Agent 365: Conditional Access (Report-only), custom security attributes, and sponsorship-change lifecycle workflows for the agent identities. | | |
| 4 | [Agent 365](Chapter%204%20Agent%20365/Agent-365-Custom-Template.md) | Now acting as the **AI Admin**, let's go through the approval workflow: approve or deny agents and apply policies so they are compliant before the rest of the organization consumes them. | | |
| 5 | [Connecting Agent 365 to the Security Portal](Chapter%205%20Security%20Portal/Connecting-Agent-365-to-the-Security-Portal.md) | Connect **Agent 365** to the **Security portal** (Microsoft Defender) to gain full visibility into your agents and proactively detect misconfigurations, suspicious activity, and runtime threats. | [Watch](https://youtu.be/ASNNfV_wLaw) | |
| 6 | Securing your Data for Agents to consume | 🚧 **Work in Progress**: Acting as your **Compliance team**, let's make sure we are not oversharing or leaking sensitive information. | | |
| 7 | [Analyzing Agent Logs in Advanced Hunting](Chapter%207%20Advanced%20Hunting/Analyzing-Agent-Logs-in-Advanced-Hunting.md) | Acting as your SOC, let's query and analyze the raw logs using **Advanced Hunting** KQL in the Microsoft Defender portal. | [Watch](https://youtu.be/Yli7HmG56Mc) | |
| 8 | [Agent 365 Logs in Microsoft Sentinel Data Lake](Chapter%208%20Sentinel%20Data%20Lake/Setting-up-Agent-365-Logs-in-Sentinel-Data-Lake.md) | 🚧 **Work in Progress**: Set up ingestion of **Agent 365 logs** into the **Microsoft Sentinel Data Lake** for long-term retention and analytics. | | |
| 9 | [Triaging Agent Incidents in Defender Portal](Chapter%209%20Defender%20Triage/Triaging-Agent-Incidents-in-Defender-Portal.md) | 🚧 **Work in Progress**: Investigate and triage **agent-related incidents** in the Microsoft Defender portal. | | |
| 10 | [Onboarding Databricks Genie](Chapter%2010%20Databricks%20Genie/Onboarding-Databricks-Genie.md) | Connect **Databricks Genie** to Agent 365 using **Registry sync**, so Genie agents show up in the agent registry for centralized visibility and governance. | [Watch](https://youtu.be/0GdsjFWNP5s) | |
| 11 | Onboarding AWS Agents | 🚧 **Coming soon**: registry sync for 3rd party agents. | | |
| 12 | Shadow AI Discovery | 🚧 **Coming soon**: discover agents employees are installing locally; allow, deny, or monitor. | | |

## Who this is for

- **Developers**
- **AI Admin**
- **Security teams**
- **Cloud CoE**
- **Identity Admin**
- **Compliance teams**

## Authors

- Marianela Ramsdell
- Wes Blackwell
