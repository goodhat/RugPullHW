// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "solmate/tokens/ERC20.sol";
import {MyUSDC} from "../src/myUSDC.sol";

interface Proxy {
    function upgradeToAndCall(address newImplementation, bytes calldata data) external;
}

contract MyUSDCTest is Test {
    // Owner and users
    address owner = makeAddr("owner");
    address whitelister = makeAddr("whitelister");
    address nobody = makeAddr("nobody");
    address user1 = makeAddr("user1");
    address user2 = makeAddr("user2");
    address admin;

    string MAINNET_RPC_URL;
    bytes32 ADMIN_SLOT;
    address USDC;
    MyUSDC myUSDC;

    uint256 userInitialBalance = 1000;

    function setUp() public {
        MAINNET_RPC_URL = vm.envString("MAINNET_RPC_URL");
        USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
        ADMIN_SLOT = 0x10d6a54a4754c8869d6886b5f5d7fbfa5b4522237ea5c60d11bc4e7a1ff9390b;

        // fork mainnet
        uint256 mainnetFork = vm.createFork(MAINNET_RPC_URL);
        vm.selectFork(mainnetFork);
        vm.rollFork(17145000);

        // get USDC admin: 0x807a96288A1A408dBC13DE2b1d087d10356395d2
        admin = bytes32ToAddress(vm.load(USDC, ADMIN_SLOT));

        deal(USDC, user1, userInitialBalance);
        deal(USDC, user2, userInitialBalance);

        // Upgrade proxy
        myUSDC = new MyUSDC();
        vm.prank(admin);
        Proxy(USDC).upgradeToAndCall(
            address(myUSDC),
            abi.encodeCall(MyUSDC.initialize, ("MyUSDC", "MYUSDC", nobody, nobody, nobody, whitelister, owner))
        );
        assertEq(MyUSDC(USDC).whitelister(), whitelister);
        vm.prank(whitelister);
        MyUSDC(USDC).whitelist(user1);
    }

    function testNormalUserCannotDoAnything() public {
        vm.startPrank(user2);
        vm.expectRevert("Whitelistable: caller is not whitelisted");
        MyUSDC(USDC).transfer(user2, 50);

        vm.expectRevert("Whitelistable: caller is not whitelisted");
        MyUSDC(USDC).transferFrom(user1, user2, 50);

        vm.expectRevert("Whitelistable: caller is not whitelisted");
        MyUSDC(USDC).mint(user2, 50);

        vm.expectRevert("Whitelistable: caller is not whitelisted");
        MyUSDC(USDC).burn(50);
    }

    function testWhitelistUserCanTransfer() public {
        vm.prank(user1);
        ERC20(USDC).transfer(user2, 50);
        assertEq(ERC20(USDC).balanceOf(user1), userInitialBalance - 50);
        assertEq(ERC20(USDC).balanceOf(user2), userInitialBalance + 50);
    }

    function testWhitelistUserCanMintToken() public {
        vm.prank(user1);
        MyUSDC(USDC).mint(user2, 50);
    }

    function bytes32ToAddress(bytes32 _bytes32) private pure returns (address) {
        return address(uint160(uint256(_bytes32)));
    }
}
