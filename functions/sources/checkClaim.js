if (!secrets.flightDataUrl) {
    throw new Error("Flight Data URL is not set in secrets.");
  }

const flightDataRequest = Functions.makeHttpRequest({
    url: secrets.flightDataUrl,
    method: 'GET',
    headers: { accept: 'application/json' },
});

// Wait for the response
const [response] = await Promise.all([flightDataRequest]);

// Check if data exists in the response
if (!response || !response.data) {
    throw new Error("Flight data not available in the response.");
}

// Parse the arguments from the input
const flightNumber = args[0];           // Flight Number
const airlineName = args[1];            // Airline Name
const departureAirportName = args[2];   // Departure Airport
const departureDatetime = args[3];      // Departure DateTime
const arrivalAirportName = args[4];     // Arrival Airport
const arrivalDatetime = args[5];        // Arrival DateTime

// Filter the flight data based on the parameters passed as args
const filteredFlight = response.data.filter(flight => {
    return (
        flight.flightNumber === flightNumber &&
        flight.airline === airlineName &&
        flight.departureAirport === departureAirportName &&
        flight.departureTime === departureDatetime &&
        flight.arrivalAirport === arrivalAirportName &&
        flight.arrivalTime === arrivalDatetime
    );
});

// If no flight matches, throw an error
if (filteredFlight.length === 0) {
    throw new Error("No flights matching the provided parameters.");
}

// Check Claim Eligibility function
function checkClaimEligibility(delay, status) {
    // If delay is 180 minutes or more, or if the status is cancelled
    if (delay >= 180 || status === "Cancelled") {
        return true; // Eligible for claim
    }
    return false; // Not eligible for claim
}

// Process each filtered flight for claim eligibility
const claimResults = filteredFlight.map(flight => {
    const isClaimable = checkClaimEligibility(flight.delayMinutes, flight.status);
    return {
        isClaimable: isClaimable,
        delayMinutes: flight.delayMinutes // returning delay in minutes (uint)
    };
});

// Return only isClaimable and delayMinutes as JSON
return Functions.encodeString(JSON.stringify(claimResults));
