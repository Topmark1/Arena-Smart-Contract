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

    /// mapping(uint256 => ArenaInfo) public checkArenaAffairs;
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
        
        topmark = address(1);
        alex = address(2);
        bob = address(3);

        mockOP.mint(topmark, 1000e18 );
        mockOP.mint(owner, 2000_000e18 );
        mockOP.mint(alex, 100e18 );

        vm.deal(msg.sender, 200e18);
        vm.deal(owner, 1000_000e18); 

        vm.prank(address(3));
        arenaGround.ApplyForWhitelisting();
         vm.prank(address(4));
        arenaGround.ApplyForWhitelisting();
         vm.prank(address(5));
        arenaGround.ApplyForWhitelisting();

        vm.prank(owner);
        mockOP.approve(address(arenaGround), 1000_000e18);
        arenaGround.deposit( 1000_000e18 ); 
        arenaGround.activateWhitelist(address(3),  10e18);
        arenaGround.activateWhitelist(address(4),  10e18);
        arenaGround.activateWhitelist(address(5),  10e18);
    }

    function test_CheckCheck() public view {
        assertEq(arenaGround.fixedNonArenaJoinRewardCap(), 999_970e18 ); 
         
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
        assertEq(arenaGround.fixedNonArenaJoinRewardCap(), 2e18 + 999_970e18); 
         
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
         mockOP.approve(address(arenaGround), 30e18);
        arenaGround.deposit(30e18); // fixedNonArenaJoinRewardCap now 1000_000

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
        assertEq(arenaGround.fixedNonArenaJoinRewardCap(), 100_000e18); // down by 90%
        assertEq( arenaGround.iconValues(alex) , 3e18+ 900_000e18 );// user has made this big profit

        // Topmark small win
        vm.prank(topmark);
        arenaGround.SetArena(1e17, 24 hours,false,"I need it to Graduate");

        vm.warp(block.timestamp + 24 hours + 1);

        vm.prank(topmark);
        arenaGround.JoinArena( 1 , 1e17,"");
        assertEq(arenaGround.fixedNonArenaJoinRewardCap(), 99_900e18); //down by 0.1%
        assertEq( arenaGround.iconValues(topmark) , 3e18+ 100e18 ); //topmark made small profit
    }
     function test_ArenaNoEarlyWinBigOrSamll() public {
        // vm.prank(owner);
        // mockOP.approve(address(arenaGround), 1000e18);
        //  vm.prank(owner);
        // arenaGround.deposit(1000e18);

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
        assertEq(arenaGround.fixedNonArenaJoinRewardCap(), 999_970e18); 
         
    }
    function test_DonateToGiveAway() public {
        vm.prank(topmark);
         mockOP.approve(address(arenaGround), 3e18);
         vm.prank(topmark);
        arenaGround.deposit(1e18);
         vm.prank(topmark);
        arenaGround.DonateToGiveAway(2e18);
        assertEq(arenaGround.fixedNonArenaJoinRewardCap(), 2e18 + 999_970e18);   
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

    // function test_DepositAndWithdraw() public {
    //     //TODO test with eth or token deposit
    //     vm.prank(msg.sender);
    //     arenaGround.deposit{value:30e18}(30e18);
    //     vm.prank(msg.sender);
    //     arenaGround.withdraw(23e18, msg.sender);
    //     assertEq( arenaGround.iconValues(address(arenaGround)) ,7e18 );
    // }

    function test_SetArena() public {
        assertEq( arenaGround.iconValues(topmark), 0 );
        vm.startPrank(topmark);
        mockOP.approve(address(arenaGround), 100e18);
        arenaGround.deposit(100e18);
        arenaGround.SetArena(20e18 , 25 hours , false, "");
        assertEq( arenaGround.iconValues(topmark), 80e18 );

        arenaGround.SetArena(40e18 , 25 hours  , false , "");
        vm.stopPrank();
        assertEq( arenaGround.iconValues(topmark), 40e18 );
        assertEq( arenaGround.arenaCount(), 2 );
        
        uint256 currentArenaValue =  arenaGround.checkArenaAffairs(1).currentArenaValue;
        assertEq( currentArenaValue, 20e18 );
        uint256 currentArenaValue2 =  arenaGround.checkArenaAffairs(2).currentArenaValue;
        assertEq( currentArenaValue2, 40e18 );
    }
       function test_JoinArenaIconWinAndClaim() public {
        assertEq( arenaGround.iconValues(bob) , 10e18 );
        vm.prank(owner);
        arenaGround.setMinLockTimer( 30);

        vm.startPrank(topmark);
        mockOP.approve(address(arenaGround), 100e18);
        arenaGround.deposit(100e18);
        arenaGround.SetArena( 5e18 , 31, true ,"");
        vm.warp(block.timestamp + 1);
        vm.stopPrank();

        
        vm.startPrank(alex);
        mockOP.approve(address(arenaGround), 10e18);
        arenaGround.deposit(10e18);
        arenaGround.JoinArena( 1 , 5e18 ,""); // alex sabotages topmark to prevent him winning contract big reward
        vm.warp(block.timestamp + 1);
        vm.stopPrank();

        vm.prank(topmark);
        arenaGround.JoinArena( 1 , 5e18 ,""); // sabotage continues
        vm.warp(block.timestamp + 1);
        vm.prank(topmark);
        arenaGround.JoinArena( 1 , 5e18 ,"");
        vm.warp(block.timestamp + 1);

        vm.prank(alex);
        arenaGround.JoinArena( 1 , 5e18 ,"");
        vm.warp(block.timestamp + 1);
        vm.prank(bob);
        arenaGround.JoinArena( 1 , 5e18, "" ); // by now locktime would have move from 31 to 0, bob is the winner
        // time must elaspe to avoid flashloan
        vm.warp(block.timestamp + 1001);
         vm.prank(bob);
        arenaGround.JoinArena( 1 , 0 , ""); // pass in any amount to claim price
        assertEq( arenaGround.iconValues(bob) , 35e18 );
    }
    function test_JoinArenaTimeExpireForArenaSetter() public {
        assertEq( arenaGround.iconValues(bob) , 10e18 );
        vm.prank(owner); 
        mockOP.approve(address(arenaGround), 30e18);
        arenaGround.deposit(30e18);// value donated to contract by owner to encourage participation
        vm.prank(owner);
        arenaGround.setMinLockTimer( 30);

        vm.prank(bob);
        arenaGround.SetArena(5e18 , 600 , true, "");
        vm.warp(block.timestamp + 1001);

        vm.prank(bob);
        arenaGround.JoinArena( 1 , 5e18 , "" ); // pass in any amount to claim price, it would not be lost
        assertEq( arenaGround.iconValues(bob) , 10e18 + 900_000e18 ); // Icon has made profit
        vm.prank(bob);
        arenaGround.withdraw(30e18 + 900_000e18, bob); //bob wins big
    }
    function test_JoinArenaTimeExpireForArenaIcon() public {
        assertEq( arenaGround.iconValues(bob) , 10e18 );
        vm.prank(owner);
        arenaGround.setMinLockTimer( 30);

        vm.startPrank(topmark);
        mockOP.approve(address(arenaGround), 10e18);
        arenaGround.deposit(10e18);
        arenaGround.SetArena(5e18 , 600, false ,"");
        vm.stopPrank();

        vm.startPrank(alex);
        mockOP.approve(address(arenaGround), 10e18);
        arenaGround.deposit(10e18);
        vm.warp(block.timestamp + 599);
        arenaGround.JoinArena( 1 , 5e18 ,"");
        vm.stopPrank();

        vm.warp(block.timestamp + 1);
        vm.prank(bob);
        arenaGround.JoinArena( 1 , 5e18 ,"");
        // enough time must elaspe to avoid flashloan
        vm.warp(block.timestamp + 151); /// bob is now winner but cant claim yet due to flash time delay
        vm.warp(block.timestamp + 851);
         vm.prank(bob);
        arenaGround.JoinArena( 1 , 5e2, "" ); // pass in any amount to claim price, it would not be lost
        assertEq( arenaGround.iconValues(bob) , 20e18 );
    }

    function test_JoinArenaAttackerCantCallManyAtOnceSimultaneouslyToWin() public {
        vm.prank(owner);
        arenaGround.setMinLockTimer( 30);

        vm.prank(bob);
        arenaGround.SetArena(5e18 , 31 , false, "");
        vm.warp(block.timestamp + 1);

        vm.startPrank(topmark); //attacker with big funds
        mockOP.approve(address(arenaGround), 30e18);
        arenaGround.deposit(30e18);
        arenaGround.JoinArena( 1 , 5e18 , "" ); 
        vm.stopPrank();

        // caller must wait atleast a second to call again
        vm.expectRevert();
        vm.prank(topmark); 
        arenaGround.JoinArena( 1 , 5e18 ,"" );
        vm.expectRevert();
        vm.prank(topmark); 
        arenaGround.JoinArena( 1 , 5e18 ,"");
    }

 function test_Fee() public {
        vm.prank(owner);
        arenaGround.setMinLockTimer( 30);

        assertEq( arenaGround.iconValues(bob) , 10e18 );
        vm.prank(owner); 
        arenaGround.setFee( 1e5);
        vm.prank(owner);
        mockOP.approve(address(arenaGround), 30e18);
        vm.prank(owner);
        arenaGround.deposit(30e18);// value donated to contract by owner as giveaway on top previous 999,970e18

        vm.prank(bob);
        arenaGround.SetArena(5e18 , 600, true, "");
        vm.warp(block.timestamp + 1001);

        vm.prank(bob);
        arenaGround.JoinArena( 1 , 50000000e18, "" ); // pass in any amount to claim price, it would not be lost
        assertEq( arenaGround.iconValues(bob) , 10e18 + 900_000e18 ); // Icon has made profit
        assertEq(arenaGround.fixedNonArenaJoinRewardCap(), 100_000e18);
        vm.prank(bob);

        vm.warp(block.timestamp + 30 days); // since bob is whitelisted, he can only withdraw after lunch time has elapsed
        arenaGround.withdraw(10e18 + 900_000e18 , bob); //bob wins big
        assertEq( arenaGround.iconValues(bob) , 0 );

        assertEq(arenaGround.accumulatedFee(), (10e18 + 900_000e18)/10);
        vm.expectRevert(); // bob has emptied his balance
        vm.prank(bob); 
        arenaGround.withdraw( 1 ,bob );
    }
}
