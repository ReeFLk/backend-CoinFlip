// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";

contract CoinFlip is VRFConsumerBaseV2 {
    /////////////////
    /*   Errors   */
    ////////////////
    error CoinFlip__InsufficientBetAmount();
    error CoinFlip__TransferFailed();

    ////////////////
    /*   Events   */
    ////////////////
    event FlipRequested();
    event CoinFlipped(uint256 indexed requestId, uint256 indexed amount, address player);
    event CoinFlippedAndLose(uint256 indexed requestId, uint256 indexed amount, address player);

    /////////////////////////
    /*   State Variables   */
    /////////////////////////
    enum Side {
        HEADS,
        TAILS
    }

    Side private s_choice;
    bool private didWin;

    /* Constants */
    uint256 private constant MINIMUM_BET = 0.01 ether;
    uint32 private constant NUM_WORDS = 1;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;

    /* Immutable state variables */
    bytes32 private immutable i_keyHash;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    address private immutable i_link;
    uint64 private immutable i_subId;
    uint32 private immutable i_callbackGasLimit;

    /////////////////////
    /*     Functions   */
    /////////////////////

    /* Constructor */
    constructor(address _vrfCoordinator, address _link, bytes32 _keyHash, uint64 _subId, uint32 _callbackGasLimit)
        VRFConsumerBaseV2(_vrfCoordinator)
    {
        i_vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
        i_link = _link;
        i_keyHash = _keyHash;
        i_subId = _subId;
        i_callbackGasLimit = _callbackGasLimit;
    }

    /*
    @notice Flip the coin
    @dev This function is called by the player to flip the coin
    @param _choice The side the player is betting on
    */
    function flip(Side _choice) external payable returns (uint256 requestId) {
        if (msg.value <= MINIMUM_BET) {
            revert CoinFlip__InsufficientBetAmount();
        }
        s_choice = _choice;
        requestId = i_vrfCoordinator.requestRandomWords(
            i_keyHash, //gasLane
            i_subId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );

        emit FlipRequested();
        return requestId;
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        if (Side(randomWords[0] % 2) == s_choice) {
            (bool success,) = payable(msg.sender).call{value: address(this).balance * 2}("");
            if (!success) {
                revert CoinFlip__TransferFailed();
            }
            didWin = true;
        } else {
            didWin = false;
        }
        emit CoinFlipped(requestId, address(this).balance, msg.sender);
    }
}
