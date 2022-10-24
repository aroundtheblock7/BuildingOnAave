//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Interfaces/IERC20.sol";
import "./Interfaces/ILendingPool.sol";

contract AAVEDAIEscrow {
    address arbiter;
    address depositor;
    address beneficiary;
    uint initialDeposit;

    // the mainnet AAVE v2 lending pool
    ILendingPool pool = ILendingPool(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);
    // aave interest bearing DAI
    IERC20 aDai = IERC20(0x028171bCA77440897B824Ca71D1c56caC55b68A3);
    // the DAI stablecoin 
    IERC20 dai = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);

    constructor(address _arbiter, address _beneficiary, uint _amount) {
        arbiter = _arbiter;
        beneficiary = _beneficiary;
        depositor = msg.sender;
        initialDeposit = _amount;

        //Depositor/msg.sender transfers dai to this contract.
        IERC20(dai).transferFrom(msg.sender, address(this), _amount); 

        //Now that DAI is the contract, we deposit it into the AAVE lending pool
        //First we need to apporve the lending pool to spend our DAI, 
        IERC20(dai).approve(address(pool), _amount);
        //Now we call deposit on the pool with the proper parameters
        pool.deposit(address(dai), _amount, address(this), 0);
    }

    function approve() external {
        require(msg.sender == arbiter);
        //Here the initialDeposit is returned to the beneficiary
        pool.withdraw(address(dai), initialDeposit, beneficiary);
        //Now the remaining balance which is the interst earned can be sent to the depositor
        pool.withdraw(address(dai), type(uint).max, depositor);
    }
}
