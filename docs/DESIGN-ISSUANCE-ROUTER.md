# IssuanceRouterV1 — Design Rationale

## Purpose

**IssuanceRouterV1** is a **product-facing orchestration contract** responsible for coordinating
access pass issuance on top of the crontag protocol.

It exists to make issuance **explicit, auditable, and safe**, without introducing hidden authority
or mutating protocol-level semantics.

IssuanceRouterV1 answers one question:

> “How does an issuer correctly mint access passes for a context using the crontag primitives?”

It is **not** part of the crontag protocol.
It is a **reference product-layer router**.

---

## What IssuanceRouterV1 Is

IssuanceRouterV1 is an **issuance coordinator**.

It:

- registers new contexts in `ContextControllerV1`
- configures minting constraints for those contexts
- calls `AccessPassV1.mint`
- explicitly records issuance via `ContextControllerV1.recordMint`
- provides a clean, UX-aligned entry point for products

It makes **implicit workflows explicit**.

---

## What IssuanceRouterV1 Is Not

IssuanceRouterV1 explicitly **does not**:

- verify access
- enforce access decisions
- interpret tiers or pricing
- infer legitimacy
- grant authority over the protocol
- mutate AccessPassV1 state beyond minting
- bypass controller logic
- hide side effects

All authority remains **local and declarative**.

---

## Architectural Position

IssuanceRouterV1 sits **above** protocol primitives:

```
Product / UI
    ↓
IssuanceRouterV1
    ↓
┌─────────────────────┐
│ ContextControllerV1 │
│ AccessPassV1        │
└─────────────────────┘
```

It never calls:

- `AccessVerifierV1`
- `AccessPointV1`
- `AccessRouterV1`

Issuance and access are intentionally separated.

---

## Core Responsibilities

### 1. Context Registration

IssuanceRouterV1 registers new contexts on behalf of issuers:

- each contextId is registered exactly once
- ownership is scoped to the issuer
- registration is explicit and irreversible

This ensures:

- no accidental context reuse
- no tier collisions
- no ambiguous issuance provenance

---

### 2. Mint Configuration

IssuanceRouterV1 configures minting rules via `ContextControllerV1`:

- mint windows
- max supply
- allowlists (optional)

These rules apply **only to future minting**.

---

### 3. Explicit Mint Orchestration

When a user mints:

1. IssuanceRouterV1 calls `AccessPassV1.mint`
2. Mint-time controller checks occur
3. IssuanceRouterV1 calls `ContextControllerV1.recordMint`

This preserves:

- controller purity
- non-retroactivity
- explicit issuance accounting

No hidden side effects occur inside protocol contracts.

---

## Authority Model

IssuanceRouterV1 has **no intrinsic authority**.

It acts only if:

- the issuer has registered the context
- the controller permits minting
- the user explicitly calls mint

Issuers may bypass IssuanceRouterV1 entirely if they choose.

This router exists for **convenience, not control**.

---

## Determinism & Safety

IssuanceRouterV1 is designed to be:

- explicit
- auditable
- replay-safe
- debuggable
- replaceable

All state changes are intentional and externally visible.

---

## Misuse & Failure Modes

Examples of explicit failure:

- minting for an unregistered context → revert
- minting after supply cap → revert
- minting outside window → revert
- attempting to record mint without ownership → revert

No silent failures.
No inferred behavior.

---

## Intended Usage

IssuanceRouterV1 is intended for:

- product UIs
- hosted issuer platforms
- reference implementations
- educational deployments

It is **not** a required component of the protocol.

---

## Explicit Stop Point (V1)

IssuanceRouterV1 deliberately stops here.

It will **not**:

- process payments
- escrow funds
- handle refunds
- perform signature verification
- batch mints
- enforce access rules
- manage upgrades

Those belong in **higher layers**.

---

## Conclusion

IssuanceRouterV1 demonstrates how **issuance can be safely orchestrated without violating protocol neutrality**.

It proves that:

- issuance logic can be explicit
- controllers remain declarative
- protocol contracts remain minimal
- products can be built without central authority

Anything more would collapse layers that must remain separate.
