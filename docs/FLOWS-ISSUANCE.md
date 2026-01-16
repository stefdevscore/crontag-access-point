# Issuance Flows (V1)

This document describes the **issuance-only flows** for minting access passes
using the crontag system.

It is **non-normative** and **illustrative**.
It deliberately excludes **all access enforcement concerns**.

Issuance ends once an AccessPass is minted and recorded.

---

## Scope & Assumptions

This document covers **issuance only**.

Assumptions:

- Base L2
- No off-chain payment proofs
- No signatures
- No access evaluation
- A single `ContextControllerV1`
- A product-level `IssuanceRouterV1`

Explicitly excluded:

- Access checks
- Access policies
- Routers
- Entry validation
- Runtime enforcement

---

## Actors

- **Issuer**
  Entity creating mintable contexts.

- **User**
  Entity minting an access pass.

- **IssuanceRouterV1**
  Product-layer coordinator for minting.

- **ContextControllerV1**
  Declarative issuance gate.

- **AccessPassV1**
  Immutable credential primitive.

---

## High-Level Architecture

```
Issuer / User
     |
     v
IssuanceRouterV1
     |
     +--> ContextControllerV1 (canMint, recordMint)
     |
     +--> AccessPassV1 (mint)
```

Issuance produces **immutable credentials only**.
No access logic is involved.

---

## Flow A — Issuer Registers a Context

### Step 1 — Product Defines ContextId

The product derives a unique contextId:

```
contextId = keccak256("devconf-2026:tier:vip")
```

Context structure is a **product concern**.

---

### Step 2 — Issuer Registers Context

Issuer claims ownership:

```
ContextControllerV1.registerContext(contextId)
```

Effects:

- Context ownership established
- Context becomes mintable
- Registration is irreversible

---

### Step 3 — Issuer Configures Mint Rules

Issuer configures future minting constraints:

```
setContextRules(
  contextId,
  mintStart,
  mintEnd,
  maxSupply,
  useAllowlist
)
```

Properties:

- Rules affect future mints only
- Existing passes are never altered
- Supply is tracked per contextId

---

## Flow B — User Mints an Access Pass

### Step 1 — User Selects Context

UI resolves:

- contextId
- tier
- expiration (optional)

---

### Step 2 — User Calls IssuanceRouterV1

```
mint(
  contextId,
  expiresAt,
  tier,
  transferable
)
```

---

### Step 3 — Issuance Eligibility Check

Router evaluates:

```
ContextControllerV1.canMint(user, contextId)
```

Failure reverts the transaction.

---

### Step 4 — Mint Pass

If allowed:

```
AccessPassV1.mint(
  contextId,
  expiresAt,
  tier,
  transferable,
  controller = ContextControllerV1
)
```

Effects:

- Token is minted
- Immutable facts recorded
- Ownership assigned

---

### Step 5 — Record Issuance

Router explicitly records supply:

```
ContextControllerV1.recordMint(contextId)
```

This is mandatory and explicit by design.

---

## Key Properties

- Issuance is **deterministic**
- No implicit side effects
- No post-mint authority
- Supply accounting is explicit
- Access is entirely out-of-scope

---

## Non-Goals

This flow does NOT include:

- Access enforcement
- Policy evaluation
- Token discovery
- Revocation
- Metadata
- Payments

---

## Conclusion

Issuance is complete once:

- a token is minted
- supply is recorded

Everything beyond this point belongs to **access layers**.
