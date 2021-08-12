const BaseVesting = artifacts.require("BaseVesting");
const RewardToken = artifacts.require("RewardErc20");
const Reverter = require('./utils/reverter');
const { constants, expectRevert, send, time, expectEvent,ether, BN } = require('@openzeppelin/test-helpers');
const { expect } = require('chai');

contract('BaseVestingTest', ([owner, user1, user2, user3,user4]) => {
    let startDate;
    const reverter = new Reverter(web3);
    const TOTALSUPPLYERC20 = ether('100000');
    before('setup', async () => {
        let currentDate = await time.latest();
        startDate = currentDate.add(time.duration.minutes(10));
        rewardToken = await RewardToken.new(TOTALSUPPLYERC20);
        baseVesting = await BaseVesting.new(rewardToken.address,owner,startDate,{from:owner});
        await baseVesting.addInvestors(user1,ether('5000'),false);
        await baseVesting.addInvestors(user2,ether('10000'),true);
        await reverter.snapshot();
    });
    afterEach('revert', reverter.revert);
    describe('Tests', async()=>{
        it('Check owner balance', async()=>{
            expect(await rewardToken.balanceOf(owner)).to.be.bignumber.equal(TOTALSUPPLYERC20);
        });
        it('Adding investors', async()=>{
            expect(await rewardToken.balanceOf(baseVesting.address)).to.be.bignumber.equal(ether('15000'));
            await expectRevert(baseVesting.addInvestors(constants.ZERO_ADDRESS,ether('5000'),false),"Invalid investor address");
            await expectRevert(baseVesting.addInvestors(user1,ether('0'),false),"Can't mint 0 tokens");
            await baseVesting.addInvestors(user3,ether('5000'),false);
            await baseVesting.addInvestors(user4,ether('10000'),true);
            expect(await rewardToken.balanceOf(baseVesting.address)).to.be.bignumber.equal(ether('30000'));
        });
        describe('Time testing', async()=>{
            it('Before contract started',async()=>{
                await expectRevert(baseVesting.getRewardBalance(ether('100'),{from:user3}),"You don't have permision");
                expect(await baseVesting.getRewardBalance(ether('100'),{from:owner})).to.be.bignumber.equal(ether('0'));
                expect(await baseVesting.getRewardBalance(ether('100'),{from:user1})).to.be.bignumber.equal(ether('0'));
                expect(await baseVesting.getRewardBalance(ether('100'),{from:user2})).to.be.bignumber.equal(ether('0'));
            })
            it('StartDate <= now < FirstRelease',async()=>{
                await time.increaseTo(startDate);
                expect(await baseVesting.getRewardBalance(ether('100'),{from:owner})).to.be.bignumber.equal(ether('0'));
                expect(await baseVesting.getRewardBalance(ether('100'),{from:user1})).to.be.bignumber.equal(ether('500'));
                expect(await baseVesting.getRewardBalance(ether('100'),{from:user2})).to.be.bignumber.equal(ether('1500'));
            })
            it('FirstRelease <= now < VestingTimeEnd',async()=>{
                await time.increaseTo(startDate.add(time.duration.minutes(10)));
                expect(await baseVesting.getRewardBalance(ether('100'),{from:user1})).to.be.bignumber.equal(ether('500'));
                expect(await baseVesting.getRewardBalance(ether('100'),{from:user2})).to.be.bignumber.equal(ether('1500'));
                await time.increaseTo(startDate.add(time.duration.minutes(310)));
                expect(await baseVesting.getRewardBalance(ether('100'),{from:user1})).to.be.bignumber.equal(ether('2750'));//55%
                expect(await baseVesting.getRewardBalance(ether('100'),{from:user2})).to.be.bignumber.equal(ether('5750'));//57.5%
            })
            it('After VestingTimeEnd',async()=>{
                await time.increaseTo(startDate.add(time.duration.minutes(610)));
                expect(await baseVesting.getRewardBalance(ether('100'),{from:user1})).to.be.bignumber.equal(ether('5000'));
                expect(await baseVesting.getRewardBalance(ether('100'),{from:user2})).to.be.bignumber.equal(ether('10000'));
            })
        })
    });
})