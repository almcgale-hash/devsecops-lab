function showMessage() {
  const params = new URLSearchParams(window.location.search);
  const msg = params.get("msg");

  // ❌ Vulnerable: directly injecting user input into the DOM
  document.getElementById("output").innerHTML = msg;
}

window.onload = showMessage;
