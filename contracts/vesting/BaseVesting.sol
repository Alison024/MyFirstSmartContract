// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2;


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../tokens/RewardErc20.sol";
contract BaseVesting is Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    enum AllocationType{SEED, PRIVATE}
    struct Investor {
        uint256 paidAmount;
        uint256 timeRewardPaid;
        uint256 mintedToken;
        AllocationType allocation;
    }

    uint256 public constant PERIOD = 6 minutes;
    uint256 public constant CLIF_PERIOD = 10 minutes;
    uint256 public constant VESTING_DURATION = 10 hours;
    uint256 public constant TOTAL_PERCENTAGE = 1e20;//100%
    uint256 public constant PERCENTAGE_PER_PERIOD = 1e18;
    uint256 public constant TGE_PERCENTAGE_PRIVATE = 1e19;
    uint256 public constant TGE_PERCENTAGE_PUBLIC = 15e18;

    mapping(address => bool) public trustedSigner;
    mapping(address => Investor) public investorInfo;
    mapping(address => Counters.Counter) public nonces;
    
    RewardErc20 public token;    
    uint256 public startDate;
    uint256 public firstRelease;
    uint256 public vestingTimeEnd;
    uint256 public tokensForLP;
    uint256 public tokensForNative;
    bool private isInitTimeStampCall;

    constructor(address rewToken,address signer ,uint256 startTimeStamp) {
        require(signer != address(0), "Invalid signer address");
        trustedSigner[signer] = true;
        trustedSigner[msg.sender] = true;
        require(rewToken != address(0), "Invalid reward token address");
        token = RewardErc20(rewToken);
        require(block.timestamp<=startTimeStamp,"You can't set new start date as past time");
        startDate = startTimeStamp;
        updateContractDate(startTimeStamp);
    }

    function updateContractDate(uint256 newStartTimeStamp) internal{
        require(startDate>block.timestamp,'Contract already start staking');
        require(block.timestamp<=newStartTimeStamp,"You can't set new start date as past time");
        startDate = newStartTimeStamp;
        firstRelease = startDate.add(CLIF_PERIOD);
        vestingTimeEnd = firstRelease.add(VESTING_DURATION);
    }

    function setInitialTimestamp (uint256 newTimeStamp) public onlyOwner {
        require(isInitTimeStampCall==false,"You already called this function");
        isInitTimeStampCall = true;
        updateContractDate(newTimeStamp);
    }

    function addInvestors(address newInvestor,uint256 amountOftokens, bool isPrivate) public onlyOwner {
        require(newInvestor!= address(0),"Invalid investor address");
        require(amountOftokens>0,"Can't mint 0 tokens");
        token.mint(address(this),amountOftokens);
        trustedSigner[newInvestor] = true;
        Investor storage investor = investorInfo[newInvestor];
        if(isPrivate){
            investor.allocation = AllocationType.SEED;
        }else{
            investor.allocation = AllocationType.PRIVATE;
        }
        investor.mintedToken = amountOftokens;
    }

    function withdrawTokens(uint256 percentageOfToken) public {
        require(trustedSigner[msg.sender] == true,"You don't have permissions");
        require(percentageOfToken <= TOTAL_PERCENTAGE,"Can't get more than 100% of tokens");
        _withdrawTokens(msg.sender, percentageOfToken);
    }

    function _withdrawTokens(address beneficiary, uint256 percentageOfToken)private{
        Investor storage investor = investorInfo[beneficiary];
        uint256 reward = _getRewardBalance(percentageOfToken,investor.allocation,investor.mintedToken);
        //uint256 balance = token.balanceOf(address(this));
        require(reward > investor.paidAmount, "No rewards available");
        uint256 amountToPay = reward.sub(investor.paidAmount);
        //require(amountToPay <= balance, "Balance of reward tokens on the contract is less than your reward");
        investor.paidAmount = amountToPay;
        investor.timeRewardPaid = block.timestamp;
        token.transfer(beneficiary, amountToPay);
        //emit RewardPaid(beneficiary, amountToPay);
    }
    function getRewardBalance(uint256 percentageOfToken) public view returns(uint256){
        require(trustedSigner[msg.sender] == true,"You don't have permissions");
        Investor storage investor = investorInfo[msg.sender];
        uint256 reward = _getRewardBalance(percentageOfToken,investor.allocation,investor.mintedToken);
        if (reward <= investor.paidAmount) {
            return 0;
        } else {
            uint256 amountToPay = reward.sub(investor.paidAmount);
            return amountToPay;
        }
    }

    function _getRewardBalance(uint256 percentageOfToken,AllocationType allocation,uint256 mintedToken) private view returns(uint256){
        uint256 vestingAvailablePercentage = _calculateAvailablePercentage(allocation);
        uint256 amountAvailable = mintedToken.mul(vestingAvailablePercentage).div(TOTAL_PERCENTAGE);
        uint256 rewardToPay = amountAvailable.mul(percentageOfToken).div(TOTAL_PERCENTAGE);
        return rewardToPay;
    }

    function _calculateAvailablePercentage(AllocationType allocation) internal view returns (uint256){
        uint256 currentTimeStamp = block.timestamp;
        uint256 tgePercentage;
        if(allocation == AllocationType.PRIVATE){
                tgePercentage = TGE_PERCENTAGE_PRIVATE;
        }else{
                tgePercentage = TGE_PERCENTAGE_PUBLIC;
        }
        if (currentTimeStamp < startDate) {
            return 0;
        } else if ( startDate <= currentTimeStamp && currentTimeStamp < firstRelease) {
            return tgePercentage;
        } else if (firstRelease <=currentTimeStamp && currentTimeStamp < vestingTimeEnd ){
            uint256 numOfPeriods = currentTimeStamp.sub(firstRelease).div(PERIOD);
            uint256 perioPercentage = (TOTAL_PERCENTAGE.sub(tgePercentage)).div(100);
            return tgePercentage.add(numOfPeriods.mul(perioPercentage));
        }else {
            return TOTAL_PERCENTAGE;
        }
    }
}