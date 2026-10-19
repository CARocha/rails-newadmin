const valid = new Set(["light", "dark", "auto"]);
export const resolveMode = (value, fallback = "auto") => valid.has(value) ? value : valid.has(fallback) ? fallback : "auto";
export const nextMode = (value) => ({ auto: "light", light: "dark", dark: "auto" })[resolveMode(value)];
export function applyInitialTheme(root = document.documentElement, storage = window.localStorage) {
  let mode = root.dataset.theme;
  try { mode = resolveMode(storage.getItem("rails-newadmin.theme"), mode); } catch { mode = resolveMode(mode); }
  root.dataset.theme = mode;
  return mode;
}
