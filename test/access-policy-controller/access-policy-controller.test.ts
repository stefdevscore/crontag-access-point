import { expect } from "chai";
import { setupAccessPointFixture } from "../helpers/setup.js";
import type { AccessPolicyController } from "../helpers/types.js";

describe("AccessPolicyControllerV1", function () {
  async function deployFixture() {
    const { ethers, owner } = await setupAccessPointFixture();

    const Factory = (await ethers.getContractFactory(
      "AccessPolicyControllerV1",
    )) as any;

    const controller = (await Factory.deploy(
      owner.address,
    )) as unknown as AccessPolicyController;

    await controller.waitForDeployment();

    return { controller, ethers, owner };
  }

  it("registers a new group", async () => {
    const { controller, ethers } = await deployFixture();

    const groupId = ethers.keccak256(ethers.toUtf8Bytes("event:main-hall"));

    await controller.registerGroup(groupId);

    expect(await controller.groupExists(groupId)).to.equal(true);
  });

  it("prevents duplicate group registration", async () => {
    const { controller, ethers } = await deployFixture();

    const groupId = ethers.keccak256(ethers.toUtf8Bytes("event:vip"));

    await controller.registerGroup(groupId);

    await expect(controller.registerGroup(groupId)).to.be.rejected;
  });

  it("denies access when group is inactive", async () => {
    const { controller, ethers } = await deployFixture();

    const groupId = ethers.keccak256(ethers.toUtf8Bytes("membership"));
    const contextId = ethers.keccak256(ethers.toUtf8Bytes("gold-tier"));

    await controller.registerGroup(groupId);

    await controller.setAccessRules(groupId, 1, ethers.ZeroAddress, false);

    await controller.setContextAllowed(groupId, contextId, true);

    expect(
      await controller.canAccess(groupId, contextId, 1, ethers.ZeroAddress),
    ).to.equal(false);
  });

  it("allows access when context, tier, and rules match", async () => {
    const { controller, ethers } = await deployFixture();

    const groupId = ethers.keccak256(ethers.toUtf8Bytes("event:hall-a"));
    const contextId = ethers.keccak256(ethers.toUtf8Bytes("tier:general"));

    await controller.registerGroup(groupId);

    await controller.setAccessRules(groupId, 1, ethers.ZeroAddress, true);

    await controller.setContextAllowed(groupId, contextId, true);

    expect(
      await controller.canAccess(groupId, contextId, 1, ethers.ZeroAddress),
    ).to.equal(true);
  });

  it("returns false for unknown groups", async () => {
    const { controller, ethers } = await deployFixture();

    expect(
      await controller.canAccess(
        ethers.keccak256(ethers.toUtf8Bytes("unknown")),
        ethers.keccak256(ethers.toUtf8Bytes("context")),
        1,
        ethers.ZeroAddress,
      ),
    ).to.equal(false);
  });
});
