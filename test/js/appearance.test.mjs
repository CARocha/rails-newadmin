import test from "node:test";
import assert from "node:assert/strict";
import { resolveMode, nextMode, applyInitialTheme } from "../../app/javascript/rails_newadmin/appearance.js";

test("untrusted stored preferences fall back to a supported configured mode", () => {
  assert.equal(resolveMode("invalid", "dark"), "dark");
  assert.equal(resolveMode(null, "invalid"), "auto");
  assert.equal(resolveMode("light", "dark"), "light");
});
test("appearance switch returns to system preference after both explicit modes", () => {
  assert.equal(nextMode("auto"), "light");
  assert.equal(nextMode("light"), "dark");
  assert.equal(nextMode("dark"), "auto");
  assert.equal(nextMode("bad"), "light");
});
test("initial rendering restores a saved mode without requiring a network request", () => {
  const root = { dataset: { theme: "auto" } };
  assert.equal(applyInitialTheme(root, { getItem: () => "dark" }), "dark");
  assert.equal(root.dataset.theme, "dark");
});
test("blocked browser storage retains the server-configured appearance", () => {
  const root = { dataset: { theme: "light" } };
  assert.equal(applyInitialTheme(root, { getItem() { throw new Error("storage denied"); } }), "light");
});
