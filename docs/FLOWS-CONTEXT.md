# FLOWS-CONTEXT.md

## Context Creation Flow (V1)

This document describes the **end-to-end flow for creating a context** in the crontag platform.

It explains:

- who creates contexts
- which contracts are involved
- what state is written
- what authority is established

This document is **non-normative**.
It describes how existing primitives are composed by a product, not protocol guarantees.

---

## Purpose of Context Creation

A **context** represents a mintable scope under which access passes may be issued.

Examples:

- event tickets (per tier)
- subscriptions
- memberships
- feature entitlements

A context:

- does **not** issue tokens
- does **not** grant access
- does **not** encode meaning

It exists solely to:

- scope minting rules
- track issuance supply
- anchor future access policies

---

## Actors

- **Issuer**
  The account creating a context.

- **IssuanceRouterV1**
  Product-level coordinator for context creation.

- **ContextControllerV1**
  Declarative, issuance-only mint gate and supply tracker.

- **AccessPolicyControllerV1** (optional)
  Platform-level registry that later groups contexts for access checks.

---

## Entry Point

```solidity
IssuanceRouterV1.createContext(...)
```

Contexts are created via the **router** in the platform flow.
Issuers do not call `ContextControllerV1` directly.

---

## High-Level Call Flow

```
Issuer
  │
  ▼
IssuanceRouterV1.createContext
  │
  ├─► ContextControllerV1.registerContext(contextId)
  │
  ├─► ContextControllerV1.setContextRules(...)
  │
  └─► (optional) AccessPolicyControllerV1.setContextAllowed(...)
```

---

## Step-by-Step Flow

### Step 1 — Context ID Definition (Product-Level)

The product defines one or more `contextId` values.

Examples:

- `event:devconf-2026:tier:general`
- `event:devconf-2026:tier:vip`
- `membership:gold`
- `subscription:monthly`

Context IDs are:

- opaque identifiers
- globally unique within the platform
- never interpreted by the protocol

---

### Step 2 — Issuer Calls IssuanceRouterV1

The issuer submits a transaction:

```solidity
createContext(
  contextId,
  mintStart,
  mintEnd,
  maxSupply,
  useAllowlist
)
```

---

### Step 3 — Context Registration

`IssuanceRouterV1` calls:

```solidity
ContextControllerV1.registerContext(contextId)
```

Effects:

- `contextId` is permanently registered
- duplicate registration is impossible

Ownership is intentionally assigned to IssuanceRouterV1.
This allows the platform to:
• enforce uniform issuance flows
• atomically configure mint rules
• prevent issuers from bypassing the router

The router acts as a delegated operator, not a semantic authority.

---

### Step 4 — Mint Rule Configuration

The router configures future minting rules:

```solidity
ContextControllerV1.setContextRules(
  contextId,
  mintStart,
  mintEnd,
  maxSupply,
  useAllowlist
)
```

Important properties:

- rules affect **future mints only**
- existing passes are never modified
- supply tracking is explicit

---

### Step 5 — Optional Access Policy Mapping

If the platform supports access groups (events, venues, memberships):

```solidity
AccessPolicyControllerV1.setContextAllowed(
  groupId,
  contextId,
  true
)
```

This:

- does **not** grant access
- only makes the context eligible for later access checks

---

## Resulting State

After context creation:

- `ContextControllerV1` knows:

  - the context owner
  - mint windows
  - supply limits
  - allowlist usage

- `AccessPolicyControllerV1` (optional) knows:
  - which access groups reference this context

No tokens are minted.
No access is granted.

---

## Key Invariants Preserved

- Context ownership is explicit
- Minting rules are declarative
- Supply is non-retroactive
- No protocol authority is extended
- All semantics remain product-defined

---

## Explicit Non-Goals

Context creation does **not**:

- issue tokens
- charge users
- grant access
- define UI semantics
- create access policies

Those belong to **issuance** and **access** flows.

---

## Summary

Context creation is the **foundation layer**:

- it defines _where minting may occur_
- it establishes _who controls minting_
- it prepares _future access logic_
- without asserting authority or meaning
