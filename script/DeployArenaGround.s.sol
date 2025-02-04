// // SPDX-License-Identifier: UNLICENSED
 pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import {ArenaGround} from "../src/ArenaGround.sol";

contract DeployArenaGround is Script {
    function run() public {
        // Set up private key and RPC URL
        //uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        //address deployer = vm.addr(deployerPrivateKey); 
        vm.startBroadcast();

        // Deploy the contract
        ArenaGround arena = new ArenaGround(31536000); // example constructor args

        // End deployment
        //vm.stopBroadcast();
    }
}
// import {Script, console2} from "forge-std/Script.sol";

// contract CounterScript is Script {
//     function setUp() public {}

//     function run() public {
//         vm.broadcast();
//     }
// }
// script/DeployArenaGround.s.sol