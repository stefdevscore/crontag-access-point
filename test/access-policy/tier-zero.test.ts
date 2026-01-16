import { expect } from "chai";
import { setupAccessPointFixture } from "../helpers/setup.js";
import type { AccessPass, AccessPoint } from "../helpers/types.js";

describe("AccessPointV1 — Tier Zero", () => {
  it("allows access when requiredTier is zero and pass tier is zero", async () => {
    const { ethers, owner, user, accessPass, controller, verifier } =
      await setupAccessPointFixture();

    const typedAccessPass = accessPass as unknown as AccessPass;
    const userAccessPass = typedAccessPass.connect(
      user,
    ) as unknown as AccessPass;

    const contextId = ethers.keccak256(ethers.toUtf8Bytes("event-tier-zero"));

    // ✅ Model C: issuer must register the context
    await controller.connect(owner).registerContext(contextId);

    const AccessPointFactory = await ethers.getContractFactory(
      "AccessPolicyV1",
    );

    // requiredTier = 0 → no tier requirement
    const accessPoint = (await AccessPointFactory.deploy(
      await accessPass.getAddress(),
      await verifier.getAddress(),
      contextId,
      0, // requiredTier
      await controller.getAddress(),
    )) as unknown as AccessPoint;

    const expiresAt = BigInt(Math.floor(Date.now() / 1000)) + 3600n;

    // Mint tier-0 pass
    const tx = await userAccessPass.mint(
      contextId,
      expiresAt,
      0,
      false,
      await controller.getAddress(),
    );

    const receipt = await tx.wait();
    const tokenId = receipt!.logs[0].args.tokenId as bigint;

    const allowed = await accessPoint.canAccess(user.address, tokenId);

    expect(allowed).to.equal(true);
  });
});
