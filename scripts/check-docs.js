const fs = require('fs');
const path = require('path');
const axios = require('axios');

const DOCS_DIR = path.join(__dirname, '..', 'docs');
const API_DOCS = path.join(DOCS_DIR, 'wb-api.md');
const MAX_AGE_DAYS = 30;

async function checkApiEndpoints() {
  const content = fs.readFileSync(API_DOCS, 'utf8');
  const endpoints = content.match(/\/api\/v\d+\/[a-zA-Z0-9/-]+/g) || [];
  
  console.log('Проверка API эндпоинтов...');
  for (const endpoint of endpoints) {
    try {
      const response = await axios.head(`https://suppliers-api.wildberries.ru${endpoint}`);
      console.log(`✓ ${endpoint} - доступен`);
    } catch (error) {
      console.warn(`⚠ ${endpoint} - возможно устарел или недоступен`);
    }
  }
}

function checkDocsAge() {
  console.log('\nПроверка возраста документации...');
  const files = fs.readdirSync(DOCS_DIR);
  
  for (const file of files) {
    const filePath = path.join(DOCS_DIR, file);
    const stats = fs.statSync(filePath);
    const ageInDays = (Date.now() - stats.mtime) / (1000 * 60 * 60 * 24);
    
    if (ageInDays > MAX_AGE_DAYS) {
      console.warn(`⚠ ${file} не обновлялся более ${MAX_AGE_DAYS} дней`);
    } else {
      console.log(`✓ ${file} актуален`);
    }
  }
}

function checkLinks() {
  console.log('\nПроверка внутренних ссылок...');
  const files = fs.readdirSync(DOCS_DIR);
  
  for (const file of files) {
    const content = fs.readFileSync(path.join(DOCS_DIR, file), 'utf8');
    const links = content.match(/\[.*?\]\((.*?)\)/g) || [];
    
    for (const link of links) {
      const [, url] = link.match(/\[.*?\]\((.*?)\)/) || [];
      if (url && !url.startsWith('http')) {
        const linkedFile = path.join(DOCS_DIR, url.replace(/^\.\//, ''));
        if (!fs.existsSync(linkedFile)) {
          console.warn(`⚠ В ${file} найдена битая ссылка: ${url}`);
        }
      }
    }
  }
}

async function main() {
  console.log('Начинаю проверку документации...\n');
  
  await checkApiEndpoints();
  checkDocsAge();
  checkLinks();
  
  console.log('\nПроверка завершена');
}

main().catch(console.error); 