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

// Extract delayMinutes from the first matching flight
const delayMinutes = filteredFlight[0].delayMinutes;
if (delayMinutes === undefined || delayMinutes === null || isNaN(delayMinutes) || delayMinutes < 0) {
    throw new Error("Invalid delayMinutes value.");
}
console.log("Delay Minutes: ", delayMinutes);
// Return the value as a Buffer of 32 bytes (uint256)
return Functions.encodeUint256(delayMinutes);