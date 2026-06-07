import { readFileSync } from 'node:fs';

const app = readFileSync(new URL('../src/App.js', import.meta.url), 'utf8');
const required = [
  '旧后台兼容基线',
  '882',
  '2000',
  '3000',
  'd_taiwan',
  'taiwan_billing',
  '活动管理'
];

const missing = required.filter((text) => !app.includes(text));
if (missing.length > 0) {
  console.error(`missing frontend compatibility text: ${missing.join(', ')}`);
  process.exit(1);
}
console.log('frontend content ok');
