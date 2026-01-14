// test/helpers/setup.ts
import hre from "hardhat";

export async function setupAccessPointFixture() {
  const { ethers } = await hre.network.connect();
  const [owner, user, other] = await ethers.getSigners();

  // Deploy AccessPass
  const AccessPass = await ethers.getContractFactory("AccessPassV1");
  const accessPass = await AccessPass.deploy("crontag Access Pass", "CRONTAG");
  await accessPass.waitForDeployment();

  // Deploy ContextControllerV1 (Model C — no args)
  const Controller = await ethers.getContractFactory("ContextControllerV1");
  const controller = await Controller.deploy();
  await controller.waitForDeployment();

  // Deploy Verifier
  const Verifier = await ethers.getContractFactory("AccessVerifierV1");
  const verifier = await Verifier.deploy(await accessPass.getAddress());
  await verifier.waitForDeployment();

  return {
    ethers,
    owner,
    user,
    other,
    accessPass,
    controller,
    verifier,
  };
}
