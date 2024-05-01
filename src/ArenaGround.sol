// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract ArenaGround {
    
    struct ArenaInfo {
        uint256 arenaAmount;
        uint256 currentArenaValue;
        uint256 creationTime;
        uint256 lockTimer;
        address iconInCharge;
    }

    mapping(uint256 => ArenaInfo) public arena;
    uint256 public arenaCount;
    address public arenaKingAddress;

    // to encourage creating an arena which earns reward if no icons join
    uint256 public fixedNonArenaJoinReward = 10000;
    // from the last time anyone join or set arena it must cross 600 seconds by all means
    uint256 public priceClaimDelay = 600 seconds;
    mapping(address => uint256) public iconValues;
    // to avoid frontrunning update when each icon calls it to ensure two icons cant call within same seconds or more
    // i.e if it is arena 1 the during creation update currentCall[1] = block.timestamp and validate before subsequent call to avoid time duplicate
    mapping(uint256 => uint256) public currentCall;
    
    constructor(
        //address arenaKingAddress
    ) {
         arenaKingAddress =  address(1111); // TODO: use for now but it should come from constructor
        iconValues[address(1)] = 100e18; //topmark testss
        iconValues[address(2)] = 10e18;
        iconValues[address(3)] = 10e18;
        iconValues[address(4)] = 10e18;
        iconValues[address(5)] = 10e18;
    }

    function Deposit( uint256 amount ) public {
        /// TODO: token conversion code to contract icon value
        iconValues[msg.sender] += amount;
    }
    function Withdraw( uint256 amount ) public {
        iconValues[msg.sender] -= amount;
        /// icon value conversion code to token value
    }
    function SetArena(
        uint256 arenaAmount,
        uint256 lockTimer 
    ) public {
        require( arenaAmount > 10000 && lockTimer > 30 , "Invalid arenaAmount or lockTimer");
        uint256 creationTime = block.timestamp;
        uint256 currentArenaValue = arenaAmount;
        address iconInCharge = msg.sender;
        
        iconValues[msg.sender] -= arenaAmount;
        iconValues[address(this)] += arenaAmount;
        uint256 dumbyArenaCount = 1;
        //to avoid arena id clash
        //look for the lowest available empty slot from 1
        while ( arena[dumbyArenaCount].arenaAmount != 0  ){
        dumbyArenaCount += 1;
        }
        arenaCount += 1;
        arena[dumbyArenaCount] =  ArenaInfo(
        arenaAmount,
        currentArenaValue,
        creationTime,
        lockTimer,
        iconInCharge
        );
        currentCall[dumbyArenaCount] = block.timestamp;
    }

    function JoinArena(
        uint256 arenaNumber, 
        uint amount
        ) public {
        ArenaInfo memory arenaToJoin = arena[arenaNumber];
        /// first check for pending Price to be claimed
        ///TODO: separate this part as a different function
        if (arenaToJoin.lockTimer == 0 || (block.timestamp - arenaToJoin.creationTime > arenaToJoin.lockTimer ) ){
            
            //to prevent flashloan Attack of claiming price automatically when it is claimable
            require ( block.timestamp - arenaToJoin.creationTime  > priceClaimDelay ); 
            
            iconValues[address(this)] -= arenaToJoin.currentArenaValue;
            iconValues[msg.sender] += arenaToJoin.currentArenaValue; // claim price
            if (arenaToJoin.currentArenaValue == arenaToJoin.arenaAmount && iconValues[address(this)] >= fixedNonArenaJoinReward ){
                iconValues[address(this)] -= fixedNonArenaJoinReward;
                iconValues[msg.sender] += fixedNonArenaJoinReward; // to encourage creating an arena which earns reward if no icons join
            }
            require ( msg.sender == arenaToJoin.iconInCharge , "Unauthroized Icon" );
            delete arena[arenaNumber]; /// delete arena after winning icon is settled 
            arenaCount -= arenaCount; //update global count
            return ;
        }

        require (amount == arenaToJoin.arenaAmount , "Invalid arena Entry Amount");       

        uint256 newLockTimer  =  arenaToJoin.lockTimer/2;
        uint256 newCurrentArenaValue = arenaToJoin.currentArenaValue + amount;
        uint256 newCreationTimer = block.timestamp; 

        arena[arenaNumber] =  ArenaInfo(
        amount,
        newCurrentArenaValue,
        newCreationTimer,
        newLockTimer ,
        msg.sender
        );

        iconValues[msg.sender] -= amount;
        iconValues[address(this)] += amount;  
        //prevent multiple call at a gola to prevent attacker with mutiple entry
        require ( block.timestamp > currentCall[arenaNumber] , "multiple call in single Seconds");
        currentCall[arenaNumber] = block.timestamp;

    }
    function checkArenaAffairs(
        uint256 arenaNumber
        ) public view returns (ArenaInfo memory) {
        return arena[arenaNumber];
    }
}
