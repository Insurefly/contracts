// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {FlightInsurance} from "src/FlightInsurance.sol";

contract FundsManager {
    /* errors */
    /* interfaces, libraries, contract */

    /* Type declarations */
    /* State variables */
    /* Events */
    /* Modifiers */
    /* Functions */

    /* constructor */

    /* receive function (if exists) */
    receive() external payable {} // Function to receive Ether. msg.data must be empty

    /* fallback function (if exists) */
    fallback() external payable {} // Fallback function is called when msg.data is not empty

    /* external */
    /* public */
    /* internal */
    /* private */
    /* internal & private view & pure functions */
    /* external & public view & pure functions */
}
