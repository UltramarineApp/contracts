// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Ultramarine.sol";
import "./utils/Button.sol";

contract FactoryUltramarine {

    event NewGame(
        uint256 indexed id_, 
        address indexed game_, 
        string indexed name_,
        string background1_,
        string emoji1_,
        string background2_,
        string emoji2_
    );

    constructor() {}

    uint256 private _id;
    mapping(uint256 => address) private _games;

    function createGame(
        string memory name_, // Football versus
        Button.Item[] memory buttons_ // [["5d2e1a","🏈"],["1a435d","⚽️"]]
    ) public returns(uint256, address) {
        _id++;
        Ultramarine _game = new Ultramarine(msg.sender, name_, buttons_);
        _games[_id] = address(_game);
        (string memory b1, string memory e1, string memory b2, string memory e2) = _game.getButtons();
        emit NewGame(_id, address(_game), name_, b1, e1, b2, e2);
        return (_id, address(_game));
    }

    function getGame(uint256 id_, address user_) public view returns(
        address,
        string memory,
        address,
        uint256,
        uint256,
        uint256,
        string memory,
        string memory,
        string memory,
        string memory
    ) {
        uint256 last = _id >= id_ ? _id - id_ + 1 : 0;
        Ultramarine _nft = Ultramarine(_games[last]);
        return _nft.getGame(user_);
    }

}
