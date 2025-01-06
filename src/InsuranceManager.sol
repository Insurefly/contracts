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

    mapping(bytes32 requestId => Request) private s_requestIdToRequest;
    // JavaScript source code
    // Fetch character name from the Star Wars API.
    // Documentation: https://swapi.info/people
    // string source = "const characterId = args[0];" "const apiResponse = await Functions.makeHttpRequest({"
    //     "url: `https://swapi.info/api/people/${characterId}/`" "});" "if (apiResponse.error) {"
    //     "throw Error('Request failed');" "}" "const { data } = apiResponse;" "return Functions.encodeString(data.name);";

    // State variable to store the returned character information
    // string public character;

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

    function sendClaimCalculationRequest(address user, uint256 claimAmount, string[] calldata args)
        external
        onlyOwner
        returns (bytes32 requestId)
    {}

    /**
     * @notice Callback function for fulfilling a request
     * @param requestId The ID of the request to fulfill
     * @param response The HTTP response data
     * @param err Any errors from the Functions request
     */
    function fulfillRequest(bytes32 requestId, bytes memory response, bytes memory err) internal override {}

    /* receive function (if exists) */
    /* fallback function (if exists) */
    /* external */
    /* public */
    /* internal */
    /* private */
    /* internal & private view & pure functions */
    /* external & public view & pure functions */
}
