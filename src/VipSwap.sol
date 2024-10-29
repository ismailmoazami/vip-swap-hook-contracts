// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseHook} from "v4-periphery/src/base/hooks/BaseHook.sol";

import {CurrencyLibrary, Currency} from "v4-core/types/Currency.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {BalanceDeltaLibrary, BalanceDelta} from "v4-core/types/BalanceDelta.sol";

import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";

import {Hooks} from "v4-core/libraries/Hooks.sol";
import {LPFeeLibrary} from "v4-core/libraries/LPFeeLibrary.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "v4-core/types/BeforeSwapDelta.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {console} from "forge-std/console.sol";
contract VipSwap is BaseHook {

    address owner;
    mapping(address => bool) public isVip;

    error MustBeOwnerOfVipCollection();
    error NotOwner();

    modifier onlyOwner() {
        if(msg.sender != owner){
            revert NotOwner();
        }
        _;
    }

    constructor(IPoolManager _manager, address[] memory _collections) BaseHook(_manager){
        owner = msg.sender;
        for(uint i=0; i < _collections.length; i++){
            require(_collections[i] != address(0), "Address Zero!");
            isVip[_collections[i]] = true;
        }
    }

    function getHookPermissions()
            public
            pure
            override
            returns (Hooks.Permissions memory)
        {
            return
                Hooks.Permissions({
                    beforeInitialize: false,
                    afterInitialize: false,
                    beforeAddLiquidity: false,
                    beforeRemoveLiquidity: false,
                    afterAddLiquidity: false,
                    afterRemoveLiquidity: false,
                    beforeSwap: true,
                    afterSwap: false,
                    beforeDonate: false,
                    afterDonate: false,
                    beforeSwapReturnDelta: false,
                    afterSwapReturnDelta: false,
                    afterAddLiquidityReturnDelta: false,
                    afterRemoveLiquidityReturnDelta: false
                });
        }

    function beforeSwap(address user, PoolKey calldata, IPoolManager.SwapParams calldata, bytes calldata hookData)
        external
        view
        override
        onlyPoolManager
        returns (bytes4, BeforeSwapDelta, uint24)
    {   
        console.log("User: ", user);
        
        (address collection, uint256 tokenId) = abi.decode(hookData, (address, uint256));
        if(!isVip[collection] || IERC721(collection).ownerOf(tokenId) != user){
            revert MustBeOwnerOfVipCollection();
        }

        return (this.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, 0);
    }

    function addCollection(address _collection) external onlyOwner{
        isVip[_collection] = true;
    }

    // View and Pure functions 
    function getHookData(address _collection, uint256 _tokenId) public pure returns(bytes memory) {
        return abi.encode(_collection, _tokenId);
    }

}