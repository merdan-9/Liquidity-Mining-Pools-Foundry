// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.4;

contract Ownable {
    error Ownable_NotOwner();
    error Ownable_NewOwnerZeroAddress();

    address private _owner;

    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);
    
    /// @dev Returns the address of the current owner.
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /// @dev Throws an error if called by any account other than the owner.
    modifier onlyOwner() {
        if (owner() != msg.sender) revert Ownable_NotOwner();
        _;
    }

    /// @dev Transfers ownership of the contract to a new account (newOwner).
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) revert Ownable_NewOwnerZeroAddress();
        _transferOwnership(newOwner);
    }

    /// @dev Internal function to transfer ownership of the contract to a new account (newOwner).
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}