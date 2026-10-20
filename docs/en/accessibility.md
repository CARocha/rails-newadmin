# Accessibility

The administrator provides a skip link, keyboard navigation, visible focus, page titles, table headers and field-associated errors. After a Turbo navigation, focus moves to the main content; rejected validation moves it to the error summary. Activate a summary link to correct its field.

On narrow screens, use the menu button to open navigation. Escape closes it and returns focus to the button. This is a disclosure section rather than a modal dialog: Tab can continue towards the content. Wide tables scroll within a named region; focus it with Tab and use the arrow keys. Charts offer the same data under “View chart data” and do not require interacting with tooltips.

On macOS, Safari may require Option+Tab or enabling keyboard navigation in your system/browser settings to reach all controls.

## Appearance and enlargement

Choose light, dark or automatic using the appearance button. Automatic mode follows the system color scheme. Reduced motion and transparency preferences are respected. You can enlarge content using your browser; tables may require horizontal scrolling within their own region.

When customizing colors, preserve sufficient contrast: 4.5:1 for normal text and 3:1 for large text and control indicators where applicable. Check focus, hover, error messages and both themes too. See [text contrast](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html) and [reflow at 320 CSS pixels](https://www.w3.org/WAI/WCAG22/Understanding/reflow.html).

## Custom resources and views

Give models and attributes understandable names and translations. Preserve visible labels, table headers, names for scrollable regions and validation messages that explain how to fix problems. Keep focus styles and semantic links and buttons. Provide equivalent tables for custom charts.

Host authentication and overridden views require their own review. Automated axe and browser checks help find regressions, but do not replace screen reader review or constitute WCAG certification. Before production use, check your real resources and journeys with your users’ assistive technologies.
