// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/test.sol";
import "../src/DutchAuction.sol";

contract DutchAuctionTest is Test {
    DutchAuction auction;
    address alice = vm.addr(1);
    address owner = vm.addr(2);

    function setUp() public {
        vm.prank(owner);
        auction = new DutchAuction();
    }

    // setAuctionStartTime
    function testSetAuctionStartTime() public {
        assertNotEq(auction.auctionStartTime(), block.timestamp);
        _setAuctionStartTimeToNow();
        assertEq(auction.auctionStartTime(), block.timestamp);
    }

    // getAuctionPrice
    function testGetAuctionPriceBeforeAuctionStart() public {
        _setAuctionStartTimeToNow();

        assertEq(auction.getAuctionPrice(), auction.AUCTION_STARTING_PRICE());
    }

    function testGetAuctionPriceDuringAuction() public {
        _setAuctionStartTimeToNow();

        uint256 duration = 5 * auction.AUCTION_DROP_INTERVAL();
        vm.warp(auction.auctionStartTime() + duration);
        assertEq(
            auction.getAuctionPrice(),
            auction.AUCTION_STARTING_PRICE() - 5 * auction.AUCTION_DROP_STEP()
        );
    }

    // auctionMint
    function testCanNotMintBeforeAuctionStart() public {
        uint256 currentPrice = auction.getAuctionPrice();
        vm.prank(alice);
        vm.deal(alice, currentPrice);
        vm.expectRevert(bytes("DutchAuction: AUCTION_NOT_STARTED"));
        auction.auctionMint{value: currentPrice}();
    }

    function testCanNotMintIfNoTokenLeft() public {
        _setAuctionStartTimeToNow();

        uint256 currentPrice = auction.getAuctionPrice();
        for (uint256 i = 0; i < auction.COLLECTION_SIZE(); i++) {
            address somebody = vm.addr(i + 100);
            vm.prank(somebody);
            vm.deal(somebody, currentPrice);
            auction.auctionMint{value: currentPrice}();
        }

        vm.prank(alice);
        vm.deal(alice, currentPrice);
        vm.expectRevert(bytes("DutchAuction: NOT_ENOUGH_TOKENS"));
        auction.auctionMint{value: currentPrice}();
    }

    function testCanNotMintIfNotEnoughEth() public {
        _setAuctionStartTimeToNow();

        uint256 currentPrice = auction.getAuctionPrice();
        vm.prank(alice);
        vm.deal(alice, currentPrice);
        vm.expectRevert(bytes("DutchAuction: NOT_ENOUGH_ETH"));
        auction.auctionMint{value: currentPrice - 1}();
    }

    function testCanNotMintIfNotEnoughEthDuringAuction() public {
        _setAuctionStartTimeToNow();

        uint256 duration = 5 * auction.AUCTION_DROP_INTERVAL();
        vm.warp(auction.auctionStartTime() + duration);

        uint256 currentPrice = auction.getAuctionPrice();
        vm.prank(alice);
        vm.deal(alice, currentPrice);
        vm.expectRevert(bytes("DutchAuction: NOT_ENOUGH_ETH"));
        auction.auctionMint{value: currentPrice - 1}();
    }

    function testCanMintAfterAuctionStart() public {
        _setAuctionStartTimeToNow();

        uint256 currentPrice = auction.getAuctionPrice();
        vm.prank(alice);
        vm.deal(alice, currentPrice);
        auction.auctionMint{value: currentPrice}();
        assertEq(auction.totalSupply(), 1);
        assertEq(auction.ownerOf(0), address(alice));
    }

    // withdrawMoney
    function testCanNotWithdrawMoneyIfNoMoney() public {
        vm.prank(owner);
        vm.expectRevert(bytes("DutchAuction: NO_MONEY_TO_WITHDRAW"));
        auction.withdrawMoney();
    }

    function testCanWithdrawMoney() public {
        _setAuctionStartTimeToNow();

        uint256 currentPrice = auction.getAuctionPrice();
        vm.prank(alice);
        vm.deal(alice, currentPrice);
        auction.auctionMint{value: currentPrice}();

        vm.prank(owner);
        auction.withdrawMoney();
        assertEq(address(owner).balance, currentPrice);
    }

    function _setAuctionStartTimeToNow() private {
        vm.prank(owner);
        auction.setAuctionStartTime(block.timestamp);
    }
}
