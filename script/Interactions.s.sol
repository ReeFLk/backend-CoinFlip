// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";
import {DevOpsTools} from "../lib/foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is Script {
    function createSubscriptionUsingConfig() public returns (uint64) {
        HelperConfig helperConfig = new HelperConfig();
        (address vrfCoordinator,,,,, uint256 deployerKey) = helperConfig.activeNetwork();
        return createSubscription(vrfCoordinator, deployerKey);
    }

    function createSubscription(address _vrfCoordinator, uint256 deployerKey) public returns (uint64) {
        console.log("Creating subscription on chainid: ", block.chainid);
        vm.startBroadcast(deployerKey);
        uint64 subId = VRFCoordinatorV2Mock(_vrfCoordinator).createSubscription();
        vm.stopBroadcast();
        console.log("Subscription ID:", subId);
        return subId;
    }

    function run() external returns (uint64) {
        return createSubscriptionUsingConfig();
    }
}

contract FundSubscription is Script {
    uint96 public constant FUND_AMOUNT = 3 ether;

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        (address vrfCoordinator, address link,, uint64 subId,, uint256 deployerKey) = helperConfig.activeNetwork();
        fundSubscription(vrfCoordinator, subId, link, deployerKey);
    }

    function fundSubscription(address _vrfCoordinator, uint64 _subId, address _link, uint256 deployerKey) public {
        console.log("Funding... With subId:", _subId);
        console.log("Sending LINK to", address(_vrfCoordinator));
        console.log("Funding on chain Id", block.chainid);
        if (block.chainid == 31337) {
            vm.startBroadcast(deployerKey);
            VRFCoordinatorV2Mock(_vrfCoordinator).fundSubscription(_subId, FUND_AMOUNT);
            vm.stopBroadcast();
        } else {
            vm.startBroadcast(deployerKey);
            LinkToken(_link).transferAndCall(address(_vrfCoordinator), FUND_AMOUNT, abi.encode(_subId));
            vm.stopBroadcast();
        }
    }

    function run() external {
        fundSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script {
    function addConsumerUsingConfig(address _coinFlip) public {
        HelperConfig helperConfig = new HelperConfig();
        (address vrfCoordinator,,, uint64 subId,, uint256 deployerKey) = helperConfig.activeNetwork();
        addConsumer(_coinFlip, vrfCoordinator, subId, deployerKey);
    }

    function addConsumer(address _coinFlip, address _vrfCoordinator, uint64 _subId, uint256 _deployerKey) public {
        console.log("Adding Consumer to", _coinFlip);
        vm.startBroadcast(_deployerKey);
        VRFCoordinatorV2Mock(_vrfCoordinator).addConsumer(_subId, _coinFlip);
        vm.stopBroadcast();
    }

    function run() external {
        address coinFlip = DevOpsTools.get_most_recent_deployment("CoinFlip", block.chainid);
        addConsumerUsingConfig(coinFlip);
    }
}
