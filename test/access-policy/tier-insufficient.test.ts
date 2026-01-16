import { expect } from "chai";
import { setupAccessPointFixture } from "../helpers/setup.js";
import type { AccessPass, AccessPoint } from "../helpers/types.js";

describe("AccessPointV1 — Tier Insufficient", () => {
  it("denies access when the pass tier is below the required tier", async () => {
    const { ethers, owner, user, accessPass, controller, verifier } =
      await setupAccessPointFixture();

    const typedAccessPass = accessPass as unknown as AccessPass;
    const userAccessPass = typedAccessPass.connect(
      user,
    ) as unknown as AccessPass;

    const contextId = ethers.keccak256(ethers.toUtf8Bytes("event-tier-test"));

    // ✅ Model C: context must be registered by issuer
    await controller.connect(owner).registerContext(contextId);

    const AccessPointFactory = await ethers.getContractFactory(
      "AccessPolicyV1",
    );

    // Require tier 2
    const accessPoint = (await AccessPointFactory.deploy(
      await accessPass.getAddress(),
      await verifier.getAddress(),
      contextId,
      2, // requiredTier
      await controller.getAddress(),
    )) as unknown as AccessPoint;

    const expiresAt = BigInt(Math.floor(Date.now() / 1000)) + 3600n;

    // Mint a tier-1 pass (insufficient)
    const tx = await userAccessPass.mint(
      contextId,
      expiresAt,
      1, // tier < requiredTier
      false,
      await controller.getAddress(),
    );

    const receipt = await tx.wait();
    const tokenId = receipt!.logs[0].args.tokenId as bigint;

    const allowed = await accessPoint.canAccess(user.address, tokenId);

    expect(allowed).to.equal(false);
  });
});
