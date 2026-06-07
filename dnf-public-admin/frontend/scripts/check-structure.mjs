import { existsSync } from 'node:fs';
import { resolve } from 'node:path';

const required = [
  'src/main.js',
  'src/App.js',
  'index.html'
];

const missing = required.filter((p) => !existsSync(resolve(process.cwd(), p)));
if (missing.length) {
  console.error('missing files:', missing.join(', '));
  process.exit(1);
}
console.log('frontend structure ok');
