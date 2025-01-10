// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {FundsManager} from "src/FundsManager.sol";

contract FlightInsurance is ReentrancyGuard {
    /* errors */
    error FlightInsurance__AmountShouldBeMoreThanZero();
    error FlightInsurance__InvalidInsuranceId();
    error FlightInsurance__TransferFailed();

    /* interfaces, libraries, contract */

    /* Type declarations */
    enum InsuranceStatus {
        Active,
        Cancelled,
        Claimed
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
    }

    /* State variables */
    uint256 private _InsuranceCounter;
    FundsManager private immutable i_FundsManager;

    mapping(uint256 _InsuranceCounter => Insurance) private s_Insurances;

    /* Events */
    event InsuranceCreated(address indexed user, Insurance indexed insurance);
    event InsuranceStatusUpdated(uint256 insuranceId, InsuranceStatus status);

    /* Modifiers */
    modifier MoreThanZero(uint256 amount) {
        if (amount <= 0) {
            revert FlightInsurance__AmountShouldBeMoreThanZero();
        }
        _;
    }

    modifier InsuranceExists(uint256 insuranceId) {
        if (s_Insurances[insuranceId].insuranceId == 0) {
            revert FlightInsurance__InvalidInsuranceId();
        }
        _;
    }

    /* Functions */

    /* constructor */
    constructor(address fundsManagerAddress) {
        _InsuranceCounter = 0;
        i_FundsManager = FundsManager(payable(fundsManagerAddress));
    }
    /* receive function (if exists) */
    /* fallback function (if exists) */
    /* external */
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
    ) public MoreThanZero(_premiumAmount) nonReentrant {
        uint256 _InsuranceId = _InsuranceCounter++;

        s_Insurances[_InsuranceCounter] = Insurance({
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
            insuranceStatus: InsuranceStatus.Active
        });

        (bool success,) = address(i_FundsManager).call{value: s_Insurances[_InsuranceCounter].premiumAmount}("");
        if (!success) {
            revert FlightInsurance__TransferFailed();
        }

        emit InsuranceCreated(_user, s_Insurances[_InsuranceCounter]);
    }

    function updateInsuranceStatus(uint256 insuranceId, InsuranceStatus status) public InsuranceExists(insuranceId) {
        s_Insurances[insuranceId].insuranceStatus = status;
        emit InsuranceStatusUpdated(insuranceId, status);
    }

    function cancelInsurance(uint256 insuranceId) public InsuranceExists(insuranceId) {
        s_Insurances[insuranceId].insuranceStatus = InsuranceStatus.Cancelled;
        emit InsuranceStatusUpdated(insuranceId, InsuranceStatus.Cancelled);
    }
    /* internal */
    /* private */
    /* internal & private view & pure functions */
    /* external & public view & pure functions */
}
