//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Interfaces/Govern.sol";
import "./Interfaces/ILendingPool.sol";

contract FlashVoter {
    ILendingPool constant pool = ILendingPool(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);
    IERC20 constant DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);

    uint constant borrowAmount = 100000e18;

    Govern public governanceToken;
    uint public proposalId;

    constructor(Govern _governanceToken, uint _proposalId) {
        governanceToken = _governanceToken;
        proposalId = _proposalId;
    }

    //Must pass in all 7 parameters when calling flashLoan. 
    //Assets, Amounts, & Modes arguments are all arrays so must use memory keyword...
    //... then upon assignment use "new" keyword with appropriate type to create new array. 
    //We must also set the array length which will be 1 for each one. 
    //Finally we assign the first and only array postiion [0] to the value/variable we are assigning it to
    function flashVote() external {
        address[] memory assets = new address[](1);
        assets[0] = address(DAI);

        uint[] memory amounts = new uint[](1);
        amounts[0] = borrowAmount;

        uint[] memory modes = new uint[](1);
        modes[0] = 0;

        pool.flashLoan(address(this), assets, amounts, modes, address(this), "", 0);
    }

    function executeOperation(
        address[] calldata,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address, bytes calldata
    ) external returns(bool) {
        DAI.approve(address(governanceToken), borrowAmount);
        governanceToken.buy(borrowAmount);
        governanceToken.vote(proposalId, true);
        governanceToken.sell(borrowAmount);

        uint totalOwed = amounts[0] + premiums[0];
        IERC20(DAI).approve(address(pool), totalOwed);
        return true;
    }
}