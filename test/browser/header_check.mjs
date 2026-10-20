import assert from "node:assert/strict";

export async function assertGrowingHeader(page) {
  await page.setViewportSize({width: 1024, height: 700});
  const brand = page.locator(".newadmin-brand");
  const original = await brand.textContent();
  await brand.evaluate(element => element.textContent = "Administration for the National Library of Nicaragua");
  await page.evaluate(() => scrollTo(0, document.documentElement.scrollHeight));
  await page.evaluate(() => new Promise(resolve => requestAnimationFrame(() => requestAnimationFrame(resolve))));
  const position = await page.evaluate(() => ({header: document.querySelector("header").getBoundingClientRect().bottom,
    sidebar: document.querySelector("aside").getBoundingClientRect().top}));
  assert.ok(position.header > 64, "The fixture must exercise a taller custom site title");
  assert.ok(position.sidebar >= position.header - 1, `Header obscures sidebar: ${JSON.stringify(position)}`);
  await brand.evaluate((element, text) => element.textContent = text, original);
  await page.evaluate(() => scrollTo(0, 0));
  await page.setViewportSize({width: 1440, height: 960});
}
