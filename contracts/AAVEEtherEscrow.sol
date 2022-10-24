//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Interfaces/IERC20.sol";
import "./Interfaces/IWETHGateway.sol";

contract AAVEEtherEscrow {
    address arbiter;
    address depositor;
    address beneficiary; 
    uint initialDeposit;
    
    
    IWETHGateway gateway = IWETHGateway(0xDcD33426BA191383f1c9B431A342498fdac73488);
    IERC20 aWETH = IERC20(0x030bA81f1c18d280636F32af80b9AAd02Cf0854e);

    constructor(address _arbiter, address _beneficiary) payable {
        arbiter = _arbiter;
        beneficiary = _beneficiary;
        depositor = msg.sender;
        //depositor/msg.sender deposits his own funds in constructor here with msg.value.
        initialDeposit = msg.value;

        // Here we dposit ETH through the WETH gateway
        gateway.depositETH{value: address(this).balance}(address(this), 0);
        
    }

    //Must have a receive function to receive the funds back. 
    receive() external payable{}
 
    //Only the arbiter can call this. Must give the 
    function approve() external {
        require(msg.sender == arbiter);
        //Here we give the gateway approval on the aWETH contract first. 
        //Then call withdraw on the gateway and set the amount to "type(uint256).max" which refers to the entire balance
        aWETH.approve(address(gateway), type(uint256).max);
        gateway.withdrawETH(type(uint256).max, address(this));

        //Here we return the principal/initialDeposit to the beneficiary.
        (bool success,) = payable(beneficiary).call{value: initialDeposit}("");
        require(success, "Transfer Failed");
        //Now the aWETH interest earned is paid to the depositor and we can self destruct since contract's use is done
        selfdestruct(payable(depositor));
    }
}
