import "@hotwired/turbo";
import { Application, Controller } from "@hotwired/stimulus";
import { applyInitialTheme, nextMode } from "./appearance.js";

const application = Application.start();
window.RailsNewadmin = { application, Controller };
application.register("newadmin-theme", class extends Controller {
  static targets = ["button", "status"];
  static values = { modes: Object, label: String };
  connect() {
    try { applyInitialTheme(); } catch {}
    this.describeMode(false);
  }
  describeMode(announce) {
    const mode = document.documentElement.dataset.theme;
    const description = `${this.labelValue}: ${this.modesValue[mode]}`;
    if (this.hasButtonTarget) this.buttonTarget.setAttribute("aria-label", description);
    if (announce && this.hasStatusTarget) this.statusTarget.textContent = description;
  }
  toggle() {
    const mode = nextMode(document.documentElement.dataset.theme);
    document.documentElement.dataset.theme = mode;
    try { window.localStorage.setItem("rails-newadmin.theme", mode); } catch {}
    this.describeMode(true);
    document.dispatchEvent(new CustomEvent("rails-newadmin:theme", { detail: { mode } }));
  }
});
application.register("newadmin-nav", class extends Controller {
  static targets = ["panel", "toggle"];
  toggle() {
    const open = this.panelTarget.dataset.open !== "true";
    this.panelTarget.dataset.open = String(open);
    this.toggleTarget.setAttribute("aria-expanded", String(open));
  }
  close(event) {
    if (!this.hasPanelTarget || event.key !== "Escape" || this.panelTarget.dataset.open !== "true") return;
    this.panelTarget.dataset.open = "false";
    this.toggleTarget.setAttribute("aria-expanded", "false");
    this.toggleTarget.focus();
  }
});
application.register("newadmin-relation", class extends Controller {
  static targets = ["search", "select", "status", "more"];
  static values = { url: String };
  connect() { this.page = 1; }
  disconnect() { clearTimeout(this.timer); this.abort?.abort(); }
  search() { clearTimeout(this.timer); this.timer = setTimeout(() => this.load(1), 180); }
  more() { this.load(this.page + 1); }
  async load(page) {
    this.abort?.abort();
    this.abort = new AbortController();
    const abort = this.abort;
    const spanish = document.documentElement.lang === "es";
    this.selectTarget.setAttribute("aria-busy", "true");
    this.moreTarget.disabled = true;
    this.statusTarget.textContent = spanish ? "Cargando opciones…" : "Loading options…";
    const url = new URL(this.urlValue, window.location.origin);
    url.searchParams.set("q", this.searchTarget.value.slice(0, 200));
    url.searchParams.set("page", page);
    try {
      const response = await fetch(url, { signal: this.abort.signal, headers: { Accept: "application/json" } });
      if (!response.ok) throw new Error("Unavailable");
      const options = await response.json();
      if (!Array.isArray(options)) throw new Error("Invalid options");
      const selected = [...this.selectTarget.options].find((option) => option.selected && option.value);
      if (page === 1) this.selectTarget.replaceChildren(new Option("", ""), ...(selected ? [selected] : []));
      const ids = new Set([...this.selectTarget.options].map((option) => option.value));
      for (const item of options) {
        if (!item || typeof item.label !== "string" || !["string", "number"].includes(typeof item.id)) continue;
        if (!ids.has(String(item.id))) this.selectTarget.add(new Option(item.label, item.id));
      }
      this.page = page;
      this.moreTarget.hidden = options.length < 20;
      this.statusTarget.textContent = `${spanish ? "Opciones cargadas" : "Options loaded"}: ${options.length}.`;
    } catch (error) {
      if (error.name !== "AbortError") this.statusTarget.textContent = document.documentElement.lang === "es" ? "No se pudieron cargar las opciones." : "Options could not be loaded.";
    } finally {
      if (this.abort === abort) {
        this.selectTarget.removeAttribute("aria-busy");
        this.moreTarget.disabled = false;
      }
    }
  }
});
// A host may run its own Turbo instance; cross-layout transitions must reload.
document.addEventListener("turbo:before-visit", (event) => {
  const path = new URL(event.detail.url).pathname;
  const mount = document.body.dataset.newadminMount;
  if (mount && path !== mount && !path.startsWith(`${mount}/`)) {
    event.preventDefault();
    window.location.assign(event.detail.url);
  }
});

// Validation responses replace the form without a full navigation.
application.register("newadmin-errors", class extends Controller {
  connect() { this.element.focus(); }
  focusField(event) {
    const link = event.target.closest("a[href^='#']");
    const field = link && document.getElementById(link.getAttribute("href").slice(1));
    if (!field) return;
    event.preventDefault();
    field.focus();
  }
});
document.addEventListener("turbo:load", (event) => {
  if (event.detail.timing?.visitStart && !document.querySelector("#newadmin-errors")) {
    document.querySelector("#main-content")?.focus();
  }
});
