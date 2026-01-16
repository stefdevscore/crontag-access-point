// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title AccessPassV1
 *
 * @notice
 * AccessPassV1 represents an immutable, non-upgradeable access credential.
 * Each token encodes a fixed set of facts at mint time. Those facts MUST
 * remain true for the lifetime of the token.
 *
 * This contract is an issuance primitive, not an authority.
 * It does not infer legitimacy, meaning, or entitlement beyond the data
 * it records and exposes.
 *
 * -----------------------------------------------------------------------
 * CORE INVARIANTS
 * -----------------------------------------------------------------------
 *
 * 1. Immutability
 * 2. Non-Retroactivity
 * 3. Explicit Facts Only
 * 4. Controller Scope Limitation
 * 5. Transfer Semantics Are Explicit
 * 6. No Hidden Authority
 * 7. Misuse Is Undeniable
 *
 * (Full invariant text intentionally unchanged)
 */

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/* -------------------------------------------------------------------------
 * Controller Interface (issuance-only, declarative)
 * ---------------------------------------------------------------------- */

interface IContextController {
  /**
   * @notice
   * Declarative predicate consulted at mint time only.
   *
   * Controllers MUST NOT mutate state and MUST NOT assume
   * any authority beyond returning a boolean.
   *
   * Returning false MUST cause mint to revert.
   */
  function canMint(
    address minter,
    bytes32 contextId
  ) external view returns (bool);
}

contract AccessPassV1 is ERC721 {
  /* ---------------------------------------------------------------------
   * Errors (explicit > strings)
   * ------------------------------------------------------------------ */

  error NonTransferable();
  error ApprovalsDisabled();
  error ControllerRejected();

  /* ---------------------------------------------------------------------
   * Immutable Pass Facts (per token)
   * ------------------------------------------------------------------ */

  struct PassData {
    bytes32 contextId;
    uint64 expiresAt; // informational only; not enforced by AccessPassV1
    uint32 tier;
    bool transferable;
    address controller; // issuance provenance only; no post-mint authority
  }

  // tokenId => immutable pass facts
  mapping(uint256 => PassData) internal _passData;

  // monotonically increasing token id (starts at 1)
  uint256 internal _nextTokenId;

  /* ---------------------------------------------------------------------
   * Events
   * ------------------------------------------------------------------ */

  event AccessPassMinted(
    uint256 indexed tokenId,
    address indexed owner,
    bytes32 indexed contextId,
    address controller
  );

  /* ---------------------------------------------------------------------
   * Constructor
   * ------------------------------------------------------------------ */

  constructor(
    string memory name_,
    string memory symbol_
  ) ERC721(name_, symbol_) {}

  /* ---------------------------------------------------------------------
   * Transfer Guards
   * ------------------------------------------------------------------ */

  function _update(
    address to,
    uint256 tokenId,
    address auth
  ) internal override returns (address) {
    // If the token already exists (i.e. this is a transfer, not a mint),
    // enforce non-transferability.
    if (_ownerOf(tokenId) != address(0)) {
      if (!_passData[tokenId].transferable) {
        revert NonTransferable();
      }
    }

    return super._update(to, tokenId, auth);
  }

  /* ---------------------------------------------------------------------
   * Approval Guards
   * ------------------------------------------------------------------ */

  function approve(address, uint256) public pure override {
    revert ApprovalsDisabled();
  }

  function setApprovalForAll(address, bool) public pure override {
    revert ApprovalsDisabled();
  }

  /* ---------------------------------------------------------------------
   * Read-Only Accessors
   * ------------------------------------------------------------------ */

  function passData(uint256 tokenId) external view returns (PassData memory) {
    _requireOwned(tokenId);
    return _passData[tokenId];
  }

  /* ---------------------------------------------------------------------
   * Minting (ONLY authority-bearing functions)
   * ------------------------------------------------------------------ */

  /**
   * @notice
   * Direct mint — mints to msg.sender.
   *
   * This function exists for users who mint directly
   * without a router.
   */
  function mint(
    bytes32 contextId,
    uint64 expiresAt,
    uint32 tier,
    bool transferable,
    address controller
  ) external payable returns (uint256 tokenId) {
    tokenId = ++_nextTokenId;

    if (controller != address(0)) {
      bool allowed = IContextController(controller).canMint(
        msg.sender,
        contextId
      );
      if (!allowed) revert ControllerRejected();
    }

    _passData[tokenId] = PassData({
      contextId: contextId,
      expiresAt: expiresAt,
      tier: tier,
      transferable: transferable,
      controller: controller
    });

    _safeMint(msg.sender, tokenId);

    emit AccessPassMinted(tokenId, msg.sender, contextId, controller);
  }

  /**
   * @notice
   * NEW — Router-safe mint.
   *
   * Allows trusted orchestration layers (e.g. IssuanceRouterV1)
   * to mint directly to the end user without custody.
   *
   * This preserves:
   * - immutability
   * - controller purity
   * - non-retroactivity
   * - explicit recipients
   */
  function mintTo(
    address to,
    bytes32 contextId,
    uint64 expiresAt,
    uint32 tier,
    bool transferable,
    address controller
  ) external payable returns (uint256 tokenId) {
    tokenId = ++_nextTokenId;

    if (controller != address(0)) {
      bool allowed = IContextController(controller).canMint(to, contextId);
      if (!allowed) revert ControllerRejected();
    }

    _passData[tokenId] = PassData({
      contextId: contextId,
      expiresAt: expiresAt,
      tier: tier,
      transferable: transferable,
      controller: controller
    });

    _safeMint(to, tokenId);

    emit AccessPassMinted(tokenId, to, contextId, controller);
  }
}
