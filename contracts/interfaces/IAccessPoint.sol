// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title IAccessPoint
 *
 * @notice
 * Minimal interface for access enforcement.
 *
 * An access point answers one question only:
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
 */
interface IAccessPoint {
  /**
   * @notice
   * Determine whether `user` should be allowed access
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
