// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {FundsManager} from "src/FundsManager.sol";
import {InsuranceManager} from "src/InsuranceManager.sol";

/**
 * @title Flight Insurance Contract
 * @author Prowlerx15
 * @notice This contract allows users to purchase flight insurance for their flights.
 *         It includes functionalities like purchasing insurance, claiming insurance,
 *         canceling insurance, and querying insurance details.
 */
contract FlightInsurance is ReentrancyGuard {
    /* errors */
    error FlightInsurance__AmountShouldBeMoreThanZero();
    error FlightInsurance__InvalidInsuranceId();
    error FlightInsurance__TransferFailed();
    error FlightInsurance__Unauthorized();
    error FlightInsurance__InvalidStatus();

    /* interfaces, libraries, contract */

    /* Type declarations */
    enum InsuranceStatus {
        Active,
        Cancelled,
        Claimed,
        Expired
    }

    struct Airport {
        string code;
        string name;
    }

    struct Airline {
        string code;
        string name;
    }

    struct Flight {
        string flightNumber;
        Airline airline;
        Airport departureAirport;
        Airport arrivalAirport;
        string departureDateAndTime;
        string arrivalDateAndTime;
    }

    struct Insurance {
        uint256 insuranceId;
        address user;
        uint256 premiumAmount;
        Flight ticket;
        InsuranceStatus insuranceStatus;
        uint256 createdAt;
    }

    /* State variables */
    uint256 private s_InsuranceCounter;

    FundsManager private immutable i_FundsManager;
    InsuranceManager private immutable i_InsuranceManager;

    uint256 private constant INSURANCE_VALIDITY_PERIOD = 30 days;

    mapping(uint256 _InsuranceCounter => Insurance) private s_Insurances;
    mapping(address => uint256[]) private s_UserInsurances;

    /* Events */
    event InsuranceCreated(address indexed user, Insurance indexed insurance);
    event InsuranceStatusUpdated(uint256 insuranceId, InsuranceStatus status);
    event InsuranceClaimed(uint256 indexed insuranceId, address indexed user);

    /* Modifiers */

    modifier InsuranceExists(uint256 insuranceId) {
        if (s_Insurances[insuranceId].insuranceId == 0) {
            revert FlightInsurance__InvalidInsuranceId();
        }
        _;
    }

    modifier onlyInsuranceOwner(uint256 insuranceId) {
        if (s_Insurances[insuranceId].user != msg.sender) {
            revert FlightInsurance__Unauthorized();
        }
        _;
    }

    /* Functions */

    /* constructor */
    constructor(address fundsManagerAddress, address insuranceManagerAddress) {
        s_InsuranceCounter = 0;
        i_FundsManager = FundsManager(payable(fundsManagerAddress));
        i_InsuranceManager = InsuranceManager(insuranceManagerAddress);
    }

    /* public */
    function createInsurance(
        address _user,
        uint256 _premiumAmount,
        string memory _flightNumber,
        string memory _airlineCode,
        string memory _airlineName,
        string memory _departureAirportCode,
        string memory _departureAirportName,
        string memory _departureDateAndTime,
        string memory _arrivalAirportCode,
        string memory _arrivalAirportName,
        string memory _arrivalDateAndTime
    ) public nonReentrant {
        uint256 _InsuranceId = s_InsuranceCounter++;

        s_Insurances[s_InsuranceCounter] = Insurance({
            insuranceId: _InsuranceId,
            user: _user,
            premiumAmount: _premiumAmount,
            ticket: Flight({
                flightNumber: _flightNumber,
                airline: Airline({code: _airlineCode, name: _airlineName}),
                departureAirport: Airport({code: _departureAirportCode, name: _departureAirportName}),
                departureDateAndTime: _departureDateAndTime,
                arrivalAirport: Airport({code: _arrivalAirportCode, name: _arrivalAirportName}),
                arrivalDateAndTime: _arrivalDateAndTime
            }),
            insuranceStatus: InsuranceStatus.Active,
            createdAt: block.timestamp
        });

        s_UserInsurances[_user].push(_InsuranceId);

        i_FundsManager.depositPremium{value: _premiumAmount}(_user);

        emit InsuranceCreated(_user, s_Insurances[s_InsuranceCounter]);
    }

    function initiateClaimRequest(uint256 insuranceId)
        public
        InsuranceExists(insuranceId)
        onlyInsuranceOwner(insuranceId)
    {
        if (s_Insurances[insuranceId].insuranceStatus != InsuranceStatus.Active) {
            revert FlightInsurance__InvalidStatus();
        }

        if (block.timestamp > s_Insurances[insuranceId].createdAt + INSURANCE_VALIDITY_PERIOD) {
            s_Insurances[insuranceId].insuranceStatus = InsuranceStatus.Expired;
            emit InsuranceStatusUpdated(insuranceId, InsuranceStatus.Expired);
            revert FlightInsurance__InvalidStatus();
        }

        string[] memory args = new string[](5);
        args[0] = s_Insurances[insuranceId].ticket.flightNumber;
        args[1] = s_Insurances[insuranceId].ticket.departureAirport.name;
        args[2] = s_Insurances[insuranceId].ticket.departureDateAndTime;
        args[3] = s_Insurances[insuranceId].ticket.arrivalAirport.name;
        args[4] = s_Insurances[insuranceId].ticket.arrivalDateAndTime;

        i_InsuranceManager.sendClaimRequest(msg.sender, s_Insurances[insuranceId].premiumAmount, args);

        s_Insurances[s_InsuranceCounter].insuranceStatus = InsuranceStatus.Claimed;

        emit InsuranceClaimed(insuranceId, s_Insurances[insuranceId].user);
    }

    function cancelInsurance(uint256 insuranceId) public InsuranceExists(insuranceId) onlyInsuranceOwner(insuranceId) {
        if (s_Insurances[insuranceId].insuranceStatus != InsuranceStatus.Active) {
            revert FlightInsurance__InvalidStatus();
        }

        s_Insurances[insuranceId].insuranceStatus = InsuranceStatus.Cancelled;
        i_FundsManager.payClaim(msg.sender, s_Insurances[insuranceId].premiumAmount / 2); // 50% refund on cancellation

        emit InsuranceStatusUpdated(insuranceId, InsuranceStatus.Cancelled);
    }

    /* internal */
    function _UpdateInsuranceStatus(uint256 insuranceId, InsuranceStatus status)
        internal
        InsuranceExists(insuranceId)
    {
        s_Insurances[insuranceId].insuranceStatus = status;
        emit InsuranceStatusUpdated(insuranceId, status);
    }

    /* external & public view & pure functions */
    function getInsurance(uint256 insuranceId) external view returns (Insurance memory) {
        return s_Insurances[insuranceId];
    }

    function getUserInsurances(address user) external view returns (uint256[] memory) {
        return s_UserInsurances[user];
    }

    function getInsuranceCounter() external view returns (uint256) {
        return s_InsuranceCounter;
    }
}
