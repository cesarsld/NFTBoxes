pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract BoxVoucher is ERC1155("some uri"), Ownable {
	using SafeMath for uint256;

	mapping(address => bool) public authorisedCallers;
	mapping(uint256 => uint256) public _supplies;

	modifier authorised() {
		require(authorisedCallers[msg.sender] || msg.sender == owner(), "BoxVoucher: Not authorised caller");
		_;
	}

	function setCaller(address _caller, bool _value) external onlyOwner {
		authorisedCallers[_caller] = _value;
	}

	function mintFor(address _to, uint256 _id, uint256 _amount) external authorised {
		_mint(_to, _id, _amount, "");
		_supplies[_id] = _supplies[_id].add(_amount);
	}

	function burnFrom(address _from, uint256 _id, uint256 _amount) external authorised {
		_burn(_from, _id, _amount);
		_supplies[_id] = _supplies[_id].sub(_amount);
	}

	function totalSupply(uint256 _id) external view returns(uint256) {
		return _supplies[_id];
	}
}