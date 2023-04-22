// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DutchAuction is ERC721Enumerable, Ownable {
    // constants
    uint256 public constant COLLECTION_SIZE = 1000;
    uint256 public constant AUCTION_STARTING_PRICE = 1 ether;
    uint256 public constant AUCTION_ENDING_PRICE = 0.01 ether;
    uint256 public constant AUCTION_PRICE_CURVE_LENGTH = 1 hours;
    uint256 public constant AUCTION_DROP_INTERVAL = 1 minutes;
    uint256 public constant AUCTION_DROP_STEP =
        (AUCTION_STARTING_PRICE - AUCTION_ENDING_PRICE) /
            (AUCTION_PRICE_CURVE_LENGTH / AUCTION_DROP_INTERVAL);
    // state
    uint256 public auctionStartTime;

    constructor() ERC721("DutchAuction", "DA") {}

    function getAuctionPrice() public view returns (uint256) {
        if (auctionStartTime == 0 || block.timestamp < auctionStartTime) {
            return AUCTION_STARTING_PRICE;
        }
        uint256 timePassed = block.timestamp - auctionStartTime;
        uint256 currentPrice = AUCTION_STARTING_PRICE -
            ((AUCTION_DROP_STEP * timePassed) / AUCTION_DROP_INTERVAL);
        if (currentPrice < AUCTION_ENDING_PRICE) {
            currentPrice = AUCTION_ENDING_PRICE;
        }
        return currentPrice;
    }

    function auctionMint() external payable {
        require(
            auctionStartTime != 0 && block.timestamp >= auctionStartTime,
            "DutchAuction: AUCTION_NOT_STARTED"
        );
        require(
            totalSupply() + 1 <= COLLECTION_SIZE,
            "DutchAuction: NOT_ENOUGH_TOKENS"
        );
        require(msg.value >= getAuctionPrice(), "DutchAuction: NOT_ENOUGH_ETH");
        _safeMint(msg.sender, totalSupply());
    }

    function setAuctionStartTime(uint256 _auctionStartTime) external onlyOwner {
        auctionStartTime = _auctionStartTime;
    }

    function withdrawMoney() external onlyOwner {
        require(
            address(this).balance > 0,
            "DutchAuction: NO_MONEY_TO_WITHDRAW"
        );
        payable(owner()).transfer(address(this).balance);
    }
}
