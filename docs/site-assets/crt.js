/* CRT overlay toggle — default ON, choice persisted in localStorage. */
(function () {
  var body = document.body;
  var btn = document.getElementById("crtToggle");
  var KEY = "pravkal-crt";

  function apply(on) {
    body.classList.toggle("crt-on", on);
    body.classList.toggle("crt-off", !on);
    btn.textContent = "CRT: " + (on ? "ON" : "OFF");
    btn.setAttribute("aria-pressed", String(on));
  }

  var stored = null;
  try { stored = localStorage.getItem(KEY); } catch (e) {}
  var on = stored === null ? true : stored === "1";
  apply(on);

  btn.addEventListener("click", function () {
    on = !on;
    apply(on);
    try { localStorage.setItem(KEY, on ? "1" : "0"); } catch (e) {}
  });
})();
