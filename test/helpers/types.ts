import type { BaseContract } from "ethers";

export interface AccessPass extends BaseContract {
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
