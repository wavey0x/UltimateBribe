// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ConvexVoter {
    function owner() external view returns (address);
}
contract UltimateBribe {

    event Bribed(address indexed briber, address indexed token, uint amount);
    event BribeRetracted(address indexed briber, address indexed token, uint amount);
    event BribeAccepted(address indexed briber, address indexed token, uint amount);

    bool accepted;
    address originalOwner;
    ConvexVoter constant voter = ConvexVoter(0x989AEb4d175e16225E39E87d0D97A3360524AD80);
    // briber -> token -> amount
    mapping (address => mapping (address => uint)) public bribe;

    constructor () {
        originalOwner = voter.owner();
    }

    function addBribe(address _token, uint _amount) external {
        require(!accepted, "Already accepted bribe");
        address owner = voter.owner();
        require(owner == originalOwner);
        require(msg.sender != owner);
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        bribe[msg.sender][_token] += _amount;
        emit Bribed(msg.sender, _token, _amount);
    }

    function retractBribe(address _token) external {
        uint amount = bribe[msg.sender][_token];
        require(amount > 0);
        bribe[msg.sender][_token] = 0;
        IERC20(_token).transfer(msg.sender, amount);
        emit BribeRetracted(msg.sender, _token, amount);
    }

    // @notice when accepting bribe, must call this function atomically in same txn that ownership is changed.
    // or else you risk losing it to a retraction.
    // @param _token to claim
    // @param _min tokens to claim. ensuring briber doesn't front-run the acceptance with a retraction
    function acceptBribe(address _token, uint _min) external {
        require(!accepted);
        address newOwner = voter.owner();
        require(msg.sender == originalOwner);
        require(msg.sender != newOwner);
        accepted = true;
        uint amount = bribe[newOwner][_token];
        bribe[newOwner][_token] = 0;
        require(amount >= _min, "Not enough");
        IERC20(_token).transfer(msg.sender, amount);
        emit BribeAccepted(newOwner, _token, amount);
    }
} 