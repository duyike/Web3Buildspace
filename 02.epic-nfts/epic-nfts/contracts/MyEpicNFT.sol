//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "hardhat/console.sol";

contract MyEpicNFT is ERC721URIStorage {
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  constructor() ERC721("SquareNFT", "SQUARE") {
    console.log("This is my nft!");
  }

  function makeAnEpicNFT() public {
    uint256 newItemId = _tokenIds.current();
    _safeMint(msg.sender, newItemId);
    _setTokenURI(
      newItemId,
      "data:application/json;base64,eyJuYW1lIjoibWVtZSBtYW4iLCJkZXNjcmlwdGlvbiI6Ik1lbWUgTWFuIHJlZmVycyB0byBhIGdyZXkgM0QgcmVuZGVyaW5nIG9mIGEgaHVtYW4gaGVhZCB3aGljaCBmdW5jdGlvbnMgYXMgdGhlIG1hc2NvdCBmb3IgdGhlIEZhY2Vib29rIHBhZ2UgJ1NwZWNpYWwgbWVtZSBmcmVzaCcuIFRoZSBoZWFkIGlzIGZyZXF1ZW50bHkgdXNlZCBpbiBhYnN1cmQgZWRpdHMsIHN1cnJlYWwgbWVtZXMgYW5kIHNoaXRwb3N0aW5nLiIsImltYWdlIjoiZGF0YTppbWFnZS9zdmcreG1sO2Jhc2U2NCxQSE4yWnlCNGJXeHVjejBpYUhSMGNEb3ZMM2QzZHk1M015NXZjbWN2TWpBd01DOXpkbWNpSUhCeVpYTmxjblpsUVhOd1pXTjBVbUYwYVc4OUluaE5hVzVaVFdsdUlHMWxaWFFpSUhacFpYZENiM2c5SWpBZ01DQXpOVEFnTXpVd0lqNEtJQ0FnSUR4emRIbHNaVDR1WW1GelpTQjdJR1pwYkd3NklIZG9hWFJsT3lCbWIyNTBMV1poYldsc2VUb2djMlZ5YVdZN0lHWnZiblF0YzJsNlpUb2dNVFJ3ZURzZ2ZUd3ZjM1I1YkdVK0NpQWdJQ0E4Y21WamRDQjNhV1IwYUQwaU1UQXdKU0lnYUdWcFoyaDBQU0l4TURBbElpQm1hV3hzUFNKaWJHRmpheUlnTHo0S0lDQWdJRHgwWlhoMElIZzlJalV3SlNJZ2VUMGlOVEFsSWlCamJHRnpjejBpWW1GelpTSWdaRzl0YVc1aGJuUXRZbUZ6Wld4cGJtVTlJbTFwWkdSc1pTSWdkR1Y0ZEMxaGJtTm9iM0k5SW0xcFpHUnNaU0krUlhCcFkwMWxiV1ZOWVc0OEwzUmxlSFErQ2p3dmMzWm5QZ289In0="
    );
    _tokenIds.increment();
    console.log("An NFT w/ ID %s has been minted to %s", newItemId, msg.sender);
  }
}
