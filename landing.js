(() => {
  const root = document.documentElement;
  const themeButton = document.getElementById("theme-toggle");
  const notice = document.getElementById("dashboard-notice");
  const configuredUrl = (window.TECHPULSE_DASHBOARD_URL || "").trim();

  let theme = "light";
  try { theme = localStorage.getItem("techpulse-site-theme") || "light"; } catch (_) {}
  root.dataset.theme = theme;

  themeButton?.addEventListener("click", () => {
    theme = root.dataset.theme === "dark" ? "light" : "dark";
    root.dataset.theme = theme;
    try { localStorage.setItem("techpulse-site-theme", theme); } catch (_) {}
  });

  document.querySelectorAll(".dashboard-link").forEach((link) => {
    if (
          configuredUrl &&
          (
            /^https:\/\/.+/i.test(configuredUrl) ||
            /^http:\/\/(127\.0\.0\.1|localhost)(:\d+)?(\/.*)?$/i.test(configuredUrl)
          )
        ) {
      link.href = "https://techpulse.sanjeevkarunanithy.workers.dev/dashboard/";
      link.target = "_self";
      link.removeAttribute("rel");
    } else {
      link.href = "#explore";
      link.addEventListener("click", (event) => {
        event.preventDefault();
        if (notice) {
          notice.hidden = false;
          window.setTimeout(() => { notice.hidden = true; }, 5500);
        }
      });
    }
  });

  const year = document.getElementById("year");
  if (year) year.textContent = new Date().getFullYear();
})();
