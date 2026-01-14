import { expect } from "chai";
import { setupAccessPointFixture } from "../helpers/setup.js";
import type { AccessPass, AccessPoint } from "../helpers/types.js";

describe("AccessPointV1 — Allow Path", () => {
  it("allows access when all explicit requirements are satisfied", async () => {
    const { ethers, owner, user, accessPass, controller, verifier } =
      await setupAccessPointFixture();

    const typedAccessPass = accessPass as unknown as AccessPass;
    const userAccessPass = typedAccessPass.connect(
      user,
    ) as unknown as AccessPass;

    const contextId = ethers.keccak256(ethers.toUtf8Bytes("event-allow-path"));

    // ✅ Model C: issuer must explicitly register the context
    await controller.connect(owner).registerContext(contextId);

    const AccessPointFactory = await ethers.getContractFactory("AccessPointV1");

    const accessPoint = (await AccessPointFactory.deploy(
      await accessPass.getAddress(),
      await verifier.getAddress(),
      contextId,
      1, // requiredTier
      await controller.getAddress(), // provenance required
    )) as unknown as AccessPoint;

    const expiresAt = BigInt(Math.floor(Date.now() / 1000)) + 3600n;

    // User mints a valid pass
    const tx = await userAccessPass.mint(
      contextId,
      expiresAt,
      2, // tier >= requiredTier
      false,
      await controller.getAddress(),
    );

    const receipt = await tx.wait();
    const tokenId = receipt!.logs[0].args.tokenId as bigint;

    const allowed = await accessPoint.canAccess(user.address, tokenId);

    expect(allowed).to.equal(true);
  });
});
