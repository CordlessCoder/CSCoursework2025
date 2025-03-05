let enabledAnimation = false;

window.addEventListener("DOMContentLoaded", function () {
  // Set theme at startup
  const current_theme = localStorage.getItem("theme")
    ? localStorage.getItem("theme")
    : "system";
  const themeButtons = document.querySelectorAll("div[id=theme-toggle]");
  let system_theme = "light";
  if (
    window.matchMedia &&
    window.matchMedia("(prefers-color-scheme: dark)").matches
  ) {
    system_theme = "dark";
  }
  localStorage.setItem("theme", current_theme);
  if (current_theme == "system") {
    document.documentElement.setAttribute("theme", system_theme);
  } else {
    document.documentElement.setAttribute("theme", current_theme);
  }
  window
    .matchMedia("(prefers-color-scheme: dark)")
    .addEventListener("change", (event) => {
      system_theme = event.matches ? "dark" : "light";
      const current_theme = localStorage.getItem("theme")
        ? localStorage.getItem("theme")
        : "system";
      if (current_theme == "system") {
        document.documentElement.setAttribute("theme", system_theme);
      }
    });

  themeButtons.forEach((btn) => {
    btn.addEventListener("click", (_) => {
      if (!enabledAnimation) {
        document.styleSheets[0].insertRule(
          "* {  --color-transition: 250ms; transition: background-color var(--color-transition) 100ms, color var(--color-transition), filter var(--color-transition) 100ms;}",
        );
        enabledAnimation = true;
      }
      let currentTheme = localStorage.getItem("theme")
        ? localStorage.getItem("theme")
        : system_theme;
      let newtheme;
      if (currentTheme == "light") {
        newtheme = "dark";
      } else {
        newtheme = "light";
      }
      document.documentElement.setAttribute("theme", newtheme);
      localStorage.setItem("theme", newtheme);
    });
  });
  const hamburger = document.querySelector("#hamburger");
  const mobileMenu = document.querySelector(".menu");

  hamburger.addEventListener("click", function () {
    this.children[0].classList.toggle("active");
    mobileMenu.classList.toggle("hide");
  });
});
