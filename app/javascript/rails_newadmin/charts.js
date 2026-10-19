import * as echarts from "echarts/core";
import { BarChart, LineChart } from "echarts/charts";
import { GridComponent, TooltipComponent, AriaComponent } from "echarts/components";
import { SVGRenderer } from "echarts/renderers";
echarts.use([BarChart, LineChart, GridComponent, TooltipComponent, AriaComponent, SVGRenderer]);

const { application, Controller } = window.RailsNewadmin;
application.register("newadmin-chart", class extends Controller {
  static targets = ["plot"];
  static values = { spec: Object };
  connect() {
    this.chart = echarts.init(this.plotTarget, null, { renderer: "svg" });
    this.redraw = () => this.render();
    this.observer = new ResizeObserver(() => this.chart?.resize());
    this.observer.observe(this.plotTarget);
    document.addEventListener("rails-newadmin:theme", this.redraw);
    this.media = window.matchMedia("(prefers-color-scheme: dark)");
    this.media.addEventListener("change", this.redraw);
    this.render();
  }
  disconnect() {
    this.observer?.disconnect();
    document.removeEventListener("rails-newadmin:theme", this.redraw);
    this.media?.removeEventListener("change", this.redraw);
    this.chart?.dispose();
  }
  render() {
    const { rows, columns, type } = this.specValue;
    const style = getComputedStyle(document.documentElement);
    const text = style.getPropertyValue("--newadmin-text").trim();
    this.chart.setOption({ animation: false, color: [style.getPropertyValue("--newadmin-chart-primary").trim()], textStyle: { color: text },
      aria: { enabled: true }, tooltip: { trigger: "axis", renderMode: "richText" }, grid: { left: 48, right: 16, top: 16, bottom: 40 },
      xAxis: { type: "category", data: rows.map(row => row[0]), axisLabel: { color: text } },
      yAxis: { type: "value", axisLabel: { color: text } }, series: [{ name: columns[1], type, data: rows.map(row => row[1]) }] }, true);
  }
});
