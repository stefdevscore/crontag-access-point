import { expect } from "chai";
import { setupAccessPointFixture } from "../helpers/setup.js";
import type { AccessPass, AccessPoint } from "../helpers/types.js";

describe("AccessPointV1 — Context Mismatch", () => {
  it("denies access when the pass contextId does not match", async () => {
    const { ethers, owner, user, accessPass, controller, verifier } =
      await setupAccessPointFixture();

    const typedAccessPass = accessPass as unknown as AccessPass;
    const userAccessPass = typedAccessPass.connect(
      user,
    ) as unknown as AccessPass;

    const correctContextId = ethers.keccak256(
      ethers.toUtf8Bytes("event-correct-context"),
    );

    const wrongContextId = ethers.keccak256(
      ethers.toUtf8Bytes("event-wrong-context"),
    );

    // ✅ Model C: issuer registers BOTH contexts
    await controller.connect(owner).registerContext(correctContextId);
    await controller.connect(owner).registerContext(wrongContextId);

    const AccessPointFactory = await ethers.getContractFactory("AccessPointV1");

    const accessPoint = (await AccessPointFactory.deploy(
      await accessPass.getAddress(),
      await verifier.getAddress(),
      correctContextId,
      1, // requiredTier
      await controller.getAddress(),
    )) as unknown as AccessPoint;

    const expiresAt = BigInt(Math.floor(Date.now() / 1000)) + 3600n;

    // Mint a pass for the WRONG (but valid) context
    const tx = await userAccessPass.mint(
      wrongContextId,
      expiresAt,
      2,
      false,
      await controller.getAddress(),
    );

    const receipt = await tx.wait();
    const tokenId = receipt!.logs[0].args.tokenId as bigint;

    const allowed = await accessPoint.canAccess(user.address, tokenId);

    expect(allowed).to.equal(false);
  });
});
