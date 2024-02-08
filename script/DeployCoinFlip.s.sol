// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Script} from "forge-std/Script.sol";
import {CoinFlip} from "../src/CoinFlip.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployCoinFlip is Script {
    function run() external returns (CoinFlip, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        (address vrfCoordinator, address link, bytes32 keyHash, uint64 subId, uint32 callbackGasLimit) =
            helperConfig.activeNetwork();

        vm.startBroadcast();
        CoinFlip coinFlip = new CoinFlip(vrfCoordinator, link, keyHash, subId, callbackGasLimit);
        vm.stopBroadcast();
        return (coinFlip, helperConfig);
    }
}
