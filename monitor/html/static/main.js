/**
 * uServer Health
 *
 * Main page script
 */

const COUNTDOWN_REFRESH_MILLISECONDS = 1000;
let countdownIntervalHandler = null;
let secondsUntilNextRefresh = 0;

/**
 * Helper function to set the status container text
 *
 * @param text
 */
function setStatusText(text) {
  window.document.getElementById('status').innerText = text;
}

/**
 * Perform a refresh of the health data by fetching the stats file again
 */
function refreshData() {
  const currentTimestamp = new Date().getTime();
  console.log('Refreshing health data for timestamp ' + currentTimestamp);
  setStatusText('Refreshing health data...');

  fetch('/stats.txt?' + currentTimestamp)
    .then(response => response.text())
    .then((data) => {
      setStatusText('Health data refreshed!')
      window.document.getElementById('heartbeatBox').innerText = data;
      setCountdownOn();
    })
}

/**
 * Return the selected amount of seconds between the data refresh
 *
 * @returns {number}
 */
function getRefreshSelectValue() {
  return parseInt(window.document.getElementById('refreshSecondsSelect').value);
}

/**
 * Add the event listener to the select field to update the amount of seconds before refreshing the data again
 */
window.document.getElementById('refreshSecondsSelect').addEventListener('change', () => {
  secondsUntilNextRefresh = getRefreshSelectValue();
});

/**
 * Timer callback function to compute the seconds left before refreshing data again
 */
function timerCallback() {
  secondsUntilNextRefresh--;

  if (secondsUntilNextRefresh <= 0) {
    setCountdownOff();
    refreshData();
    secondsUntilNextRefresh = getRefreshSelectValue();
  } else {
    const formattedTimeLeft = new Date(secondsUntilNextRefresh * 1000).toISOString().substr(11, 8);
    setStatusText('Health data will be refreshed again in ' + formattedTimeLeft);
  }
}

/**
 * Set the timer event that will fire the callback function every n seconds (defined by a const)
 */
function setCountdownOn() {
  countdownIntervalHandler = setInterval(timerCallback, COUNTDOWN_REFRESH_MILLISECONDS);
}

/**
 * Reset (clear) the timer event that was calling the callback function
 */
function setCountdownOff() {
  if (countdownIntervalHandler !== null) {
    clearInterval(countdownIntervalHandler);
  }
}

/**
 * Main script
 */
setCountdownOn();
