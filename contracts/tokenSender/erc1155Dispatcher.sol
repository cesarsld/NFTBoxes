pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "../Controller.sol";


contract ERC1155Dispatcher is Controller{

	function disperseOneToken(IERC1155 _token, uint256 _id, address[] calldata _recipients, uint256[] calldata _values) public {
		require(_recipients.length == _values.length, "ERC1155Dispatcher: Arrays not same length");
		for (uint256 i = 0; i < _values.length; i++)
			_token.safeTransferFrom(msg.sender, _recipients[i], _id, _values[i], "");
	}

	function disperseMany(IERC1155 _token, uint256[] calldata _ids, address[] calldata _recipients, uint256[] calldata _values) public {
		require(_recipients.length == _values.length && _recipients.length == _values.length, "ERC1155Dispatcher: Arrays not same length");
		for (uint256 i = 0; i < _values.length; i++)
			_token.safeTransferFrom(msg.sender, _recipients[i], _ids[i], _values[i], "");
	}

	function disperseBatchToken(IERC1155 _token, uint256[] calldata _ids, address[] calldata _recipients, uint256[][] calldata _values) public {
		require(_recipients.length == _values.length, "ERC1155Dispatcher: Arrays not same length");
		for (uint256 i = 0; i < _values.length; i++)
			_token.safeBatchTransferFrom(msg.sender, _recipients[i], _ids, _values[i], "");
	}

	function disperseOneTokenFrom(
		IERC1155 _token,
		uint256 _id,
		address[] calldata _recipients,
		uint256[] calldata _values,
		address _from)
		public 
		onlyOwner {
		require(_recipients.length == _values.length, "ERC1155Dispatcher: Arrays not same length");
		for (uint256 i = 0; i < _values.length; i++)
			_token.safeTransferFrom(_from, _recipients[i], _id, _values[i], "");
	}

	function disperseBatchToken(
		IERC1155 _token,
		uint256[] calldata _ids,
		address[] calldata _recipients,
		uint256[][] calldata _values,
		address _from)
		public
		onlyOwner{
		require(_recipients.length == _values.length, "ERC1155Dispatcher: Arrays not same length");
		for (uint256 i = 0; i < _values.length; i++)
			_token.safeBatchTransferFrom(_from, _recipients[i], _ids, _values[i], "");
	}
}
