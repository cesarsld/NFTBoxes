// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/introspection/ERC165.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract HasSecondarySaleFees is ERC165 {
	
	mapping(uint256 => address payable) royaltyAddressMemory;
	mapping(uint256 => uint256) royaltyMemory;  
	mapping(uint256 => uint256) artworkNFTReference;
		
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
		uint256 NFTRef = artworkNFTReference[id];
		
		address payable[] memory addressArray;
		addressArray[0] = royaltyAddressMemory[NFTRef];
		return addressArray;
	}
	
	function getFeeBps(uint256 id) public view returns (uint[] memory){
		uint256 NFTRef = artworkNFTReference[id];
		
		uint[] memory bpsArray;
		bpsArray[0] = royaltyMemory[NFTRef];
		return bpsArray;
	}
 
}


contract NFTBoxesNFT is ERC721, Ownable, HasSecondarySaleFees {
	using SafeMath for uint256;    

	uint256 NFTIndex;
	address boxContract;

	mapping(address => bool) public authorisedCaller;

	mapping(uint256 => string) hashIPFSMemory;
	mapping(uint256 => string) hashArweaveMemory;
	mapping(uint256 => string) artistNameMemory;
	mapping(uint256 => address) signatureAddressMemory;
	mapping(uint256 => string) signatureHashMemory;
	mapping(uint256 => string) signatureMessageMemory;
	mapping(uint256 => uint256) editionSizeMemory;
	mapping(uint256 => string) artTitleMemory;
	mapping(uint256 => string) artworkTypeMemory;
	mapping(uint256 => uint256) editionNumberMemory;
	mapping(uint256 => string) boxDetailsMemory;

	mapping(uint256 => uint256) totalCreated;
	mapping(uint256 => uint256) totalMinted;
  
	mapping (uint256 => bool) mintingActive;

	constructor() ERC721("NFTBoxes", "[NFT]") public {
	updateURI("https://nftboxes.azurewebsites.net/api/HttpTrigger?id=");
	NFTIndex = 1;
	boxContract = 0x6A53Dc033D85D98B59F6dc596588860d962a3Cf6;
	}  

	event NewNFTMouldCreated(uint256 NFTIndex, string artworkHashIPFS, string artworkHashArweave, string artistName, 
	uint256 editionSize, string artTitle, string artworkType, string artworkSeries);
	event NewNFTMouldSignatures(uint256 NFTIndex, address signatureAddress, string signatureHash, string signatureMessage);
	event NewNFTMouldRoyalties(address royaltyAddress, uint256 royaltyBps);
	event NewNFTCreatedFor(uint256 NFTId, uint256 tokenId, address recipient);
	event CloseNFTWindow(uint256 NFTId);
	
	modifier authorised() {
		require(authorisedCaller[msg.sender] || msg.sender == owner(), "VendingMachine: Not authorised to execute");
		_;
	}

	function setCaller(address _caller, bool _value) external onlyOwner {
		authorisedCaller[_caller] = _value;
	}

	function createNFTMould(
		string memory artworkHashIPFS,
		string memory artworkHashArweave,
		string memory artistName, 
		address signatureAddress,
		string memory signatureHash,
		string memory signatureMessage, 
		uint256 editionSize,
		string memory artTitle,
		string memory artworkType,
		string memory boxDetails,
		address payable royaltyAddress,
		uint256 royaltyBps) 
		public onlyOwner {
		mintingActive[NFTIndex] = true;
		
		hashIPFSMemory[NFTIndex] = artworkHashIPFS;
		hashArweaveMemory[NFTIndex] = artworkHashArweave;
		artistNameMemory[NFTIndex] = artistName;
		
		signatureAddressMemory[NFTIndex] = signatureAddress;
		signatureHashMemory[NFTIndex] = signatureHash;
		signatureMessageMemory[NFTIndex] = signatureMessage;
		
		editionSizeMemory[NFTIndex] = editionSize;
		artTitleMemory[NFTIndex] = artTitle;
		artworkTypeMemory[NFTIndex] = artworkType;
		boxDetailsMemory[NFTIndex] = boxDetails;
 
		totalCreated[NFTIndex] = 0;
		totalMinted[NFTIndex] = 0;
		
		royaltyAddressMemory[NFTIndex] = royaltyAddress;
		royaltyMemory[NFTIndex] = royaltyBps;
		
		emit NewNFTMouldCreated(NFTIndex, artworkHashIPFS, artworkHashArweave, artistName, editionSize, artTitle, artworkType, boxDetails);
		emit NewNFTMouldSignatures(NFTIndex, signatureAddress, signatureHash, signatureMessage);
		emit NewNFTMouldRoyalties(royaltyAddress, royaltyBps);
			
		NFTIndex = NFTIndex + 1;
	}

	function NFTMachineFor(uint256 NFTId, address _recipient) public authorised {
		require(mintingActive[NFTId] == true, "Mint not active");
		uint256 editionId = totalMinted[NFTId] + 1;
		require(editionId <= editionSizeMemory[NFTId], "Cannot mint more");
		
		uint256 tokenId = totalSupply() + 1;
		artworkNFTReference[tokenId] = NFTId;
		editionNumberMemory[tokenId] = editionId;
		_safeMint(_recipient, tokenId);

		totalMinted[NFTId] = editionId;
		
		if (totalMinted[NFTId] == editionSizeMemory[NFTId]) {
			_closeNFTWindow(NFTId);
		}
		
		emit NewNFTCreatedFor(NFTId, tokenId, _recipient);
	}

	function closeNFTWindow(uint256 NFTId) public onlyOwner {
		mintingActive[NFTId] = false;
		editionSizeMemory[NFTId] = totalMinted[NFTId];
		
		emit CloseNFTWindow(NFTId); 
	}

	function _closeNFTWindow(uint256 NFTId) internal {
		mintingActive[NFTId] = false;
		editionSizeMemory[NFTId] = totalMinted[NFTId];
		
		emit CloseNFTWindow(NFTId); 
	}
	
	function withdrawFunds() public onlyOwner {
		msg.sender.transfer(address(this).balance);
	}

	function getFileData(uint256 tokenId) public view returns (string memory hashIPFS, string memory hashArweave, string memory artworkType) {
		require(_exists(tokenId), "Token does not exist.");
		uint256 NFTRef = artworkNFTReference[tokenId];
		
		hashIPFS = hashIPFSMemory[NFTRef];
		hashArweave = hashArweaveMemory[NFTRef];
		artworkType = artworkTypeMemory[NFTRef];        
	}

	function getMetadata(uint256 tokenId) public view returns (string memory artistName, uint256 editionSize, string memory artTitle, uint256 editionNumber, string memory boxDetails, bool isActive) {
		require(_exists(tokenId), "Token does not exist.");
		uint256 NFTRef = artworkNFTReference[tokenId];
		
		artistName = artistNameMemory[NFTRef];
		editionSize = editionSizeMemory[NFTRef];
		artTitle = artTitleMemory[NFTRef];
		editionNumber = editionNumberMemory[tokenId];
		boxDetails = boxDetailsMemory[NFTRef];

		isActive = mintingActive[NFTRef];
	}
	
	function getRoyaltyData(uint256 tokenId) public view returns (address payable artistAddress, uint256 royaltyFeeById) {
		require(_exists(tokenId), "Token does not exist.");
		uint256 NFTRef = artworkNFTReference[tokenId];
		
		artistAddress = royaltyAddressMemory[NFTRef];
		royaltyFeeById = royaltyMemory[NFTRef];
	}
	
	function getSignatureData(uint256 tokenId) public view returns (address signatureAddress, string memory signatureHash, string memory signatureMessage) {
		require(_exists(tokenId), "Token does not exist.");
		uint256 NFTRef = artworkNFTReference[tokenId];
		
		signatureAddress = signatureAddressMemory[NFTRef];
		signatureHash = signatureHashMemory[NFTRef];
		signatureMessage = signatureMessageMemory[NFTRef];
	}

	function NFTMouldFileData(uint256 NFTId) public view returns (string memory hashIPFS, string memory hashArweave, string memory artworkType, uint256 unmintedEditions) {
		hashIPFS = hashIPFSMemory[NFTId];
		hashArweave = hashArweaveMemory[NFTId];
		artworkType = artworkTypeMemory[NFTId];
		unmintedEditions = editionSizeMemory[NFTId] - totalMinted[NFTId];
	}

	function NFTMouldMetadata(uint256 NFTId) public view returns (string memory artistName, uint256 editionSize, string memory artTitle, string memory boxDetails, bool isActive) {
		artistName = artistNameMemory[NFTId];
		editionSize = editionSizeMemory[NFTId];
		artTitle = artTitleMemory[NFTId];
		boxDetails = boxDetailsMemory[NFTId];
		
		isActive = mintingActive[NFTId];
	}
	
	function NFTMouldRoyaltyData(uint256 NFTId) public view returns (address payable artistAddress, uint256 royaltyFeeById) {
		artistAddress = royaltyAddressMemory[NFTId];
		royaltyFeeById = royaltyMemory[NFTId];
	}
	
	function NFTMouldSignatureData(uint256 NFTId) public view returns (address signatureAddress, string memory signatureHash, string memory signatureMessage) {
		signatureAddress = signatureAddressMemory[NFTId];
		signatureHash = signatureHashMemory[NFTId];
		signatureMessage = signatureMessageMemory[NFTId];
	}    
	
	function updateURI(string memory newURI) public onlyOwner {
		_setBaseURI(newURI);
	}

	function updateBoxContract(address newBoxContract) public onlyOwner {
		boxContract = newBoxContract;
	}       
}
