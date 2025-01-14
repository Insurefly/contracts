// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/Strings.sol";
import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/FunctionsClient.sol";
import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";
import {FlightInsurance} from "src/FlightInsurance.sol";
import {FundsManager} from "src/FundsManager.sol";

/**
 * @title Insurance Manager
 * @author Prowlerx15
 * @notice This contract will manage all the insurances.
 * @notice The contract also contains the claim insurance feature. The contract uses Chainlink function to check if the insurance CAN BE CLAIMED or NOT.
 * @notice If the insurance can be claimed then the user will be funded with the claim amount.
 * @notice The contract first calculates the claim amount by using Chainlink functions.
 * @notice The claim calculation logic is executed on Chainlink oracles to reduce computation cost while keeping decentralization.
 * @notice Then the claim amount is funded to the user.
 */
contract InsuranceManager is ConfirmedOwner, FunctionsClient {
    /* errors */
    error InsuranceManager__InvalidAmount();
    error InsuranceManager__RequestNotFound();
    error InsuranceManager__ClaimAlreadyProcessed();

    /* interfaces, libraries, contract */
    using FunctionsRequest for FunctionsRequest.Request;

    /* Type declarations */

    enum ClaimType {
        CheckClaim,
        CalculateClaim
    }

    struct ClaimRequest {
        address user;
        uint256 premiumAmount;
        ClaimType claimType;
        bool processed;
        bool isValid;
    }

    /* State variables */
    address private immutable router;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_gasLimit;
    bytes32 private immutable i_donID;

    FundsManager private immutable i_FundsManager;

    string private s_ClaimSourceCode;
    string private s_CalculateClaimSourceCode;
    bytes public s_lastResponse;
    bytes public s_lastError;

    uint64 s_secretVersion;
    uint8 s_secretSlot;

    mapping(bytes32 requestId => ClaimRequest) private s_requestIdToRequest;

    /* Events */
    event ClaimRequestInitiated(bytes32 indexed requestId, address indexed user, ClaimType claimType);
    event ClaimProcessed(bytes32 indexed requestId, address indexed user, bool success);
    event ClaimPaid(address indexed user, uint256 amount, bytes32 indexed requestId);

    /* Modifiers */
    modifier amountMustBeGreatThanZero(uint256 premiumAmount) {
        if (premiumAmount == 0) {
            revert InsuranceManager__InvalidAmount();
        }
        _;
    }

    modifier validRequest(bytes32 requestId) {
        if (!s_requestIdToRequest[requestId].isValid) {
            revert InsuranceManager__RequestNotFound();
        }
        _;
    }

    modifier notProcessed(bytes32 requestId) {
        if (s_requestIdToRequest[requestId].processed) {
            revert InsuranceManager__ClaimAlreadyProcessed();
        }
        _;
    }
    /* Functions */
    /* constructor */

    constructor(
        address _router,
        uint64 subscriptionId,
        uint32 gasLimit,
        bytes32 donID,
        string memory claimSourceCode,
        string memory calculateClaimSourceCode,
        address fundsManagerAddress,
        uint64 secretVersion,
        uint8 secretSlot
    ) FunctionsClient(_router) ConfirmedOwner(msg.sender) {
        router = _router;
        i_subscriptionId = subscriptionId;
        i_gasLimit = gasLimit;
        i_donID = donID;
        s_ClaimSourceCode = claimSourceCode;
        s_CalculateClaimSourceCode = calculateClaimSourceCode;
        i_FundsManager = FundsManager(payable(fundsManagerAddress));

        s_secretVersion = secretVersion;
        s_secretSlot = secretSlot;
    }

    /* receive function (if exists) */
    /* fallback function (if exists) */

    /* external */
    function sendClaimRequest(address user, uint256 premiumAmount, string[] calldata args)
        external
        amountMustBeGreatThanZero(premiumAmount)
        returns (bytes32 requestId)
    {
        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(s_ClaimSourceCode); // Initialize the request with JS code
        if (args.length > 0) req.setArgs(args); // Set the arguments for the request

        requestId = _sendRequest(req.encodeCBOR(), i_subscriptionId, i_gasLimit, i_donID);

        // s_requestIdToRequest[requestId] = ClaimRequest(user, claimAmount, ClaimType.CheckClaim);
        s_requestIdToRequest[requestId] = ClaimRequest({
            user: user,
            premiumAmount: premiumAmount,
            claimType: ClaimType.CheckClaim,
            processed: false,
            isValid: true
        });

        emit ClaimRequestInitiated(requestId, user, ClaimType.CheckClaim);
        return requestId;
    }

    function sendCalculateClaimRequest(address user, uint256 premiumAmount, uint256 delay)
        public
        amountMustBeGreatThanZero(premiumAmount)
        returns (bytes32 requestId)
    {
        string[] memory args = new string[](2);
        args[0] = Strings.toString(premiumAmount);
        args[1] = Strings.toString(delay);

        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(s_CalculateClaimSourceCode); // Initialize the request with JS code
        if (args.length > 0) req.setArgs(args); // Set the arguments for the request

        requestId = _sendRequest(req.encodeCBOR(), i_subscriptionId, i_gasLimit, i_donID);

        s_requestIdToRequest[requestId] = ClaimRequest({
            user: user,
            premiumAmount: premiumAmount,
            claimType: ClaimType.CalculateClaim,
            processed: false,
            isValid: true
        });

        emit ClaimRequestInitiated(requestId, user, ClaimType.CalculateClaim);
        return requestId;
    }

    /* public */

    /* internal */
    function fulfillRequest(bytes32 requestId, bytes memory response, bytes memory err)
        internal
        override
        validRequest(requestId)
        notProcessed(requestId)
    {
        s_requestIdToRequest[requestId].processed = true;

        if (s_requestIdToRequest[requestId].claimType == ClaimType.CheckClaim) {
            (bool isClaimable, uint256 delay) = _claimFullfillRequest(response);
            if (isClaimable) {
                _processClaim(requestId, delay);
            }
        } else {
            uint256 claimAmount = _calculateClaimFullfillRequest(response);
            _transferClaim(s_requestIdToRequest[requestId].user, claimAmount, requestId);
        }

        s_lastResponse = response;
        s_lastError = err;

        emit ClaimProcessed(requestId, s_requestIdToRequest[requestId].user, true);
    }
    /* private */

    /* internal & private view & pure functions */
    function _claimFullfillRequest(bytes memory response) internal pure returns (bool isClaimable, uint256 delay) {
        delay = (uint256(bytes32(response)));
        if (delay >= 180) {
            return (true, delay);
        } else {
            return (false, delay);
        }
    }

    function _calculateClaimFullfillRequest(bytes memory response) internal pure returns (uint256 claimAmount) {
        claimAmount = (uint256(bytes32(response)));
        return claimAmount;
    }

    function _processClaim(bytes32 requestId, uint256 delay) internal {
        sendCalculateClaimRequest(
            s_requestIdToRequest[requestId].user, s_requestIdToRequest[requestId].premiumAmount, delay
        );
    }

    function _transferClaim(address user, uint256 amount, bytes32 requestId) internal {
        i_FundsManager.payClaim(user, amount);
        emit ClaimPaid(user, amount, requestId);
    }

    /* external & public view & pure functions */
    function getRouter() external view returns (address) {
        return router;
    }

    function getSubscriptionId() external view returns (uint64) {
        return i_subscriptionId;
    }

    function getGasLimit() external view returns (uint32) {
        return i_gasLimit;
    }

    function getDonID() external view returns (bytes32) {
        return i_donID;
    }

    function getClaimSourceCode() external view returns (string memory) {
        return s_ClaimSourceCode;
    }

    function getCalculateClaimSourceCode() external view returns (string memory) {
        return s_CalculateClaimSourceCode;
    }

    function getLastResponse() external view returns (bytes memory) {
        return s_lastResponse;
    }

    function getLastError() external view returns (bytes memory) {
        return s_lastError;
    }

    function getRequestDetails(bytes32 requestId) external view returns (ClaimRequest memory) {
        return s_requestIdToRequest[requestId];
    }
}
