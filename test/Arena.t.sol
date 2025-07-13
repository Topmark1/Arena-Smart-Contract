// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Test, console2} from "forge-std/Test.sol";
import {ArenaGround} from "../src/ArenaGround.sol";

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract MockOPToken is ERC20 {
    constructor() ERC20("MockOptimism", "MOP") {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

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
    MockOPToken public mockOP;

    function setUp() public {    
        mockOP = new MockOPToken();

        arenaGround = new ArenaGround(30 days, address(mockOP));
        // mg.sender not same as address (this), owner is address(this)
        owner = arenaGround.ownerView();
        

        // vm.prank(owner);
        // arenaGround.activateWhitelist(address(1),  100e18);
        // vm.prank(owner);
        // arenaGround.activateWhitelist(address(2),  10e18);
        vm.prank(owner);
        arenaGround.activateWhitelist(address(3),  10e18);
        arenaGround.activateWhitelist(address(4),  10e18);
        arenaGround.activateWhitelist(address(5),  10e18);
        topmark = address(1);
        alex = address(2);
        bob = address(3);

        mockOP.mint(topmark, 1000e18 );
        mockOP.mint(owner, 1000e18 );
        mockOP.mint(alex, 100e18 );

        vm.deal(msg.sender, 200e18);
        vm.deal(owner, 200e18);   

    }

    function test_CheckCheck() public view {
        assertEq(arenaGround.fixedNonArenaJoinRewardCap(), 0); 
         
    }
    function test_deposit() public {
        vm.prank(topmark);
         mockOP.approve(address(arenaGround), 1e18);
         vm.prank(topmark);
        arenaGround.deposit(1e18);

        assertEq( arenaGround.iconValues(address(topmark)) ,1e18 );

        vm.prank(owner);
        mockOP.approve(address(arenaGround), 2e18);
         vm.prank(owner);
        arenaGround.deposit(2e18);
        assertEq(arenaGround.fixedNonArenaJoinRewardCap(), 2e18); 
         
    }
     function test_withdraw() public {
        uint256 balanceBefore = mockOP.balanceOf(topmark);
       vm.prank(topmark);
         mockOP.approve(address(arenaGround), 3e18);
         vm.prank(topmark);
        arenaGround.deposit(3e18);
        vm.prank(owner);
        arenaGround.setFee(1e5);
        vm.prank(topmark);
        arenaGround.withdraw(1e18, topmark);

        assertEq( arenaGround.iconValues(address(topmark)) , 2e18 );
        assertEq( arenaGround.accumulatedFee()  , 1e17 );
        assertEq( balanceBefore - arenaGround.accumulatedFee() -2e18, mockOP.balanceOf(topmark));
    }
     function test_ArenaWinBigOrSamll() public {
        vm.prank(owner);
        mockOP.approve(address(arenaGround), 1000e18);
         vm.prank(owner);
        arenaGround.deposit(1000e18);

        vm.prank(topmark);
         mockOP.approve(address(arenaGround), 3e18);
         vm.prank(topmark);
        arenaGround.deposit(3e18);

        vm.prank(alex);
        mockOP.approve(address(arenaGround), 3e18);
        vm.prank(alex);
        arenaGround.deposit(3e18);
        assertEq( arenaGround.iconValues(alex) , 3e18 );

        //Alex big win
        vm.prank(alex);
        arenaGround.SetArena(1e17, 24 hours,true,"I need it badly");

        vm.warp(block.timestamp + 25 hours );

        vm.prank(alex);
        arenaGround.JoinArena( 1 , 1e17,"");
        assertEq(arenaGround.fixedNonArenaJoinRewardCap(), 100e18); 
        assertEq( arenaGround.iconValues(alex) , 3e18+ 900e18 );// user has made big profit

        // Topmark small win
        vm.prank(topmark);
        arenaGround.SetArena(1e17, 24 hours,false,"I need it to Graduate");

        vm.warp(block.timestamp + 24 hours + 1);

        vm.prank(topmark);
        arenaGround.JoinArena( 1 , 1e17,"");
        assertEq(arenaGround.fixedNonArenaJoinRewardCap(), 999e17); 
        assertEq( arenaGround.iconValues(topmark) , 3e18+ 1e17 ); //topmark made small profit
    }
     function test_ArenaNoEarlyWinBigOrSamll() public {
        vm.prank(owner);
        mockOP.approve(address(arenaGround), 1000e18);
         vm.prank(owner);
        arenaGround.deposit(1000e18);

        vm.prank(topmark);
         mockOP.approve(address(arenaGround), 3e18);
         vm.prank(topmark);
        arenaGround.deposit(3e18);

        vm.prank(alex);
        mockOP.approve(address(arenaGround), 3e18);
        vm.prank(alex);
        arenaGround.deposit(3e18);

        vm.prank(alex);
        arenaGround.SetArena(1e17, 24 hours,true,"");

        for (uint256 i; i < 10; i++){
        vm.warp(block.timestamp + 1);
        vm.prank(alex);
        arenaGround.JoinArena( 1 , 1e17,"");
        }
        for (uint256 i; i < 7; i++){
        vm.warp(block.timestamp + 1);
        vm.prank(topmark);
        arenaGround.JoinArena( 1 , 1e17,"");
        }

        vm.warp(block.timestamp + arenaGround.priceClaimDelay() + 1);
        vm.prank(topmark);
        arenaGround.JoinArena( 1 , 1e17,"");

        assertEq (arenaGround.arenaCount() , 0);
        assertEq( arenaGround.iconValues(topmark) , 3e18+ 1e17 * 11 ); //topmark made profit
        assertEq(arenaGround.fixedNonArenaJoinRewardCap(), 1000e18); 
         
    }
    function test_DonateToGiveAway() public {
        vm.prank(topmark);
         mockOP.approve(address(arenaGround), 3e18);
         vm.prank(topmark);
        arenaGround.deposit(1e18);
         vm.prank(topmark);
        arenaGround.DonateToGiveAway(2e18);
        assertEq(arenaGround.fixedNonArenaJoinRewardCap(), 2e18);   
    }
    function test_ArenaCount() public {
        vm.prank(alex);
        mockOP.approve(address(arenaGround), 3e18);
        vm.prank(topmark);
        mockOP.approve(address(arenaGround), 3e18);
        vm.prank(topmark);
        arenaGround.deposit(3e18);
        vm.prank(alex);
        arenaGround.deposit(3e18);

        vm.prank(alex);
        arenaGround.SetArena(1e17, 24 hours,true,"");
        vm.prank(topmark);
        arenaGround.SetArena(1e18, 24 hours,true,"");


        for (uint256 i; i < 7; i++){
        vm.warp(block.timestamp + 1);
        vm.prank(topmark);
        arenaGround.JoinArena( 1 , 1e17,"");
        }

        vm.warp(block.timestamp + arenaGround.priceClaimDelay() + 1);
        vm.prank(topmark);
        arenaGround.JoinArena( 1 , 1e17,"");


        vm.prank(topmark);
        arenaGround.SetArena(1e18, 34 hours,false,"");

        assertEq (arenaGround.arenaCount(), 2 );
        assertEq (arenaGround.arenaCount()+1, arenaGround.checkAllArenaAffairs().length);
        assertEq (arenaGround.checkAllArenaAffairs()[arenaGround.arenaCount()].arenaAmount,0 );
        assertGt (arenaGround.checkAllArenaAffairs()[arenaGround.arenaCount()-1].arenaAmount,0 );
    }

//     function test_DepositAndWithdraw() public {
//         //TODO test with eth or token deposit
//         vm.prank(msg.sender);
//         arenaGround.deposit{value:30e18}(30e18);
//         vm.prank(msg.sender);
//         arenaGround.withdraw(23e18, msg.sender);
//         assertEq( arenaGround.iconValues(address(arenaGround)) ,7e18 );
//     }

//     function test_SetArena() public {
//         assertEq( arenaGround.iconValues(topmark), 100e18 );
//         vm.prank(topmark);
//         arenaGround.SetArena(20e18 , 600 ,"");
//         assertEq( arenaGround.iconValues(topmark), 80e18 );

//         vm.prank(topmark);
//         arenaGround.SetArena(40e18 , 600 ,"");
//         assertEq( arenaGround.iconValues(topmark), 40e18 );
//         assertEq( arenaGround.arenaCount(), 2 );
//         (,uint256 currentArenaValue,,,) =  arenaGround.arena(1);
//         assertEq( currentArenaValue, 20e18 );
//         (,currentArenaValue,,,) =  arenaGround.arena(2);
//         assertEq( currentArenaValue, 40e18 );
//     }
//        function test_JoinArenaIconWinAndClaim() public {
//         assertEq( arenaGround.iconValues(bob) , 10e18 );
//         vm.prank(topmark);
//         arenaGround.SetArena( 5e18 , 31 ,"");
//         vm.warp(block.timestamp + 1);
//         vm.prank(topmark);
//         arenaGround.JoinArena( 1 , 5e18 ,"");
//         vm.warp(block.timestamp + 1);
//         vm.prank(topmark);
//         arenaGround.JoinArena( 1 , 5e18 ,"");
//         vm.warp(block.timestamp + 1);
//         vm.prank(topmark);
//         arenaGround.JoinArena( 1 , 5e18 ,"");
//         vm.warp(block.timestamp + 1);

//         vm.prank(alex);
//         arenaGround.JoinArena( 1 , 5e18 ,"");
//         vm.warp(block.timestamp + 1);
//         vm.prank(bob);
//         arenaGround.JoinArena( 1 , 5e18 ); // by now locktime would have move from 31 to 0, bob is winn,""er
//         // time most elaspe to avoid flashloan
//         vm.warp(block.timestamp + 1001);
//          vm.prank(bob);
//         arenaGround.JoinArena( 1 , 0 ); // pass in any amount to claim pri,""ce
//         assertEq( arenaGround.iconValues(bob) , 35e18 );
//     }
//     function test_JoinArenaTimeExpireForArenaSetter() public {
//         assertEq( arenaGround.iconValues(bob) , 10e18 );
//         vm.prank(owner); 
//         arenaGround.deposit{value:150e18}(150e18);// value donated to contract by owner to encourage participation
//         vm.prank(owner);
//         arenaGround.setFixedNonArenaJoinReward(100e14);

//         vm.prank(bob);
//         arenaGround.SetArena(5e18 , 600 ,"");
//         vm.warp(block.timestamp + 1001);

//         vm.prank(bob);
//         arenaGround.JoinArena( 1 , 0 ); // pass in any amount to claim price, it would not be lo,""st
//         assertEq( arenaGround.iconValues(bob) , 10e18 + 100e14 ); // Icon has made profit
//         vm.prank(bob);
//         arenaGround.withdraw(10e18 + 100e14, bob); //bob wins big
//     }
//     function test_JoinArenaTimeExpireForArenaIcon() public {
//          assertEq( arenaGround.iconValues(bob) , 10e18 );
//         vm.prank(topmark);
//         arenaGround.SetArena(5e18 , 600 ,"");
//         vm.warp(block.timestamp + 599);
//         vm.prank(alex);
//         arenaGround.JoinArena( 1 , 5e18 ,"");
//         vm.warp(block.timestamp + 1);
//         vm.prank(bob);
//         arenaGround.JoinArena( 1 , 5e18 ,"");
//         // time most elaspe to avoid flashloan
//         vm.warp(block.timestamp + 151); /// bob is now winner but cant claim yet due to flash time delay
//         vm.warp(block.timestamp + 851);
//          vm.prank(bob);
//         arenaGround.JoinArena( 1 , 0 ); // pass in any amount to claim price, it would not be lo,""st
//         assertEq( arenaGround.iconValues(bob) , 20e18 );
//     }

//     function test_JoinArenaAttackerCantCallManyAtOnceSimultaneouslyToWin() public {
//         vm.prank(bob);
//         arenaGround.SetArena(5e18 , 31 ,"");
//         vm.warp(block.timestamp + 1);

//         vm.prank(topmark); //attacker with big funds
//         arenaGround.JoinArena( 1 , 5e18 ); // pass in any amount to claim price, it would not be lo,""st
//         //vm.warp(block.timestamp + 1);
//         vm.expectRevert();
//         vm.prank(topmark); 
//         arenaGround.JoinArena( 1 , 5e18 ); // pass in any amount to claim price, it would not be lo,""st
//         vm.expectRevert();
//         vm.prank(topmark); 
//         arenaGround.JoinArena( 1 , 5e18 ,"");
//     }

//  function test_Fee() public {
//         assertEq( arenaGround.iconValues(bob) , 10e18 );
//         vm.prank(owner); 
//         arenaGround.setFee( 1e5);
//         vm.prank(owner);
//         arenaGround.deposit{value:150e18}(150e18);// value donated to contract by owner to encourage participation
//         vm.prank(owner);
//         arenaGround.setFixedNonArenaJoinReward(100e14);

//         vm.prank(bob);
//         arenaGround.SetArena(5e18 , 600 ,"");
//         vm.warp(block.timestamp + 1001);

//         vm.prank(bob);
//         arenaGround.JoinArena( 1 , 0 ); // pass in any amount to claim price, it would not be lo,""st
//         assertEq( arenaGround.iconValues(bob) , 10e18 + 100e14 ); // Icon has made profit
//         vm.prank(bob);
//         arenaGround.withdraw(10e18 + 100e14 - ((10e18 + 100e14)/10 ) , bob); //bob wins big
//     }

//     function testFuzz_SetNumber(uint256 x) public {
//        // counter.setNumber(x);
//         //assertEq(counter.number(), x);
//     } 
}
