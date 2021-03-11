pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../interfaces/IVendingMachine.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IBoxVoucher.sol";

contract HasSecondaryBoxSaleFees is ERC165 {
    
    address payable teamAddress;
    uint256 teamSecondaryBps;  
        
   /*
    * bytes4(keccak256('getFeeBps(uint256)')) == 0x0ebd4c7f
    * bytes4(keccak256('getFeeRecipients(uint256)')) == 0xb9c4d9fb
    *
    * => 0x0ebd4c7f ^ 0xb9c4d9fb == 0xb7799584
    */
    
    bytes4 private constant _INTERFACE_ID_FEES = 0xb7799584;
    
    constructor() public {
        _registerInterface(_INTERFACE_ID_FEES);
    }

    function getFeeRecipients(uint256 id) public view returns (address payable[] memory){
        address payable[] memory addressArray = new address payable[](1);
        addressArray[0] = teamAddress;
        return addressArray;
    }
    
    function getFeeBps(uint256 id) public view returns (uint[] memory){
        uint[] memory bpsArray = new uint[](1);
        bpsArray[0] = teamSecondaryBps; 
        return bpsArray;
    }
 
}


contract NFTBoxesBox is ERC721("NFTBox", "[BOX]"), Ownable, HasSecondaryBoxSaleFees {
    
	struct BoxMould{
		uint8				live; // bool
		uint8				shared; // bool
		uint128				maxEdition;
		uint128				maxBuyAmount;
		uint128				currentEditionCount;
		uint256				price;
		address payable[]	artists;
		uint256[]			shares;
		string				name;
		string				series;
		string				theme;
		string				ipfsHash;
		string				arweaveHash;
	}

	struct Box {
		uint256				mouldId;
		uint256				edition;
	}

	IVendingMachine public	vendingMachine;
	IBoxVoucher public		boxVoucher;
	uint256 public			boxMouldCount;
	uint256 public			gasFee;

	uint256 constant public TOTAL_SHARES = 1000;
	uint256 constant DELIMITOR = 100000;

	mapping(uint256 => BoxMould) public	boxMoulds;
	mapping(uint256 =>  Box) public	boxes;
	mapping(uint256 => bool) public lockedBoxes;
	mapping(uint256 => uint256) public voucherValidityInterval;
	mapping(uint256 => address[]) public reservations;

	mapping(address => uint256) public teamShare;
	address payable[] public team;

	uint256 gasMoney;

	mapping(address => bool) public authorisedCaller;

	event BoxMouldCreated(uint256 id);
	event BoxBought(uint256 indexed boxMould, uint256 boxEdition, uint256 tokenId);
	event BatchDeployed(uint256 indexed boxMould, uint256 batchSize);

	constructor() public {
		_setBaseURI("https://nftboxesbox.azurewebsites.net/api/HttpTrigger?id=");
		gasFee = 1050;
		boxMouldCount = 2;
		team.push(payable(0x3428B1746Dfd26C7C725913D829BE2706AA89B2e));
		team.push(payable(0x63a9dbCe75413036B2B778E670aaBd4493aAF9F3));
		team.push(payable(0x4C7BEdfA26C744e6bd61CBdF86F3fc4a76DCa073));
		team.push(payable(0xf521Bb7437bEc77b0B15286dC3f49A87b9946773));
		team.push(payable(0x3945476E477De76d53b4833a46c806Ef3D72b21E));
		team.push(payable(0xd084c5fF298E951E0e4CD29dD29684d5a54C0d8e));

		teamShare[address(0x3428B1746Dfd26C7C725913D829BE2706AA89B2e)] = 600;
        teamShare[address(0x63a9dbCe75413036B2B778E670aaBd4493aAF9F3)] = 10;
        teamShare[address(0x4C7BEdfA26C744e6bd61CBdF86F3fc4a76DCa073)] = 30;
        teamShare[address(0xf521Bb7437bEc77b0B15286dC3f49A87b9946773)] = 60;
        teamShare[address(0x3945476E477De76d53b4833a46c806Ef3D72b21E)] = 10;
        teamShare[address(0xd084c5fF298E951E0e4CD29dD29684d5a54C0d8e)] = 20;
		authorisedCaller[0x63a9dbCe75413036B2B778E670aaBd4493aAF9F3] = true;
		vendingMachine = IVendingMachine(0x6d4530149e5B4483d2F7E60449C02570531A0751);
	}

	function updateURI(string memory newURI) public onlyOwner {
		_setBaseURI(newURI);
	}

	modifier authorised() {
		require(authorisedCaller[msg.sender] || msg.sender == owner(), "NFTBoxes: Not authorised to execute.");
		_;
	}

	function setCaller(address _caller, bool _value) external onlyOwner {
		authorisedCaller[_caller] = _value;
	}

	function addTeamMember(address payable _member) external onlyOwner {
		for (uint256 i = 0; i < team.length; i++)
			require( _member != team[i], "NFTBoxes: members exists already");
		team.push(_member);
	}

	function removeTeamMember(address payable _member) external onlyOwner {
		for (uint256 i = 0; i < team.length; i++)
			if (team[i] == _member) {
				delete teamShare[_member];
				team[i] = team[team.length - 1];
				team.pop();
			}
	}

	function setTeamShare(address _member, uint _share) external onlyOwner {
		require(_share <= TOTAL_SHARES, "NFTBoxes: share must be below 1000");
		for (uint256 i = 0; i < team.length; i++)
			if (team[i] == _member)
				teamShare[_member] = _share;
	}

	function setLockOnBox(uint256 _id, bool _lock) external authorised {
		require(_id <= boxMouldCount && _id > 0, "NFTBoxes: Mould ID does not exist.");
		lockedBoxes[_id] = _lock;
	}

	function createBoxMould(
		uint128 _max,
		uint128 _maxBuyAmount,
		uint128 _reserve,
		uint256 _price,
		address payable[] memory _artists,
		uint256[] memory _shares,
		string memory _name,
		string memory _series,
		string memory _theme,
		string memory _ipfsHash,
		string memory _arweaveHash)
		external
		onlyOwner {
		require(_artists.length == _shares.length, "NFTBoxes: arrays are not of same length");
		require(_reserve <= _max, "NFTBoxes: Cannot mint more vouchers than boxes");
		boxMoulds[boxMouldCount + 1] = BoxMould({
			live: uint8(0),
			shared: uint8(0),
			maxEdition: _max,
			maxBuyAmount: _maxBuyAmount,
			currentEditionCount: 0,
			price: _price,
			artists: _artists,
			shares: _shares,
			name: _name,
			series: _series,
			theme: _theme,
			ipfsHash: _ipfsHash,
			arweaveHash: _arweaveHash
		});
		boxMouldCount++;
		lockedBoxes[boxMouldCount] = true;
		boxVoucher.mintFor(msg.sender, boxMouldCount, _reserve);
		emit BoxMouldCreated(boxMouldCount);
	}

	function removeArtist(uint256 _id, address payable _artist) external onlyOwner {
		BoxMould storage boxMould = boxMoulds[_id];
		require(_id <= boxMouldCount && _id > 0, "NFTBoxes: Mould ID does not exist.");
		for (uint256 i = 0; i < boxMould.artists.length; i++) {
			if (boxMould.artists[i] == _artist) {
				boxMould.artists[i] = boxMould.artists[boxMould.artists.length - 1];
				boxMould.artists.pop();
				boxMould.shares[i] = boxMould.shares[boxMould.shares.length - 1];
				boxMould.shares.pop();
			}
		}
	}
	
	function addArtists(uint256 _id, address payable _artist, uint256 _share) external onlyOwner {
		BoxMould storage boxMould = boxMoulds[_id];
		require(_id <= boxMouldCount && _id > 0, "NFTBoxes: Mould ID does not exist");
		boxMould.artists.push(_artist);
		boxMould.shares.push(_share);
	}

	// dont even need this tbh?
	// function getArtistRoyalties(uint256 _id) external view returns (address payable[] memory artists, uint256[] memory royalties) {
	// 	require(_id <= boxMouldCount && _id > 0, "NFTBoxes: Mould ID does not exist.");
	// 	BoxMould memory boxMould = boxMoulds[_id];
	// 	artists = boxMould.artists;
	// 	royalties = boxMould.shares;
	// }

	function buyManyBoxes(uint256 _id, uint128 _quantity) external payable {
		BoxMould storage boxMould = boxMoulds[_id];
		uint128 currentEdition = boxMould.currentEditionCount;
		uint128 max = boxMould.maxEdition;
		require(_id <= boxMouldCount && _id > 0, "NFTBoxes: Mould ID does not exist");
		require(!lockedBoxes[_id], "NFTBoxes: Box is locked");
		require(voucherValidityInterval[_id] != 0 && block.timestamp > voucherValidityInterval[_id],
			"NFTBoxes: Buy window not open");
		require(boxMould.price.mul(_quantity) == msg.value, "NFTBoxes: !price");
		require(currentEdition + _quantity <= max, "NFTBoxes: Too many boxes");
		require(_quantity <= boxMould.maxBuyAmount, "NFTBoxes: !buy");

		for (uint128 i = 0; i < _quantity; i++)
			_buy(currentEdition, _id, i, msg.sender);
		boxMould.currentEditionCount += _quantity;
		if (currentEdition + _quantity == max)
			boxMould.live = uint8(1);
	}

	function buyBoxesWithVouchers(uint256 _id, uint128 _quantity) external payable {
		BoxMould storage boxMould = boxMoulds[_id];
		uint128 currentEdition = boxMould.currentEditionCount;
		uint128 max = boxMould.maxEdition;
		require(_id <= boxMouldCount && _id > 0, "NFTBoxes: Mould ID does not exist");
		require(!lockedBoxes[_id], "NFTBoxes: Box is locked");
		require(boxMould.price.mul(_quantity) == msg.value, "NFTBoxes: !price");

		boxVoucher.burnFrom(msg.sender, _id, _quantity);
		boxVoucher.mintFor(msg.sender, _id + DELIMITOR, _quantity);
		for (uint128 i = 0; i < _quantity; i++)
			_buy(currentEdition, _id, i, msg.sender);
		boxMould.currentEditionCount += _quantity;
		if (currentEdition + _quantity == max)
			boxMould.live = uint8(1);
	}

	function reserveBoxes(uint256 _id, uint256 _quantity) external payable {
		BoxMould memory boxMould = boxMoulds[_id];
		require(_id <= boxMouldCount && _id > 0, "NFTBoxes: Mould ID does not exist");
		require(voucherValidityInterval[_id] == 0, "NFTBoxes: Cannot reserve anymore");
		require(boxMould.price.mul(_quantity).mul(gasFee).div(TOTAL_SHARES) == msg.value, "NFTBoxes: !price");

		boxVoucher.burnFrom(msg.sender, _id, _quantity);
		boxVoucher.mintFor(msg.sender, _id + DELIMITOR, _quantity);
		for (uint256 i = 0; i < _quantity; i++)
			reservations[_id].push(msg.sender);
		gasMoney = gasMoney.add(msg.value.sub(boxMould.price.mul(_quantity)));
	}

	function withdrawGasMoney() external onlyOwner {
		msg.sender.transfer(gasMoney);
		gasMoney = 0;
	}

	function distributeReservedBoxes(uint256 _id, uint256 _amount) external authorised {
		require(_id <= boxMouldCount && _id > 0, "NFTBoxes: Mould ID does not exist");
		require(!lockedBoxes[_id], "NFTBoxes: Box is locked");
		require(voucherValidityInterval[_id] == 0, "NFTBoxes: Box distribution over");

		BoxMould storage boxMould = boxMoulds[_id];
		uint128 currentEdition = boxMould.currentEditionCount;
		uint256 length = reservations[_id].length;
		uint256 i = 0;
		while (length > 0 && _amount > 0) {
			_buy(currentEdition, _id, i, reservations[_id][length - 1]);
			reservations[_id].pop();
			length--;
			_amount--;
			i++;
		}
		boxMould.currentEditionCount += uint128(i);
		if (currentEdition + i == boxMould.maxEdition)
			boxMould.live = uint8(1);
		if (length == 0)
			voucherValidityInterval[_id] = block.timestamp + 900;
	}

	function _buy(uint128 _currentEdition, uint256 _id, uint256 _new, address _recipient) internal {
		boxes[totalSupply() + 1] = Box(_id, _currentEdition + _new + 1);
		//safe mint?
		emit BoxBought(_id, _currentEdition + _new + 1, totalSupply() + 1);
		_mint(_recipient, totalSupply() + 1);
	}

	// close a sale if not sold out
	function closeBox(uint256 _id) external authorised {
		BoxMould storage boxMould = boxMoulds[_id];
		require(_id <= boxMouldCount && _id > 0, "NFTBoxes: Mould ID does not exist.");
		boxMould.live = uint8(1);
	}

	function setVendingMachine(address _machine) external onlyOwner {
		vendingMachine = IVendingMachine(_machine);
	}

	function setBoxVoucher(address _vouchers) external onlyOwner {
		boxVoucher = IBoxVoucher(_vouchers);
	}

	function setGasFee(uint256 _fee) external onlyOwner {
		gasFee = _fee;
	}

	function distributeOffchain(uint256 _id, address[][] calldata _recipients, uint256[] calldata _ids) external authorised {
		BoxMould memory boxMould= boxMoulds[_id];
		require(boxMould.live == 1, "NTFBoxes: Box is still live");
		require (_recipients[0].length == _ids.length, "NFTBoxes: Wrong array size.");

		// i is batch number
		for (uint256 i = 0; i < _recipients.length; i++) {
			// j is for the index of nft ID to send
			for (uint256 j = 0;j <  _recipients[0].length; j++)
				vendingMachine.NFTMachineFor(_ids[j], _recipients[i][j]);
		}
		emit BatchDeployed(_id, _recipients.length);
	}

	function distributeShares(uint256 _id) external {
		BoxMould storage boxMould= boxMoulds[_id];
		require(_id <= boxMouldCount && _id > 0, "NFTBoxes: ID !exist.");
		require(boxMould.live == 1 && boxMould.shared == 0,  "NFTBoxes: cannot distribute");
		require(is100(_id), "NFTBoxes: sum != 100%.");

		boxMould.shared = 1;
		uint256 rev = uint256(boxMould.currentEditionCount).mul(boxMould.price);
		uint256 share;
		for (uint256 i = 0; i < team.length; i++) {
			share = rev.mul(teamShare[team[i]]).div(TOTAL_SHARES);
			team[i].transfer(share);
		}
		for (uint256 i = 0; i < boxMould.artists.length; i++) {
			share = rev.mul(boxMould.shares[i]).div(TOTAL_SHARES);
			boxMould.artists[i].transfer(share);
		}
	}

	function is100(uint256 _id) internal returns(bool) {
		BoxMould storage boxMould= boxMoulds[_id];
		uint256 total;
		for (uint256 i = 0; i < team.length; i++) {
			total = total.add(teamShare[team[i]]);
		}
		for (uint256 i = 0; i < boxMould.shares.length; i++) {
			total = total.add(boxMould.shares[i]);
		}
		return total == TOTAL_SHARES;
	}

	function getReservationCount(uint256 _id) external view returns(uint256) {
		return reservations[_id].length;
	}

	function getArtist(uint256 _id) external view returns (address payable[] memory) {
		return boxMoulds[_id].artists;
	}

	function getArtistShares(uint256 _id) external view returns (uint256[] memory) {
		return boxMoulds[_id].shares;
	}

    function updateTeamAddress(address payable newTeamAddress) public onlyOwner {
        teamAddress = newTeamAddress;
    }
    
    function updateSecondaryFee(uint256 newSecondaryBps) public onlyOwner {
        teamSecondaryBps = newSecondaryBps;
    }

    function getBoxMetaData(uint256 _id) external view returns 
    (uint256 boxId, uint256 boxEdition, uint128 boxMax, string memory boxName, string memory boxSeries, string memory boxTheme, string memory boxHashIPFS, string memory boxHashArweave) {
        Box memory box = boxes[_id];
        BoxMould memory mould = boxMoulds[box.mouldId];
        return (box.mouldId, box.edition, mould.maxEdition, mould.name, mould.series, mould.theme, mould.ipfsHash, mould.arweaveHash);
    }

	function _transfer(address from, address to, uint256 tokenId) internal override {
		Box memory box = boxes[tokenId];
		require(!lockedBoxes[box.mouldId], "NFTBoxes: Box is locked");
		super._transfer(from, to, tokenId);
	}
}
