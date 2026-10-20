import assert from "node:assert/strict";
import { readFile, writeFile, mkdir } from "node:fs/promises";
import { createRequire } from "node:module";
import { chromium, firefox, webkit } from "playwright";
import { assertPaletteContrast } from "./contrast.mjs";
import { assertAppearanceAnnouncement } from "./appearance_check.mjs";
import { assertGrowingHeader } from "./header_check.mjs";
const require = createRequire(import.meta.url);
const [origin, credentialsPath] = process.argv.slice(2);
const credentials = JSON.parse(await readFile(credentialsPath, "utf8"));
const violations = [];
const incomplete = [];
let audits = 0;
const engines = {chromium, firefox, webkit};
for (const name of (process.env.A11Y_BROWSERS || "chromium").split(",")) {
  const browser = await engines[name].launch(name === "firefox" ? {firefoxUserPrefs: {"accessibility.tabfocus": 7}} : {});
  try {
    const context = await browser.newContext({viewport: {width: 1440, height: 960}, reducedMotion: "reduce"});
    const page = await context.newPage();
    const errors = [];
    page.on("pageerror", error => errors.push(error.message));
    async function ready(path) {
      await page.goto(`${origin}/admin${path}`);
      await page.waitForFunction(() => window.RailsNewadmin?.application.controllers.some(c => c.identifier === "newadmin-theme"));
    }
    async function inspect(label, locales = ["en", "es"]) {
      console.log(`${name}: checking ${label}`);
      await page.addScriptTag({path: require.resolve("axe-core/axe.min.js")});
      for (const locale of locales) {
        // Locale changes must render translated content, rather than just an html lang attribute.
        if (new URL(page.url()).searchParams.get("locale") !== locale) {
          const url = new URL(page.url()); url.searchParams.set("locale", locale);
          await page.goto(url.href);
          await page.locator("main h1").waitFor();
          await page.addScriptTag({path: require.resolve("axe-core/axe.min.js")});
        }
        if (label === "dashboard") {
          const summary = page.locator("details summary");
          await summary.press("Enter");
          assert.equal(await page.locator("details table").isVisible(), true);
        }
        for (const [theme, scheme] of [["light", "light"], ["dark", "dark"], ["auto", "light"], ["auto", "dark"]]) {
          await page.emulateMedia({colorScheme: scheme});
          await page.evaluate(theme => document.documentElement.dataset.theme = theme, theme);
          await assertPaletteContrast(page);
          for (const width of [1440, 1024, 768, 320]) {
            await page.setViewportSize({width, height: 960});
            const report = await page.evaluate(async () => {
              const report = await axe.run(document, {runOnly: {type: "tag", values: ["wcag2a", "wcag2aa", "wcag21aa", "wcag22aa"]}});
              const simplify = items => items.map(v => ({id: v.id, nodes: v.nodes.map(n => ({target: n.target, summary: n.failureSummary}))}));
              return {violations: simplify(report.violations), incomplete: simplify(report.incomplete)};
            });
            const result = report.violations;
            if (report.incomplete.length) incomplete.push({browser: name, label, locale, theme, scheme, width, result: report.incomplete});
            audits++;
            if (result.length) violations.push({browser: name, label, locale, theme, scheme, width, result});
            const overflow = await page.evaluate(() => ({scroll: document.documentElement.scrollWidth, viewport: innerWidth, elements: [...document.querySelectorAll("body *")].filter(e => e.getBoundingClientRect().right > innerWidth + 1).slice(0, 8).map(e => ({tag:e.tagName, cls:e.className, width:e.getBoundingClientRect().width}))}));
            if (overflow.scroll > overflow.viewport + 1) violations.push({browser: name, label, locale, theme, width, overflow});
          }
        }
      }
    }
    await ready("/session/new"); await assertAppearanceAnnouncement(page); await inspect("login");
    await ready("/password/new"); await inspect("recovery");
    await ready(`/password/edit?token=${encodeURIComponent(credentials.token)}`); await inspect("reset");
    await ready("/session/new");
    await page.locator('[name="email_address"]').fill(credentials.email);
    await page.locator('[name="password"]').fill(credentials.password);
    await page.locator('[type="submit"]').press("Enter");
    await page.waitForURL(url => url.pathname === "/admin/");
    await assertGrowingHeader(page);
    const screens = [["dashboard", "/"], ["list", "/resources/articles"], ["empty", "/resources/articles?q=no-such-article"],
      ["detail", `/resources/articles/${credentials.article}`], ["new", "/resources/articles/new"],
      ["edit", `/resources/articles/${credentials.article}/edit`], ["delete", `/resources/articles/${credentials.article}/delete`],
      ["users", "/admin_users"], ["new-user", "/admin_users/new"], ["edit-user", `/admin_users/${credentials.user}/edit`],
      ["groups", "/groups"], ["new-group", "/groups/new"], ["edit-group", `/groups/${credentials.group}/edit`]];
    // A server-side 422 must move focus to a linked summary, even after Turbo replaces the form.
    for (const locale of ["en", "es"]) {
      for (const [path, field] of [["/resources/articles/new", "record[title]"], ["/admin_users/new", "admin_user[email_address]"], ["/groups/new", "group[name]"]]) {
        await ready(`${path}?locale=${locale}`);
        await page.locator(`[name="${field}"]`).fill("");
        await page.locator("main form").evaluate(form => form.noValidate = true);
        await page.locator('main [type="submit"]').press("Enter");
        await page.locator("#newadmin-errors").waitFor();
        await page.waitForFunction(() => document.activeElement?.id === "newadmin-errors");
        await inspect(`invalid-${field}`, [locale]);
        const targetID = await page.locator(`[name="${field}"]`).getAttribute("id");
        await page.locator(`#newadmin-errors a[href="#${targetID}"]`).first().press("Enter");
        await page.waitForFunction(field => document.activeElement?.name === field, field);
      }
    }
    await ready("/resources/articles?locale=en");
    await page.setViewportSize({width: 320, height: 960});
    async function tabTo(selector, reverse = false) {
      for (let step = 0; step < 120; step++) {
        if (await page.locator(selector).evaluate(e => e === document.activeElement)) return;
        await page.keyboard.press(`${reverse ? "Shift+" : ""}${name === "webkit" && process.platform === "darwin" ? "Alt+Tab" : "Tab"}`);
      }
      assert.fail(`Keyboard could not reach ${selector}`);
    }
    await tabTo(".skip-link");
    await page.keyboard.press("Enter");
    await page.waitForFunction(() => document.activeElement.id === "main-content");
    await tabTo(".newadmin-mobile-toggle", true);
    await page.keyboard.press("Enter");
    assert.equal(await page.locator(".newadmin-mobile-toggle").getAttribute("aria-expanded"), "true");
    await tabTo('aside a[href$="/resources/articles"]');
    await page.keyboard.press("Escape");
    assert.equal(await page.locator(".newadmin-mobile-toggle").evaluate(e => e === document.activeElement), true);
    assert.equal(await page.locator("aside").isVisible(), false);
    await tabTo('[name="q"]');
    await tabTo(".newadmin-table-scroll");
    const scroll = await page.locator(".newadmin-table-scroll").evaluate(e => e.scrollLeft);
    await page.keyboard.press(scroll > 0 ? "ArrowLeft" : "ArrowRight", {delay: 150});
    await page.waitForFunction(before => document.querySelector(".newadmin-table-scroll").scrollLeft !== before, scroll);
    await tabTo('main a[href$="/resources/articles/new"]', true);
    await page.keyboard.press("Enter");
    await page.waitForURL(url => url.pathname.endsWith("/new"));
    await page.waitForFunction(() => document.activeElement.id === "main-content");
    await tabTo('[name="record[title]"]');
    await tabTo('[name="record[category_id]"]');
    const relationSearch = page.locator('[data-newadmin-relation-target="search"]');
    await relationSearch.fill("Accessible");
    await page.waitForFunction(() => document.querySelector('[data-newadmin-relation-target="status"]').textContent.includes("1"));
    await tabTo('[name="record[category_id]"]');
    // Native select type-ahead works across macOS and Linux popup implementations.
    await page.keyboard.press("a");
    await page.waitForFunction(() => document.querySelector('[name="record[category_id]"]').value !== "");
    assert.equal(await page.locator('[name="record[category_id]"]').getAttribute("aria-busy"), null);
    await page.route("**/resources/articles/options/category?**", route => route.fulfill({status: 503, contentType: "application/json", body: "[]"}));
    await relationSearch.fill("Unavailable");
    await page.waitForFunction(() => /could not|No se pudieron/.test(document.querySelector('[data-newadmin-relation-target="status"]').textContent));
    assert.equal(await page.locator('[name="record[category_id]"]').getAttribute("aria-busy"), null);
    await inspect("relation-error", ["en"]);
    await page.unroute("**/resources/articles/options/category?**");
    // CSS zoom is an enlargement regression check; it is not claimed as manual browser zoom.
    for (const path of ["/", "/resources/articles", "/resources/articles/new", "/admin_users/new", "/groups/new"]) {
      await ready(`${path}?locale=es`);
      await page.setViewportSize({width: 1280, height: 960});
      await page.evaluate(() => document.documentElement.style.zoom = "2");
      assert.equal(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth + 1), true, `${path}: 200% enlargement overflow`);
      await page.evaluate(() => document.documentElement.style.zoom = "");
    }
    for (const [label, path] of screens) { await ready(path); await inspect(label); }
    await ready("/?locale=en");
    await page.locator('form[action*="/session"] button').press("Enter");
    await page.waitForURL(url => url.pathname.endsWith("/session/new"));
    await page.locator('[name="email_address"]').fill(credentials.reader);
    await page.locator('[name="password"]').fill(credentials.password);
    await page.locator('[type="submit"]').press("Enter");
    await page.waitForURL(url => url.pathname === "/admin/");
    const denied = await page.goto(`${origin}/admin/admin_users?locale=en`);
    assert.equal(denied.status(), 403);
    await inspect("denied");
    assert.deepEqual(errors, [], `${name} browser errors`);
    console.log(`${name}: builtin auth, CRUD/errors, dashboard/data, access management/denied, keyboard, reflow and enlargement passed`);
  } finally { await browser.close(); }
}
await mkdir("pkg", {recursive: true});
await writeFile("pkg/accessibility-results.json", JSON.stringify({axe: require("axe-core/package.json").version, audits, violations, incomplete}, null, 2));
assert.equal(violations.length, 0, `${violations.length} failing states; first findings: ${JSON.stringify(violations.slice(0, 3))}`);
console.log(`${audits} axe audits: zero detected violations. ${incomplete.length} states have checks requiring human review; see local pkg/accessibility-results.json.`);
