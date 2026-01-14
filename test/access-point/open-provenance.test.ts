import { expect } from "chai";
import { setupAccessPointFixture } from "../helpers/setup.js";
import type { AccessPass, AccessPoint } from "../helpers/types.js";

describe("AccessPointV1 — Open Provenance", () => {
  it("allows access when no controller provenance is required", async () => {
    const { ethers, owner, user, accessPass, controller, verifier } =
      await setupAccessPointFixture();

    const typedAccessPass = accessPass as unknown as AccessPass;
    const userAccessPass = typedAccessPass.connect(
      user,
    ) as unknown as AccessPass;

    const contextId = ethers.keccak256(
      ethers.toUtf8Bytes("event-open-provenance"),
    );

    // ✅ Model C: issuer must register the context
    await controller.connect(owner).registerContext(contextId);

    const AccessPointFactory = await ethers.getContractFactory("AccessPointV1");

    // requiredController = address(0) → provenance NOT enforced
    const accessPoint = (await AccessPointFactory.deploy(
      await accessPass.getAddress(),
      await verifier.getAddress(),
      contextId,
      1, // requiredTier
      ethers.ZeroAddress,
    )) as unknown as AccessPoint;

    const expiresAt = BigInt(Math.floor(Date.now() / 1000)) + 3600n;

    // Mint via ANY controller (still must pass canMint)
    const tx = await userAccessPass.mint(
      contextId,
      expiresAt,
      1,
      false,
      await controller.getAddress(),
    );

    const receipt = await tx.wait();
    const tokenId = receipt!.logs[0].args.tokenId as bigint;

    const allowed = await accessPoint.canAccess(user.address, tokenId);

    expect(allowed).to.equal(true);
  });
});
