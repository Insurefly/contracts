const requestConfig = require("../configs/checkClaimConfig.js");
const { simulateScript, decodeResult } = require("@chainlink/functions-toolkit");

async function main() {
    // Simulate the script based on the configuration
    const { responseBytesHexstring, errorString, capturedTerminalOutput } = await simulateScript(requestConfig);

    console.log(`${capturedTerminalOutput}\n`);

    // If there's a response, decode it
    if (responseBytesHexstring) {
        const decodedResponse = decodeResult(responseBytesHexstring, requestConfig.expectedReturnType);
        console.log(
            `Response returned by script during local simulation: ${decodedResponse}\n`
        );
    }

    // If there's an error, log the error
    if (errorString) {
        console.log(`Error returned by simulated script:\n${errorString}\n`);
    }
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
