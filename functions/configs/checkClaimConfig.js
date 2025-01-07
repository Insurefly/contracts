const fs = require("fs");
const { Location, ReturnType, CodeLanguage } = require("@chainlink/functions-toolkit");

// Configure the request by setting the fields below
const requestConfig = {
    source: fs.readFileSync(__dirname + "/../sources/checkClaim.js").toString(),
    codeLocation: Location.Inline,
    secrets: {},
    secretsLocation: Location.DONHosted,
    // Here we pass params as arguments to filter the data
    args: [
        "BA204",                                // Flight number (parameter 1)
        "British Airways",                      // Airline name (parameter 2)
        "Los Angeles International Airport",    // Departure airport name (parameter 3)
        "2025-01-05T15:00:00",                  // Departure datetime (parameter 4)
        "London Heathrow Airport",
        "2025-01-06T07:30:00"
    ],
    codeLanguage: CodeLanguage.JavaScript,
    expectedReturnType: ReturnType.string,
};

module.exports = requestConfig;
