import { expect } from "chai";
import { setupAccessPointFixture } from "../helpers/setup.js";
import type { BaseContract } from "ethers";

/* -------------------------------------------------------------
 * Minimal local interface for typing
 * ---------------------------------------------------------- */
interface AccessRouter extends BaseContract {
  canAccess(groupId: string, user: string, tokenId: bigint): Promise<boolean>;
}

describe("AccessRouterV1", function () {
  async function deployFixture() {
    const {
      ethers,
      owner,
      user,
      other,
      accessPass,
      controller, // ContextControllerV1
      verifier, // AccessVerifierV1
    } = await setupAccessPointFixture();

    // Deploy AccessPolicyControllerV1 (product-layer)
    const PolicyFactory = await ethers.getContractFactory(
      "AccessPolicyControllerV1",
    );
    const policyController = await PolicyFactory.deploy(owner.address);
    await policyController.waitForDeployment();

    // Deploy AccessRouterV1
    const RouterFactory = await ethers.getContractFactory("AccessRouterV1");

    const router = (await RouterFactory.deploy(
      await verifier.getAddress(),
      await accessPass.getAddress(),
      await policyController.getAddress(),
    )) as unknown as AccessRouter;

    await router.waitForDeployment();

    return {
      ethers,
      owner,
      user,
      other,
      accessPass,
      controller,
      verifier,
      policyController,
      router,
    };
  }

  it("allows access when canonical verification and policy both succeed", async () => {
    const { ethers, user, accessPass, policyController, router } =
      await deployFixture();

    const groupId = ethers.keccak256(ethers.toUtf8Bytes("event:main-hall"));
    const contextId = ethers.keccak256(ethers.toUtf8Bytes("tier:general"));

    await policyController.registerGroup(groupId);
    await policyController.setAccessRules(groupId, 1, ethers.ZeroAddress, true);
    await policyController.setContextAllowed(groupId, contextId, true);

    await accessPass
      .connect(user)
      .mint(contextId, 0n, 1, true, ethers.ZeroAddress);

    expect(await router.canAccess(groupId, user.address, 1n)).to.equal(true);
  });

  it("denies access if canonical verification fails (wrong owner)", async () => {
    const { ethers, owner, user, accessPass, policyController, router } =
      await deployFixture();

    const groupId = ethers.keccak256(ethers.toUtf8Bytes("event:secure"));
    const contextId = ethers.keccak256(ethers.toUtf8Bytes("tier:vip"));

    await policyController.registerGroup(groupId);
    await policyController.setAccessRules(groupId, 1, ethers.ZeroAddress, true);
    await policyController.setContextAllowed(groupId, contextId, true);

    await accessPass
      .connect(user)
      .mint(contextId, 0n, 1, true, ethers.ZeroAddress);

    expect(await router.canAccess(groupId, owner.address, 1n)).to.equal(false);
  });

  it("denies access if policy rejects even when token is canonically valid", async () => {
    const { ethers, user, accessPass, policyController, router } =
      await deployFixture();

    const groupId = ethers.keccak256(ethers.toUtf8Bytes("event:vip"));
    const contextId = ethers.keccak256(ethers.toUtf8Bytes("tier:general"));

    await policyController.registerGroup(groupId);
    await policyController.setAccessRules(
      groupId,
      2, // requires higher tier
      ethers.ZeroAddress,
      true,
    );
    await policyController.setContextAllowed(groupId, contextId, true);

    await accessPass
      .connect(user)
      .mint(contextId, 0n, 1, true, ethers.ZeroAddress);

    expect(await router.canAccess(groupId, user.address, 1n)).to.equal(false);
  });

  it("denies access for expired tokens even if policy allows", async () => {
    const { ethers, user, accessPass, policyController, router } =
      await deployFixture();

    const groupId = ethers.keccak256(ethers.toUtf8Bytes("event:time-boxed"));
    const contextId = ethers.keccak256(ethers.toUtf8Bytes("tier:limited"));

    await policyController.registerGroup(groupId);
    await policyController.setAccessRules(groupId, 1, ethers.ZeroAddress, true);
    await policyController.setContextAllowed(groupId, contextId, true);

    const expiredAt = BigInt(Math.floor(Date.now() / 1000)) - 10n;

    await accessPass
      .connect(user)
      .mint(contextId, expiredAt, 1, true, ethers.ZeroAddress);

    expect(await router.canAccess(groupId, user.address, 1n)).to.equal(false);
  });

  it("returns false for unknown groups", async () => {
    const { ethers, user, accessPass, router } = await deployFixture();

    const unknownGroup = ethers.keccak256(ethers.toUtf8Bytes("unknown"));
    const contextId = ethers.keccak256(ethers.toUtf8Bytes("tier:any"));

    await accessPass
      .connect(user)
      .mint(contextId, 0n, 1, true, ethers.ZeroAddress);

    expect(await router.canAccess(unknownGroup, user.address, 1n)).to.equal(
      false,
    );
  });
});
