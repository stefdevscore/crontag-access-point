// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title AccessVerifierV1
 *
 * @notice
 * Canonical, stateless verifier for AccessPassV1.
 *
 * This contract evaluates access strictly from immutable facts
 * recorded in a single AccessPassV1 instance.
 *
 * It does NOT:
 * - infer legitimacy
 * - consult controllers
 * - mutate state
 * - grant or revoke access
 *
 * It answers one question only:
 *
 *   “Does this pass satisfy these explicit requirements?”
 */
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IAccessPassV1 is IERC721 {
  struct PassData {
    bytes32 contextId;
    uint64 expiresAt;
    uint32 tier;
    bool transferable;
    address controller;
  }

  function passData(uint256 tokenId) external view returns (PassData memory);
}

contract AccessVerifierV1 {
  /* ---------------------------------------------------------------------
   * Immutable Reference
   * ------------------------------------------------------------------ */

  address public immutable accessPass;

  constructor(address accessPass_) {
    accessPass = accessPass_;
  }

  /* ---------------------------------------------------------------------
   * Verification
   * ------------------------------------------------------------------ */

  /**
   * @notice
   * Determine whether access SHOULD be allowed.
   *
   * @param user            Address attempting access
   * @param tokenId         AccessPassV1 tokenId
   * @param requiredContext Required contextId (exact match, 0 = any)
   * @param requiredTier    Minimum tier required (0 = any)
   */
  function verify(
    address user,
    uint256 tokenId,
    bytes32 requiredContext,
    uint32 requiredTier
  ) external view returns (bool) {
    // 1. Token must exist
    if (!_exists(tokenId)) {
      return false;
    }

    // 2. Ownership check
    if (IERC721(accessPass).ownerOf(tokenId) != user) {
      return false;
    }

    IAccessPassV1.PassData memory data = IAccessPassV1(accessPass).passData(
      tokenId
    );

    // 3. Context match (0 = wildcard)
    if (requiredContext != bytes32(0) && data.contextId != requiredContext) {
      return false;
    }

    // 4. Expiration check (0 = no expiry)
    if (data.expiresAt != 0 && block.timestamp > data.expiresAt) {
      return false;
    }

    // 5. Tier requirement (0 = any tier)
    if (requiredTier != 0 && data.tier < requiredTier) {
      return false;
    }

    return true;
  }

  /* ---------------------------------------------------------------------
   * Internal
   * ------------------------------------------------------------------ */

  function _exists(uint256 tokenId) internal view returns (bool) {
    try IERC721(accessPass).ownerOf(tokenId) returns (address) {
      return true;
    } catch {
      return false;
    }
  }
}
