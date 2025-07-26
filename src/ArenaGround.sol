// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


contract ArenaGround {
    /* 
    Hisimi ArenaGround

    This is a Giveaway Contract that aims to gift out funds to users by setting or joining arena and being alone inside the arena till the arena Lock time period expires.
Basically you can stop others from winning, others can stop you from winning, if no one stops you, you can win it all. 
    Major functions:
    1. Deposit: for users to increase their icon value, icon value is used to enter arenas with as low as a cent worth of OP, this is just to prevent sybil attacks and ensure participants are actual users that need this giveaway and not bots. Note, users should give contract transfer approval before token deposit can go through.
    2. withdraw: For users to withdraw their funds while paying a little fragment as contract fee depending on public fee set by contract owner between 0% to 5%
    3. SetArena: This function is used by users to start an arena with the aim to remain alone there for a period of Lock time, this user stand the chance of owning as much as 90% of the contract reward or giveaway value
    4. JoinArena: This function sabotages a users chance of being a alone in their arena, and the joiner stand the chance of owning the fund used by all the users who are currently in that specific arena at the moment, The lock time reduces by half everytime a new user joins the arena

    Author : Topmarktech - https://x.com/TechTopmark?t=I6h_ck2wMcKEEmjn-s4B0A&s=09
    */

    using SafeERC20 for IERC20;

    //// Events
    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount, uint256 fee);
    event ArenaCreated(uint256 indexed arenaId, address indexed creator, uint256 amount, uint256 lockTime, string message);
    event ArenaJoined(uint256 indexed arenaId, address indexed joiner, uint256 newLockTime);
    event ArenaWon(uint256 indexed arenaId, address indexed winner, uint256 reward);
    event OwnershipTransferred(address indexed newOwner);
    
    struct ArenaInfo {
        uint256 arenaAmount;
        uint256 currentArenaValue;
        uint256 creationTime;
        uint256 lockTimer;
        address iconInCharge;
        bool bigGiveAwayAim;
        string message; // emotional message to explain why you need the giveaway so that no one joins your arena
    }
  
    mapping(uint256 => ArenaInfo) public arena;
    uint256 public arenaCount;
    uint256 public currentArenaIdCap;

    // to encourage creating an arena which earns reward if no icons join
    uint256 public small = 1e5; //0.1% default
    uint256 public big = 9e7; //90% default

    // from the last time anyone join or set arena it must cross 1000 seconds by all means
    uint256 public priceClaimDelay = 1000 seconds;
    // TODO: withdrawal fee percent 10**6 precision, fixed fee for now
    uint256 public accumulatedFee;
    uint256 public fee ;
    uint256 public fixedNonArenaJoinRewardCap;
    uint256 public launchTime;
    uint256 public minLockTimer;
    uint256 public minArenaAmount = 1e16;
   
    mapping(address => uint256) public iconValues;
    // to avoid frontrunning update when each icon calls it to ensure two icons cant call within same seconds or more
    // i.e if it is arena 1 the during creation update currentCall[1] = block.timestamp and validate before subsequent call to avoid time duplicate
    mapping(uint256 => uint256) public currentCall;

    mapping(address => uint256) public leaderBoardValues;
    mapping(uint256 => address) public leaderBoardActives;
    uint256 leads;

    // whitelistedaddresses cant withdraw their funds untill lunch time expiry but they can participate like every other participant and theor fund is safe
    mapping (address => bool) whitelistedAddresses;
    // to ensure only users that want to be whitelisted to prevent owner from locking users funds in contract
    mapping (address => bool) applyForWhitelist;

    // keeps of address donating to giveway as they are entitled to percentage of available shares, 1e8 max 
    uint256 public availableFeeShares;
    mapping (address => uint256 ) public feeShares;

    address owner ;

    IERC20 public token;  // Optimism token (OP)
    

    constructor(
        uint256 _launchTime,
        address _tokenAddress
    ) {
        launchTime = _launchTime + block.timestamp;
        owner = msg.sender; 
        minLockTimer = 24 hours;
        token = IERC20(_tokenAddress);  // Set token address for Optimism (OP token)
        feeShares[msg.sender] =  1e8; // creator gets 100% by default and would be reduced as donations are made to contract
    }
  
    function deposit( uint256 amount ) public payable {
      // Deposit OP (Optimism ERC-20 token), users need to make approval for contract first
        token.safeTransferFrom(msg.sender, address(this), amount);
        if(msg.sender == owner){
            fixedNonArenaJoinRewardCap += amount;
             return ;
        }
        iconValues[msg.sender] += amount;
        emit Deposited(msg.sender, amount);
    }
    function withdraw(uint256 amount, address recipient) public {
         //OP withdrawal
            if (recipient == address(0)) recipient = msg.sender ;
                if(msg.sender == owner){
                    require(amount <= accumulatedFee + fixedNonArenaJoinRewardCap, "Owner cant Withdraw Users Fund");
                    if( amount <= accumulatedFee){
                      accumulatedFee -= amount;
                     }else{
                    fixedNonArenaJoinRewardCap -= amount;
                     }

                    token.safeTransfer(recipient, amount); // Withdraw fee in OP token (ERC-20)
                    if (address(this).balance > 0){ // to withdraw contract donations and accidental native tokens
                     (bool success, ) = recipient.call{value: address(this).balance}("");
                    require(success, "Transfer failed.");
                    }
                return ;
                }

        //whitelisted addresses can withdraw untill lunch time but can participate in giveaways like everyother users untill lunch time
        if ( whitelistedAddresses[msg.sender] && block.timestamp < launchTime ) return; 

        // Ensure the sender has enough balance to withdraw
        require(iconValues[msg.sender] >= amount, "Insufficient balance");

        // Subtract the requested amount from sender's balance
        iconValues[msg.sender] -= amount;
        uint256 feeValue = fee * amount / 1e6 ;
        accumulatedFee += feeValue;

          if (amount > 0) {
            require(token.balanceOf(address(this)) >= (amount-feeValue), "Insufficient OP balance");
            token.safeTransfer(recipient, (amount-feeValue));
            }
        emit Withdrawn(msg.sender, amount, feeValue);
    }

    /*
    *params 
    arenaAmout: the Amount used to to start arena and also determines the value needed by anyone that wants to join the arena
    LockTimer: the time period that arena setter must stay in the arena without having a new participant to have right to claim contract fund, the lowest possible is 24hours by default but subject to change depending on owner and contract economy
    bigGiveAwayAim: user can aim for a big contract reward of small if they remain alone in the contract
    _message :  Emotional message to explain why you need the giveaway so that no one joins your arena
    */
    function SetArena(
        uint256 arenaAmount,
        uint256 lockTimer,
        bool bigGiveAwayAim,
        string calldata _message
    ) public {
        require( arenaAmount >= minArenaAmount && lockTimer >= minLockTimer , "Invalid arenaAmount or lockTimer");
        require(bytes(_message).length <= 50, "Message too long");
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
        currentArenaIdCap = currentArenaIdCap < dumbyArenaCount? dumbyArenaCount: currentArenaIdCap;
        arena[dumbyArenaCount] =  ArenaInfo(
        arenaAmount,
        currentArenaValue,
        creationTime,
        lockTimer,
        iconInCharge,
        bigGiveAwayAim,
        _message
        );
        currentCall[dumbyArenaCount] = block.timestamp;
        emit ArenaCreated( dumbyArenaCount, iconInCharge, arenaAmount, lockTimer , _message);
    }

    /// to participate in arrena and also used by winner to claim arena victory
    // Remain Alone in Your Arena to get contract win or be the last man standing and arena Owner to win!!!
    function JoinArena(
        uint256 arenaNumber, 
        uint amount,
        string calldata newMessage
        ) public {
        require(bytes(newMessage).length <= 50, "Message too long");
        
        ArenaInfo memory arenaToJoin = arena[arenaNumber];
        /// first check for pending Price to be claimed
        ///TODO: separate this part as a different function
        if (arenaToJoin.lockTimer == 0 || (block.timestamp - arenaToJoin.creationTime > arenaToJoin.lockTimer ) ){
            
            //to prevent flashloan Attack of claiming price automatically when it is claimable
            require ( block.timestamp - arenaToJoin.creationTime  > priceClaimDelay, "Cant Claim Price Yet"); 
            
            iconValues[msg.sender] += arenaToJoin.currentArenaValue; // claim price
            if (leaderBoardValues[msg.sender] == 0) leaderBoardActives[++leads] = msg.sender;

            if (arenaToJoin.currentArenaValue == arenaToJoin.arenaAmount  ){
                uint256 reward; // to encourage creating an arena which earns reward if no icons join
                if (arenaToJoin.bigGiveAwayAim){ 
                reward = fixedNonArenaJoinRewardCap * big / 1e8;
                fixedNonArenaJoinRewardCap -= reward;
                iconValues[msg.sender] += reward; 
                leaderBoardValues[msg.sender] += reward;
                }
                else{
                reward = fixedNonArenaJoinRewardCap * small / 1e8;
                fixedNonArenaJoinRewardCap -= reward;
                iconValues[msg.sender] += reward; 
                leaderBoardValues[msg.sender] += reward;
                }

                emit ArenaWon(arenaNumber, msg.sender, reward);
            }
            else{
                leaderBoardValues[msg.sender] += arenaToJoin.currentArenaValue - arenaToJoin.arenaAmount;
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
        msg.sender ,
        arenaToJoin.bigGiveAwayAim,
        newMessage
        );

        iconValues[msg.sender] -= amount;
        //prevent multiple call at a goal to prevent attacker with mutiple entry
        require ( block.timestamp > currentCall[arenaNumber] , "multiple call in single Seconds");
        currentCall[arenaNumber] = block.timestamp;

        emit ArenaJoined(arenaNumber, msg.sender, newLockTimer);
    }

    function DonateToGiveAway(
        uint256 amount
    ) public {
        token.safeTransferFrom(msg.sender, address(this), amount);
        fixedNonArenaJoinRewardCap += amount;
            if(availableFeeShares >  amount / 1e18){
                availableFeeShares -= amount / 1e18;
                feeShares[owner] -= amount / 1e18;
                feeShares[msg.sender] += amount / 1e18;
            }
            else{
                feeShares[owner] -= availableFeeShares;
                feeShares[msg.sender] += availableFeeShares;
                availableFeeShares = 0;
            }
    }

    function transferFeeShares(
        uint256 amount,
        address to
    ) public {
        require(to != address(0), "Invalid address");
        feeShares[msg.sender] -= amount;
        feeShares[to] += amount;
    }

     // to prevent owner from locking users fund using whitelist function, so only addresses that apply get this opportunity
    function ApplyForWhitelisting() public{ 
        applyForWhitelist[msg.sender] = true;
    }

    ///// Views
    function checkArenaAffairs(
        uint256 arenaNumber
        ) public view returns (ArenaInfo memory) {
        return arena[arenaNumber];
    }
    function checkAllArenaAffairs() public view returns (ArenaInfo[] memory) {
            ArenaInfo[] memory arenas =  new ArenaInfo[](arenaCount+1); //plus 1 for validation purpose, the last array position must be empty
            uint256 j;
            for (uint256 i = 0; i <= currentArenaIdCap ; i++){
                if (arena[i].arenaAmount != 0)
                arenas[j++] = arena[i];
            }
            //uint256 arrayLength = arenas.length;
        return arenas ;
    }
    function checkUserBalance(
        address user
        ) public view returns (uint256) {
        return iconValues[user];
    }
       function ownerView() public view returns (address) {
        return owner;
    }

    /////Admin Setters 
    function setBigSmallRewardPercent(uint256 _big, uint256 _small ) external{
        require(owner == msg.sender, "Unauthorized Caller");
        require ( _big < 9e7 && small < 5e6, "GiveAwayReward Error");
        big = _big;
        small = _small;
    }
    function setPriceClaimDelay(uint256 _priceClaimDelay) external{
        require(owner == msg.sender, "Unauthorized Caller");
        priceClaimDelay = _priceClaimDelay;
    }
    function setFee(uint256 _newfee) external{
        require(owner == msg.sender, "Unauthorized Caller");
        require (_newfee <= 1e5,"Fee above 10%");
        fee = _newfee;
    }
    function setAvailableFeeShares(uint256 _newAvailableFeeShares) external{
        require(owner == msg.sender, "Unauthorized Caller");
        require (_newAvailableFeeShares <= 1e8,"Fee above 100%");
        availableFeeShares = _newAvailableFeeShares;
    }
    function setMinLockTimer(uint256 _newminLockTimer) external{
        require(owner == msg.sender, "Unauthorized Caller");
        minLockTimer = _newminLockTimer;
    }
    function setMinArenaAmount(uint256 _minArenaAmount) external{
        require(owner == msg.sender, "Unauthorized Caller");
        minArenaAmount = _minArenaAmount;
    }
    function activateWhitelist(address whitelist, uint256 value) public{
        require(owner == msg.sender, "Unauthorized Caller");
        require(applyForWhitelist[whitelist]);
        require(block.timestamp < launchTime);
        //owner is a trusted role which will ensure this will not be taken advantage of to drain reward
        // value will be determined by governance as protocol progress
        require(value < (fixedNonArenaJoinRewardCap/100) , "excess value for Whitelist");

        whitelistedAddresses[whitelist] = true;
        iconValues[whitelist] += value; 
        fixedNonArenaJoinRewardCap -= value;
    }
    function setNewOwner(address _newOwner) external{
        require(owner == msg.sender, "Unauthorized Caller");
        owner = _newOwner;
        emit OwnershipTransferred(_newOwner);
    }
    receive() external payable{}
}
