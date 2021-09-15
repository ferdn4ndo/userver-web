function updateData() {
  console.log('Refreshing health data...')
  fetch('/stats.txt')
    .then(response => response.text())
    .then((data) => {
      window.document.getElementById('heartbeatBox').innerText = data;
    })
}

function getRefreshSelectValue() {
  return window.document.getElementById('refreshSecondsSelect').value;
}

let secondsToRefresh = getRefreshSelectValue();

window.document.getElementById('refreshSecondsSelect').addEventListener('change', () => {
  secondsToRefresh = getRefreshSelectValue();
});

function updateTimer() {
  if (secondsToRefresh <= 0) {
    updateData()
    secondsToRefresh = getRefreshSelectValue();
  } else {
    secondsToRefresh--;
  }

  window.document.getElementById('countdown').innerText = 'Data will be updated again in ' + secondsToRefresh + ' seconds...';
}

setInterval(updateTimer, 1000); // Time in milliseconds
