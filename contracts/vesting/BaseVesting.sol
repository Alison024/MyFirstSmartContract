// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2;


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract BaseVesting is Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    struct Investor {
        uint256 paidAmount;
        uint256 timeRewardPaid;
        uint256 mintedToken;
        bool isPrivate;
    }

    uint256 public constant PERIOD = 1 minutes;
    uint256 public constant CLIF_PERIOD = 10 minutes;
    uint256 public constant VESTING_DURATION = 10 hours;
    uint256 public constant PERCENTAGE = 1e18;//1%

    mapping(address => bool) public trustedSigner;
    mapping(address => Investor) public investorInfo;

    IERC20 public token;    
    uint256 public startDate;
    uint256 public vestingTimeEnd;
    uint256 public tokensForLP;
    uint256 public tokensForNative;

    constructor(address signer_) {
        require(signer_ != address(0), "Invalid signer address");
        trustedSigner[signer_] = true;
    }
}