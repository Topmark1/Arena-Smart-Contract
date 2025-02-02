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

    ///TODO admin reset depending on contract active
    // to encourage creating an arena which earns reward if no icons join
    uint256 public fixedNonArenaJoinReward = 10000;
    // from the last time anyone join or set arena it must cross 600 seconds by all means
    uint256 public priceClaimDelay = 600 seconds;
    // TODO: withdrawal fee percent 10**6 precision, fixed fee for now
    uint256 public accumulatedFee;
    uint256 public fee ;
    uint256 public fixedNonArenaJoinRewardCap;
    uint256 public launchTime;

    mapping(address => uint256) public iconValues;
    // to avoid frontrunning update when each icon calls it to ensure two icons cant call within same seconds or more
    // i.e if it is arena 1 the during creation update currentCall[1] = block.timestamp and validate before subsequent call to avoid time duplicate
    mapping(uint256 => uint256) public currentCall;
    address owner ;
    
    constructor(
        uint256 _launchTime
    ) {
        launchTime = _launchTime + block.timestamp;
        owner = msg.sender; //arenaKingAddress
    }
 
    function deposit( uint256 amount ) public payable {
        if(msg.sender == owner){
            fixedNonArenaJoinRewardCap += msg.value;
             iconValues[address(this)] += msg.value;
             return ;
        }
        /// TODO: token conversion code to contract icon value
        require(msg.value == amount,"Amount Error");
        iconValues[msg.sender] += amount;
        iconValues[address(this)] += amount;
    }
    function withdraw(uint256 amount, address recipient) public {
       if(msg.sender == owner){
            accumulatedFee -= amount;
            (bool success, ) = recipient.call{value: amount}("");
            require(success, "Transfer failed");
            return ;
        }
        // Ensure the sender has enough balance to withdraw
        require(iconValues[msg.sender] >= amount, "Insufficient balance");

        // Subtract the requested amount from sender's balance
        iconValues[msg.sender] -= amount;
        iconValues[address(this)] -= (amount-fee);
        accumulatedFee += fee;

         // Send the requested amount of Ether to the sender
        (bool success2, ) = recipient.call{value: amount - fee}("");
        require(success2, "Transfer failedd");
    }
    function SetArena(
        uint256 arenaAmount,
        uint256 lockTimer 
    ) public {
        require( arenaAmount >= 1e15 && lockTimer > 30 , "Invalid arenaAmount or lockTimer");
        uint256 creationTime = block.timestamp;
        uint256 currentArenaValue = arenaAmount;
        address iconInCharge = msg.sender;
        
        iconValues[msg.sender] -= arenaAmount;
        
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

    /// to participate in arrena and also used by winner to claim arena victory
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
            
            iconValues[msg.sender] += arenaToJoin.currentArenaValue; // claim price

            if (arenaToJoin.currentArenaValue == arenaToJoin.arenaAmount && fixedNonArenaJoinRewardCap >= fixedNonArenaJoinReward ){
                fixedNonArenaJoinRewardCap -= fixedNonArenaJoinReward;
                iconValues[msg.sender] += fixedNonArenaJoinReward; // to encourage creating an arena which earns reward if no icons join
            }
            require ( msg.sender == arenaToJoin.iconInCharge , "Unauthroized Icon" );
            delete arena[arenaNumber]; /// delete arena after winning icon is settled 
            arenaCount -= 1; //update global count
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
        //prevent multiple call at a goal to prevent attacker with mutiple entry
        require ( block.timestamp > currentCall[arenaNumber] , "multiple call in single Seconds");
        currentCall[arenaNumber] = block.timestamp;

    }
    ///// Views
    function checkArenaAffairs(
        uint256 arenaNumber
        ) public view returns (ArenaInfo memory) {
        return arena[arenaNumber];
    }
       function ownerView() public view returns (address) {
        return owner;
    }

    /////Admin Setters 
    function setFixedNonArenaJoinReward(uint256 _fixedNonArenaJoinReward) external{
        require(owner == msg.sender, "Unauthorized Caller");
        fixedNonArenaJoinReward = _fixedNonArenaJoinReward;
    }
    function setPriceClaimDelay(uint256 _priceClaimDelay) external{
        require(owner == msg.sender, "Unauthorized Caller");
        priceClaimDelay = _priceClaimDelay;
    }
    function setFee(uint256 _newfee) external{
        require(owner == msg.sender, "Unauthorized Caller");
        fee = _newfee;
    }
    function activateWhitelist(address whitelist, uint256 value) public{
        require(owner == msg.sender, "Unauthorized Caller");
        require(block.timestamp < launchTime);
        iconValues[whitelist] = value; 
    }
        
    function setNewOwner(address _newOwner) external{
        require(owner == msg.sender, "Unauthorized Caller");
        owner = _newOwner;
    }
}
