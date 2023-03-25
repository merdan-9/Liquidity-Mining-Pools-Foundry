// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.4;

/// @title Multicall
/// @notice Enables calling multiple methods in a single call

abstract contract Multicall {
    function multicall(bytes[] calldata data) external payable returns (bytes[] memory results) {
        uint len = data.length;
        results = new bytes[](len);
        for (uint i = 0; i < len; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);
            
            if (!success) {
                // Next 5 lines from https://ethereum.stackexchange.com/a/83577
                if (result.length < 68) revert();
                assembly {
                    result := add(result, 0x04)
                }
                revert(abi.decode(result, (string)));
            }
            results[i] = result;
        }
    }
}