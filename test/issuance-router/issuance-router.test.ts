import { expect } from "chai";
import { setupAccessPointFixture } from "../helpers/setup.js";
import type { IssuanceRouter, AccessPass } from "../helpers/types.js";

describe("IssuanceRouterV1", function () {
  it("registers a new context and records issuer", async () => {
    const { ethers, owner, accessPass, controller } =
      await setupAccessPointFixture();

    const treasury = ethers.Wallet.createRandom().address;

    const RouterFactory = await ethers.getContractFactory("IssuanceRouterV1");
    const router = (await RouterFactory.deploy(
      await accessPass.getAddress(),
      await controller.getAddress(),
      treasury,
    )) as unknown as IssuanceRouter;

    await router.waitForDeployment();

    const issuerRouter = router.connect(owner) as unknown as IssuanceRouter;

    const contextId = ethers.keccak256(ethers.toUtf8Bytes("issuer-context"));

    await issuerRouter.createContext(contextId, 0n, 0n, 10n, false);

    expect(await issuerRouter.issuerOf(contextId)).to.equal(owner.address);
  });

  it("allows a user to mint through the router", async () => {
    const { ethers, owner, user, accessPass, controller } =
      await setupAccessPointFixture();

    const treasury = ethers.Wallet.createRandom().address;

    const RouterFactory = await ethers.getContractFactory("IssuanceRouterV1");
    const router = (await RouterFactory.deploy(
      await accessPass.getAddress(),
      await controller.getAddress(),
      treasury,
    )) as unknown as IssuanceRouter;

    await router.waitForDeployment();

    const issuerRouter = router.connect(owner) as unknown as IssuanceRouter;
    const userRouter = router.connect(user) as unknown as IssuanceRouter;
    const typedAccessPass = accessPass as unknown as AccessPass;

    const contextId = ethers.keccak256(ethers.toUtf8Bytes("mintable-context"));

    await issuerRouter.createContext(contextId, 0n, 0n, 1n, false);

    await userRouter.mint(
      contextId,
      BigInt(Math.floor(Date.now() / 1000) + 3600),
      1,
      false,
    );

    // deterministic first mint
    expect(await typedAccessPass.ownerOf(1n)).to.equal(user.address);
  });

  it("deducts a 2% fee and sends it to the treasury", async () => {
    const { ethers, owner, user, accessPass, controller } =
      await setupAccessPointFixture();

    const treasurySigner = ethers.Wallet.createRandom().connect(
      ethers.provider,
    );

    // fund treasury so balance checks are clean
    await owner.sendTransaction({
      to: treasurySigner.address,
      value: ethers.parseEther("1"),
    });

    const RouterFactory = await ethers.getContractFactory("IssuanceRouterV1");
    const router = (await RouterFactory.deploy(
      await accessPass.getAddress(),
      await controller.getAddress(),
      treasurySigner.address,
    )) as unknown as IssuanceRouter;

    await router.waitForDeployment();

    const issuerRouter = router.connect(owner) as unknown as IssuanceRouter;
    const userRouter = router.connect(user) as unknown as IssuanceRouter;

    const contextId = ethers.keccak256(ethers.toUtf8Bytes("fee-context"));

    await issuerRouter.createContext(contextId, 0n, 0n, 1n, false);

    const mintPrice = ethers.parseEther("1");
    const expectedFee = (mintPrice * 2n) / 100n; // 2%

    const treasuryBefore = await ethers.provider.getBalance(
      treasurySigner.address,
    );

    await userRouter.mint(contextId, 0n, 1, false, {
      value: mintPrice,
    });

    const treasuryAfter = await ethers.provider.getBalance(
      treasurySigner.address,
    );

    expect(treasuryAfter - treasuryBefore).to.equal(expectedFee);
  });

  it("enforces allowlist when enabled", async () => {
    const { ethers, owner, user, accessPass, controller } =
      await setupAccessPointFixture();

    const treasury = ethers.Wallet.createRandom().address;

    const RouterFactory = await ethers.getContractFactory("IssuanceRouterV1");
    const router = (await RouterFactory.deploy(
      await accessPass.getAddress(),
      await controller.getAddress(),
      treasury,
    )) as unknown as IssuanceRouter;

    await router.waitForDeployment();

    const issuerRouter = router.connect(owner) as unknown as IssuanceRouter;
    const userRouter = router.connect(user) as unknown as IssuanceRouter;

    const contextId = ethers.keccak256(
      ethers.toUtf8Bytes("allowlisted-context"),
    );

    await issuerRouter.createContext(contextId, 0n, 0n, 1n, true);

    await expect(userRouter.mint(contextId, 0n, 1, false)).to.be.rejected;

    await issuerRouter.setAllowlist(contextId, user.address, true);

    await expect(userRouter.mint(contextId, 0n, 1, false)).to.not.be.rejected;
  });

  it("prevents minting beyond max supply", async () => {
    const { ethers, owner, user, accessPass, controller } =
      await setupAccessPointFixture();

    const treasury = ethers.Wallet.createRandom().address;

    const RouterFactory = await ethers.getContractFactory("IssuanceRouterV1");
    const router = (await RouterFactory.deploy(
      await accessPass.getAddress(),
      await controller.getAddress(),
      treasury,
    )) as unknown as IssuanceRouter;

    await router.waitForDeployment();

    const issuerRouter = router.connect(owner) as unknown as IssuanceRouter;
    const userRouter = router.connect(user) as unknown as IssuanceRouter;

    const contextId = ethers.keccak256(
      ethers.toUtf8Bytes("supply-capped-context"),
    );

    await issuerRouter.createContext(contextId, 0n, 0n, 1n, false);

    await userRouter.mint(contextId, 0n, 1, false);

    await expect(userRouter.mint(contextId, 0n, 1, false)).to.be.rejected;
  });
});
