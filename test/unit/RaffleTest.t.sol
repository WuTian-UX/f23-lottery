//SPDX

pragma solidity ^0.8.18;

import {DeployRaffle} from '../../script/DeployRaffle.s.sol';
import {Raffle} from '../../src/Raffle.sol';
import {HelperConfig} from '../../script/HelperConfig.s.sol';
import {Test, console} from 'forge-std/Test.sol';

contract RaffleTest is Test {
    Raffle raffle;
    // 使用cheatcode 生成用户
    address player1 = makeAddr('player1');
    uint PLAYERSTARTBALANCE = 1000 ether;
    HelperConfig helperConfig;

    uint256 enteranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 keyHash;
    uint64 subscriptionId;
    uint32 callbackGasLimit;
    uint32 numWords;
    event Raffle__Enterance(address indexed player);
    function setUp() external {
        DeployRaffle deployRaffle = new DeployRaffle();
        (raffle, helperConfig) = deployRaffle.run();

        (
            enteranceFee,
            interval,
            vrfCoordinator,
            keyHash,
            subscriptionId,
            callbackGasLimit
            // numWords
        ) = helperConfig.activeNetworkConfig();
    }

    function testRaffleInitStateIsOpen() external view {
        require(
            raffle.s_raffleState() == Raffle.RaffleState.OPEN,
            'Raffle should be in open state'
        );
    }

    // 测试用户进入抽奖且投入金额不足
    function testEnterRaffleNotEnoughFee() external {
        // 模拟
        vm.prank(player1);
        // vm.deal(player1, PLAYERSTARTBALANCE);
        // 执行
        vm.expectRevert();
        raffle.enterRaflle();
        // 断言
    }

    // 测试用户进入抽奖
    function testEnterRaffle() external {
        // 模拟
        vm.prank(player1);
        vm.deal(player1, PLAYERSTARTBALANCE);
        // 执行
        raffle.enterRaflle{value: enteranceFee}();
        // 断言
        assertEq(raffle.getPlayer(0), player1);
    }

    // 测试用户进入抽奖触发事件
    function testEnterRaffleEmit() external {
        // 模拟
        vm.prank(player1);
        vm.deal(player1, PLAYERSTARTBALANCE);
        // 执行
        vm.expectEmit(true, false, false, false, address(raffle));
        emit Raffle__Enterance(player1);
        raffle.enterRaflle{value: enteranceFee}(); /*  */
        // 断言
    }

    // 测试摇奖时不能进入抽奖
    function testCantEnterRaffleWhenCalculation() external {
        // 模拟用户进入
        vm.prank(player1);
        vm.deal(player1, PLAYERSTARTBALANCE);
        raffle.enterRaflle{value: 0.2 ether}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        // 执行vrf
        raffle.performUpkeep('');

        // 已开始获取随机数，停止进入抽奖
        console.log('player1.balance:', player1.balance);
        vm.expectRevert(Raffle.Raffle__IsNotOpen.selector);
        raffle.enterRaflle{value: 0.2 ether}();
    }
}
