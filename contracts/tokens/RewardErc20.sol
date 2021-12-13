// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract RewardErc20 is ERC20 {
    constructor(uint256 supply) ERC20("Reward Token", "REWARDERC20") {
        _mint(msg.sender, supply);
    }

    function mint(address account, uint256 amount) public {
        _mint(account, amount);
    }
}