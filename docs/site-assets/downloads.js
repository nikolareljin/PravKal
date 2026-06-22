/* Always-latest downloads.
   Release asset names embed the version (e.g. pravkal-1.0.0-linux-x86_64.AppImage),
   so a static /releases/latest/download/<name> link breaks on every version bump.
   Instead we query the GitHub API for the latest release and wire each per-OS
   button to the real asset. If the API is unreachable (offline, rate-limited),
   the static fallback hrefs (the releases page) remain. */
(function () {
  var repo = document.body.getAttribute("data-repo") || "nikolareljin/PravKal";
  var api = "https://api.github.com/repos/" + repo + "/releases/latest";

  // Match an asset filename to a button key. Keys are arch-specific so an
  // Intel asset is never wired to an Apple-Silicon button (and vice versa).
  // The ci-helpers release workflow names assets:
  //   pravkal-<tag>-{linux-x86_64,macos-arm64,macos-x86_64}.{tar.gz,dmg,deb,rpm,AppImage}
  //   pravkal-<tag>-windows-x86_64.zip   (a zip, NOT a bare .exe)
  function classify(name) {
    var n = name.toLowerCase();
    if (n.endsWith(".deb")) return "deb";
    if (n.endsWith(".rpm")) return "rpm";
    if (n.endsWith(".appimage")) return "appimage";
    if (n.indexOf("windows") !== -1 && n.endsWith(".zip")) return "win";
    if (n.indexOf("macos-arm64") !== -1 && n.endsWith(".dmg")) return "dmg-arm64";
    if (n.indexOf("macos-x86_64") !== -1 && n.endsWith(".dmg")) return "dmg-x64";
    if (n.indexOf("macos-arm64") !== -1 && n.endsWith(".tar.gz")) return "mac-tar-arm64";
    if (n.indexOf("macos-x86_64") !== -1 && n.endsWith(".tar.gz")) return "mac-tar-x64";
    if (n.indexOf("linux") !== -1 && n.endsWith(".tar.gz")) return "linux-tar";
    return null;
  }

  function human(bytes) {
    if (!bytes && bytes !== 0) return "";
    var mb = bytes / (1024 * 1024);
    if (mb >= 1) return "(" + mb.toFixed(1) + " MB)";
    return "(" + Math.max(1, Math.round(bytes / 1024)) + " KB)";
  }

  function fallbackLabel() {
    // Show a sensible label instead of the "…" placeholder when we can't reach
    // the API; the static per-button links already point at the releases page.
    var ver = document.getElementById("relVersion");
    if (ver && ver.textContent === "…") ver.textContent = "latest";
  }

  // Feature-detect fetch: on old browsers / some webviews it's absent, and
  // calling it would throw before the .catch handler runs. Fall back cleanly.
  if (typeof window.fetch !== "function") {
    fallbackLabel();
    return;
  }

  fetch(api, { headers: { Accept: "application/vnd.github+json" } })
    .then(function (r) { if (!r.ok) throw new Error("HTTP " + r.status); return r.json(); })
    .then(function (rel) {
      var ver = document.getElementById("relVersion");
      if (ver) ver.textContent = rel.tag_name || rel.name || "latest";

      var byKey = {};
      (rel.assets || []).forEach(function (a) {
        var k = classify(a.name);
        if (k && !byKey[k]) byKey[k] = a;
      });

      var buttons = document.querySelectorAll(".btn.dl[data-asset]");
      for (var i = 0; i < buttons.length; i++) {
        var btn = buttons[i];
        var key = btn.getAttribute("data-asset");
        var asset = byKey[key];
        var meta = btn.querySelector(".dl-meta");
        if (asset) {
          btn.href = asset.browser_download_url;
          if (meta) meta.textContent = human(asset.size);
          btn.classList.remove("pending");
        } else {
          // No such asset in the latest release — mark pending, keep releases-page href.
          btn.classList.add("pending");
          if (meta) meta.textContent = "(pending)";
        }
      }

      // Hide the Windows "build pending" note once a real asset exists.
      var winNote = document.getElementById("winNote");
      if (winNote && byKey.win) winNote.style.display = "none";
    })
    .catch(function () {
      // API unreachable (offline / rate-limited): keep the static fallback
      // links and replace the "…" placeholder so the page doesn't look broken.
      fallbackLabel();
    });
})();
