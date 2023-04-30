// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;

import "forge-std/console.sol";

contract WhitelistProxy {
    bytes32 private constant IMPLEMENTATION_SLOT = 0x7050c9e0f4ca769c69bd3a8ef740bc37934f8e2c036e5a723fd8ee048ed3f8c3;
    bytes32 private constant ADMIN_SLOT = 0x10d6a54a4754c8869d6886b5f5d7fbfa5b4522237ea5c60d11bc4e7a1ff9390b;

    // keccak256("WHITELIST_STORAGE_POSITION")
    bytes32 private constant WHITELIST_STORAGE_POSITION =
        0x4fadd3ec89648dd73ebdf9c5da76fef8f1d9346b491ca302b261c0233b08519f;

    struct WhitelistStorage {
        bool initiailized;
        address whitelister;
        mapping(address => bool) whitelists;
    }

    // The function name cannot be initialize, or else the proxy cannot fallback to logic's initialize();
    function initializeWhitelistProxy(address whitelister) external {
        require(!whitelistStorage().initiailized, "Already initialized.");
        require(whitelister != _getSlotToAddress(ADMIN_SLOT), "Proxy admin cannot fallback to set whitelists");
        whitelistStorage().initiailized = true;
        whitelistStorage().whitelister = whitelister;
    }

    function whitelistStorage() internal pure returns (WhitelistStorage storage ds) {
        bytes32 position = WHITELIST_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function addWhitelist(address addr) external {
        require(msg.sender == whitelistStorage().whitelister);
        whitelistStorage().whitelists[addr] = true;
    }

    function removeWhitelist(address addr) external {
        require(msg.sender == whitelistStorage().whitelister);
        whitelistStorage().whitelists[addr] = false;
    }

    function changeWhitelister(address newWhitelister) external {
        require(newWhitelister != address(0), "Whitelister cannot be zero address.");
        whitelistStorage().whitelister = newWhitelister;
    }

    function isWhitelisted(address addr) external view returns (bool) {
        return whitelistStorage().whitelists[addr];
    }

    fallback() external payable virtual {
        require(whitelistStorage().whitelists[msg.sender], "You are not invited.");
        // 0xa2327a938Febf5FEC13baCFb16Ae10EcBc4cbDCF is the address of logic contract.
        // Not sure why _getSlotToAddress(IMPLEMENTATION_SLOT) != 0xa2327a938Febf5FEC13baCFb16Ae10EcBc4cbDCF
        // To be investigated
        // _delegate(_getSlotToAddress(IMPLEMENTATION_SLOT));
        _delegate(0xa2327a938Febf5FEC13baCFb16Ae10EcBc4cbDCF);
    }

    receive() external payable {
        revert("This is a proxy contract.");
    }

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
