// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title IssuanceRouterV1
 *
 * @notice
 * Product-facing issuance coordinator for the crontag protocol.
 *
 * This contract:
 * - registers contexts
 * - configures minting rules
 * - mints AccessPassV1 tokens
 * - explicitly records issuance
 * - collects a flat protocol fee (2%)
 *
 * It is NOT part of the crontag protocol.
 * It introduces NO hidden authority.
 *
 * All behavior is explicit and auditable.
 */

/* -------------------------------------------------------------------------
 * Minimal Interfaces (read-only where possible)
 * ---------------------------------------------------------------------- */

interface IAccessPassV1 {
  /**
   * @notice
   * Mint an access pass directly to a recipient.
   *
   * @dev
   * This function is intentionally public to allow router-based
   * orchestration without requiring ERC721Receiver support.
   */
  function mintTo(
    address to,
    bytes32 contextId,
    uint64 expiresAt,
    uint32 tier,
    bool transferable,
    address controller
  ) external payable returns (uint256 tokenId);
}

interface IContextControllerV1 {
  function registerContext(bytes32 contextId) external;

  function setContextRules(
    bytes32 contextId,
    uint64 mintStart,
    uint64 mintEnd,
    uint64 maxSupply,
    bool useAllowlist
  ) external;

  function setAllowlist(
    bytes32 contextId,
    address minter,
    bool allowed
  ) external;

  function recordMint(bytes32 contextId) external;
}

/* -------------------------------------------------------------------------
 * Issuance Router
 * ---------------------------------------------------------------------- */

contract IssuanceRouterV1 {
  /* ---------------------------------------------------------------------
   * Constants (protocol economics)
   * ------------------------------------------------------------------ */

  uint256 public constant FEE_BPS = 200; // 2%
  uint256 public constant BPS_DENOMINATOR = 10_000;

  /* ---------------------------------------------------------------------
   * Immutable Wiring (product trust boundary)
   * ------------------------------------------------------------------ */

  address public immutable accessPass;
  address public immutable contextController;
  address public immutable treasury;

  /* ---------------------------------------------------------------------
   * Errors
   * ------------------------------------------------------------------ */

  error NotContextOwner();
  error ZeroAddress();
  error FeeTransferFailed();

  /* ---------------------------------------------------------------------
   * Context Ownership (product-level)
   * ------------------------------------------------------------------ */

  // contextId => issuer
  mapping(bytes32 => address) public issuerOf;

  modifier onlyIssuer(bytes32 contextId) {
    if (issuerOf[contextId] != msg.sender) revert NotContextOwner();
    _;
  }

  /* ---------------------------------------------------------------------
   * Constructor
   * ------------------------------------------------------------------ */

  constructor(
    address accessPass_,
    address contextController_,
    address treasury_
  ) {
    if (
      accessPass_ == address(0) ||
      contextController_ == address(0) ||
      treasury_ == address(0)
    ) revert ZeroAddress();

    accessPass = accessPass_;
    contextController = contextController_;
    treasury = treasury_;
  }

  /* ---------------------------------------------------------------------
   * Context Creation
   * ------------------------------------------------------------------ */

  /**
   * @notice
   * Create a new context and configure its minting rules.
   *
   * Flow:
   * 1. Register context in ContextControllerV1
   * 2. Record issuer ownership locally
   * 3. Configure mint rules
   */
  function createContext(
    bytes32 contextId,
    uint64 mintStart,
    uint64 mintEnd,
    uint64 maxSupply,
    bool useAllowlist
  ) external {
    // Register with controller (may revert if already registered)
    IContextControllerV1(contextController).registerContext(contextId);

    // Record issuer ownership (irreversible)
    issuerOf[contextId] = msg.sender;

    // Configure mint rules
    IContextControllerV1(contextController).setContextRules(
      contextId,
      mintStart,
      mintEnd,
      maxSupply,
      useAllowlist
    );
  }

  /* ---------------------------------------------------------------------
   * Optional Allowlist Management
   * ------------------------------------------------------------------ */

  function setAllowlist(
    bytes32 contextId,
    address minter,
    bool allowed
  ) external onlyIssuer(contextId) {
    IContextControllerV1(contextController).setAllowlist(
      contextId,
      minter,
      allowed
    );
  }

  /* ---------------------------------------------------------------------
   * Mint Orchestration
   * ------------------------------------------------------------------ */

  /**
   * @notice
   * Mint an access pass for a given context via the router.
   *
   * @dev
   * A flat 2% protocol fee is deducted and sent to the treasury.
   * The remaining value is forwarded implicitly as issuer revenue.
   *
   * Explicit flow:
   * 1. Collect protocol fee
   * 2. AccessPassV1.mintTo (controller consulted there)
   * 3. ContextControllerV1.recordMint
   */
  function mint(
    bytes32 contextId,
    uint64 expiresAt,
    uint32 tier,
    bool transferable
  ) external payable returns (uint256 tokenId) {
    uint256 fee = (msg.value * FEE_BPS) / BPS_DENOMINATOR;

    if (fee > 0) {
      (bool sent, ) = treasury.call{value: fee}("");
      if (!sent) revert FeeTransferFailed();
    }

    tokenId = IAccessPassV1(accessPass).mintTo{value: msg.value - fee}(
      msg.sender,
      contextId,
      expiresAt,
      tier,
      transferable,
      contextController
    );

    IContextControllerV1(contextController).recordMint(contextId);
  }
}
