# AccessPointV1 — Design Rationale

## Purpose

**AccessPointV1** is a **reference access enforcement contract** built on top of the crontag protocol.

It demonstrates how access decisions can be made **using protocol facts only**, without introducing new authority, interpretation, or hidden policy.

The access point exists to answer one question, deterministically:

> “Given the current on-chain state, should this account be allowed access here?”

It is **not** part of the crontag protocol itself.
It is a **policy layer**, intentionally local and replaceable.

---

## What an Access Point Is

An access point is a **consumer** of protocol primitives.

It:

- reads immutable access facts from `AccessPassV1`
- uses `AccessVerifierV1` for canonical verification
- applies **local, explicit policy**
- returns a boolean allow / deny result

It does **not** issue tokens, interpret meaning, or assert legitimacy.

---

## What an Access Point Is Not

AccessPointV1 explicitly **does not**:

- define who may issue passes
- define pricing or payments
- verify that payment occurred or was fair
- infer issuer legitimacy
- consult controllers dynamically
- discover or select tokens
- mutate state
- emit events
- provide reasons or metadata
- act as a registry or directory
- act as a global authority

Any such behavior belongs **outside** the protocol and **outside** this reference implementation.

---

## Canonical Assumptions

AccessPointV1 makes the following **explicit assumptions**, all of which are intentional.

### 1. Known Token Universe

AccessPointV1 assumes a **known AccessPassV1 instance**.

- The verifier is bound to a specific `AccessPassV1`
- Only passes from that instance are considered
- This enables canonical fee collection and prevents shadow token universes

This is not censorship — it is **explicit scope**.

Anyone may deploy their own access point if they want different assumptions.

---

### 2. Explicit Token Selection (Caller-Supplied)

AccessPointV1 evaluates **exactly one access pass at a time**.

- The caller **must supply the `tokenId`** being evaluated
- The access point does **not** discover, enumerate, or select tokens
- Token discovery is an application- or client-level concern

This constraint is deliberate:

- prevents hidden heuristics
- avoids on-chain iteration
- preserves determinism
- keeps responsibility explicit

If a caller supplies the “wrong” token, access is denied.

---

### 3. Local Policy, Not Legitimacy

Any policy enforced by an access point is:

- **local**
- **opt-in**
- **non-legitimizing**

For example:

- requiring a specific `contextId`
- requiring a minimum tier
- requiring a specific controller provenance

A controller match **does not** imply that a pass is valid, official, correct, or legitimate.

It means only:

> “This access point chooses to trust passes minted through this controller.”

Clients must treat access points as **policy statements**, not truth.

---

## Configuration Surface (Immutable)

AccessPointV1 is configured **once**, at deployment.

### Required Configuration

- `accessPass` — canonical `AccessPassV1` instance
- `accessVerifier` — canonical `AccessVerifierV1`
- `requiredContextId` — the context this access point represents
- `requiredTier` — minimum acceptable tier

### Optional Configuration

- `requiredController` — if set, require:
  `pass.controller == requiredController`

If `requiredController` is unset (`address(0)`), provenance is not enforced.

---

## Tier Semantics

Tiers are treated as **monotonic integers**.

- A higher tier always satisfies a lower requirement
- Tier meaning is not interpreted
- Tier naming, pricing, and benefits are external concerns

AccessPointV1 enforces **only**:
pass.tier >= requiredTier

AccessPointV1 does **not** verify:

- that a user paid a correct amount
- that pricing was fair
- that tiers map to real-world benefits

Those responsibilities belong to the issuer or product layer.

---

## Context Semantics

`contextId` identifies the **thing being accessed**.

Examples:

- an event
- a membership
- a subscription
- a gated resource

AccessPointV1 does not:

- validate the origin of the context
- enforce uniqueness across controllers
- infer real-world meaning

It performs **exact matching only**.

---

## Verification Flow

When `canAccess(address user, uint256 tokenId)` is called:

1. Delegate verification to `AccessVerifierV1`

   - token existence
   - ownership
   - context match
   - expiration
   - tier requirement

2. If configured, enforce controller provenance

   - require `pass.controller == requiredController`

3. Return `true` or `false`

No state changes.
No side effects.
No caching.

---

## Determinism & Safety

AccessPointV1 is:

- stateless
- deterministic
- replay-safe
- safe to call on-chain or off-chain
- safe to compose with other contracts
- safe to index and audit

Given the same inputs and block state, it will always return the same result.

---

## Misuse & Failure Modes

AccessPointV1 makes misuse **explicit and undeniable**.

Examples:

- a pass minted for the wrong context → denied
- a pass with insufficient tier → denied
- a pass minted via a different controller → denied (if enforced)
- a fabricated or nonsensical pass → denied

There are no silent failures and no reinterpretation.

---

## Intended Usage

AccessPointV1 is intended to be used by:

- applications enforcing gated behavior
- smart contracts controlling privileged actions
- off-chain services checking eligibility
- frontends displaying access state
- auditors validating policy correctness

It is a **reference**, not a monopoly.

---

## Explicit Stop Point (V1)

AccessPointV1 deliberately stops here.

It will **not** add:

- multi-context support
- dynamic policy updates
- admin roles
- pricing logic
- metadata
- allowlists
- reasons or error codes
- aggregation or registries

If those are needed, they belong in **other layers**.

---

## Conclusion

AccessPointV1 demonstrates how **access enforcement can be built on top of crontag without violating its invariants**.

It proves that:

- protocol facts are sufficient
- policy can remain local
- misuse can be undeniable
- authority need not be centralized

Anything more would compromise neutrality.

This document defines the boundary — implementation must not cross it.
