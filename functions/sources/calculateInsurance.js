// Function to calculate the insurance value based on delay or cancellation
function calculateInsuranceValue(insuranceValue, delay) {
    // if (status === "Cancelled") {
    //     // If the flight is cancelled, double the insurance value
    //     insuranceValue = insuranceValue * 2;
    // } 
    if (delay >= 180) {
        // If delay is 180 minutes or more, apply 5% increase for each 30-minute interval
        const additionalDelay = Math.ceil((delay - 180) / 30);
        insuranceValue = insuranceValue + (additionalDelay * insuranceValue * 0.05);
    }

    return insuranceValue;
}

// Get parameters (delay, insurance value, status)
const delay = parseInt(args[0]);
const insuranceValue = parseInt(args[1]);
const status = args[2];

// Calculate the insurance value
const calculatedValue = calculateInsuranceValue(insuranceValue, delay);

console.log("Insurance Value: ", calculatedValue);
// Return the calculated value as uint256
return Functions.encodeUint256(calculatedValue);
