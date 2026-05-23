const https = require('https');

function fetch(url) {
  return new Promise((resolve, reject) => {
    https.get(url, { rejectUnauthorized: false }, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => resolve({ status: res.statusCode, body: data }));
    }).on('error', reject);
  });
}

async function main() {
  const packages = [
    { name: 'moonbitlang/core', branch: 'main', file: 'moon.mod' },
    { name: 'moonbitlang/x', branch: 'main', file: 'moon.mod.json' },
    { name: 'Lampese/moonbit-chalk', branch: 'main', file: 'moon.mod.json' },
    { name: 'tonyfettes/fish', branch: 'main', file: 'moon.mod.json' },
    { name: 'tonyfettes/fish', branch: 'master', file: 'moon.mod.json' },
    { name: 'peter-jerry-ye/parser-combinator', branch: 'main', file: 'moon.mod.json' },
    { name: 'peter-jerry-ye/moonbit-parser-combinator', branch: 'main', file: 'moon.mod.json' },
    { name: 'Lampese/moonbit-unicode-ffi', branch: 'main', file: 'moon.mod.json' },
    { name: 'Lampese/moonbit-interval-set', branch: 'main', file: 'moon.mod.json' },
    { name: 'Lampese/moonbit-gtree', branch: 'main', file: 'moon.mod.json' },
    { name: 'Lampese/moonbit-mlist', branch: 'main', file: 'moon.mod.json' },
    { name: 'Lampese/moonbit-nums', branch: 'main', file: 'moon.mod.json' },
    { name: 'lijunchen/unstable', branch: 'main', file: 'moon.mod.json' },
    { name: 'bobzhang/fantasy', branch: 'main', file: 'moon.mod.json' },
  ];

  for (const pkg of packages) {
    const url = `https://raw.githubusercontent.com/${pkg.name}/${pkg.branch}/${pkg.file}`;
    try {
      const res = await fetch(url);
      console.log(`\n=== ${pkg.name} (${pkg.file}) ===`);
      console.log(`Status: ${res.status}`);
      if (res.status === 200) {
        console.log(res.body);
      }
    } catch (e) {
      console.error(`Failed ${pkg.name}: ${e.message}`);
    }
  }
}

main();
