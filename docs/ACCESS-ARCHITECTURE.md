┌────────────────────────────┐
│ Client / UI │
│ │
│ (explicit inputs only) │
│ - groupId │
│ - contextId │
│ - tokenId │
│ - user │
└─────────────┬──────────────┘
│
│
▼
┌────────────────────────────┐
│ IssuanceRouterV1 │
│ (product coordinator) │
│ │
│ createContext() │
│ mint() │
└─────────────┬──────────────┘
│
│ issuance only
│
┌───────┴────────┐
│ │
▼ ▼
┌───────────────┐ ┌────────────────┐
│ Context │ │ AccessPassV1 │
│ ControllerV1 │ │ (ERC-721) │
│ │ │ │
│ - register │ │ - immutable │
│ - rules │ │ pass facts │
│ - canMint │ │ - ownership │
│ - recordMint │ │ - expiration │
└───────────────┘ └────────────────┘

====================================================
ACCESS TIME ONLY
====================================================

┌────────────────────────────┐
│ Client / UI │
│ │
│ canAccess(groupId, │
│ user, tokenId) │
└─────────────┬──────────────┘
│
▼
┌────────────────────────────┐
│ AccessRouterV1 │
│ (orchestration only) │
│ │
│ - no storage │
│ - no discovery │
│ - read-only │
└─────────────┬──────────────┘
│
│ ① protocol truth
▼
┌────────────────────────────┐
│ AccessVerifierV1 │
│ (canonical authority) │
│ │
│ verify(user, tokenId) │
│ │
│ - ownership │
│ - expiration │
│ - invariants │
└─────────────┬──────────────┘
│
│ only if valid
▼
┌────────────────────────────┐
│ AccessPassV1 │
│ │
│ passData(tokenId) │
│ → contextId │
│ → tier │
│ → controller │
└─────────────┬──────────────┘
│
│ ② product policy
▼
┌────────────────────────────┐
│ AccessPolicyControllerV1 │
│ │
│ canAccess(groupId, │
│ contextId, │
│ tier, │
│ controller) │
│ │
│ - group active │
│ - context allowed │
│ - tier sufficient │
│ - provenance match │
└─────────────┬──────────────┘
│
▼
ACCESS GRANTED / DENIED
