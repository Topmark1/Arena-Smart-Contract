// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {ArenaGround} from "../src/ArenaGround.sol";

contract ArenaTest is Test {

    ArenaGround public arenaGround;
    address topmark;
    address alex;
    address bob;

    /// mapping(uint256 => ArenaInfo) public arena;
    mapping(address => uint256) public iconValues;
    mapping(uint256 => uint256) public currentCall;
    uint256 public arenaCount;
    address public arenaKingAddress;
    uint256 public fixedNonArenaJoinReward;
    address owner ;

    function setUp() public {    
        arenaGround = new ArenaGround(30 days);
        // mg.sender not same as address (this), owner is address(this)
        owner = arenaGround.ownerView();
        

        vm.prank(owner);
        arenaGround.activateWhitelist(address(1),  100e18);
        vm.prank(owner);
        arenaGround.activateWhitelist(address(2),  10e18);
        vm.prank(owner);
        arenaGround.activateWhitelist(address(3),  10e18);
        arenaGround.activateWhitelist(address(4),  10e18);
        arenaGround.activateWhitelist(address(5),  10e18);
        topmark = address(1);
        alex = address(2);
        bob = address(3);
        vm.deal(msg.sender, 200e18);
        vm.deal(owner, 200e18);   

    }

    function test_CheckCheck() public view {
        assertEq(arenaGround.fixedNonArenaJoinReward(), 10000); 
        assertEq( arenaGround.iconValues(topmark), 100e18); 
    }
    function test_DepositAndWithdraw() public {
        //TODO test with eth or token deposit
        vm.prank(msg.sender);
        arenaGround.deposit{value:30e18}(30e18);
        vm.prank(msg.sender);
        arenaGround.withdraw(23e18, msg.sender);
        assertEq( arenaGround.iconValues(address(arenaGround)) ,7e18 );
    }

    function test_SetArena() public {
        assertEq( arenaGround.iconValues(topmark), 100e18 );
        vm.prank(topmark);
        arenaGround.SetArena(20e18 , 600 );
        assertEq( arenaGround.iconValues(topmark), 80e18 );

        vm.prank(topmark);
        arenaGround.SetArena(40e18 , 600 );
        assertEq( arenaGround.iconValues(topmark), 40e18 );
        assertEq( arenaGround.arenaCount(), 2 );
        (,uint256 currentArenaValue,,,) =  arenaGround.arena(1);
        assertEq( currentArenaValue, 20e18 );
        (,currentArenaValue,,,) =  arenaGround.arena(2);
        assertEq( currentArenaValue, 40e18 );
    }
       function test_JoinArenaIconWinAndClaim() public {
        assertEq( arenaGround.iconValues(bob) , 10e18 );
        vm.prank(topmark);
        arenaGround.SetArena( 5e18 , 31 );
        vm.warp(block.timestamp + 1);
        vm.prank(topmark);
        arenaGround.JoinArena( 1 , 5e18 );
        vm.warp(block.timestamp + 1);
        vm.prank(topmark);
        arenaGround.JoinArena( 1 , 5e18 );
        vm.warp(block.timestamp + 1);
        vm.prank(topmark);
        arenaGround.JoinArena( 1 , 5e18 );
        vm.warp(block.timestamp + 1);

        vm.prank(alex);
        arenaGround.JoinArena( 1 , 5e18 );
        vm.warp(block.timestamp + 1);
        vm.prank(bob);
        arenaGround.JoinArena( 1 , 5e18 ); // by now locktime would have move from 31 to 0, bob is winner
        // time most elaspe to avoid flashloan
        vm.warp(block.timestamp + 1001);
         vm.prank(bob);
        arenaGround.JoinArena( 1 , 0 ); // pass in any amount to claim price
        assertEq( arenaGround.iconValues(bob) , 35e18 );
    }
    function test_JoinArenaTimeExpireForArenaSetter() public {
        assertEq( arenaGround.iconValues(bob) , 10e18 );
        vm.prank(owner); 
        arenaGround.deposit{value:150e18}(150e18);// value donated to contract by owner to encourage participation
        vm.prank(owner);
        arenaGround.setFixedNonArenaJoinReward(100e14);

        vm.prank(bob);
        arenaGround.SetArena(5e18 , 600 );
        vm.warp(block.timestamp + 1001);

        vm.prank(bob);
        arenaGround.JoinArena( 1 , 0 ); // pass in any amount to claim price, it would not be lost
        assertEq( arenaGround.iconValues(bob) , 10e18 + 100e14 ); // Icon has made profit
        vm.prank(bob);
        arenaGround.withdraw(10e18 + 100e14, bob); //bob wins big
    }
    function test_JoinArenaTimeExpireForArenaIcon() public {
         assertEq( arenaGround.iconValues(bob) , 10e18 );
        vm.prank(topmark);
        arenaGround.SetArena(5e18 , 600 );
        vm.warp(block.timestamp + 599);
        vm.prank(alex);
        arenaGround.JoinArena( 1 , 5e18 );
        vm.warp(block.timestamp + 1);
        vm.prank(bob);
        arenaGround.JoinArena( 1 , 5e18 );
        // time most elaspe to avoid flashloan
        vm.warp(block.timestamp + 151); /// bob is now winner but cant claim yet due to flash time delay
        vm.warp(block.timestamp + 851);
         vm.prank(bob);
        arenaGround.JoinArena( 1 , 0 ); // pass in any amount to claim price, it would not be lost
        assertEq( arenaGround.iconValues(bob) , 20e18 );
    }

    function test_JoinArenaAttackerCantCallManyAtOnceSimultaneouslyToWin() public {
        vm.prank(bob);
        arenaGround.SetArena(5e18 , 31 );
        vm.warp(block.timestamp + 1);

        vm.prank(topmark); //attacker with big funds
        arenaGround.JoinArena( 1 , 5e18 ); // pass in any amount to claim price, it would not be lost
        //vm.warp(block.timestamp + 1);
        vm.expectRevert();
        vm.prank(topmark); 
        arenaGround.JoinArena( 1 , 5e18 ); // pass in any amount to claim price, it would not be lost
        vm.expectRevert();
        vm.prank(topmark); 
        arenaGround.JoinArena( 1 , 5e18 );
    }

 function test_Fee() public {
        assertEq( arenaGround.iconValues(bob) , 10e18 );
        vm.prank(owner); 
        arenaGround.setFee( 1e5);
        vm.prank(owner);
        arenaGround.deposit{value:150e18}(150e18);// value donated to contract by owner to encourage participation
        vm.prank(owner);
        arenaGround.setFixedNonArenaJoinReward(100e14);

        vm.prank(bob);
        arenaGround.SetArena(5e18 , 600 );
        vm.warp(block.timestamp + 1001);

        vm.prank(bob);
        arenaGround.JoinArena( 1 , 0 ); // pass in any amount to claim price, it would not be lost
        assertEq( arenaGround.iconValues(bob) , 10e18 + 100e14 ); // Icon has made profit
        vm.prank(bob);
        arenaGround.withdraw(10e18 + 100e14 - ((10e18 + 100e14)/10 ) , bob); //bob wins big
    }

    function testFuzz_SetNumber(uint256 x) public {
       // counter.setNumber(x);
        //assertEq(counter.number(), x);
    } 
}
