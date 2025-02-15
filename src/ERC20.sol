// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Pausable.sol";
import "forge-std/console.sol";

contract ERC20 is Pausable {

    mapping(address account => uint256) private _balances;
    mapping(address account => mapping(address spender => uint256)) private _allowances;
    mapping(address account => uint256) private _nonces;

    uint256 private _totalSupply;
    uint256 private current_nonce;

    string private _name;
    string private _symbol;
    address public owner;

    event Transfer(address indexed from, address to, uint256 value);
    event Approval(address indexed from, address to, uint256 value);

    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        owner = msg.sender;

        mint(msg.sender, 100 ether);
    }

    modifier isPaused() {
        require(_paused != true, "Account is Paused");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    modifier checkBalance(uint256 value) {
        require(_balances[msg.sender] >= value, "Not Sufficient Balances");
        _;
    }


    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return 18;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 value) public checkBalance(value) isPaused returns (bool) {
        _balances[msg.sender] -= value;
        _balances[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function allowance(address _owner, address spender) public view returns (uint256) {
        return _allowances[_owner][spender];
    }

    function approve(address spender, uint256 value) public checkBalance(value) isPaused returns (bool) {
        _allowances[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
    }

    function transferFrom (
        address from, 
        address to, 
        uint256 value) public isPaused returns (bool) {

        require(_balances[from] >= value, "Not Sufficient Balance");
        require(_allowances[from][to] >= value, "Not Allowed value");

        _balances[from] -= value;
        _balances[to] += value;
        emit Transfer(from, to, value);
    }

    function mint(address account, uint256 value) public onlyOwner {
        _balances[account] += value;
        _totalSupply += value;
    }

    function burn(address to, uint256 value) public onlyOwner {
        _balances[to] -= value;
        _totalSupply -= value;
    }

    function burnByUser(uint256 value) public {
        transfer(address(0), value);
        _totalSupply -= value;
    }

    function pause() public override onlyOwner{
        _paused = true;
        emit Paused(msg.sender);
    }
    function _toTypedDataHash(bytes32 structHash) public pure returns (bytes32 digest) {
        assembly ("memory-safe") {
            let ptr := mload(0x40)
            mstore(ptr, hex"19_01")
            // mstore(add(ptr, 0x02), domainSeparator)
            mstore(add(ptr, 0x02), structHash)
            digest := keccak256(ptr, 0x22)
        }

    }

    function permit(
        address _owner, 
        address spender, 
        uint256 value, 
        uint256 deadline, 
        uint8 v,
        bytes32 r,
        bytes32 s) 
        public {
        
        current_nonce = _nonces[_owner];

        bytes32 hash = keccak256(abi.encode(
            keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"), 
            _owner, 
            spender, 
            value, 
            current_nonce, 
            deadline
            ));
        bytes32 digest = _toTypedDataHash(hash);
        address recoveredSigner = ecrecover(digest, v, r, s);

        if (recoveredSigner != _owner) {
            revert("INVALID_SIGNER");
        }

        if (block.timestamp > deadline) {
            revert("Not matched deadline");
        }

        _allowances[_owner][spender] = value;
        _nonces[_owner] += 1;

    }

    function nonces(address _owner) public view returns (uint256) {
        
        return _nonces[_owner];
    }
}