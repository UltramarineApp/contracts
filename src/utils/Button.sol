// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Button {
    struct Item {
        string _background;
        string _emoji;
    }

    struct Items {
        Item[] _item;
    }

    function get(
        Items storage items_,
        uint256 i_
    ) internal view returns (
        string memory background_,
        string memory emoji_
    ) {
        background_ = items_._item[i_]._background;
        emoji_ =  items_._item[i_]._emoji;
    }

    function set(
        Items storage items_,
        string memory background_,
        string memory emoji_
    ) internal {
        items_._item.push(Item(background_, emoji_));
    }
}
