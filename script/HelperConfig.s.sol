//SPDX
pragma solidity ^0.8.18;

import {Script} from 'forge-std/Script.sol';
import {VRFCoordinatorV2Mock} from '@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2Mock.sol';
import {Test, console} from 'forge-std/Test.sol'; // 用于测试
contract HelperConfig is Script {
    struct NetworkConfig {
        // 变量和主合约构造函数参数一一对应
        uint256 enteranceFee;
        uint256 interval;
        address vrfCoordinator;
        bytes32 keyHash;
        uint64 subscriptionId;
        uint32 callbackGasLimit;
        // uint32 numWords;
    }
    NetworkConfig public activeNetworkConfig;
    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else { 
            activeNetworkConfig = getOrCreateAnvilConfig();
        }
    }
    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory sepoliaConfig = NetworkConfig({
            enteranceFee: 0.1 ether,
            interval: 1 days,
            vrfCoordinator: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625, // vrf v2 coordinator
            keyHash: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
            subscriptionId: 0,
            callbackGasLimit: 500000
            // numWords: 1
        });
        return sepoliaConfig;
    }

    function getOrCreateAnvilConfig() public returns (NetworkConfig memory) {
        // Check to see if we set an active network config
        if (activeNetworkConfig.vrfCoordinator != address(0)) {
            return activeNetworkConfig;
        }

        vm.startBroadcast();

        // 模拟vrf v2
        uint96 baseFee = 0.25 ether; //
        uint96 gasPriceLink = 1e9 gwei; // 1 wei
        VRFCoordinatorV2Mock vrfCoordinator = new VRFCoordinatorV2Mock(
            baseFee,
            gasPriceLink
        );

        vm.stopBroadcast();

        return
            NetworkConfig({
                enteranceFee: 0.1 ether,
                interval: 1 days,
                vrfCoordinator: address(vrfCoordinator), // vrf v2 coordinator
                keyHash: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
                subscriptionId: 0,
                callbackGasLimit: 500000
                // numWords: 1
            });
    }
}
