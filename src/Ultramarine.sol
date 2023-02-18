// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "./utils/Button.sol";

interface IPUSHCommInterface {
    function sendNotification(address _channel, address _recipient, bytes calldata _identity) external;
}

contract Ultramarine is ERC721, VRFConsumerBaseV2, ConfirmedOwner {
    using Strings for uint256;
    using Counters for Counters.Counter;
    using Button for Button.Items;

    event NewGame(
        address indexed user_,
        uint256 indexed tokenId_,
        uint256 indexed amount_,
        uint256 balance_,
        uint256 liquidity_,
        uint256 move_,
        uint256 rand_
    );

    struct Bet {
        uint256 amount;
        uint256 move;
        uint256 rand;
    }

    Counters.Counter private _counter;
    Button.Items private _button;
    uint256 private _liquidity;

    mapping(address => uint256) private _balance; // user => balance
    mapping(uint256 => uint256) private _request; // requestId => tokenId
    mapping(uint256 => Bet) private _bet;         // tokenId => Bet

    address private EPNS_COMM_ADDRESS = 0xb3971BCef2D791bc4027BbfedFb47319A4AAaaAa;
    address private _channel;

    VRFCoordinatorV2Interface COORDINATOR;
    bytes32 private keyHash = 0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15;
    address private coordinator = 0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D;
    uint32 private callbackGasLimit = 100000;
    uint16 private requestConfirmations = 3;
    uint32 private numWords = 1;
    uint64 private subscriptionId; // 9938

    modifier isLiquid() {
        require(_liquidity > 0, "No liquidity in the game.");
        _;
    }

    constructor(
        address owner_,
        string memory name_,
        Button.Item[] memory buttons_
    )
        ERC721(name_, "GAME")
        VRFConsumerBaseV2(coordinator)
        ConfirmedOwner(owner_)
    {
        _setButtons(buttons_);
        COORDINATOR = VRFCoordinatorV2Interface(coordinator);
    }

    function setButtons(Button.Item[] memory buttons_) public onlyOwner {
        _setButtons(buttons_);
    }

    function setSubscriptionId(uint64 subscriptionId_) public onlyOwner {
        _setSubscriptionId(subscriptionId_);
    }

    function setChannel(address channel_) public onlyOwner {
        _setChannel(channel_);
    }

    function _setButtons(Button.Item[] memory buttons_) private {
        for (uint256 i = 0; i < buttons_.length; i++) {
            _button.set(buttons_[i]._background, buttons_[i]._emoji);
        }
    }

    function _setSubscriptionId(uint64 subscriptionId_) private {
        subscriptionId = subscriptionId_;
    }

    function _setChannel(address channel_) private {
        _channel = channel_;
    }

    function play(
        uint256 amount_,
        uint256 move_
    ) external payable isLiquid returns (
        uint256 requestId
    ) {
        _balance[msg.sender] += msg.value;
        require(_balance[msg.sender] >= amount_, "The user balance is insufficient.");

        uint256 percent = amount_ * 100 / _liquidity;
        require(percent >= 1, "Understatement of min bet in the game.");
        require(percent <= 10, "Exceeded max bet in the game.");

        _counter.increment();
        uint256 tokenId = _counter.current();
        _safeMint(msg.sender, tokenId);

        if (subscriptionId <= 0) {
            requestId = uint256(keccak256(abi.encodePacked(
                block.timestamp,
                amount_,
                msg.sender,
                move_,
                tokenId
            )));
        } else {
            requestId = COORDINATOR.requestRandomWords(
                keyHash,
                subscriptionId,
                requestConfirmations,
                callbackGasLimit,
                numWords
            );
        }

        _request[requestId] = tokenId;
        _bet[tokenId] = Bet({
            amount: amount_,
            move: move_,
            rand: 0
        });

        if (subscriptionId <= 0) {
            uint256[] memory randomWords_ = new uint256[](1);
            randomWords_[0] = requestId;
            fulfillRandomWords(requestId, randomWords_);
        } else {
            emit NewGame(
                msg.sender,
                tokenId,
                amount_,
                _balance[msg.sender],
                _liquidity,
                move_,
                0
            );
        }
    }

    function fulfillRandomWords(
        uint256 requestId_,
        uint256[] memory randomWords_
    ) internal override {
        uint256 tokenId = _request[requestId_];
        address user = ownerOf(tokenId);
        Bet storage bet = _bet[tokenId];
        bet.rand = (randomWords_[0] % 2) + 1;
        
        if (bet.move == bet.rand) {
            _liquidity -= bet.amount;
            _balance[user] += bet.amount;
        } else {
            _liquidity += bet.amount;
            _balance[user] -= bet.amount;
        }

        emit NewGame(
            user, 
            tokenId, 
            bet.amount, 
            _balance[user], 
            _liquidity, 
            bet.move, 
            bet.rand
        );
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (
        string memory
    ) {
        _requireMinted(tokenId);

        string memory result = _bet[tokenId].rand == 0 
            ? ""
            : _bet[tokenId].move == _bet[tokenId].rand 
                ? "Winning "
                : "Losing ";
         (, string memory rand_emoji) = _button.get(_bet[tokenId].rand - 1);
        (string memory background, string memory emoji) = _button.get(_bet[tokenId].move - 1);
        string memory image = string(abi.encodePacked(
            "data:image/svg+xml;base64,",
            Base64.encode(bytes(string(abi.encodePacked(
                '<svg width="350" height="350" style="background:#',
                background,
                '" xmlns="http://www.w3.org/2000/svg"><text style="fill-opacity: .1;font-family: Verdana, sans-serif;font-weight: bold;font-size: 50px;text-anchor: middle;stroke: white;stroke-width: 2;stroke-opacity: .1;letter-spacing: 3px;fill: none;text-transform: uppercase;" x="175" y="75" text-anchor="middle">',
                result,
                '</text><text style="font-size: 100px;" text-anchor="middle" x="75" y="125" dy="1em" dx="1em">',
                emoji,
                '</text></svg>'
            )))) 
        ));

        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(abi.encodePacked(
                    '{"name": "', string(abi.encodePacked(
                        result, 'Game #', Strings.toString(tokenId)
                    )), '","description": "', string(abi.encodePacked(
                        'ULTRAMARINE NFT GAME ENGINE'
                    )), '","external_url": "', string(abi.encodePacked(
                        'https://ultramarine.app/#/', Strings.toHexString(uint160(address(this)), 20), '/history/', Strings.toString(tokenId)
                    )), '","attributes": [{"trait_type": "Random","value": "', 
                    rand_emoji, 
                    '"},{"trait_type": "Amount","value": "', 
                    Strings.toString(_bet[tokenId].amount), 
                    '"},{"trait_type": "Result","value": "', 
                    result, 
                    '"}],"image": "', 
                    image, 
                    '"}'
                ))
            )
        );
    }

    function getName() public view returns(string memory) {
        return name();
    }

    function getButton(uint256 id_) public view returns(string memory b, string memory e) {
        (b, e) = _button.get(id_);
    }

    function getOwner() public view returns(address) {
        return owner();
    }

    function getNumberOfGames() public view returns(uint256) {
        return _counter.current();
    }

    function getBalance() public view returns(uint256) {
        return _balance[msg.sender];
    }

    function getBalanceOf(address user_) public view returns(uint256) {
        return _balance[user_];
    }

    function getLiquidity() public view returns(uint256) {
        return _liquidity;
    }

    function getChannel() public view returns(address) {
        return _channel;
    }

    function getSubscriptionId() public view returns(uint64) {
        return subscriptionId;
    }

    function getButtons() public view returns(
        string memory background1_,
        string memory emoji1_,
        string memory background2_,
        string memory emoji2_
    ) {
        (background1_, emoji1_) = _button.get(0);
        (background2_, emoji2_) = _button.get(1);
    }

    function getGame(address user_) public view returns(
        address game_,
        string memory name_,
        address owner_,
        uint256 balance_,
        uint256 liquidity_,
        uint256 numberOfGames_,
        string memory background1_,
        string memory emoji1_,
        string memory background2_,
        string memory emoji2_
    ) {
        game_ = address(this);
        name_ = getName();
        owner_ = getOwner();
        balance_ = getBalanceOf(user_);
        liquidity_ = getLiquidity();
        numberOfGames_ = getNumberOfGames();
        (background1_, emoji1_, background2_, emoji2_) = getButtons();
    }

    function getBet(uint256 num_) public view returns(
        uint256 id_,
        address user_,
        uint256 amount_,
        uint256 move_,
        uint256 rand_
    ) {
        uint256 last = _counter.current() >= num_ ? _counter.current() - num_ + 1 : 0;
        Bet memory b = _bet[last];
        return (last, ownerOf(last), b.amount, b.move, b.rand);
    }

    function addLiquidity() public payable {
        _liquidity += msg.value;
    }

    function maxBet() public view returns(uint256) {
        return _liquidity / 10;
    }

    function minBet() public view returns(uint256) {
        return _liquidity / 100;
    }

    function withdraw() public payable {
        if (_balance[msg.sender] > 0) {
            uint256 b = _balance[msg.sender];
            _balance[msg.sender] = 0;
            payable(msg.sender).transfer(b);
            if (_channel != address(0)) {
                IPUSHCommInterface(EPNS_COMM_ADDRESS).sendNotification(
                    _channel,
                    address(this),
                    bytes(
                        string(
                            abi.encodePacked(
                                "0",
                                "+",
                                "1",
                                "+",
                                "Liquidity in the game",
                                "+",
                                "Liquidity: ",
                                Strings.toString(_liquidity)
                            )
                        )
                    )
                );
            }
        }
    }

    function withdraw(address receiver_) public payable onlyOwner {
        require(receiver_ != address(0));
        uint256 l = _liquidity;
        _liquidity = 0;
        payable(receiver_).transfer(l);
    }
}
