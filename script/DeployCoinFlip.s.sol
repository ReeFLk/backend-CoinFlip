// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Script, console} from "forge-std/Script.sol";
import {CoinFlip} from "../src/CoinFlip.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "./Interactions.s.sol";

contract DeployCoinFlip is Script {
    function run() external returns (CoinFlip, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        (
            address vrfCoordinator,
            address link,
            bytes32 keyHash,
            uint64 subId,
            uint32 callbackGasLimit,
            uint256 deployerKey
        ) = helperConfig.activeNetwork();

        if (subId == 0) {
            CreateSubscription createSubscription = new CreateSubscription();
            subId = createSubscription.createSubscription(vrfCoordinator, deployerKey);
            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(vrfCoordinator, subId, link, deployerKey);
        }

        vm.startBroadcast();
        CoinFlip coinFlip = new CoinFlip(vrfCoordinator, link, keyHash, subId, callbackGasLimit);
        vm.stopBroadcast();

        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(address(coinFlip), vrfCoordinator, subId, deployerKey);
        return (coinFlip, helperConfig);
    }
}
