//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Interfaces/IERC20.sol";
import "./Interfaces/ILendingPool.sol";

contract AAVEInterestLottery {
	// the timestamp of the drawing event
	uint public drawing;
	// the price of the ticket in DAI (100 DAI)
	uint ticketPrice = 100e18;

	mapping(address => bool) public purchasedTicket;

	ILendingPool pool = ILendingPool(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);
	IERC20 aDai = IERC20(0x028171bCA77440897B824Ca71D1c56caC55b68A3); 
	IERC20 dai = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);

	//Creating array allows us to keep track of all ticketHolders and ensures they do not buy ticket twice
	address[] public ticketHolders;

	constructor() {
        drawing = block.timestamp + 1 weeks;
	}

	//This function handles both purchase of tickets for each user and approval & deposit of dai into pool to earn interest
	function purchase() external {
		require(!purchasedTicket[msg.sender]);
        dai.transferFrom(msg.sender, address(this), ticketPrice);
		dai.approve(address(pool), ticketPrice);
		pool.deposit(address(dai), ticketPrice, address(this), 0);
		ticketHolders.push(msg.sender);
	}

	event Winner(address);

	//Chainlink VRF better alternative here than block.timestamp for random number
	function pickWinner() external {
        require(block.timestamp > drawing);
		uint totalPurchasers = ticketHolders.length;
		uint winnerIdx = uint (blockhash(block.number - 1)) % totalPurchasers;
		address winner = ticketHolders[winnerIdx];
		emit Winner(winner);
	}   
}
