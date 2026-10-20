import "@hotwired/turbo";
import { Application, Controller } from "@hotwired/stimulus";
const application = Application.start();
window.HostFixture = { application, starts: (window.HostFixture?.starts || 0) + 1 };
application.register("host-counter", class extends Controller {
  static targets = ["value"];
  increment() { this.valueTarget.textContent = String(Number(this.valueTarget.textContent) + 1); }
});
