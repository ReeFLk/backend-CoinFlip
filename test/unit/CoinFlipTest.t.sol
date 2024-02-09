// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {CoinFlip} from "../../src/CoinFlip.sol";
import {DeployCoinFlip} from "../../script/DeployCoinFlip.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2Mock.sol";

contract CoinFlipTest is Test {
    event FlipRequested();
    event CoinFlipped(uint256 indexed requestId, uint256 indexed amount, address player);

    CoinFlip coinFlip;
    HelperConfig helperConfig;

    address vrfCoordinator;
    address link;
    bytes32 keyHash;
    uint64 subId;
    uint32 callbackGasLimit;
    uint256 deployerKey;

    address public PLAYER = makeAddr("player");
    uint256 public STARTING_BALANCE = 10 ether;

    function setUp() public {
        DeployCoinFlip deployer = new DeployCoinFlip();
        (coinFlip, helperConfig) = deployer.run(); //run the deploy script
        (vrfCoordinator, link, keyHash, subId, callbackGasLimit, deployerKey) = helperConfig.activeNetwork();
    }
    //////////////////////
    //   Flip Function  //
    //////////////////////

    function testFlipWithInsuffisantBetAmount() public {
        vm.prank(PLAYER);
        vm.expectRevert(CoinFlip.CoinFlip__InsufficientBetAmount.selector);
        coinFlip.flip(CoinFlip.Side.HEADS);
    }

    function testFlipEmit() public {
        hoax(PLAYER, STARTING_BALANCE);
        vm.expectEmit(true, false, false, false, address(coinFlip));
        emit FlipRequested();
        coinFlip.flip{value: 1 ether}(CoinFlip.Side.HEADS);
    }

    ///////////////////////////////
    //    FullfilRandomWords     //
    ///////////////////////////////
    modifier skipFork() {
        if (block.chainid != 31337) {
            return;
        }
        _;
    }

    function testFullFilRandomWordsCoinFlipped() public skipFork{
        hoax(PLAYER, STARTING_BALANCE);
        uint256 requestId = coinFlip.flip{value: 1 ether}(CoinFlip.Side.HEADS);
        vm.expectEmit(true, true, false, true);
        emit CoinFlipped(requestId, 1 ether, vrfCoordinator);
        VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(requestId, address(coinFlip));
    }
}
