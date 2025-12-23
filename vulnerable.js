function showMessage() {
  const params = new URLSearchParams(window.location.search);
  const msg = params.get("msg");

  // ✅ Safe: treat input as text, not HTML
  document.getElementById("output").textContent = msg;
}

window.onload = showMessage;
