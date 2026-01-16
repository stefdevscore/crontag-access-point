// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {AccessVerifierV1} from "./vendor/crontag-protocol/AccessVerifierV1.sol";
import {AccessPassV1} from "./vendor/crontag-protocol/AccessPassV1.sol";
import {AccessPolicyControllerV1} from "./AccessPolicyControllerV1.sol";

/**
 * @title AccessRouterV1
 *
 * @notice
 * Canonical access orchestration contract for the crontag platform.
 *
 * Protocol truth is evaluated FIRST.
 * Product policy is evaluated SECOND.
 *
 * This contract:
 * - is read-only
 * - stores no state
 * - performs no inference
 * - performs no issuance
 */
contract AccessRouterV1 {
  /* ---------------------------------------------------------------------
   * Immutable Dependencies
   * ------------------------------------------------------------------ */

  AccessVerifierV1 public immutable verifier;
  AccessPassV1 public immutable accessPass;
  AccessPolicyControllerV1 public immutable policyController;

  constructor(
    address verifier_,
    address accessPass_,
    address policyController_
  ) {
    verifier = AccessVerifierV1(verifier_);
    accessPass = AccessPassV1(accessPass_);
    policyController = AccessPolicyControllerV1(policyController_);
  }

  /* ---------------------------------------------------------------------
   * Access Predicate
   * ------------------------------------------------------------------ */

  /**
   * @notice
   * Determine whether `user` MAY access `groupId` using `tokenId`.
   *
   * Returns true IF AND ONLY IF:
   * - canonical verification succeeds
   * - policy evaluation succeeds
   */
  function canAccess(
    bytes32 groupId,
    address user,
    uint256 tokenId
  ) external view returns (bool) {
    /* -------------------------------------------------------------
     * Step 1 — Canonical Verification (Protocol Truth)
     * ---------------------------------------------------------- */

    bool valid = verifier.verify(
      user,
      tokenId,
      bytes32(0), // no required context
      0 // no required tier
    );

    if (!valid) {
      return false;
    }

    /* -------------------------------------------------------------
     * Step 2 — Read Immutable Pass Facts
     * ---------------------------------------------------------- */

    AccessPassV1.PassData memory pass = accessPass.passData(tokenId);

    /* -------------------------------------------------------------
     * Step 3 — Policy Evaluation (Product Truth)
     * ---------------------------------------------------------- */

    return
      policyController.canAccess(
        groupId,
        pass.contextId,
        pass.tier,
        pass.controller
      );
  }
}
