const { exec } = require('child_process');
const puppeteer = require('puppeteer');

(async () => {
    // build it first
    console.log('Starting local web server...');
    const server = exec('npx http-server build/web -p 8080');
    
    await new Promise(r => setTimeout(r, 2000));
    
    const browser = await puppeteer.launch({headless: "new"});
    const page = await browser.newPage();
    
    page.on('console', msg => console.log('BROWSER CONSOLE:', msg.text()));
    page.on('pageerror', err => console.log('BROWSER ERROR:', err.toString()));
    
    await page.goto('http://localhost:8080');
    await new Promise(r => setTimeout(r, 5000));
    
    await browser.close();
    server.kill();
})();
