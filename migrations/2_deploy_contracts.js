const BaseVesting = artifacts.require("BaseVesting");
const RewardToken = artifacts.require("RewardErc20");
const {ether} = require("@openzeppelin/test-helpers");
module.exports = async function (deployer) {
    const signer = "0x8a00fC2D85E609dAEFb24fb53c92bF312FB08190"//my addres
    const startDate = "1629122400";//(Mon, 16 Aug 2021 13:00:00 GMT)
    const totalAllocatedAmount = ether("100000");
    await deployer.deploy(RewardToken,totalAllocatedAmount);
    const rewardTokenAddress = RewardToken.address;
    await deployer.deploy(
        BaseVesting,
        rewardTokenAddress,
        signer,
        startDate
    )
}
