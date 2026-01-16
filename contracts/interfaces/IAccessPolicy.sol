// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title IAccessPolicy
 *
 * @notice
 * Minimal interface for access policy evaluation.
 *
 * An access policy answers one question only:
 *
 *   “Should this account be allowed access here, right now?”
 *
 * It MUST:
 * - be read-only
 * - be deterministic
 * - have no side effects
 *
 * It MUST NOT:
 * - issue tokens
 * - mutate state
 * - emit events
 * - explain reasons
 * - discover or select tokens
 * - assert legitimacy or authority
 *
 * This interface represents a **pure policy leaf**.
 * Storage, routing, aggregation, and UX concerns live elsewhere.
 */
interface IAccessPolicy {
  /**
   * @notice
   * Evaluate whether `user` should be granted access
   * using the supplied access pass.
   *
   * @param user     Address attempting access
   * @param tokenId  AccessPassV1 tokenId being evaluated
   *
   * @return allowed True if access is granted, false otherwise
   */
  function canAccess(
    address user,
    uint256 tokenId
  ) external view returns (bool);
}
