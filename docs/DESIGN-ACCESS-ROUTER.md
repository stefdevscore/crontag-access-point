
# AccessRouterV1 — Design Rationale

## Purpose

**AccessRouterV1** is a **platform-level access aggregation and routing contract**.

It allows a product platform to act as a *single access point* for many issuers,
contexts, and access policies **without becoming an authority** and **without
violating crontag protocol invariants**.

AccessRouterV1 answers one question only:

> “Given this user and token, does any configured access policy allow access here?”

It does **not** issue passes, mutate protocol state, or interpret legitimacy.
It composes existing access points.

---

## What AccessRouterV1 Is

AccessRouterV1 is:

- a **read-only coordinator**
- a **policy multiplexer**
- a **UX-aligned abstraction**
- a **platform convenience layer**

It enables:

- many issuers
- many contexts
- many tiers
- many access points

…to be consumed through **one contract call**.

---

## What AccessRouterV1 Is Not

AccessRouterV1 does **not**:

- issue AccessPass tokens
- verify payments
- mutate protocol state
- enforce minting rules
- infer legitimacy
- select tokens automatically
- enumerate user holdings
- emit events
- cache results
- override AccessPoint logic

It is not part of the crontag protocol.

---

## Architectural Position

```
User / Client
     ↓
AccessRouterV1   ← platform layer
     ↓
AccessPointV1(s) ← policy layer
     ↓
AccessVerifierV1 ← protocol primitive
     ↓
AccessPassV1     ← immutable facts
```

Each layer remains independent and replaceable.

---

## Canonical Assumptions

### 1. Known Token Universe

AccessRouterV1 assumes a **single canonical AccessPassV1 universe** via the
underlying AccessPointV1 contracts it references.

It does not attempt to unify multiple token contracts.

---

### 2. Explicit Token Selection

The caller **must supply the tokenId**.

AccessRouterV1 does not:

- scan balances
- guess which token to use
- select “best” passes

Responsibility remains explicit and deterministic.

---

### 3. Delegated Authority Only

AccessRouterV1 **never overrides** AccessPoint decisions.

It only aggregates:

- if *any* configured AccessPoint allows access → allow
- otherwise → deny

---

## Configuration Model

AccessRouterV1 stores **references**, not rules.

### Stored Data

- list of registered AccessPointV1 contracts
- optional grouping by issuer or context (platform-defined)
- optional active / inactive flags

No protocol data is duplicated.

---

## Access Evaluation Flow

When `canAccess(user, tokenId)` is called:

1. Iterate over configured AccessPointV1 references
2. Call `canAccess(user, tokenId)` on each
3. If **any** returns `true` → return `true`
4. Otherwise → return `false`

This mirrors logical OR composition.

---

## Determinism & Safety

AccessRouterV1 is:

- read-only
- deterministic
- composable
- replay-safe
- audit-friendly

Given the same configuration and block state, it always returns the same result.

---

## Platform Usage Pattern

Typical product usage:

- Platform deploys **one AccessRouterV1**
- Issuers register AccessPointV1 contracts
- Platform UI maps events / subscriptions to AccessPoints
- Clients query a single router

This enables a clean UX without collapsing authority.

---

## Misuse & Failure Modes

All misuse remains explicit:

- wrong tokenId → denied
- wrong context → denied
- inactive access point → denied
- misconfigured issuer → denied

No silent failures.

---

## Explicit Stop Point (V1)

AccessRouterV1 deliberately excludes:

- priority ordering
- weighted access
- partial approvals
- reason codes
- enumeration helpers
- token discovery
- payment checks
- governance logic

If needed, these belong in **higher layers**.

---

## Conclusion

AccessRouterV1 provides **platform-scale ergonomics** without protocol compromise.

It proves that:

- access can be aggregated without central authority
- issuers remain sovereign
- clients remain explicit
- protocol invariants remain intact

This contract exists to simplify UX — not to redefine trust.
