// Starts Playwright's Chromium *without* automation flags so Google SSO works,
// using the dedicated test profile (.pw-profile/). Log in to Slack here once;
// `npm run dev` then reuses the session with the extension loaded.
import { spawn } from 'node:child_process';
import { chromium } from 'playwright';
import { PROFILE_DIR, CDP_ARGS } from './config.mjs';

spawn(chromium.executablePath(), [
  `--user-data-dir=${PROFILE_DIR}`,
  ...CDP_ARGS,
  '--no-first-run',
  '--no-default-browser-check',
  'https://app.slack.com/client',
], { stdio: 'ignore', detached: true }).unref();
console.log('Chromium started; CDP on 127.0.0.1:9222');
