// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/FactoryUltramarine.sol";

contract FactoryUltramarineTest is Test {
    FactoryUltramarine public factory;

    function setUp() public {
        factory = new FactoryUltramarine();
    }

    function testCreateGame() public {
        Button.Item[] memory buttons_ = new Button.Item[](2);
        buttons_[0]._background = "5d2e1a";
        buttons_[0]._emoji = unicode"🏈";
        buttons_[1]._background = "1a435d";
        buttons_[1]._emoji = unicode"⚽️";
        factory.createGame("Game", buttons_);
        (, , address owner, , , , , , ) = factory.getGame(1);
        assertEq(owner, address(this));
    }
}
