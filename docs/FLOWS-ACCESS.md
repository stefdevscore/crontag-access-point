# FLOWS-ACCESS.md (Updated)

This document describes the **access verification flow** in the crontag platform.

It explains:

- how access is evaluated
- which contracts are consulted
- where authority begins and ends
- how protocol truth and product policy are cleanly separated

This document is **non-normative** and **illustrative**.

---

## Core Principle

**Canonical protocol verification always happens first.**

If a token is not canonically valid, **no policy evaluation occurs**.
Policies only filter _already-valid_ access passes.

> Protocol truth is absolute.
> Policy truth is contextual.

---

## Actors

- **User / Client**
- **AccessRouterV1** (platform aggregation)
- **AccessVerifierV1** (protocol primitive)
- **AccessPolicyControllerV1** (product-layer policy registry)
- **AccessPassV1** (immutable credential)

---

## High-Level Architecture

Client software never queries individual policies or protocol primitives directly.

```
Client
  ↓
AccessRouterV1
  ↓
AccessVerifierV1
  ↓
AccessPassV1
  ↓
AccessPolicyControllerV1
```

---

## Flow A — Access Check for a Group (Event, Membership, Feature)

### Step 1 — Client Supplies Explicit Inputs

The client must provide:

- `groupId` — platform-defined access scope
  (event space, membership, venue, feature gate)
- `tokenId` — explicit AccessPass token
- `user` — address attempting access

No inference, scanning, or token discovery occurs on-chain.

---

### Step 2 — AccessRouterV1 Receives Query

```
canAccess(
  groupId,
  user,
  tokenId
)
```

Responsibilities:

- orchestration only
- read-only
- deterministic
- no state mutation

---

### Step 3 — Canonical Verification (Protocol Truth)

The router **first** delegates to the protocol primitive:

```
AccessVerifierV1.verify(
  user,
  tokenId,
  requiredContext,
  requiredTier
)
```

This verifies:

- token existence
- ownership
- expiration
- canonical invariants

❌ If this step fails → **ACCESS DENIED immediately**

No policy logic is evaluated.

---

### Step 4 — Read Immutable Pass Facts

Only after canonical validity is established, the router reads:

```
AccessPassV1.passData(tokenId)
```

Retrieves immutable facts:

- `contextId`
- `tier`
- `controller`
- `expiresAt`

---

### Step 5 — Policy Evaluation (Product Truth)

The router evaluates platform policy:

```
AccessPolicyControllerV1.canAccess(
  groupId,
  token.contextId,
  token.tier,
  token.controller
)
```

This checks:

- group registration
- policy active flag
- context membership
- tier requirements
- controller provenance (if configured)

❌ If policy rejects → **ACCESS DENIED**

---

### Step 6 — Final Decision

Access is granted **if and only if**:

- canonical verification succeeds **and**
- policy evaluation allows it

Otherwise, access is denied.

No state changes occur.

---

## Determinism Guarantees

This flow is:

- read-only
- deterministic
- replay-safe
- side-effect free

Given the same inputs at the same block height, the result is identical.

---

## Explicit Non-Goals

This flow does NOT include:

- payments
- refunds
- revocation
- policy priority or weighting
- token enumeration
- UI heuristics
- governance logic

---

## Summary

- Protocol truth is evaluated **first**
- Product policy is evaluated **second**
- Policy can never override protocol invalidity
- Access remains explicit, composable, and trust-preserving

This separation allows platform flexibility **without collapsing authority**.
