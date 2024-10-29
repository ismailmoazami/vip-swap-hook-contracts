// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract MockNFT is ERC721 {
    uint256 totalSupply;
    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
        mint();
    }

    function mint() public {
        _mint(msg.sender, totalSupply);
        totalSupply++;
    }

}