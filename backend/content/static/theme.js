let enabledAnimation = false;

window.addEventListener("DOMContentLoaded", function () {
  // Set theme at startup
  const currentTheme = localStorage.getItem("theme")
    ? localStorage.getItem("theme")
    : "light";
  document.documentElement.setAttribute("theme", currentTheme);
  const themeButtons = document.querySelectorAll("div[id=theme-toggle]");

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
        : "light";
      let newtheme;
      if (currentTheme == "light") {
        newtheme = "dark";
      } else if (currentTheme == "dark") {
        newtheme = "light";
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
