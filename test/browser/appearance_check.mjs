import assert from "node:assert/strict";

export async function assertAppearanceAnnouncement(page) {
  const button = page.locator('[data-action="newadmin-theme#toggle"]');
  const before = await button.getAttribute("aria-label");
  await button.press("Enter");
  const mode = await page.locator("html").getAttribute("data-theme");
  const after = await button.getAttribute("aria-label");
  assert.notEqual(after, before, "Changing appearance must announce the selected mode");
  const modes = JSON.parse(await page.locator("body").getAttribute("data-newadmin-theme-modes-value"));
  assert.ok(after.includes(modes[mode]), "The accessible name must describe the selected mode");
  assert.ok((await page.locator('[data-newadmin-theme-target="status"]').textContent()).includes(modes[mode]));
}
