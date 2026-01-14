import { expect } from "chai";
import { setupAccessPointFixture } from "../helpers/setup.js";
import type { AccessPass, AccessPoint } from "../helpers/types.js";

describe("AccessPointV1 — Controller Provenance", () => {
  it("denies access when the pass was minted via a different controller", async () => {
    const { ethers, owner, user, accessPass, controller, verifier } =
      await setupAccessPointFixture();

    const typedAccessPass = accessPass as unknown as AccessPass;
    const userAccessPass = typedAccessPass.connect(
      user,
    ) as unknown as AccessPass;

    // Deploy a SECOND controller (different provenance)
    const ControllerFactory = await ethers.getContractFactory(
      "ContextControllerV1",
    );

    const otherController = await ControllerFactory.deploy();
    await otherController.waitForDeployment();

    const contextId = ethers.keccak256(
      ethers.toUtf8Bytes("event-controller-mismatch"),
    );

    // ✅ Model C: issuer registers the SAME context on BOTH controllers
    await controller.connect(owner).registerContext(contextId);
    await otherController.connect(owner).registerContext(contextId);

    const AccessPointFactory = await ethers.getContractFactory("AccessPointV1");

    // AccessPoint trusts ONLY `controller`
    const accessPoint = (await AccessPointFactory.deploy(
      await accessPass.getAddress(),
      await verifier.getAddress(),
      contextId,
      1, // requiredTier
      await controller.getAddress(), // trusted controller
    )) as unknown as AccessPoint;

    const expiresAt = BigInt(Math.floor(Date.now() / 1000)) + 3600n;

    // Mint via DIFFERENT controller (valid, but wrong provenance)
    const tx = await userAccessPass.mint(
      contextId,
      expiresAt,
      2,
      false,
      await otherController.getAddress(),
    );

    const receipt = await tx.wait();
    const tokenId = receipt!.logs[0].args.tokenId as bigint;

    const allowed = await accessPoint.canAccess(user.address, tokenId);

    expect(allowed).to.equal(false);
  });
});
