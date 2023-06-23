// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// Import OpenZeppelin contracts
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NFTMarketplace is ERC721URIStorage {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;
    Counters.Counter private _itemsSold;

    address payable owner;
    uint256 listingPrice = 0.001 ether;

    mapping (uint256=>MarketItem) marketItemIds;

    struct MarketItem {
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }

    event MarketItemCreated (
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sold
    );

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner of the marketplace can call this function.");
        _;
    }

    constructor() ERC721("NFT Hypno Token", "NFTHTK") {
        owner = payable(msg.sender);
    }

    // List NFT for sale
    function createMarketItem(uint tokenId, uint _price) private {
        require(_price>0, "Price must be greater than 0.");
        require(msg.value == listingPrice, "Price must be equal to listing price.");

        marketItemIds[tokenId] = MarketItem(
            tokenId,
            payable(msg.sender),
            payable(address(this)),
            _price,
            false
        );

        _transfer(msg.sender, address(this), tokenId);
        emit MarketItemCreated(tokenId, msg.sender, address(this), _price, false);
    }

    // Update listing price
    function updateListingPrice(uint256 _price) public payable onlyOwner {
        listingPrice = _price;
    }

    // Get listing price
    function getListingPrice() public view returns (uint256) {
        return listingPrice;
    }

    // Create/Mint NFT
    function createToken(string memory _tokenURI, uint _price) public payable returns (uint256) {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();

        _mint(msg.sender, newItemId);
        _setTokenURI(newItemId, _tokenURI);

        createMarketItem(newItemId, _price);

        return newItemId;
    }

    // Resell token one holds
    function tokenResale(uint _tokenId, uint _price) public payable {
        require(_price>0, "Price must be greater than 0.");
        require(msg.value == listingPrice, "Price must be equal to listing price.");

        MarketItem memory item = marketItemIds[_tokenId];
        require(item.owner == msg.sender, "Only owner of the token can resale it.");

        item.price = _price;
        item.sold = false;
        item.seller = payable(msg.sender);
        item.owner = payable(address(this));
        marketItemIds[_tokenId] = item;

        _itemsSold.decrement();
        _transfer(msg.sender, address(this), _tokenId);
    }

    // Token sale in marketplace
    function createMarketSale(uint tokenId) public payable {
        uint price = marketItemIds[tokenId].price;
        require(msg.value == price, "Price must be equal to the asking price of the token.");

        marketItemIds[tokenId].owner = payable(msg.sender);
        marketItemIds[tokenId].sold = true;

        _itemsSold.increment();

        _transfer(address(this), msg.sender, tokenId);
        payable(owner).transfer(listingPrice);
        payable(marketItemIds[tokenId].seller).transfer(msg.value);
    }

    // Fetch all items held by contract
    function fetchMarketItems() public view returns(MarketItem[] memory) {
        uint itemCount = _tokenIds.current();
        uint unsoldItemCount = _tokenIds.current() - _itemsSold.current();
        uint currentIndex = 0;

        MarketItem[] memory items = new MarketItem[](unsoldItemCount);
        for(uint i=0;i<itemCount;i++) {
            if(marketItemIds[i+1].owner == address(this)) {
                uint currentId = marketItemIds[i+1].tokenId;
                MarketItem storage currentItem = marketItemIds[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    // Fetch all items owned by user
    function fetchMyNFT() public view returns(MarketItem[] memory) {
        uint totCount = _tokenIds.current();
        uint myItemCount = 0;
        uint currentIndex = 0;

        for(uint i=0;i<totCount;i++) {
            if(marketItemIds[i+1].owner == msg.sender) {
                myItemCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](myItemCount);

        for(uint i=0;i<totCount;i++) {
            if(marketItemIds[i+1].owner == msg.sender) {
                uint currentId = marketItemIds[i+1].tokenId;
                MarketItem storage currentItem = marketItemIds[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    // Fetch all items listed for sale by user
    function fetchItemsListed() public view returns(MarketItem[] memory) {
        uint totCount = _tokenIds.current();
        uint myItemCount = 0;
        uint currentIndex = 0;

        for(uint i=0;i<totCount;i++) {
            if(marketItemIds[i+1].seller == msg.sender) {
                myItemCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](myItemCount);

        for(uint i=0;i<totCount;i++) {
            if(marketItemIds[i+1].seller == msg.sender) {
                uint currentId = marketItemIds[i+1].tokenId;
                MarketItem storage currentItem = marketItemIds[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }
}