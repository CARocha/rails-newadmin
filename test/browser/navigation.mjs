import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { chromium } from "playwright";

const [origin, prefix, credentialsPath, variant] = process.argv.slice(2);
const credentials = JSON.parse(await readFile(credentialsPath, "utf8"));
const browser = await chromium.launch();
try {
  const context = await browser.newContext();
  await context.addInitScript(() => {
    window.documentID = crypto.randomUUID();
    const listeners = new Map();
    const add = EventTarget.prototype.addEventListener;
    const remove = EventTarget.prototype.removeEventListener;
    EventTarget.prototype.addEventListener = function(type, callback, options) {
      if (this === document && type === "rails-newadmin:theme") {
        if (!listeners.has(type)) listeners.set(type, new Set());
        listeners.get(type).add(callback);
      }
      return add.call(this, type, callback, options);
    };
    EventTarget.prototype.removeEventListener = function(type, callback, options) {
      if (this === document) listeners.get(type)?.delete(callback);
      return remove.call(this, type, callback, options);
    };
    window.chartThemeListeners = () => listeners.get("rails-newadmin:theme")?.size || 0;
  });
  const page = await context.newPage();
  const errors = [];
  const failures = [];
  const remoteRequests = [];
  let createRequests = 0;
  page.on("request", request => {
    if (request.url().startsWith("http") && new URL(request.url()).origin !== origin) remoteRequests.push(request.url());
    if (request.method() === "POST" && new URL(request.url()).pathname === `${prefix}/control/resources/articles`) createRequests++;
  });
  page.on("pageerror", error => errors.push(error.message));
  page.on("console", message => { if (["error", "warning"].includes(message.type())) errors.push(message.text()); });
  page.on("response", response => { if (response.status() >= 400 && !response.url().endsWith("/favicon.ico")) failures.push(`${response.status()} ${response.url()}`); });
  const url = path => `${origin}${prefix}${path}`;
  await page.goto(url("/session/new"));
  await page.locator('input[name="email_address"]').fill(credentials.email);
  await page.locator('input[name="password"]').fill(credentials.password);
  await page.locator('input[type="submit"]').click();
  await page.waitForURL(url("/"));
  await page.waitForFunction(() => window.HostFixture?.application.controllers.length === 1);
  const hostDocument = await page.evaluate(() => window.documentID);
  await page.locator("#host-second").click();
  await page.waitForURL(url("/second"));
  assert.equal(await page.evaluate(() => window.documentID), hostDocument, "host internal navigation must use Turbo");
  await page.locator("#host-increment").click();
  assert.equal(await page.locator("output").innerText(), "1");
  await page.locator("#admin-entry").click();
  await page.waitForURL(url("/control/"));
  await page.waitForFunction(() => window.RailsNewadmin?.application.controllers.some(c => c.identifier === "newadmin-chart"));
  const adminDocument = await page.evaluate(() => window.documentID);
  assert.notEqual(adminDocument, hostDocument, "entering admin must load a new document");
  assert.equal(await page.evaluate(() => typeof window.HostFixture), "undefined", "host runtime leaked into admin");
  assert.equal(await page.locator('[data-newadmin-chart-target="plot"] svg').count(), 1);
  await page.evaluate(() => document.fonts.load('16px "bootstrap-icons"'));
  assert.equal(await page.evaluate(() => document.fonts.check('16px "bootstrap-icons"')), true);
  await page.locator('aside a[href$="/resources/articles"]').click();
  await page.waitForURL(url("/control/resources/articles"));
  await page.waitForFunction(() => window.chartThemeListeners() === 0);
  assert.equal(await page.evaluate(() => window.documentID), adminDocument, "admin internal navigation must use Turbo");
  await page.goBack();
  await page.waitForURL(url("/control/"));
  await page.waitForFunction(() => window.chartThemeListeners() === 1);
  assert.equal(await page.locator('[data-newadmin-chart-target="plot"] svg').count(), 1);
  await page.locator("#return-to-host").click();
  await page.waitForURL(url("/"));
  await page.waitForFunction(() => window.HostFixture?.starts === 1);
  assert.equal(await page.evaluate(() => typeof window.RailsNewadmin), "undefined", "admin runtime leaked into host");
  await page.goBack();
  await page.waitForURL(url("/control/"));
  await page.waitForFunction(() => window.chartThemeListeners() === 1);
  assert.equal(await page.evaluate(() => typeof window.HostFixture), "undefined");
  await page.goForward();
  await page.waitForURL(url("/"));
  await page.waitForFunction(() => window.HostFixture?.starts === 1);
  assert.equal(await page.evaluate(() => typeof window.RailsNewadmin), "undefined");
  // A plain host link must also cross layouts safely, even without data-turbo=false.
  await page.locator("#admin-plain").click();
  await page.waitForURL(url("/control/"));
  await page.waitForFunction(() => window.RailsNewadmin?.application.controllers.some(c => c.identifier === "newadmin-chart"));
  assert.equal(await page.evaluate(() => typeof window.HostFixture), "undefined");
  const stableDocument = await page.evaluate(() => window.documentID);
  const application = await page.evaluateHandle(() => window.RailsNewadmin.application);
  for (let cycle = 0; cycle < 3; cycle++) {
    await page.locator('aside a[href$="/resources/articles"]').click();
    await page.waitForURL(url("/control/resources/articles"));
    await page.waitForFunction(() => window.chartThemeListeners() === 0);
    const mode = await page.locator("html").getAttribute("data-theme");
    await page.locator('[data-action="newadmin-theme#toggle"]').click();
    const expected = {auto: "light", light: "dark", dark: "auto"}[mode];
    assert.equal(await page.locator("html").getAttribute("data-theme"), expected, "one click must advance one theme");
    await page.locator(".newadmin-brand").click();
    await page.waitForURL(url("/control/"));
    await page.waitForFunction(() => window.chartThemeListeners() === 1);
    assert.equal(await page.locator('[data-newadmin-chart-target="plot"] svg').count(), 1);
    assert.equal(await page.evaluate(app => app === window.RailsNewadmin.application, application), true, "Stimulus application replaced");
    assert.equal(await page.evaluate(() => window.documentID), stableDocument);
  }
  await page.locator('aside a[href$="/resources/articles"]').click();
  await page.waitForURL(url("/control/resources/articles"));
  await page.locator('a[href$="/resources/articles/new"]').click();
  await page.waitForURL(url("/control/resources/articles/new"));
  const title = `Browser created ${variant} ${prefix || "root"}`;
  await page.locator('input[name="record[title]"]').fill(title);
  await page.locator('input[name="record[status]"]').fill("draft");
  await page.locator('form[action$="/resources/articles"] input[type="submit"]').click();
  await page.waitForURL(location => /\/control\/resources\/articles\/\d+$/.test(location.pathname));
  assert.equal(createRequests, 1, "a single form submission must send a single POST");
  assert.equal(await page.evaluate(() => window.documentID), stableDocument);
  const direct = await context.newPage();
  const directScripts = [];
  direct.on("request", request => { if (request.resourceType() === "script") directScripts.push(request.url()); });
  await direct.goto(url("/control/resources/articles"));
  await direct.waitForLoadState("networkidle");
  assert.equal(directScripts.some(path => /rails_newadmin\/charts[-.]/.test(path)), false, "list must not load chart bundle");
  assert.equal(await direct.locator("tbody tr").filter({hasText: title}).count(), 1);
  await direct.close();
  await page.locator(`form[action="${prefix}/session"] button`).click();
  await page.waitForURL(url("/session/new"));
  assert.equal(await page.evaluate(() => typeof window.RailsNewadmin), "undefined");
  await page.goBack();
  await page.waitForURL(url("/session/new"));
  await page.goto(url("/control"));
  await page.waitForURL(url("/session/new"));
  assert.deepEqual(remoteRequests, [], "unexpected remote asset requests");
  assert.deepEqual(failures, [], "HTTP failures during navigation");
  assert.deepEqual(errors, [], "browser errors or duplicate-runtime warnings");
  console.log(`${variant} ${prefix || "/"}: host/admin/history/CRUD/logout, single runtimes/listeners and local assets passed`);
} finally {
  await browser.close();
}
