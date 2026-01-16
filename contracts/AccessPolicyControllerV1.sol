// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title AccessPolicyControllerV1
 *
 * @notice
 * Declarative access policy registry for the crontag platform.
 *
 * This contract:
 * - stores access rules per groupId
 * - maps issued contexts to access groups
 * - is consulted ONLY at access time
 * - has NO authority over issuance
 * - performs NO state mutation during access checks
 *
 * It is NOT part of the crontag protocol.
 * It is a product-layer coordination primitive.
 */
contract AccessPolicyControllerV1 {
  /* ---------------------------------------------------------------------
   * Errors
   * ------------------------------------------------------------------ */

  error NotAuthorized();
  error GroupAlreadyRegistered();
  error GroupNotRegistered();
  error ZeroAddress();

  /* ---------------------------------------------------------------------
   * Ownership (platform-level)
   * ------------------------------------------------------------------ */

  address public immutable owner;

  constructor(address owner_) {
    if (owner_ == address(0)) revert ZeroAddress();
    owner = owner_;
  }

  modifier onlyOwner() {
    if (msg.sender != owner) revert NotAuthorized();
    _;
  }

  /* ---------------------------------------------------------------------
   * Group Registration
   * ------------------------------------------------------------------ */

  // groupId => registered
  mapping(bytes32 => bool) public groupExists;

  /**
   * @notice
   * Register a new access group.
   *
   * groupId is an opaque platform-defined identifier:
   * - event space
   * - membership scope
   * - venue
   * - feature gate
   */
  function registerGroup(bytes32 groupId) external onlyOwner {
    if (groupExists[groupId]) revert GroupAlreadyRegistered();
    groupExists[groupId] = true;
  }

  /* ---------------------------------------------------------------------
   * Access Rules
   * ------------------------------------------------------------------ */

  struct AccessRules {
    uint32 requiredTier; // 0 = any tier
    address requiredController; // 0 = any provenance
    bool active;
  }

  // groupId => rules
  mapping(bytes32 => AccessRules) internal _rules;

  // groupId => contextId => allowed
  mapping(bytes32 => mapping(bytes32 => bool)) internal _allowedContexts;

  /* ---------------------------------------------------------------------
   * Configuration (explicit, platform-controlled)
   * ------------------------------------------------------------------ */

  function setAccessRules(
    bytes32 groupId,
    uint32 requiredTier,
    address requiredController,
    bool active
  ) external onlyOwner {
    if (!groupExists[groupId]) revert GroupNotRegistered();

    _rules[groupId] = AccessRules({
      requiredTier: requiredTier,
      requiredController: requiredController,
      active: active
    });
  }

  function setContextAllowed(
    bytes32 groupId,
    bytes32 contextId,
    bool allowed
  ) external onlyOwner {
    if (!groupExists[groupId]) revert GroupNotRegistered();
    _allowedContexts[groupId][contextId] = allowed;
  }

  /* ---------------------------------------------------------------------
   * Read-Only Access Predicate
   * ------------------------------------------------------------------ */

  /**
   * @notice
   * Determine whether a token MAY be considered for access
   * under this group’s policy.
   *
   * This function:
   * - is read-only
   * - does NOT verify ownership
   * - does NOT check expiration
   * - does NOT assert legitimacy
   *
   * Those remain protocol concerns.
   */
  function canAccess(
    bytes32 groupId,
    bytes32 tokenContextId,
    uint32 tokenTier,
    address tokenController
  ) external view returns (bool) {
    if (!groupExists[groupId]) return false;

    AccessRules memory rules = _rules[groupId];
    if (!rules.active) return false;

    if (!_allowedContexts[groupId][tokenContextId]) {
      return false;
    }

    if (rules.requiredTier != 0 && tokenTier < rules.requiredTier) {
      return false;
    }

    if (
      rules.requiredController != address(0) &&
      tokenController != rules.requiredController
    ) {
      return false;
    }

    return true;
  }
}
