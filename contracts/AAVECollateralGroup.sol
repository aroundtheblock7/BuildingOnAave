// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Interfaces/IERC20.sol";
import "./Interfaces/ILendingPool.sol";

contract AAVECollateralGroup {
	ILendingPool pool = ILendingPool(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);
	IERC20 dai = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
	IERC20 aDai = IERC20(0x028171bCA77440897B824Ca71D1c56caC55b68A3); 

	uint depositAmount = 10000e18;
	address[] members;

	//Here we transfer funds from each member to the contract. Member addresses are tracked in members array.
	//We also approve & deposit the total funds in the contract to the spent by the pool so we can earn interest
	constructor(address[] memory _members) {
		members = _members;
		for (uint i = 0;  i < _members.length; i++) {
			dai.transferFrom(_members[i], address(this), depositAmount);
		}
		uint totalDeposit = _members.length * depositAmount;
		dai.approve(address(pool), totalDeposit);
		pool.deposit(address(dai), totalDeposit, address(this), 0);
	}

	function isMember(address _address) private view returns (bool) {
		for (uint i = 0; i < members.length; i++) {
			if (members[i] == _address) {
				return true;
			}
		}
		return false;
	}

	//Pays back each member their "share" of the aDai interest earned. Pool must be approved to spend aDai before withdrawn.
	function withdraw() external {
		require(isMember(msg.sender));
		uint totalBalance = aDai.balanceOf(address(this));
		uint fundsPerMember = totalBalance / members.length;
		aDai.approve(address(pool), totalBalance);
		for (uint i = 0; i < members.length; i++) {
			pool.withdraw(address(dai), fundsPerMember, members[i]);
		}
	}

	//Once borrow is called, amount must be sent via IERC20 to msg.sender so they can use it.
	//getUserAccountData function in the Pool contract provides info on parameters that must be returned when called
	//We are only interested in the healthFactor so return that only here. 
	function borrow(address asset, uint amount) external {
		require(isMember(msg.sender));
		pool.borrow(address(dai), amount, 2, 0, address(this));
	    (,,,,, uint healthFactor) = pool.getUserAccountData(address(this));
		require(healthFactor > 2e18);
		IERC20(asset).transfer(msg.sender, amount);
	}

	//Assets must first be sent from msg.sender back to this contract before it can be paid
	//Next approve must be called on the dai contract to give the pool permission to use/access for repayment
	//Finally we can call repay on the pool for the amount specified.
	function repay(address asset, uint amount) external {
		IERC20(asset).transferFrom(msg.sender, address(this), amount);
		IERC20(dai).approve(address(pool), amount);
		pool.repay(asset, amount, 2, address(this));
	}
}
