// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;

import "forge-std/console.sol";

// This file was the original attempt of WhitelistProxy.sol.
contract WhiteListGuard {
    bytes32 private constant IMPLEMENTATION_SLOT = 0x7050c9e0f4ca769c69bd3a8ef740bc37934f8e2c036e5a723fd8ee048ed3f8c3;
    bytes32 private constant ADMIN_SLOT = 0x10d6a54a4754c8869d6886b5f5d7fbfa5b4522237ea5c60d11bc4e7a1ff9390b;
    mapping(address => bool) whiteLists;
    // bool initiailized = false;

    function initializeWhiteListGuard(address wlAdmin) external {
        // The function name cannot be initialize,
        // or the proxy cannot fallback to logic's initialize();
        // require(!initiailized, "Already initialized.");
        require(wlAdmin != _getSlotToAddress(ADMIN_SLOT), "Admin cannot fallback.");
        assembly {
            // keccak256("WHITE_LIST_ADMIN_SLOT");
            sstore(0xfceb218fe7ebc64d23dc5044d8de1c1547a7ba3e8f55bb814071240be35fd94b, wlAdmin)
        }
        // wlAdmin != admin
        // I found this is a bad practice :/
        // Should just write a contract that inherit the old one, and override some funciton
        // Btw, I can try to put this storage like in diamond.
    }

    function addWhiteList(address addr) external {
        require(msg.sender == _getSlotToAddress(0xfceb218fe7ebc64d23dc5044d8de1c1547a7ba3e8f55bb814071240be35fd94b));
        whiteLists[addr] = true;
    }

    function removeWhiteList(address addr) external {
        require(msg.sender == _getSlotToAddress(0xfceb218fe7ebc64d23dc5044d8de1c1547a7ba3e8f55bb814071240be35fd94b));
        whiteLists[addr] = true;
    }

    function isWhiteListed(address addr) external view returns (bool) {
        return whiteLists[addr];
    }

    fallback() external payable virtual {
        require(whiteLists[msg.sender], "You are not invited.");
        // console.log(_getSlotToAddress(IMPLEMENTATION_SLOT));
        // _delegate(_getSlotToAddress(IMPLEMENTATION_SLOT));
        _delegate(0xa2327a938Febf5FEC13baCFb16Ae10EcBc4cbDCF);
    }

    receive() external payable {}

    function _getSlotToAddress(bytes32 _slot) internal view returns (address value) {
        assembly {
            value := sload(_slot)
        }
    }

    function _delegate(address _implementation) internal virtual {
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), _implementation, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
}
