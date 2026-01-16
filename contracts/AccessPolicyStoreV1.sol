// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./interfaces/IAccessPolicy.sol";

/**
 * @title AccessPolicyStoreV1
 *
 * @notice
 * On-chain registry for access policies used by a platform.
 *
 * This contract:
 * - stores references to AccessPolicy contracts
 * - groups them under arbitrary keys (e.g. eventId, membershipId)
 * - allows enable/disable without redeploying policies
 *
 * It does NOT:
 * - evaluate access
 * - issue tokens
 * - interpret contexts or tiers
 * - enforce ownership semantics beyond this registry
 *
 * This is a STORAGE + REFERENCE layer only.
 */
contract AccessPolicyStoreV1 {
  /* ---------------------------------------------------------------------
   * Errors
   * ------------------------------------------------------------------ */

  error NotOwner();
  error ZeroAddress();
  error PolicyAlreadyRegistered();
  error PolicyNotRegistered();

  /* ---------------------------------------------------------------------
   * Ownership (platform-level)
   * ------------------------------------------------------------------ */

  address public immutable owner;

  modifier onlyOwner() {
    if (msg.sender != owner) revert NotOwner();
    _;
  }

  /* ---------------------------------------------------------------------
   * Policy Storage
   * ------------------------------------------------------------------ */

  /**
   * @dev
   * A policy reference with an active flag.
   */
  struct PolicyRef {
    address policy;
    bool active;
  }

  /**
   * @dev
   * groupId => list of policy references
   *
   * groupId is an opaque identifier chosen by the platform:
   * - eventId
   * - subscriptionId
   * - membershipId
   * - venueId
   * - featureId
   */
  mapping(bytes32 => PolicyRef[]) internal _policiesByGroup;

  /**
   * @dev
   * groupId => policy => index + 1
   *
   * Used to prevent duplicates and enable toggling.
   */
  mapping(bytes32 => mapping(address => uint256)) internal _policyIndex;

  /* ---------------------------------------------------------------------
   * Events (explicit, auditable)
   * ------------------------------------------------------------------ */

  event PolicyAdded(bytes32 indexed groupId, address indexed policy);
  event PolicyStatusUpdated(
    bytes32 indexed groupId,
    address indexed policy,
    bool active
  );

  /* ---------------------------------------------------------------------
   * Constructor
   * ------------------------------------------------------------------ */

  constructor(address owner_) {
    if (owner_ == address(0)) revert ZeroAddress();
    owner = owner_;
  }

  /* ---------------------------------------------------------------------
   * Policy Registration
   * ------------------------------------------------------------------ */

  /**
   * @notice
   * Register a policy under a group.
   *
   * Policies are immutable contracts.
   * Registration is explicit and duplicate-safe.
   */
  function addPolicy(bytes32 groupId, address policy) external onlyOwner {
    if (policy == address(0)) revert ZeroAddress();
    if (_policyIndex[groupId][policy] != 0) {
      revert PolicyAlreadyRegistered();
    }

    _policiesByGroup[groupId].push(PolicyRef({policy: policy, active: true}));

    _policyIndex[groupId][policy] = _policiesByGroup[groupId].length;

    emit PolicyAdded(groupId, policy);
  }

  /* ---------------------------------------------------------------------
   * Policy Activation
   * ------------------------------------------------------------------ */

  /**
   * @notice
   * Enable or disable a registered policy.
   *
   * This allows:
   * - emergency shutdown
   * - phased rollouts
   * - temporary deactivation
   *
   * Without redeploying anything.
   */
  function setPolicyActive(
    bytes32 groupId,
    address policy,
    bool active
  ) external onlyOwner {
    uint256 idx = _policyIndex[groupId][policy];
    if (idx == 0) revert PolicyNotRegistered();

    _policiesByGroup[groupId][idx - 1].active = active;

    emit PolicyStatusUpdated(groupId, policy, active);
  }

  /* ---------------------------------------------------------------------
   * Read-Only Accessors
   * ------------------------------------------------------------------ */

  /**
   * @notice
   * Return all policy references for a group.
   *
   * This is intended to be consumed by AccessRouterV1.
   */
  function policiesForGroup(
    bytes32 groupId
  ) external view returns (PolicyRef[] memory) {
    return _policiesByGroup[groupId];
  }
}
