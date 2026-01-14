# crontag-access-point

Reference access enforcement contracts built on top of the **crontag protocol**.

This repository provides a **minimal, explicit, non-authoritative policy layer**
that demonstrates how access decisions can be enforced using protocol facts
without introducing new authority, interpretation, or hidden policy.

---

## What This Repository Is

`crontag-access-point` contains:

- A **reference access point interface**
- A **single canonical implementation (AccessPointV1)**
- Supporting documentation and tests

It demonstrates how applications can enforce access by **consuming**
protocol primitives such as:

- `AccessPassV1`
- `AccessVerifierV1`
- (optionally) `ContextControllerV1`

This repository is **not part of the crontag protocol**.
It is an example of how the protocol can be used.

---

## What This Repository Is Not

This repository does **not**:

- Issue access passes
- Define pricing or payment logic
- Verify that payment occurred
- Infer legitimacy or authority
- Act as a registry or directory
- Provide metadata, reasons, or explanations
- Enforce global policy
- Introduce admin or governance roles

All policy enforced here is **local, explicit, and opt-in**.

---

## Architecture Overview

The crontag system is intentionally layered:

```
crontag-protocol
  ├─ AccessPassV1        (immutable access facts)
  ├─ ContextControllerV1 (issuance constraints)
  └─ AccessVerifierV1    (canonical verification)

crontag-access-point
  └─ AccessPointV1       (local access enforcement)

crontag-client
  └─ UI / SDK / Indexer  (token discovery, UX, aggregation)
```

This repository lives **strictly in the policy layer**.

---

## Design Philosophy

Access points are:

- **Consumers**, not authorities
- **Deterministic**, not interpretive
- **Stateless**, not mutable
- **Replaceable**, not canonical

An access point answers one question only:

> “Given this token and this block state, should access be allowed here?”

It does not answer _why_, _who is legitimate_, or _what something means_.

---

## Documentation

- `docs/DESIGN-ACCESS-POINT.md` — formal design rationale and constraints
- `docs/REPO_TREE.md` — generated repository structure

These documents are **non-normative but constraining**.
Implementations that diverge should do so explicitly.

---

## Status

- No production guarantees
- Reference implementation only
- Versioned independently from `crontag-protocol`

This repository exists to make **correct usage obvious**, not to define truth.

---

## License

MIT — see `LICENSE`.
