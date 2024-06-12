// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {VRFCoordinatorV2Interface} from '@chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol';
import {VRFConsumerBaseV2} from '@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol';
import {Test, console} from 'forge-std/Test.sol';


contract Raffle is VRFConsumerBaseV2 {
    error Raffle__NotEngouthEnteranceFee();
    error Raffle__IsNotOpen();


    uint16 private constant REQUEST_CONFFIRMATIONS = 3;
    uint256 private immutable i_enterRaflleFee; // enterance fee
    uint256 private i_interval; // interval to pick the winner
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator; // chainlink vrf coordinatior
    address payable[] private s_players;
    bytes32 private immutable i_keyHash; // chainlink vrf keyHash
    uint32 private immutable i_CallbackGasLimit;
    uint32 private immutable i_numWords; // number of words to get from chainlink vrf
    uint256 private s_lastTimeStamp; // 上次开奖时间
    uint64 private immutable i_subscriptionId;
    address private s_recentWinner;
    RaffleState public s_raffleState;
    uint32 private constant NUM_WORDS = 1;
    // 枚举 抽奖状态
    enum RaffleState {
        OPEN, //0
        CALCULATING //1
    }

    /* EVENT -emit */
    event Raffle__Enterance(address indexed player);
    event Raffle__Winner(address indexed winner);

    constructor(
        uint256 enteranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 keyHash,
        uint64 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(vrfCoordinator) {
        i_enterRaflleFee = enteranceFee;
        i_interval = interval;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_keyHash = keyHash;
        i_subscriptionId = subscriptionId;
        i_CallbackGasLimit = callbackGasLimit;
        i_numWords = NUM_WORDS;
        s_raffleState = RaffleState.OPEN;
    }
    function enterRaflle() external payable {
        // require(msg.value < i_enterRaflleFee, 'NotEngouthEnteranceFee');

    
        // console.log('i_enterRaflleFee:', i_enterRaflleFee);
        // console.log(s_raffleState);
        if (msg.value < i_enterRaflleFee) {
            revert Raffle__NotEngouthEnteranceFee();
        }
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__IsNotOpen();
        }
        
        console.log('pass');
        s_players.push(payable(msg.sender)); // Add the player to the list

        emit Raffle__Enterance(msg.sender);
    }

    // 回调函数 获取随机数
    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        uint256 indexOfWinner = _randomWords[0] % s_players.length;
        address payable winner = s_players[indexOfWinner];
        s_recentWinner = winner;
        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0); // 重置参与者数组
        s_lastTimeStamp = block.timestamp;

        // CEI 检查条件 影响变量 最后再进行交互
        emit Raffle__Winner(winner);
        (bool success, ) = winner.call{value: address(this).balance}('');
        if (!success) {
            revert('Failed to send money to winner');
        }
    }

    // ChainLink 自动化

    /* 检查是否可以抽奖
     * 判断抽奖时间间隔
     * 抽奖状态= open
     * 合约有eth
     *
     */
    function checkUpkeep(
        bytes memory /* checkData */
    ) public view returns (bool upkeepNeeded, bytes memory /* performData */) {
        bool timePassed = (block.timestamp - s_lastTimeStamp) >= i_interval;
        bool raffleStateIsOpen = s_raffleState == RaffleState.OPEN;
        bool hasEth = address(this).balance > 0;
        upkeepNeeded = (timePassed && raffleStateIsOpen && hasEth);
        return (true, '0x0');
    }

    function performUpkeep(bytes calldata /* performData */) external {
        (bool upkeepNeeded, ) = checkUpkeep('');
        if (!upkeepNeeded) {
            revert('Raffle is not open');
        }
        if (block.timestamp - s_lastTimeStamp < i_interval) {
            revert('Not enough time has passed since the last raffle');
        }

        if (s_raffleState != RaffleState.OPEN) {
            revert('Raffle is not open');
        }

        s_raffleState = RaffleState.CALCULATING;

        // 使用chainklink vrf 获取随机数
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_keyHash,
            i_subscriptionId,
            REQUEST_CONFFIRMATIONS, // 确认数
            i_CallbackGasLimit, // gas limit
            i_numWords
        );
    }

    /*Getter*/
    function getEnterancrFee() public view returns (uint256) {
        return i_enterRaflleFee;
    }

    function getPlayer(uint256 idx) public view returns (address) {
        return s_players[idx];
    }
}
