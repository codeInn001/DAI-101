// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";


contract NFTMarketplace is IERC721Receiver  {
    uint256 public africaPrintCount = 0;
    // declaring a struct for the africaprint
    struct AfricaPrint {
        IERC721 nft;
        uint256 tokenId;
        uint256 price;
        address payable seller;
        bool sold;
        bool forSale;
        bool flagged;
        uint avgRating;
        uint numOfRaters;
        uint totalRating;
    }

    mapping(uint256 => AfricaPrint) public africaPrints;
    address  public ownerAddress;

    constructor() {
        ownerAddress = msg.sender;
    }

    modifier onlySeller(uint _index) {
        require(msg.sender == africaPrints[_index].seller, "Only the contract owner can perform this action");
        _;
    }

    modifier notFlagged(uint256 _index) {
        require(!africaPrints[_index].flagged, "this  africaprint is flagged");
        _;
    }

    // this function will add a new africaprint to the marketplace
    function listAfricaPrint(IERC721 _nft, uint256 _tokenId, uint256 _price
    ) external {
        require(_price > 0, "NFTMarketplace: Price should be above zero");
        _nft.safeTransferFrom(msg.sender, address(this), _tokenId);
        require(_nft.ownerOf(_tokenId) == address(this), "Transfer of NFT to marketplace failed");
        africaPrints[africaPrintCount] = AfricaPrint(
            _nft,
            _tokenId,
            _price,
            payable(msg.sender),
            false,
            true,
            false,
        // Rating
            0,
            0,
            0
        );
        africaPrintCount++;
    }

    // this function will facilitate the buying of a africaprint nft when called
    function buyAfricaPrint(uint256 _index) external payable notFlagged(_index) {
        AfricaPrint storage africaPrint = africaPrints[_index];
        require(africaPrint.forSale == true, "this  africaprint is not for sale");
        require(_index >= 0 && _index < africaPrintCount,
            "NFTMarketplace: africaprint doesn't exist"
        );
        require(msg.value == africaPrint.price,
            "NFTMarketplace: You need to match the selling price"
        );
        require(!africaPrint.sold, "NFTMarketplace: africaprint already sold");
        require(africaPrint.seller != msg.sender, "You can't buy your own africaprint");
        address payable seller = africaPrint.seller;

        africaPrint.seller = payable(msg.sender);
        africaPrint.sold = true;
        africaPrint.nft.safeTransferFrom(address(this), msg.sender, africaPrint.tokenId);
        (bool success,) = seller.call{value: msg.value}("");
        require(success, "Transfer of payment to seller failed");
        require(africaPrint.nft.ownerOf(africaPrint.tokenId) == msg.sender, "Transfer of NFT to buyer failed");
    }

    // this function will get a africaprint listing from the mapping list
    function getAfricaPrint(uint256 _index) public view returns (AfricaPrint memory) {
        return africaPrints[_index];
    }

    //Function using which the platform owner can flag a africa print
    function toggleFlag(uint256 _index) public {
        require(msg.sender == ownerAddress,"Only the owner can access this function");
        africaPrints[_index].flagged = !africaPrints[_index].flagged;
    }

    // this function will set the africaprint listing to not for sale and only the owner can do that
    function toggleForSale(uint256 _index) public notFlagged(_index) onlySeller(_index) {
        // if token's forSale is false make it true and vice versa
        africaPrints[_index].forSale = !africaPrints[_index].forSale;
    }

    function rateAfricaPrint(uint256 _index, uint256 _rating) public notFlagged(_index){
        AfricaPrint memory africaPrint = africaPrints[_index];

        africaPrint.totalRating += _rating;
        africaPrint.numOfRaters++;

        africaPrint.avgRating = africaPrint.totalRating / africaPrint.numOfRaters;
    }

    // this function will facilitate the changing of the price of a africaprint by the owner
    function modifyAfricaPrintPrice(uint256 _africaPrintPrice, uint256 _index)
    public
    notFlagged(_index)
    onlySeller(_index)
    payable
    {
        require(_africaPrintPrice > 0, "Enter a valid new price");
        africaPrints[_index].price = _africaPrintPrice;
    }

    //Override function
    function onERC721Received( address operator, address from, uint256 tokenId, bytes calldata data ) public override returns (bytes4) {
        return this.onERC721Received.selector;
    }
    
}