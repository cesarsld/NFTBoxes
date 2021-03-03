pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IBoxVoucher is IERC1155 {
	function mintFor(address _to, uint256 _id, uint256 _amount) external;
	function burnFrom(address _from, uint256 _id, uint256 _amount) external;
	function totalSupply(uint256 _id) external view returns(uint256);
}