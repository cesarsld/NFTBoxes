pragma solidity ^0.6.12;

interface IVendingMachine {

	function NFTMachineFor(uint256 NFTId, address _recipient) external;
}