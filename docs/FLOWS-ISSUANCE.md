# Issuance & Access Flows (V1)

This document describes the **end-to-end flows** for creating contexts (events, subscriptions, memberships) and minting access passes using the crontag system.

It is **non-normative**: it does not define protocol rules.
It is **illustrative**: it shows how the existing primitives are intended to be composed by a product.

The flows below assume:
- Base L2 (no alternative currencies)
- No off-chain payment proofs
- No signature-based authorization
- A single default `ContextControllerV1`
- A product-level `IssuanceRouterV1`

---

## Actors

- **Issuer**  
  A user creating an event, subscription, or membership.

- **User**  
  A user minting an access pass.

- **AccessPassV1**  
  Immutable credential primitive.

- **ContextControllerV1**  
  Declarative, issuance-only mint gate.

- **IssuanceRouterV1**  
  Product-level coordinator for minting and supply accounting.

- **AccessPointV1**  
  Stateless access enforcement (used later, not during minting).

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

Access enforcement happens **later**, via `AccessPointV1` and `AccessVerifierV1`.

---

## Flow A — Issuer Creates an Event With Two Tiers

### Example

Issuer wants to create:

**Event:** DevConf 2026  
**Tier 1:** General Admission  
- Required tier: 1  
- Supply: 500  

**Tier 2:** VIP  
- Required tier: 2  
- Supply: 250  

Both tiers share:
- Same event identity
- Same mint window
- Same controller
- Different supply and tier constraints

---

### Step 1 — Issuer Defines Context IDs (Product-Level)

The product derives **distinct contextIds**.

For example:

```
contextId_tier1 = keccak256("devconf-2026:tier:1")
contextId_tier2 = keccak256("devconf-2026:tier:2")
```

> Context IDs are opaque identifiers.  
> Their structure is a **product concern**, not a protocol concern.

---

### Step 2 — Issuer Registers Contexts

Issuer calls `ContextControllerV1.registerContext` for each context:

```
registerContext(contextId_tier1)
registerContext(contextId_tier2)
```

Effects:
- Context ownership is claimed
- Context IDs become mintable
- Registration is irreversible

---

### Step 3 — Issuer Configures Mint Rules

For each context, issuer configures rules:

```
setContextRules(
  contextId_tier1,
  mintStart,
  mintEnd,
  500,      // maxSupply
  false     // useAllowlist
)

setContextRules(
  contextId_tier2,
  mintStart,
  mintEnd,
  250,
  false
)
```

Important properties:
- Rules apply only to future minting
- Changing rules does not affect existing passes
- Supply is tracked per `(contextId)`

---

### Step 4 — Issuer Creates Access Points

Issuer (or product) deploys **one AccessPointV1 per context**:

```
AccessPointV1(
  accessPass,
  accessVerifier,
  contextId_tier1,
  requiredTier = 1,
  requiredController = ContextControllerV1
)

AccessPointV1(
  accessPass,
  accessVerifier,
  contextId_tier2,
  requiredTier = 2,
  requiredController = ContextControllerV1
)
```

These access points:
- Do not mint
- Do not track supply
- Do not know about payments
- Only evaluate access later

---

## Flow B — User Mints a Ticket

### Step 1 — User Chooses Tier

User selects:
- Event: DevConf 2026
- Tier: VIP (tier 2)

The UI resolves:
- `contextId = contextId_tier2`
- `tier = 2`

---

### Step 2 — User Calls IssuanceRouterV1

User submits a mint transaction:

```
mintPass(
  contextId_tier2,
  tier = 2,
  expiresAt
)
```

---

### Step 3 — IssuanceRouterV1 Checks Mint Eligibility

IssuanceRouterV1 calls:

```
ContextControllerV1.canMint(user, contextId_tier2)
```

If this returns `false`, the transaction reverts.

This enforces:
- mint window
- max supply
- allowlist (if enabled)

---

### Step 4 — IssuanceRouterV1 Mints the Pass

If allowed:

```
AccessPassV1.mint(
  contextId_tier2,
  expiresAt,
  tier = 2,
  transferable,
  controller = ContextControllerV1
)
```

Effects:
- Token is minted
- Immutable pass facts are recorded
- Ownership is assigned to the user

---

### Step 5 — IssuanceRouterV1 Records Supply

After a successful mint:

```
ContextControllerV1.recordMint(contextId_tier2)
```

This increments supply **explicitly**.

> This call is required by design.  
> Supply tracking is never implicit.

---

## Flow C — Access Enforcement (Later)

When access needs to be checked (e.g. event entry):

```
AccessPointV1.canAccess(user, tokenId)
```

Internally:
1. Delegates to `AccessVerifierV1`
2. Checks context match
3. Checks expiration
4. Checks tier
5. Checks controller provenance (if configured)

No state changes occur.

---

## Key Architectural Properties

- **Issuance and access are decoupled**
- **Supply is explicit and auditable**
- **Context semantics are product-defined**
- **Protocol contracts remain neutral**
- **Misuse is always visible**

---

## Non-Goals (Explicit)

These flows do **not** include:

- pricing logic
- payment handling
- refunds
- revocation
- pass invalidation
- metadata
- UI design

Those belong in higher layers.

---

## Conclusion

These flows demonstrate that:

- Multiple tiers are naturally supported
- Supply is enforceable without protocol mutation
- Issuers retain flexibility
- Authority remains explicit
- The protocol remains neutral

All power exists at the product layer — by design.
