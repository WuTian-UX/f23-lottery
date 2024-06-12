//SPDX-

pragma solidity ^0.8.18;

import {Script} from 'forge-std/Script.sol';
import {Raffle} from '../src/Raffle.sol';
import {HelperConfig} from './HelperConfig.s.sol';

contract DeployRaffle is Script {
    function run() external returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();

        // 解构写法，到“独立”的变量中
        (
            uint256 enteranceFee,
            uint256 interval,
            address vrfCoordinator,
            bytes32 keyHash,
            uint64 subscriptionId,
            uint32 callbackGasLimit
            // uint32 numWords
        ) = helperConfig.activeNetworkConfig();

        vm.startBroadcast();
        Raffle raffle = new Raffle(
            enteranceFee,
            interval,
            vrfCoordinator,
            keyHash,
            subscriptionId,
            callbackGasLimit
        );

        vm.stopBroadcast();

        return (raffle, helperConfig);
    }
}