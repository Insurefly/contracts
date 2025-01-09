const fs = require("fs");
const { Location, ReturnType, CodeLanguage } = require("@chainlink/functions-toolkit");

// Configure the request by setting the fields below
const requestConfig = {
    source: fs.readFileSync(__dirname + "/../sources/checkClaim.js").toString(),
    codeLocation: Location.Inline,
    secrets: {flightDataUrl: process.env.FLIGHT_DATA_URL ?? ""},
    secretsLocation: Location.DONHosted,
    // Here we pass params as arguments to filter the data
    args: [
        "AF456",                                        // Flight number (parameter 0)
        "Air France",                                   // Airline name (parameter 1)
        "Charles de Gaulle Airport",                    // Departure airport name (parameter 2)
        "2025-01-05T19:00:00",                          // Departure datetime (parameter 3)
        "Toronto Pearson International Airport",        // Arrival airport name (parameter 4)
        "2025-01-05T22:30:00"                           // Arrival datetime (parameter 5)
    ],
    codeLanguage: CodeLanguage.JavaScript,
    expectedReturnType: ReturnType.string,
};

module.exports = requestConfig;
