// SPDX-License-Identifier: MIT
pragma solidity 0.8.26; 

import {Test} from "forge-std/Test.sol";
import {Deployers} from "@uniswap/v4-core/test/utils/Deployers.sol";
import {MockERC20} from "solmate/src/test/utils/mocks/MockERC20.sol";
import {PoolManager} from "v4-core/PoolManager.sol";
import {Currency, CurrencyLibrary} from "v4-core/types/Currency.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {Hooks} from "v4-core/libraries/Hooks.sol";
import {PoolSwapTest} from "v4-core/test/PoolSwapTest.sol";
import {TickMath} from "v4-core/libraries/TickMath.sol";
import {console} from "forge-std/console.sol";
import {VipSwap} from "src/VipSwap.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {MockNFT} from "src/MockNFT.sol";

contract VipSwapTest is Test, Deployers{

    using CurrencyLibrary for Currency;

    address[] addresses;
    VipSwap hook;
    MockNFT nft;

    function setUp() external {
        
        deployFreshManagerAndRouters();
        deployMintAndApprove2Currencies();
        
        nft = new MockNFT("NFT", "NFT");
        nft.mint();
        addresses = [address(nft), address(1)];
        address hookAddress = address(uint160(Hooks.BEFORE_SWAP_FLAG));
        deployCodeTo(
            "VipSwap.sol",
            abi.encode(manager, addresses),
            hookAddress
        );

        hook = VipSwap(hookAddress);

        (key, ) = initPool(currency0, currency1, hook, 1000, SQRT_PRICE_1_1);

        modifyLiquidityRouter.modifyLiquidity(
            key,
            IPoolManager.ModifyLiquidityParams({
                tickLower: -60, 
                tickUpper: 60,
                liquidityDelta: 100 ether,
                salt: bytes32(0)
            }),
            ZERO_BYTES
        );

    }

    // function test_cant_swap_if_not_owner_of_vip_collection() external {
       
    //     PoolSwapTest.TestSettings memory testSettings = PoolSwapTest.TestSettings({
    //         takeClaims: false, settleUsingBurn: false
    //     });

    //     IPoolManager.SwapParams memory params = IPoolManager.SwapParams({
    //         zeroForOne: true, 
    //         amountSpecified: -0.0001 ether,
    //         sqrtPriceLimitX96: TickMath.MIN_SQRT_PRICE + 1
    //     });

    //     bytes memory hookData = hook.getHookData(address(0), 0);
    //     vm.prank(address(1));

    //     vm.expectRevert();
    //     swapRouter.swap(key, params, testSettings, hookData);

    // }

    function test_can_swap_if_is_owner_of_vip_collection() external {
        
        PoolSwapTest.TestSettings memory testSettings = PoolSwapTest.TestSettings({
            takeClaims: false, settleUsingBurn: false
        });

        IPoolManager.SwapParams memory params = IPoolManager.SwapParams({
            zeroForOne: true, 
            amountSpecified: -0.0001 ether,
            sqrtPriceLimitX96: TickMath.MIN_SQRT_PRICE + 1
        });

        bytes memory hookData = hook.getHookData(address(nft), 1);

        console.log("Is vip? : ", hook.isVip(address(nft)));
        console.log("is owner of token id 2? : ", nft.ownerOf(1));
        console.log("msg.sender : ", msg.sender);
        console.log("address this: ", address(this));
        console.log("swap router: ", address(swapRouter));
        
        uint256 balanceBeforeSwap = currency1.balanceOfSelf();
        swapRouter.swap(key, params, testSettings, hookData);
        uint256 balanceAfterSwap = currency1.balanceOfSelf();
        assertGt(balanceAfterSwap, balanceBeforeSwap);
        
    }

}