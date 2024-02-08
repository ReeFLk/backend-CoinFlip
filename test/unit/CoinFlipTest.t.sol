// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Test,console} from "forge-std/Test.sol";
import {CoinFlip} from "../../src/CoinFlip.sol";
import {DeployCoinFlip} from "../../script/DeployCoinFlip.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract CoinFlipTest is Test {
    event FlipRequested();

    CoinFlip coinFlip;
    HelperConfig helperConfig;

    address vrfCoordinator;
    address link;
    bytes32 keyHash;
    uint64 subId;
    uint32 callbackGasLimit;

    address public PLAYER = makeAddr("player");
    uint256 public STARTING_BALANCE = 10 ether;

    function setUp() public {
        DeployCoinFlip deployer = new DeployCoinFlip();
        (coinFlip, helperConfig) = deployer.run(); //run the deploy script
        (vrfCoordinator, link, keyHash, subId, callbackGasLimit) = helperConfig.activeNetwork();
    }

    function testFlipWithInsuffisantBetAmount() public {
        vm.prank(PLAYER);
        vm.expectRevert(CoinFlip.CoinFlip__InsufficientBetAmount.selector);
        coinFlip.flip(CoinFlip.Side.HEADS);
    }

    function testFlip() public {
        hoax(PLAYER, STARTING_BALANCE);
        // vm.expectEmit(true, false, false, false, address(coinFlip));
        // emit FlipRequested();
        uint256 requestId = coinFlip.flip{value: 1 ether}(CoinFlip.Side.HEADS);
        console.log(requestId);
    }
}
