// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/FunctionsClient.sol";
import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";

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
    /* interfaces, libraries, contract */
    using FunctionsRequest for FunctionsRequest.Request;

    /* Type declarations */

    enum CheckClaimOrCalculateClaim {
        CheckClaim,
        CalculateClaim
    }

    struct Request {
        address user;
        uint256 claimAmount;
        CheckClaimOrCalculateClaim checkClaimOrCalculateClaim;
    }
    /* State variables */

    address private immutable router;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_gasLimit;
    bytes32 private immutable i_donID;

    string private s_ClaimSourceCode;
    string private s_CalculateClaimSourceCode;
    bytes public s_lastResponse;
    bytes public s_lastError;

    mapping(bytes32 requestId => Request) private s_requestIdToRequest;

    /* Events */
    /* Modifiers */
    /* Functions */
    /* constructor */

    constructor(address _router, uint64 subscriptionId, uint32 gasLimit, bytes32 donID, string memory claimSourceCode)
        FunctionsClient(_router)
        ConfirmedOwner(msg.sender)
    {
        router = _router;
        i_subscriptionId = subscriptionId;
        i_gasLimit = gasLimit;
        i_donID = donID;
        s_ClaimSourceCode = claimSourceCode;
    }

    function sendClaimRequest(address user, uint256 claimAmount, string[] calldata args)
        external
        onlyOwner
        returns (bytes32 requestId)
    {
        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(s_ClaimSourceCode); // Initialize the request with JS code
        if (args.length > 0) req.setArgs(args); // Set the arguments for the request

        requestId = _sendRequest(req.encodeCBOR(), i_subscriptionId, i_gasLimit, i_donID);
        s_requestIdToRequest[requestId] = Request(user, claimAmount, CheckClaimOrCalculateClaim.CheckClaim);
        return requestId;
    }

    function _claimFullfillRequest(bytes memory response) internal pure returns (bool isClaimable) {
        uint256 claim = (uint256(bytes32(response)));
        if (claim == 1) {
            return true;
        } else {
            return false;
        }
    }

    function sendCalculateClaimRequest(address user, uint256 claimAmount, string[] calldata args)
        external
        onlyOwner
        returns (bytes32 requestId)
    {
        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(s_CalculateClaimSourceCode); // Initialize the request with JS code
        if (args.length > 0) req.setArgs(args); // Set the arguments for the request

        requestId = _sendRequest(req.encodeCBOR(), i_subscriptionId, i_gasLimit, i_donID);
        s_requestIdToRequest[requestId] = Request(user, claimAmount, CheckClaimOrCalculateClaim.CalculateClaim);
        return requestId;
    }

    function _calculateClaimFullfillRequest() internal {}

    function fulfillRequest(bytes32 requestId, bytes memory response, bytes memory err) internal override {
        if (s_requestIdToRequest[requestId].checkClaimOrCalculateClaim == CheckClaimOrCalculateClaim.CheckClaim) {
            _claimFullfillRequest(response);
        } else {
            _calculateClaimFullfillRequest();
        }
        s_lastResponse = response;
        s_lastError = err;
    }

    function _transferClaim() internal {}

    /* receive function (if exists) */
    /* fallback function (if exists) */
    /* external */
    /* public */
    /* internal */
    /* private */
    /* internal & private view & pure functions */
    /* external & public view & pure functions */
}
