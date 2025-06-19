/* eslint-disable max-len */

// The Cloud Functions for Firebase SDK to create Cloud Functions and set up triggers.
const functions = require("firebase-functions");

// Axios is a modern, promise-based HTTP client
const axios = require("axios");

/**
 * Proxies a geocoding request to LocationIQ to protect the API key.
 * The Flutter app will call this function instead of calling LocationIQ directly.
 * @param {object} data The data passed to the function, expects { address: "..." }.
 * @param {object} context The context of the function call, including auth info.
 * @return {Promise<object>} A promise that resolves with the geocoding data.
 */
exports.geocodeAddressProxy = functions.https.onCall(async (data, context) => {
  // 1. --- Authentication & Input Validation ---

  // Ensure the user calling the function is authenticated.
  // This prevents unauthorized users from running up your LocationIQ bill.
  if (!context.auth) {
    throw new functions.https.HttpsError(
        "unauthenticated",
        "The function must be called by an authenticated user.",
    );
  }

  const address = data.address;
  if (!address || typeof address !== "string" || address.trim().length < 5) {
    throw new functions.https.HttpsError(
        "invalid-argument",
        "The function must be called with a valid 'address' argument.",
    );
  }

  // 2. --- Retrieve the Secure API Key ---
  // This retrieves the key you set in Step 2. It is never exposed to the client.
  const apiKey = functions.config().locationiq.key;

  if (!apiKey) {
    // This is a server-side configuration error, not the user's fault.
    console.error("LocationIQ API Key is not configured.");
    throw new functions.https.HttpsError(
        "internal",
        "The service is not configured correctly. Please contact support.",
    );
  }

  // 3. --- Call the External API (LocationIQ) ---
  const encodedAddress = encodeURIComponent(address);
  const apiUrl = `https://us1.locationiq.com/v1/search.php?key=${apiKey}&q=${encodedAddress}&format=json`;

  try {
    console.log(`Making request to LocationIQ for address: ${address}`);
    const response = await axios.get(apiUrl);

    // Check for successful response from LocationIQ
    if (response.status === 200) {
      console.log("LocationIQ request successful.");
      // We don't need to send the entire verbose response back to the client.
      // Let's just send the results array.
      return {
        success: true,
        data: response.data,
      };
    } else {
      // LocationIQ returned a non-200 status code
      const errorMsg =
        `LocationIQ returned error: ${response.status} ${response.statusText}`;
      console.error(errorMsg);
      throw new functions.https.HttpsError(
          "unavailable",
          `The geocoding service returned an error (${response.status}).`,
      );
    }
  } catch (error) {
    console.error("Error calling LocationIQ API:", error);

    // Handle common axios/network errors
    if (error.response) {
      // The request was made and the server responded with a non-2xx status code
      throw new functions.https.HttpsError(
          "unavailable",
          `The geocoding service is unavailable. (Status: ${error.response.status})`,
      );
    } else if (error.request) {
      // The request was made but no response was received
      throw new functions.https.HttpsError(
          "unavailable",
          "No response from geocoding service. Check network.",
      );
    } else {
      // Something happened in setting up the request that triggered an Error
      throw new functions.https.HttpsError(
          "internal",
          "An internal error occurred while geocoding.",
      );
    }
  }
});
