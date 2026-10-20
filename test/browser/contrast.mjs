import assert from "node:assert/strict";

// Supplement axe's inconclusive symbol/SVG checks using the rendered theme tokens.
export async function assertPaletteContrast(page) {
  const results = await page.evaluate(() => {
    const style = getComputedStyle(document.documentElement);
    const luminance = token => {
      const color = style.getPropertyValue(`--newadmin-${token}`).trim();
      if (!/^#[a-f0-9]{6}$/i.test(color)) throw new Error(`Expected fixture color token: ${token}=${color}`);
      const values = [1, 3, 5].map(offset => parseInt(color.slice(offset, offset + 2), 16) / 255)
        .map(value => value <= 0.04045 ? value / 12.92 : ((value + 0.055) / 1.055) ** 2.4);
      return values.reduce((sum, value, index) => sum + value * [0.2126, 0.7152, 0.0722][index], 0);
    };
    return [
      ["text", "surface", 4.5], ["text", "canvas", 4.5],
      ["text-muted", "surface-raised", 4.5], ["sidebar-text", "sidebar", 4.5],
      ["primary", "surface", 4.5], ["on-primary", "primary", 4.5],
      ["danger", "danger-bg", 4.5], ["surface", "danger", 4.5],
      ["control-border", "surface", 3], ["chart-primary", "surface", 3],
      ["chart-secondary", "surface", 3], ["chart-secondary", "canvas", 3],
      ["chart-secondary", "sidebar", 3]
    ].map(([foreground, background, minimum]) => {
      const [dark, light] = [luminance(foreground), luminance(background)].sort((a, b) => a - b);
      return {foreground, background, minimum, ratio: (light + 0.05) / (dark + 0.05)};
    });
  });
  for (const result of results) assert.ok(result.ratio >= result.minimum, `Theme contrast: ${JSON.stringify(result)}`);
}
