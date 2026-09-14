# ❄️ Onboarding Snowflake Cortex Agents

[🏠 Back to Home](../README.md)

Your organization already runs Snowflake Cortex Agents in its own Snowflake account. To bring them under the same governance umbrella as `Wildpaws Trail Guide` and `Sous Snark`, you connect Snowflake to Agent 365. Just like Databricks Genie, there are two independent integration paths, and this chapter sets up both:

1. Connected platforms (Snowflake AI), the admin-side sync that pulls your existing Snowflake agents into the Agent 365 registry for visibility and governance.
2. Install the Snowflake Cortex Agents app from the AI Marketplace, the end-user chat surface in Teams and Microsoft 365 Copilot.

This chapter assumes Snowflake and your Cortex Agents already exist.

---

## Index

- [What you'll build](#what-youll-build)
- [Prerequisites](#prerequisites)
- [Option 1 — Connect Snowflake in Connected platforms](#option-1--connect-snowflake-in-connected-platforms)
  - [Step 1: Create a service user, role, and key in Snowflake](#step-1-create-a-service-user-role-and-key-in-snowflake)
  - [Step 2: Connect the Snowflake AI platform](#step-2-connect-the-snowflake-ai-platform)
- [Option 2 — Install Snowflake Cortex Agents from the Marketplace](#option-2--install-snowflake-cortex-agents-from-the-marketplace)
  - [Step 4: Install the app from the AI Marketplace](#step-4-install-the-app-from-the-ai-marketplace)
  - [Step 5: Configure the app for a chat in Teams](#step-5-configure-the-app-for-a-chat-in-teams)
- [Verify the setup](#verify-the-setup)
- [Reference](#reference)

## What you'll build

```mermaid
flowchart LR
  subgraph SF["Snowflake (existing)"]
    A1["Agent: Sales Analytics"]
    A2["Agent: Support Knowledge"]
    A3["Agent: Finance Ops"]
  end
  A1 & A2 & A3 -->|Service user + token| CP["Connected platforms<br/>(Snowflake AI)"]
  CP --> AR["Agent 365 agent registry"]
  AR --> GOV["Inventory, posture, and governance actions"]
  MP["Snowflake Cortex Agents app<br/>(AI Marketplace)"] -->|Install| AR
  AR -->|Deploy to users| T["Microsoft Teams / Copilot chat"]
  T -->|Configure account + agent| SF
```

By the end of this chapter:

- Snowflake is a connected platform in Agent 365, and your Cortex Agents show up in the Agent 365 agent registry alongside your Copilot Studio and Foundry pilot agents.
- The AI Admin can monitor sync status and apply the governance actions the Snowflake API supports, all from the Microsoft 365 admin center.
- The Snowflake Cortex Agents app is installed from the AI Marketplace and made available to end users in Teams and Microsoft 365 Copilot.

## Prerequisites

- Your organization is onboarded to Microsoft Agent 365 (see [Chapter 4: Agent 365](../Chapter%204%20Agent%20365/Agent-365-Custom-Template.md)).
- A Microsoft 365 admin role that can manage the agent registry (for example, Global Administrator).
- An existing Snowflake account that already hosts one or more Cortex Agents, with `ACCOUNTADMIN` access to create a service user and grant it access to those agents.
- Your Snowflake account URL (looks like `https://<orgname>-<account>.snowflakecomputing.com`).

## Option 1 — Connect Snowflake in Connected platforms

This is the admin visibility path. It authenticates to Snowflake as a service user (not a person) and syncs your agents into the Agent 365 registry.

### Step 1: Create a service user, role, and key in Snowflake

Run as `ACCOUNTADMIN` in a Snowflake SQL file (worksheet). This creates a least-privilege service identity that can list and read the agents. Replace `<your_warehouse>` and `<your_db>.<your_schema>` with the warehouse and the database/schema where your Cortex Agents live.

The Snowflake AI form offers two authentication methods: RSA key and Bearer Token. Use RSA key-pair, it's the best practice for a service-to-service connection: Snowflake stores only your public key, the private key stays in the connector, and it supports zero-downtime rotation. Snowflake is also phasing out single-secret sign-in for service users. A Bearer Token (programmatic access token) is a simpler but long-lived shared secret, use it only for quick tests. Both are shown below.

1a. Create the role and service user:

```sql
USE ROLE ACCOUNTADMIN;

CREATE ROLE IF NOT EXISTS AGENT365_SYNC_ROLE;
GRANT USAGE ON WAREHOUSE <your_warehouse> TO ROLE AGENT365_SYNC_ROLE;
GRANT USAGE ON DATABASE <your_db> TO ROLE AGENT365_SYNC_ROLE;
GRANT USAGE ON SCHEMA <your_db>.<your_schema> TO ROLE AGENT365_SYNC_ROLE;
GRANT USAGE ON ALL AGENTS IN SCHEMA <your_db>.<your_schema> TO ROLE AGENT365_SYNC_ROLE;
GRANT USAGE ON FUTURE AGENTS IN SCHEMA <your_db>.<your_schema> TO ROLE AGENT365_SYNC_ROLE;
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE AGENT365_SYNC_ROLE;

CREATE USER IF NOT EXISTS SVC_AGENT365
  DEFAULT_ROLE = AGENT365_SYNC_ROLE
  DEFAULT_WAREHOUSE = <your_warehouse>
  TYPE = SERVICE                 -- programmatic-only user (no password/UI login)
  COMMENT = 'Service user for Agent 365 Connected platforms sync';
GRANT ROLE AGENT365_SYNC_ROLE TO USER SVC_AGENT365;
```

1b. Generate an RSA key pair. The connector uses the private key; Snowflake stores only the public key.

- Windows (PowerShell, no extra tools required):

  ```powershell
  $rsa  = [System.Security.Cryptography.RSA]::Create(2048)
  $priv = [Convert]::ToBase64String($rsa.ExportPkcs8PrivateKey(), 'InsertLineBreaks')
  $pub  = [Convert]::ToBase64String($rsa.ExportSubjectPublicKeyInfo())
  Set-Content "$HOME\svc_agent365_key.p8" "-----BEGIN PRIVATE KEY-----`r`n$priv`r`n-----END PRIVATE KEY-----" -Encoding ascii
  $pub   # copy this single line into the ALTER USER statement below
  ```

- macOS / Linux (openssl):

  ```bash
  openssl genrsa 2048 | openssl pkcs8 -topk8 -inform PEM -out svc_agent365_key.p8 -nocrypt
  openssl rsa -in svc_agent365_key.p8 -pubout -out svc_agent365_key.pub
  ```

Register the public key on the service user, the single base64 line from `$pub` (or the body of the `.pub` file), with no `-----BEGIN/END-----` lines and no line breaks:

```sql
ALTER USER SVC_AGENT365 SET RSA_PUBLIC_KEY='MIIBIjANBgkqh...';
DESC USER SVC_AGENT365;   -- confirm RSA_PUBLIC_KEY_FP is now populated
```

1c. Get the account identifier the form asks for (the `myorg-myaccount` format, not a URL):

```sql
SELECT CURRENT_ORGANIZATION_NAME() AS org, CURRENT_ACCOUNT_NAME() AS account;
-- Account identifier = <org>-<account>, for example MYORG-MYACCOUNT
```

### Step 2: Connect the Snowflake AI platform

1. Open the [Microsoft 365 admin center](https://admin.microsoft.com/Adminportal/Home#/homepage).
2. In the navigation pane, select Agents > All Agents to open the agent registry.
3. In the Connected platforms web part, select Manage, then + Connect a platform.
4. Fill in the form:
   - Name and Description, for example `Snowflake - Pilot`.
   - External platform: Snowflake AI.
   - Import agents automatically: Never for manual, admin-triggered syncs, or On a schedule (choose a frequency such as Daily and a time) for recurring imports.
   - Authentication method: RSA key (recommended) or Bearer Token.
   - Account identifier: the `<org>-<account>` value from Step 1c, for example `MYORG-MYACCOUNT`.
   - Database and Schema: the location of your agents. ⚠️ The form defaults to `snowflake_intelligence` / `Agents` (the Snowsight default), and the schema box shows `Agents` as grey placeholder text. If your agents live elsewhere, for example `AGENT365_PILOT.AGENTS`, type both fields in yourself, or the sync finds no agents (and the Verify button stays greyed until every required field has real text).
   - Snowflake user: `SVC_AGENT365`.
   - Private key (for RSA key): paste the contents of `svc_agent365_key.p8`, or Browse to the file. For Bearer Token, paste the token secret instead.
5. Select Verify authentication to confirm Agent 365 can reach Snowflake and authenticate (you should see Connection verified successfully).
6. Select Save to create the connection. With On a schedule set, Agent 365 imports your agents on the chosen frequency; you can also trigger a manual sync anytime from the connection's menu on the Connected platforms page.

## Option 2 — Install Snowflake Cortex Agents from the Marketplace

Connected platforms (Option 1) gives the AI Admin visibility and governance over the agents that run in Snowflake. To let end users actually chat with Snowflake Cortex Agents inside Microsoft 365, install the Snowflake Cortex Agents app from the AI Marketplace, then have each user connect it to their account.

### Step 4: Install the app from the AI Marketplace

1. Open the [Microsoft 365 admin center](https://admin.microsoft.com/Adminportal/Home#/homepage).
2. In the navigation pane, select Agents > All agents and search for Snowflake Cortex Agents (published by Snowflake Inc. as a Third party agent), or find it under Agents > Marketplace.
3. Review the About this agent details, description, publisher, and Permissions, then select Install (or Get it now).
4. Choose which users or groups the app is available to, and optionally which users have it pre-installed, then confirm the install.
5. Once installed, the app appears in Agents > All agents with Publisher type: Third party, Publisher: Snowflake Inc., and channel icons for Teams and Microsoft 365 Copilot. Its status may show Not available until the app finishes propagating to Teams and a user engages it.

> This install is a Marketplace deployment for end-user consumption, separate from the Connected platforms connection in Option 1, which exists purely for admin visibility and governance. Use both together: Connected platforms tracks the Cortex Agents running in Snowflake, while the Marketplace app gives users a chat surface in Teams and Copilot.

### Step 5: Configure the app for a chat in Teams

1. In Microsoft Teams, open a chat with the Snowflake Cortex Agents app (search for it in the app bar or Apps if it isn't pinned yet). Newly deployed apps can take time to appear in Teams.
2. Enter `config` in the chat to start the account connection flow. Sign in with your organizational Microsoft account. If Snowflake has not yet been configured for your Microsoft organization, select **I'm the Snowflake administrator**, enter the Snowflake account URL, and select **Connect Snowflake account**. Use the account that actually hosts the Cortex Agents, for example `https://<orgname>-<account>.snowflakecomputing.com`.
3. Enter `choose agent` in the chat. Select the Cortex Agent to use, for example Sales Analytics. If no agents are listed, confirm that you connected the correct Snowflake account and that the signed-in user's default Snowflake role has `USAGE` on the warehouse, database, schema, and agent objects.
4. Ask a question in natural language, for example *"What was total revenue by region?"*. The Cortex Agent answers inside Teams, citing its sources (semantic view or search results).

Other useful chat commands include:

- `show configured accounts`: List the Snowflake accounts connected to the app.
- `add account`: Connect another Snowflake account.
- `choose agent`: Switch to another available Cortex Agent.
- `logout`: End the current Snowflake session so you can authenticate again after changing a user's default role or account access.

## Verify the setup

- The Snowflake connection shows a Last sync status of success on the Connected platforms page.
- Your Cortex Agents appear in the Agent 365 agent registry, listed alongside your Copilot Studio and Foundry pilot agents, with Publisher: Snowflake Inc. and an Entra agent ID.
- Selecting a synced agent shows its metadata and the governance actions currently supported by the Snowflake API.
- The Snowflake Cortex Agents Marketplace app shows Available in Agents > All agents, with channel icons for Teams and Microsoft 365 Copilot.
- In Teams, a configured chat answers a data question and shows Sources under the response.

With Snowflake synced into the registry and installed for end users, the AI Admin has one inventory that spans Copilot Studio, Foundry, Databricks, and Snowflake, and end users have a governed way to chat with their Snowflake data directly in Teams.

## Reference

- [Connected platforms in the Microsoft 365 agent registry](https://learn.microsoft.com/microsoft-agent-365/admin/connected-platforms)
- [Connect existing agents to Microsoft Agent 365](https://learn.microsoft.com/microsoft-agent-365/connect-existing-agents)
- [Manage agent registry in Microsoft 365 admin center (Marketplace)](https://learn.microsoft.com/microsoft-365/admin/manage/agent-registry)
- [Governance and Lifecycle actions for agents (Install, Uninstall, Block)](https://learn.microsoft.com/microsoft-365/admin/manage/agent-actions)
- [Snowflake Cortex Agents overview](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-agents)
- [Create and manage Cortex Agents](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-agents-manage)
- [Snowflake programmatic access tokens](https://docs.snowflake.com/en/user-guide/programmatic-access-tokens)

---

[🏠 Back to Home](../README.md)
