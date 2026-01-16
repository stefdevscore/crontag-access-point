// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./interfaces/IAccessPolicy.sol";

/* -------------------------------------------------------------------------
 * Minimal read-only interface for AccessPassV1
 * ---------------------------------------------------------------------- */

interface IAccessPassV1 {
  struct PassData {
    bytes32 contextId;
    uint64 expiresAt;
    uint32 tier;
    bool transferable;
    address controller;
  }

  function passData(uint256 tokenId) external view returns (PassData memory);
}

/* -------------------------------------------------------------------------
 * Minimal interface for AccessVerifierV1
 * ---------------------------------------------------------------------- */

interface IAccessVerifierV1 {
  function verify(
    address user,
    uint256 tokenId,
    bytes32 requiredContext,
    uint32 requiredTier
  ) external view returns (bool);
}

/* -------------------------------------------------------------------------
 * Access Policy
 * ---------------------------------------------------------------------- */

/**
 * @title AccessPolicyV1
 *
 * @notice
 * Reference access policy built on top of the crontag protocol.
 *
 * This contract defines a **single, explicit access policy**.
 *
 * It is:
 * - stateless
 * - read-only
 * - deterministic
 *
 * This contract is a POLICY LAYER.
 * It is NOT part of the protocol.
 *
 * It enforces access using:
 * - immutable AccessPass facts
 * - a canonical AccessVerifier
 * - explicit, local policy configuration
 *
 * No authority is asserted beyond this policy.
 */
contract AccessPolicyV1 is IAccessPolicy {
  /* ---------------------------------------------------------------------
   * Immutable Configuration
   * ------------------------------------------------------------------ */

  address public immutable accessPass;
  address public immutable accessVerifier;

  bytes32 public immutable requiredContextId;
  uint32 public immutable requiredTier;

  // Optional issuance provenance requirement
  address public immutable requiredController;

  /* ---------------------------------------------------------------------
   * Constructor
   * ------------------------------------------------------------------ */

  constructor(
    address accessPass_,
    address accessVerifier_,
    bytes32 requiredContextId_,
    uint32 requiredTier_,
    address requiredController_
  ) {
    accessPass = accessPass_;
    accessVerifier = accessVerifier_;
    requiredContextId = requiredContextId_;
    requiredTier = requiredTier_;
    requiredController = requiredController_;
  }

  /* ---------------------------------------------------------------------
   * Access Evaluation
   * ------------------------------------------------------------------ */

  /**
   * @notice
   * Evaluate whether `user` should be granted access using `tokenId`.
   *
   * This function is:
   * - read-only
   * - deterministic
   * - side-effect free
   *
   * @dev
   * Returns true if and only if:
   * - the token passes canonical verification
   * - the context matches
   * - the tier requirement is satisfied
   * - the controller provenance (if required) matches
   */
  function canAccess(
    address user,
    uint256 tokenId
  ) external view returns (bool) {
    // 1. Canonical verification
    bool allowed = IAccessVerifierV1(accessVerifier).verify(
      user,
      tokenId,
      requiredContextId,
      requiredTier
    );

    if (!allowed) {
      return false;
    }

    // 2. Optional controller provenance enforcement
    if (requiredController != address(0)) {
      IAccessPassV1.PassData memory data = IAccessPassV1(accessPass).passData(
        tokenId
      );

      if (data.controller != requiredController) {
        return false;
      }
    }

    return true;
  }
}
