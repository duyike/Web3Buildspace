// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./token.sol";
import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract TokenExchange is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint;

    string public exchange_name = "DETH/ETH Exchange";

    address tokenAddr = 0x5FbDB2315678afecb367f032d93F642f64180aa3;
    IERC20 public token = IERC20(tokenAddr);

    // Liquidity pool for the exchange
    uint private token_reserves = 0;
    uint private eth_reserves = 0;

    mapping(address => uint) private lps;
    uint private lp_prop_denominator = 1000000000;

    // Needed for looping through the keys of the lps mapping
    address[] private lp_providers;

    // liquidity rewards
    uint private swap_fee_numerator = 3;
    uint private swap_fee_denominator = 100;

    // Constant: x * y = k
    uint private k;

    uint private rate_denominator = 1000;

    constructor() {}

    modifier exchangeRateLimit(uint max_exchange_rate, uint min_exchange_rate) {
        require(max_exchange_rate >= 0, "Invalid max exchange rate");
        require(min_exchange_rate >= 0, "Invalid min exchange rate");
        require(
            token_reserves * rate_denominator <=
                eth_reserves * max_exchange_rate,
            "Exchange rate is too high"
        );
        require(
            token_reserves * rate_denominator >=
                eth_reserves * min_exchange_rate,
            "Exchange rate is too low"
        );
        _;
    }

    // Function createPool: Initializes a liquidity pool between your Token and ETH.
    // ETH will be sent to pool in this transaction as msg.value
    // amountTokens specifies the amount of tokens to transfer from the liquidity provider.
    // Sets up the initial exchange rate for the pool by setting amount of token and amount of ETH.
    function createPool(uint amountTokens) external payable onlyOwner {
        // This function is already implemented for you; no changes needed.

        // require pool does not yet exist:
        require(token_reserves == 0, "Token reserves was not 0");
        require(eth_reserves == 0, "ETH reserves was not 0.");

        // require nonzero values were sent
        require(msg.value > 0, "Need eth to create pool.");
        uint tokenSupply = token.balanceOf(msg.sender);
        require(
            amountTokens <= tokenSupply,
            "Not have enough tokens to create the pool"
        );
        require(amountTokens > 0, "Need tokens to create pool.");

        token.safeTransferFrom(msg.sender, address(this), amountTokens);

        token_reserves = token.balanceOf(address(this));
        eth_reserves = msg.value;
        k = token_reserves * eth_reserves;
    }

    // Function removeLP: removes a liquidity provider from the list.
    // This function also removes the gap left over from simply running "delete".
    function removeLP(uint index) private {
        require(
            index < lp_providers.length,
            "specified index is larger than the number of lps"
        );
        lp_providers[index] = lp_providers[lp_providers.length - 1];
        lp_providers.pop();
    }

    // Function getSwapFee: Returns the current swap fee ratio to the client.
    function getSwapFee() public view returns (uint, uint) {
        return (swap_fee_numerator, swap_fee_denominator);
    }

    // ============================================================
    //                    FUNCTIONS TO IMPLEMENT
    // ============================================================

    /* ========================= Liquidity Provider Functions =========================  */

    // Function addLiquidity: Adds liquidity given a supply of ETH (sent to the contract as msg.value).
    // You can change the inputs, or the scope of your function, as needed.
    function addLiquidity(
        uint max_exchange_rate,
        uint min_exchange_rate
    ) external payable exchangeRateLimit(max_exchange_rate, min_exchange_rate) {
        require(msg.value > 0, "Need eth to add liquidity.");
        uint amountToken = (msg.value * token_reserves) / eth_reserves;
        uint tokenBalance = token.balanceOf(msg.sender);
        require(
            amountToken <= tokenBalance,
            "Not have enough tokens to add liquidity"
        );

        token.safeTransferFrom(msg.sender, address(this), amountToken);

        eth_reserves += msg.value;
        token_reserves = token.balanceOf(address(this));
        k = token_reserves * eth_reserves;

        if (lps[msg.sender] == 0) {
            lp_providers.push(msg.sender);
        }
        lps[msg.sender] += (msg.value * lp_prop_denominator) / eth_reserves;
    }

    // Function removeLiquidity: Removes liquidity given the desired amount of ETH to remove.
    // You can change the inputs, or the scope of your function, as needed.
    function removeLiquidity(
        uint amountETH,
        uint max_exchange_rate,
        uint min_exchange_rate
    ) public payable exchangeRateLimit(max_exchange_rate, min_exchange_rate) {
        require(amountETH > 0, "Need eth to remove liquidity.");
        require(
            amountETH * lp_prop_denominator <= lps[msg.sender] * eth_reserves,
            "Not have enough liquidity to remove"
        );

        uint amountToken = (amountETH * token_reserves) / eth_reserves;
        token.safeTransfer(msg.sender, amountToken);
        bool sent = payable(msg.sender).send(amountETH);
        require(sent, "Failed to send ETH");

        uint oldEthReserves = eth_reserves;
        eth_reserves -= amountETH;
        token_reserves = token.balanceOf(address(this));
        k = token_reserves * eth_reserves;

        uint senderIndex;
        for (uint i = 0; i < lp_providers.length; i++) {
            address provider = lp_providers[i];
            if (provider == msg.sender) {
                senderIndex = i;
                lps[provider] =
                    (lps[provider] *
                        eth_reserves -
                        amountETH *
                        lp_prop_denominator) /
                    (eth_reserves - amountETH);
            } else {
                lps[provider] = (lps[provider] * oldEthReserves) / eth_reserves;
            }
        }
        if (lps[msg.sender] == 0) {
            removeLP(senderIndex);
        }
    }

    // Function removeAllLiquidity: Removes all liquidity that msg.sender is entitled to withdraw
    // You can change the inputs, or the scope of your function, as needed.
    function removeAllLiquidity(
        uint max_exchange_rate,
        uint min_exchange_rate
    ) external payable exchangeRateLimit(max_exchange_rate, min_exchange_rate) {
        require(lps[msg.sender] > 0, "Not have any liquidity to remove");

        uint amountETH = (lps[msg.sender] * eth_reserves) / lp_prop_denominator;
        uint amountToken = (amountETH * token_reserves) / eth_reserves;
        token.safeTransfer(msg.sender, amountToken);
        bool sent = payable(msg.sender).send(amountETH);
        require(sent, "Failed to send ETH");

        uint oldEthReserves = eth_reserves;
        eth_reserves -= amountETH;
        token_reserves = token.balanceOf(address(this));
        k = token_reserves * eth_reserves;

        uint senderIndex;
        for (uint i = 0; i < lp_providers.length; i++) {
            address provider = lp_providers[i];
            if (provider == msg.sender) {
                senderIndex = i;
                delete lps[provider];
            } else {
                lps[provider] = (lps[provider] * oldEthReserves) / eth_reserves;
            }
        }
        removeLP(senderIndex);
    }

    function addressLiquidity(address addr) public view returns (uint) {
        return lps[addr];
    }

    /***  Define additional functions for liquidity fees here as needed ***/

    /* ========================= Swap Functions =========================  */

    // Function swapTokensForETH: Swaps your token with ETH
    // You can change the inputs, or the scope of your function, as needed.
    function swapTokensForETH(
        uint amountTokens,
        uint max_exchange_rate
    ) external payable exchangeRateLimit(max_exchange_rate, 0) {
        require(amountTokens > 0, "Need tokens to swap.");
        require(
            amountTokens <= token.balanceOf(msg.sender),
            "Not have enough tokens to swap"
        );
        require(max_exchange_rate >= 0, "Invalid max exchange rate");
        require(
            token_reserves * rate_denominator <=
                eth_reserves * max_exchange_rate,
            "Exchange rate is too high"
        );

        uint amountETH = eth_reserves - k / (token_reserves + amountTokens);
        // k will now slightly change on every swap. Ignore this for now.
        uint fee = (amountETH * swap_fee_numerator) / swap_fee_denominator;
        amountETH -= fee;

        token.safeTransferFrom(msg.sender, address(this), amountTokens);
        bool sent = payable(msg.sender).send(amountETH);
        require(sent, "Failed to send ETH");

        eth_reserves -= amountETH;
        token_reserves = token.balanceOf(address(this));
    }

    // Function swapETHForTokens: Swaps ETH for your tokens
    // ETH is sent to contract as msg.value
    // You can change the inputs, or the scope of your function, as needed.
    function swapETHForTokens(uint max_exchange_rate) external payable {
        require(msg.value > 0, "Need eth to swap.");
        require(max_exchange_rate >= 0, "Invalid max exchange rate");
        require(
            eth_reserves * rate_denominator <=
                token_reserves * max_exchange_rate,
            "Exchange rate is too high"
        );

        uint amountTokens = token_reserves - k / (eth_reserves + msg.value);
        // k will now slightly change on every swap. Ignore this for now.
        uint fee = (amountTokens * swap_fee_numerator) / swap_fee_denominator;
        amountTokens -= fee;

        token.safeTransfer(msg.sender, amountTokens);

        eth_reserves += msg.value;
        token_reserves = token.balanceOf(address(this));
    }
}
