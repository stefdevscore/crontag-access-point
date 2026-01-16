import type { BaseContract, Overrides } from "ethers";

export interface AccessPass extends BaseContract {
  // ERC-721 surface you actually use in tests
  ownerOf(tokenId: bigint): Promise<string>;

  mint(
    contextId: string,
    expiresAt: bigint,
    tier: number,
    transferable: boolean,
    controller: string,
  ): Promise<any>;
}

export interface AccessPoint extends BaseContract {
  canAccess(user: string, tokenId: bigint): Promise<boolean>;
}

export interface IssuanceRouter extends BaseContract {
  createContext(
    contextId: string,
    mintStart: bigint,
    mintEnd: bigint,
    maxSupply: bigint,
    useAllowlist: boolean,
  ): Promise<void>;

  mint(
    contextId: string,
    expiresAt: bigint,
    tier: number,
    transferable: boolean,
    overrides?: Overrides & { value?: bigint },
  ): Promise<any>;

  setAllowlist(
    contextId: string,
    minter: string,
    allowed: boolean,
  ): Promise<void>;

  issuerOf(contextId: string): Promise<string>;
}

export interface AccessPolicyController extends BaseContract {
  registerGroup(groupId: string): Promise<any>;
  groupExists(groupId: string): Promise<boolean>;

  setAccessRules(
    groupId: string,
    requiredTier: number,
    requiredController: string,
    active: boolean,
  ): Promise<any>;

  setContextAllowed(
    groupId: string,
    contextId: string,
    allowed: boolean,
  ): Promise<any>;

  canAccess(
    groupId: string,
    tokenContextId: string,
    tokenTier: number,
    tokenController: string,
  ): Promise<boolean>;
}
