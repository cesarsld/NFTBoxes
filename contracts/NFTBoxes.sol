pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../interfaces/IVendingMachine.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

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
        address payable[] memory addressArray;
        addressArray[0] = teamAddress;
        return addressArray;
    }
    
    function getFeeBps(uint256 id) public view returns (uint[] memory){
        uint[] memory bpsArray;
        bpsArray[0] = teamSecondaryBps; 
        return bpsArray;
    }
 
}


contract NFTBoxesBox is ERC721("NFTBox", "[BOX]"), Ownable, HasSecondaryBoxSaleFees {
    
	struct BoxMould{
		uint8				live; // bool
		uint8				shared; // bool
		uint128				maxEdition;
		uint152				maxBuyAmount;
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
	uint256 public			boxMouldCount;

	uint256 constant public TOTAL_SHARES = 1000;

	mapping(uint256 => BoxMould) public	boxMoulds;
	mapping(uint256 =>  Box) public	boxes;
	mapping(uint256 => bool) public lockedBoxes;

	mapping(address => uint256) public teamShare;
	address payable[] public team;

	mapping(address => bool) public authorisedCaller;

	event BoxMouldCreated(uint256 id);
	event BoxBought(uint256 indexed boxMould, uint256 boxEdition, uint256 tokenId);

	constructor() public {
		_setBaseURI("https://nftboxesbox.azurewebsites.net/api/HttpTrigger?id=");
		team.push(payable(0x3428B1746Dfd26C7C725913D829BE2706AA89B2e));
		team.push(payable(0x63a9dbCe75413036B2B778E670aaBd4493aAF9F3));
		team.push(payable(0x4C7BEdfA26C744e6bd61CBdF86F3fc4a76DCa073));
		team.push(payable(0xf521Bb7437bEc77b0B15286dC3f49A87b9946773));
		team.push(payable(0x3945476E477De76d53b4833a46c806Ef3D72b21E));

		teamShare[address(0x3428B1746Dfd26C7C725913D829BE2706AA89B2e)] = 580;
		teamShare[address(0x63a9dbCe75413036B2B778E670aaBd4493aAF9F3)] = 10;
		teamShare[address(0x4C7BEdfA26C744e6bd61CBdF86F3fc4a76DCa073)] = 30;
		teamShare[address(0xf521Bb7437bEc77b0B15286dC3f49A87b9946773)] = 30;
		teamShare[address(0x3945476E477De76d53b4833a46c806Ef3D72b21E)] = 10;
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
		require(_artists.length == _shares.length, "NFTBoxes: arrays are not of same length.");
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
		require(_id <= boxMouldCount && _id > 0, "NFTBoxes: Mould ID does not exist.");
		boxMould.artists.push(_artist);
		boxMould.shares.push(_share);
	}

	// dont even need this tbh?
	function getArtistRoyalties(uint256 _id) external view returns (address payable[] memory artists, uint256[] memory royalties) {
		require(_id <= boxMouldCount && _id > 0, "NFTBoxes: Mould ID does not exist.");
		BoxMould memory boxMould = boxMoulds[_id];
		artists = boxMould.artists;
		royalties = boxMould.shares;
	}

	function buyManyBoxes(uint256 _id, uint128 _quantity) external payable {
		BoxMould storage boxMould = boxMoulds[_id];
		uint128 currentEdition = boxMould.currentEditionCount;
		uint128 max = boxMould.maxEdition;
		require(_id <= boxMouldCount && _id > 0, "NFTBoxes: Mould ID does not exist.");
		require(!lockedBoxes[_id], "NFTBoxes: Box is locked");
		require(boxMould.price.mul(_quantity) == msg.value, "NFTBoxes: Wrong total price.");
		require(currentEdition + _quantity <= max, "NFTBoxes: Minting too many boxes.");
		require(_quantity <= boxMould.maxBuyAmount, "NFTBoxes: Cannot buy this many boxes.");

		for (uint128 i = 0; i < _quantity; i++)
			_buy(currentEdition, _id, i);
		boxMould.currentEditionCount += _quantity;
		if (currentEdition + _quantity == max)
			boxMould.live = uint8(1);
	}

	function _buy(uint128 _currentEdition, uint256 _id, uint256 _new) internal {
		boxes[totalSupply() + 1] = Box(_id, _currentEdition + _new + 1);
		//safe mint?
		emit BoxBought(_id, _currentEdition + _new, totalSupply());
		_mint(msg.sender, totalSupply() + 1);
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

	function distributeOffchain(uint256 _id, address[][] calldata _recipients, uint256[] calldata _ids) external authorised {
		BoxMould memory boxMould= boxMoulds[_id];
		require(boxMould.live == 1, "NTFBoxes: Box is still live, cannot start distribution");
		require (_recipients[0].length == _ids.length, "NFTBoxes: Wrong array size.");

		// i is batch number
		for (uint256 i = 0; i < _recipients.length; i++) {
			// j is for the index of nft ID to send
			for (uint256 j = 0;j <  _recipients[0].length; j++)
				vendingMachine.NFTMachineFor(_ids[j], _recipients[i][j]);
		}
	}

	function distributeShares(uint256 _id) external {
		BoxMould storage boxMould= boxMoulds[_id];
		require(_id <= boxMouldCount && _id > 0, "NFTBoxes: Mould ID does not exist.");
		require(boxMould.live == 1 && boxMould.shared == 0,  "NFTBoxes: cannot distribute shares yet.");
		require(is100(_id), "NFTBoxes: shares do not add up to 100%.");

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

	function _getNewSeed(bytes32 _seed) public pure returns (bytes32) {
		return keccak256(abi.encodePacked(_seed));
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
