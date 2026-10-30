import path from 'node:path';

export const ROOT = new URL('..', import.meta.url).pathname;
export const PROFILE_DIR = path.join(ROOT, '.pw-profile');
export const EXTENSION_DIR = path.join(ROOT, 'extension');
export const CDP_URL = 'http://127.0.0.1:9222';
// CDP gives full control of the browser (incl. the logged-in Slack session):
// bind it to loopback only, never expose it.
export const CDP_ARGS = ['--remote-debugging-port=9222', '--remote-debugging-address=127.0.0.1'];
