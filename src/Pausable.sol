// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Pausable {
    bool internal _paused;
    
    event Paused(address account);
    event Unpaused(address account);

    error EnforcedPause();
    error ExpectedPause();

    constructor() {
        _paused = false;
    }

    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    modifier whenPaused() {
        _requirePaused;
        _;
    }
    
    function _requireNotPaused() internal view {
        if (_paused) {
            revert EnforcedPause();
        }
    }
    
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    function _requirePaused() internal view {
        if (!_paused) {
            revert ExpectedPause();
        }
    }

    function pause() public virtual whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    function unpause() public virtual whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}