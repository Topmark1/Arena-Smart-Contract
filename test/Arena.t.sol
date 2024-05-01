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

    function setUp() public {    
        arenaGround = new ArenaGround();
        topmark = address(1);
        alex = address(2);
        bob = address(3);
    }

    function test_CheckCheck() public view {
        assertEq(arenaGround.fixedNonArenaJoinReward(), 10000); 
        assertEq( arenaGround.iconValues(topmark), 1e18); 
    }
    function test_DepositAndWithdraw() public {
        arenaGround.Deposit(30e18);
        arenaGround.Withdraw(23e18);
        assertEq( arenaGround.iconValues(address(this)) ,7e18 );
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
        vm.warp(block.timestamp + 601);
         vm.prank(bob);
        arenaGround.JoinArena( 1 , 0 ); // pass in any amount to claim price
        assertEq( arenaGround.iconValues(bob) , 35e18 );
    }
    function test_JoinArenaTimeExpireForArenaSetter() public {
        vm.prank(topmark);
        arenaGround.SetArena(5e18 , 600 );
        vm.warp(block.timestamp + 601);

        vm.prank(topmark);
        arenaGround.JoinArena( 1 , 0 ); // pass in any amount to claim price, it would not be lost
        assertEq( arenaGround.iconValues(topmark) , 100e18 );
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
        vm.warp(block.timestamp + 451);
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



    function testFuzz_SetNumber(uint256 x) public {
       // counter.setNumber(x);
        //assertEq(counter.number(), x);
    } 
}
