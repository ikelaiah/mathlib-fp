(() => {
  "use strict";

  const root = document.body.dataset.docRoot || "";
  const search = document.querySelector("#search");
  const results = document.querySelector("#results");
  const themeToggle = document.querySelector("#theme-toggle");
  const themeIcon = themeToggle?.querySelector("span[aria-hidden='true']");
  const colorPreference = window.matchMedia("(prefers-color-scheme: dark)");
  const items = Array.isArray(globalThis.mathlibSearchIndex)
    ? globalThis.mathlibSearchIndex
    : [];

  function storedTheme() {
    try {
      const value = localStorage.getItem("mathlib-theme");
      return value === "light" || value === "dark" ? value : null;
    } catch (_error) {
      return null;
    }
  }

  function effectiveTheme() {
    return document.documentElement.dataset.theme ||
      (colorPreference.matches ? "dark" : "light");
  }

  function updateThemeControl() {
    const current = effectiveTheme();
    const next = current === "dark" ? "light" : "dark";
    themeToggle?.setAttribute("aria-label", `Switch to ${next} theme`);
    themeToggle?.setAttribute("title", `Switch to ${next} theme`);
    if (themeIcon) {
      themeIcon.textContent = current === "dark" ? "☀" : "☾";
    }
  }

  const savedTheme = storedTheme();
  if (savedTheme) {
    document.documentElement.dataset.theme = savedTheme;
  }
  updateThemeControl();

  themeToggle?.addEventListener("click", () => {
    const next = effectiveTheme() === "dark" ? "light" : "dark";
    document.documentElement.dataset.theme = next;
    try {
      localStorage.setItem("mathlib-theme", next);
    } catch (_error) {
      // The selected theme still applies for this page when storage is unavailable.
    }
    updateThemeControl();
  });

  colorPreference.addEventListener?.("change", () => {
    if (!storedTheme()) {
      updateThemeControl();
    }
  });

  function closeResults() {
    results.hidden = true;
    results.replaceChildren();
    search.setAttribute("aria-expanded", "false");
  }

  function renderResults() {
    const query = search.value.toLowerCase().trim();
    if (!query) {
      closeResults();
      return;
    }

    const matches = items
      .filter((item) => `${item.title} ${item.text}`.toLowerCase().includes(query))
      .slice(0, 12);
    const list = document.createElement("ul");
    list.className = "search-result-list";

    for (const item of matches) {
      const row = document.createElement("li");
      const link = document.createElement("a");
      link.href = root + item.url;
      link.textContent = item.title;
      row.append(link);
      list.append(row);
    }

    results.replaceChildren();
    if (matches.length) {
      results.append(list);
    } else {
      const empty = document.createElement("p");
      empty.className = "search-empty";
      empty.textContent = `No documentation found for “${search.value.trim()}”.`;
      results.append(empty);
    }
    results.hidden = false;
    search.setAttribute("aria-expanded", "true");
  }

  search.addEventListener("input", renderResults);
  search.addEventListener("keydown", (event) => {
    if (event.key === "Escape") {
      closeResults();
      search.blur();
    }
  });

  document.addEventListener("keydown", (event) => {
    const target = event.target;
    const isTyping = target instanceof HTMLInputElement ||
      target instanceof HTMLTextAreaElement || target?.isContentEditable;
    if (event.key === "/" && !isTyping) {
      event.preventDefault();
      search.focus();
    }
  });

  document.addEventListener("click", (event) => {
    if (!results.contains(event.target) && event.target !== search) {
      closeResults();
    }
  });
})();
