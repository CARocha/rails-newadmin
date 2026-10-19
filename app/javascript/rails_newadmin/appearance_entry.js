import { applyInitialTheme } from "./appearance.js";
try { applyInitialTheme(); } catch { /* Styles still follow the system when storage is blocked. */ }
