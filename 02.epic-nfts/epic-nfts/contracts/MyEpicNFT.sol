//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "hardhat/console.sol";
import { Base64 } from "./libraries/Base64.sol";

contract MyEpicNFT is ERC721URIStorage {
  event NewEpicNFTMinted(address sender, uint256 tokenId);

  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  string baseSVG =
    "<svg xmlns='http://www.w3.org/2000/svg' preserveAspectRatio='xMinYMin meet' viewBox='0 0 350 350'><style>.base { fill: white; font-family: serif; font-size: 24px; }</style><rect width='100%' height='100%' fill='black' /><text x='50%' y='50%' class='base' dominant-baseline='middle' text-anchor='middle'>";

  string[] firstWords = [
    "Gael",
    "Elvira",
    "Janek",
    "Junia",
    "Joseito",
    "Larine"
  ];
  string[] secondWords = [
    "Amity",
    "Maure",
    "Brittaney",
    "Jarvis",
    "Deana",
    "Bertina"
  ];
  string[] thirdWords = [
    "Yettie",
    "Dian",
    "Melany",
    "Keelby",
    "Virgie",
    "Dewey"
  ];

  constructor() ERC721("SquareNFT", "SQUARE") {
    console.log("This is my nft!");
  }

  function makeAnEpicNFT() public {
    uint256 newItemId = _tokenIds.current();

    string memory firstWord = randomPick(newItemId, firstWords);
    string memory secondWord = randomPick(newItemId, secondWords);
    string memory thirdWord = randomPick(newItemId, thirdWords);
    string memory combinedWord = string(
      abi.encodePacked(firstWord, secondWord, thirdWord)
    );

    string memory finalSVG = string(
      abi.encodePacked(baseSVG, combinedWord, "</text></svg>")
    );
    console.log("\n--------------------");
    console.log(finalSVG);
    console.log("--------------------\n");

    string memory json = Base64.encode(
      abi.encodePacked(
        '{"name": "',
        // We set the title of our NFT as the generated word.
        combinedWord,
        '", "description": "A highly acclaimed collection of squares.", "image": "data:image/svg+xml;base64,',
        // We add data:image/svg+xml;base64 and then append our base64 encode our svg.
        Base64.encode(bytes(finalSVG)),
        '"}'
      )
    );
    string memory finalTokenId = string(
      abi.encodePacked("data:application/json;base64,", json)
    );
    console.log("\n--------------------");
    console.log(finalTokenId);
    console.log("--------------------\n");

    _safeMint(msg.sender, newItemId);
    _setTokenURI(newItemId, finalTokenId);
    _tokenIds.increment();
    emit NewEpicNFTMinted(msg.sender, newItemId);
    console.log("An NFT w/ ID %s has been minted to %s", newItemId, msg.sender);
  }

  function randomPick(uint256 tokenId, string[] memory words)
    public
    pure
    returns (string memory)
  {
    uint256 rand = random(abi.encodePacked("WORD", Strings.toString(tokenId)));
    uint256 index = rand % words.length;
    return words[index];
  }

  function random(bytes memory input) internal pure returns (uint256) {
    return uint256(keccak256(input));
  }
}
