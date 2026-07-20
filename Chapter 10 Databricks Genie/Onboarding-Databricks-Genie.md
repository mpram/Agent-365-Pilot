# 🧬 Onboarding Databricks Genie

[🏠 Back to Home](../README.md)

> **Databricks Genie** spaces run entirely inside your Databricks workspace, outside the Microsoft ecosystem. To bring them under the same governance umbrella as `Wildpaws Trail Guide` and `Sous Snark`, you connect Databricks to **Agent 365** using **Registry sync**. This pulls Genie's agent metadata into the Agent 365 agent registry for centralized visibility and governance, without moving or redeploying anything in Databricks.

## Video Tutorial

[![Watch the video tutorial](https://img.youtube.com/vi/0GdsjFWNP5s/maxresdefault.jpg)](https://youtu.be/0GdsjFWNP5s)

> ▶️ [Watch the walkthrough on YouTube](https://youtu.be/0GdsjFWNP5s)

---

## Index

- [What you'll build](#what-youll-build)
- [Prerequisites](#prerequisites)
- [Step 1: Create a Databricks service principal](#step-1-create-a-databricks-service-principal)
- [Step 2: Grant the service principal admin access to the workspace](#step-2-grant-the-service-principal-admin-access-to-the-workspace)
- [Step 3: Connect Databricks Genie in Registry sync](#step-3-connect-databricks-genie-in-registry-sync)
- [Step 4: Sync and review the imported agents](#step-4-sync-and-review-the-imported-agents)
- [Verify the connection](#verify-the-connection)
- [Reference](#reference)

## What you'll build

```mermaid
flowchart LR
  G["Databricks Genie space"] -->|Service principal credentials| RS["Registry sync connector"]
  RS --> AR["Agent 365 agent registry"]
  AR --> GOV["Inventory, posture, and governance actions"]
```

By the end of this chapter:

- Databricks Genie is a **connected platform** in Agent 365 Registry sync.
- Genie agents show up in the **Agent 365 agent registry**, alongside `Wildpaws Trail Guide` and `Sous Snark`.
- The AI Admin can monitor sync status and apply the governance actions the Databricks API supports, all from the Microsoft 365 admin center.

> **Preview note:** Registry sync is a **preview** feature. It isn't intended for production use yet and is covered by the [supplemental terms of use](https://learn.microsoft.com/legal/microsoft-365/supplemental-terms) for previews.

## Prerequisites

- Your organization is **onboarded to Microsoft Agent 365** (see [Chapter 4: Agent 365](../Chapter%204%20Agent%20365/Agent-365-Custom-Template.md)).
- A Microsoft 365 admin role that can manage the agent registry (for example, **Global Administrator**).
- A **Databricks workspace** with an existing Genie space, and account-level access to create a service principal.
- The workspace's **Workspace URL** (from the Databricks portal address bar).

## Step 1: Create a Databricks service principal

Registry sync authenticates to Databricks as a service principal, not a user, so create one dedicated to this connection.

1. Sign in to the [Databricks account console](https://accounts.azuredatabricks.net/) (or your account console URL).
2. Go to **User management** > **Service principals** > **Add service principal**.
3. Give it a descriptive name, for example `agent365-registry-sync`, then select **Add**.
4. Open the new service principal, go to **Secrets**, and select **Generate secret**.
5. Copy and store the **Client ID** (Application ID) and **Client Secret** immediately. The secret is shown only once.

## Step 2: Grant the service principal admin access to the workspace

Registry sync needs the service principal to have admin access in the target workspace so it can list and read Genie agents.

1. In the Databricks account console, go to **Workspaces**, select the workspace that hosts your Genie space, and open its **Permissions**.
2. Add the service principal created in Step 1 and assign it the **Admin** role for the workspace.
3. If the workspace uses Unity Catalog, also confirm the service principal has `CAN_USE` access to the Genie space and any SQL warehouse it depends on.

## Step 3: Connect Databricks Genie in Registry sync

1. Open the [Microsoft 365 admin center](https://admin.microsoft.com/Adminportal/Home#/homepage).
2. In the navigation pane, select **Agents** > **All Agents** to open the agent registry.
3. In the **Registry sync** web part, select **Manage**.
4. Select **+ Connect a platform**.
5. Enter a connection name (for example, `Databricks Genie - Prod`) and a short description.
6. For **Platform**, select **Databricks Genie**.
7. Select the **region** where your Databricks workspace is deployed.
8. Choose whether to **import agents automatically** on future syncs.
9. Enter the authentication credentials from Steps 1-2:
   - **Workspace URL**
   - **Client ID** (service principal Application ID)
   - **Client Secret**
10. Select **Validate** to confirm Agent 365 can reach the workspace and authenticate.
11. Select **Save** to create the connection.

## Step 4: Sync and review the imported agents

1. On the **Registry sync** page, select your new Databricks connection.
2. Select **Sync agents** to trigger the first synchronization.
3. Open the connection's details to review:
   - Platform provider and region
   - Last run date and last sync status
   - Total synced agents
   - Synchronization results (including any errors to resolve)
4. Repeat **Sync agents** any time you add or change Genie spaces in Databricks. Scheduled, automatic syncs are planned for a future release.

## Verify the connection

- The Databricks connection shows a **Last sync status** of success on the **Registry sync** page.
- Your Genie agent(s) now appear in the Agent 365 **agent registry**, listed alongside your Copilot Studio and Foundry pilot agents.
- Selecting a synced Genie agent shows its basic metadata and the governance actions currently supported by the Databricks API.

With Databricks Genie synced into the registry, the AI Admin now has one inventory that spans Copilot Studio, Foundry, and Databricks, ready for the same governance and security workflows covered in earlier chapters.

## Reference

- [Registry sync in the Microsoft 365 agent registry (preview)](https://learn.microsoft.com/microsoft-agent-365/admin/agent-registry)
- [Connect existing agents to Microsoft Agent 365](https://learn.microsoft.com/microsoft-agent-365/connect-existing-agents)
- [Databricks service principals](https://docs.databricks.com/)
- [Overview of Microsoft Agent 365](https://learn.microsoft.com/microsoft-agent-365/overview)

---

[🏠 Back to Home](../README.md)
