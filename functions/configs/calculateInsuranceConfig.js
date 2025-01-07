const fs = require("fs");
const { Location, ReturnType, CodeLanguage } = require("@chainlink/functions-toolkit");

// Configure the request by setting the fields below
const requestConfig = {
    source: fs.readFileSync(__dirname + "/../sources/calculateInsurance.js").toString(),
    codeLocation: Location.Inline,
    secrets: {},
    secretsLocation: Location.DONHosted,
    // Pass parameters for insurance calculation (delay, insurance value, status)
    args: [
        "300",                // Delay in minutes (parameter 1) as string
        "10000",              // Insurance value (parameter 2) as string
        "Delayed",            // Flight status (parameter 3)
    ],
    codeLanguage: CodeLanguage.JavaScript,
    expectedReturnType: ReturnType.string,
};

module.exports = requestConfig;
