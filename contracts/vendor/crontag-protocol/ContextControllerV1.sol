// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title ContextControllerV1
 *
 * @notice
 * Declarative, issuance-only mint gate for AccessPassV1.
 *
 * This contract:
 * - Encodes minting constraints per (contextOwner, contextId)
 * - Is consulted ONLY at mint time
 * - Has NO post-mint authority
 * - Does NOT interpret context semantics
 *
 * All rules affect future minting only.
 *
 * Authority is explicitly scoped:
 * - Each contextId has exactly one contextOwner
 * - Only that contextOwner may configure rules for that contextId
 */
contract ContextControllerV1 {
  /* ---------------------------------------------------------------------
   * Errors
   * ------------------------------------------------------------------ */

  error NotAuthorized();
  error ContextAlreadyRegistered();
  error ContextNotRegistered();

  /* ---------------------------------------------------------------------
   * Context Ownership
   * ------------------------------------------------------------------ */

  // contextId => context owner
  mapping(bytes32 => address) public contextOwner;

  modifier onlyContextOwner(bytes32 contextId) {
    if (contextOwner[contextId] != msg.sender) revert NotAuthorized();
    _;
  }

  /* ---------------------------------------------------------------------
   * Context Rules
   * ------------------------------------------------------------------ */

  struct ContextRules {
    uint64 mintStart; // 0 = no start restriction
    uint64 mintEnd; // 0 = no end restriction
    uint64 maxSupply; // 0 = unlimited
    uint64 minted; // issuance counter (context-local)
    bool useAllowlist;
  }

  // contextId => rules
  mapping(bytes32 => ContextRules) internal _rules;

  // contextId => minter => allowed
  mapping(bytes32 => mapping(address => bool)) internal _allowlist;

  /* ---------------------------------------------------------------------
   * Context Registration
   * ------------------------------------------------------------------ */

  /**
   * @notice
   * Register a new contextId and claim ownership over it.
   *
   * A contextId may only be registered once.
   * Registration is explicit and irreversible.
   */
  function registerContext(bytes32 contextId) external {
    if (contextOwner[contextId] != address(0)) {
      revert ContextAlreadyRegistered();
    }

    contextOwner[contextId] = msg.sender;
  }

  /* ---------------------------------------------------------------------
   * Configuration (future minting only)
   * ------------------------------------------------------------------ */

  function setContextRules(
    bytes32 contextId,
    uint64 mintStart,
    uint64 mintEnd,
    uint64 maxSupply,
    bool useAllowlist
  ) external onlyContextOwner(contextId) {
    _rules[contextId].mintStart = mintStart;
    _rules[contextId].mintEnd = mintEnd;
    _rules[contextId].maxSupply = maxSupply;
    _rules[contextId].useAllowlist = useAllowlist;
    // NOTE: minted counter intentionally NOT reset
  }

  function setAllowlist(
    bytes32 contextId,
    address minter,
    bool allowed
  ) external onlyContextOwner(contextId) {
    _allowlist[contextId][minter] = allowed;
  }

  /* ---------------------------------------------------------------------
   * Mint Predicate (issuance-only, declarative)
   * ------------------------------------------------------------------ */

  function canMint(
    address minter,
    bytes32 contextId
  ) external view returns (bool) {
    // Unregistered contexts cannot mint
    if (contextOwner[contextId] == address(0)) {
      return false;
    }

    ContextRules memory rules = _rules[contextId];

    if (rules.mintStart != 0 && block.timestamp < rules.mintStart) {
      return false;
    }

    if (rules.mintEnd != 0 && block.timestamp > rules.mintEnd) {
      return false;
    }

    if (rules.maxSupply != 0 && rules.minted >= rules.maxSupply) {
      return false;
    }

    if (rules.useAllowlist && !_allowlist[contextId][minter]) {
      return false;
    }

    return true;
  }

  /* ---------------------------------------------------------------------
   * Issuance Accounting (explicit, opt-in)
   * ------------------------------------------------------------------ */

  /**
   * @notice
   * MUST be called by the contextOwner *after* a successful mint.
   *
   * This preserves non-retroactivity and avoids side effects in canMint.
   */
  function recordMint(bytes32 contextId) external onlyContextOwner(contextId) {
    _rules[contextId].minted += 1;
  }
}
