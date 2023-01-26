// SPDX-License-Identifier: MIT

pragma solidity >=0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract M4AI_OGACAI is ERC721, Ownable {
  IERC721 private ogac = IERC721(0xA83ad73eEd496fcD7adc5F4027CbAD818D0075a0);
  IERC721 private m4 = IERC721(0x68EA301ECc143C239e354a632FDb6fa1D08dA8D9);
  //address to receive 40% of every withdrawal ALSO has the ability to use the mint for address and withdraw functions
  address private partnerAddr = address(0x0555);  //NEEDS_PARTNER_ADDRESS_HERE!!!
  using Strings for uint256;
  using Counters for Counters.Counter;

  Counters.Counter private supply;

  string public uriPrefix = "https://ipfs.m4rabbit.io/m4ogac/collection/";
  string public uriSuffix = ".json";
  string public hiddenMetadataUri = "https://ipfs.m4rabbit.io/m4ogac/unrevealed.gif";
  
  uint256 public cost = 0.018 ether;
  uint256 public maxSupply = 500;
  uint256 public maxMintAmountPerTx = 25;

  bool public paused = true;
  bool public saleOn = false;
  bool public revealed = false;

  constructor() ERC721("M4AI/OGACAI AI collection", "M4OGACAI") {}

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount!");
    require(supply.current() + _mintAmount <= maxSupply, "Max supply exceeded!");
    _;
  }

  function totalSupply() public view returns (uint256) {
    return supply.current();
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) {
    // require(!paused, "paused!");
    require(!paused || (paused && (ogac.balanceOf(msg.sender) > 0 || (m4.balanceOf(msg.sender) > 0))), "Only M4 and OGAC Holders May Mint Now.");
    require(saleOn, "Sale Has Not Started.");
    require(msg.value >= cost * _mintAmount, "incorrect funds sent!");
    _mintLoop(msg.sender, _mintAmount);
  }

  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwnerOrPartner {
    _mintLoop(_receiver, _mintAmount);
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = 1;
    uint256 ownedTokenIndex = 0;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
      address currentTokenOwner = ownerOf(currentTokenId);

      if (currentTokenOwner == _owner) {
        ownedTokenIds[ownedTokenIndex] = currentTokenId;

        ownedTokenIndex++;
      }

      currentTokenId++;
    }

    return ownedTokenIds;
  }

  function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(_tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : "";
  }

  function reveal() public onlyOwnerOrPartner {
    revealed = !revealed;
  }

  function setCost(uint256 _cost) public onlyOwnerOrPartner {
    cost = _cost;
  }

  function setSup(uint256 _newsup) public onlyOwnerOrPartner {
    maxSupply = _newsup;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwnerOrPartner {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwnerOrPartner {
    uriSuffix = _uriSuffix;
  }

  function setPaused() public onlyOwnerOrPartner {
    paused = !paused;
  }

  modifier onlyOwnerOrPartner() {
    require(msg.sender == owner() || msg.sender == partnerAddr);
    _;
  }

function withdraw() public onlyOwnerOrPartner {
    // This will pass 40% of the initial sale to partner
    (bool hs, ) = payable(partnerAddr).call{value: address(this).balance * 40 / 100}("");
    require(hs);
    // This will transfer the remaining contract balance to the owner.
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
}

  function _mintLoop(address _receiver, uint256 _mintAmount) internal {
    for (uint256 i = 0; i < _mintAmount; i++) {
      supply.increment();
      _safeMint(_receiver, supply.current());
    }
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}
