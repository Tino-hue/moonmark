const { execFileSync } = require('child_process');
const fs = require('fs');
const os = require('os');
const path = require('path');

const source = `fn main {
  let x = 42
}
`;

function extractText(src, start, end) {
  const lines = src.split('\n');
  if (start.row === end.row) {
    return lines[start.row].slice(start.column, end.column);
  }
  let text = lines[start.row].slice(start.column);
  for (let i = start.row + 1; i < end.row; i++) {
    text += '\n' + lines[i];
  }
  text += '\n' + lines[end.row].slice(0, end.column);
  return text;
}

function parseTreeSitterXml(xml, source) {
  xml = xml.replace(/<\?xml[^?]*\?>\s*/, '');
  const sourceMatch = xml.match(/<sources>\s*<source[^>]*>([\s\S]*)<\/source>\s*<\/sources>/);
  if (sourceMatch) xml = sourceMatch[1].trim();

  let pos = 0;

  function skipWhitespace() {
    while (pos < xml.length && /\s/.test(xml[pos])) pos++;
  }

  function parseNode() {
    skipWhitespace();
    if (pos >= xml.length || xml[pos] !== '<') return null;
    if (xml[pos + 1] === '/') return null;

    pos++; // <
    const nameStart = pos;
    while (pos < xml.length && xml[pos] !== ' ' && xml[pos] !== '>') pos++;
    const type = xml.slice(nameStart, pos);

    let srow = 0, scol = 0, erow = 0, ecol = 0;
    while (pos < xml.length && xml[pos] !== '>') {
      const attrStart = pos;
      while (pos < xml.length && xml[pos] !== '=' && xml[pos] !== '>' && xml[pos] !== ' ') pos++;
      const attrName = xml.slice(attrStart, pos).trim();
      if (xml[pos] === '=') {
        pos++; // =
        while (pos < xml.length && xml[pos] === ' ') pos++;
        const quote = xml[pos];
        pos++; // " or '
        const valStart = pos;
        while (pos < xml.length && xml[pos] !== quote) pos++;
        const val = xml.slice(valStart, pos);
        pos++; // closing quote
        if (attrName === 'srow') srow = +val;
        else if (attrName === 'scol') scol = +val;
        else if (attrName === 'erow') erow = +val;
        else if (attrName === 'ecol') ecol = +val;
      } else {
        pos++;
      }
    }
    pos++; // >

    const children = [];
    while (true) {
      skipWhitespace();
      if (pos >= xml.length) break;
      if (xml[pos] === '<' && xml[pos + 1] === '/') break;
      if (xml[pos] === '<') {
        const child = parseNode();
        if (child) children.push(child);
      } else {
        // anonymous token text, skip
        while (pos < xml.length && xml[pos] !== '<') pos++;
      }
    }

    if (xml[pos] === '<' && xml[pos + 1] === '/') {
      pos += 2; // </
      while (pos < xml.length && xml[pos] !== '>') pos++;
      pos++; // >
    }

    const start = { row: srow, column: scol };
    const end = { row: erow, column: ecol };
    const text = extractText(source, start, end);
    return { type, text, startPosition: start, endPosition: end, children };
  }

  return parseNode();
}

const tmpFile = path.join(os.tmpdir(), `test-binding-${Date.now()}.mbt`);
fs.writeFileSync(tmpFile, source, 'utf-8');

try {
  const stdout = execFileSync(path.join(__dirname, 'tree-sitter.exe'), ['parse', '-x', tmpFile], {
    encoding: 'utf-8',
    maxBuffer: 10 * 1024 * 1024,
    windowsHide: true,
  });
  const root = parseTreeSitterXml(stdout, source);
  if (root) {
    console.log('AST root type:', root.type);
    console.log('Children count:', root.children.length);
    const firstDecl = root.children[0];
    if (firstDecl) {
      console.log('First child type:', firstDecl.type);
      const funcDecl = firstDecl.children.find(c => c.type === 'function_declaration');
      if (funcDecl) {
        const idNode = funcDecl.children.find(c => c.type === 'identifier');
        if (idNode) console.log('Function name:', idNode.text);
      }
    }
    console.log('test-binding: PASSED');
  } else {
    console.error('test-binding: FAILED - empty AST');
    process.exit(1);
  }
} catch (e) {
  console.error('test-binding: FAILED', e.message);
  process.exit(1);
} finally {
  try { fs.unlinkSync(tmpFile); } catch {}
}
