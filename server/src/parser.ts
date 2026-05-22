import * as path from 'path';
import { execFileSync } from 'child_process';
import * as fs from 'fs';
import * as os from 'os';

let language: any = null;
try {
  const Parser = require('tree-sitter');
  const binding = require(path.join(__dirname, '../../bindings/node/moonhighlight.node'));
  language = Parser.Language.load(binding);
} catch (e) {
  console.warn('[moonbit-ls] Native parser not built. Fallback to tree-sitter CLI.');
}

export interface ParseNode {
  type: string;
  text: string;
  startPosition: { row: number; column: number };
  endPosition: { row: number; column: number };
  children: ParseNode[];
}

function convertNode(node: any): ParseNode {
  return {
    type: node.type,
    text: node.text,
    startPosition: node.startPosition,
    endPosition: node.endPosition,
    children: node.children.map(convertNode),
  };
}

function extractText(
  source: string,
  start: { row: number; column: number },
  end: { row: number; column: number }
): string {
  const lines = source.split('\n');
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

function parseTreeSitterXml(xml: string, source: string): ParseNode | null {
  xml = xml.replace(/<\?xml[^?]*\?>\s*/, '');
  const sourceMatch = xml.match(/<sources>\s*<source[^>]*>([\s\S]*)<\/source>\s*<\/sources>/);
  if (sourceMatch) xml = sourceMatch[1].trim();

  let pos = 0;

  function skipWhitespace() {
    while (pos < xml.length && /\s/.test(xml[pos])) pos++;
  }

  function parseNode(): ParseNode | null {
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

    const children: ParseNode[] = [];
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

    // consume closing tag
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

function parseDocumentWithCliSync(source: string): ParseNode | null {
  const tmpFile = path.join(
    os.tmpdir(),
    `moonbit-lsp-${Date.now()}-${Math.random().toString(36).slice(2)}.mbt`
  );
  fs.writeFileSync(tmpFile, source, 'utf-8');
  try {
    const treeSitterPath = path.join(__dirname, '..', '..', 'tree-sitter.exe');
    const projectRoot = path.join(__dirname, '..', '..');
    const stdout = execFileSync(treeSitterPath, ['parse', '-x', tmpFile], {
      encoding: 'utf-8',
      maxBuffer: 10 * 1024 * 1024,
      windowsHide: true,
      cwd: projectRoot,
    });
    return parseTreeSitterXml(stdout, source);
  } catch (e: any) {
    // tree-sitter may exit non-zero for syntax errors but still output XML with ERROR nodes
    if (e.stdout) {
      try {
        return parseTreeSitterXml(e.stdout, source);
      } catch {}
    }
    console.error('[moonbit-ls] CLI parse failed:', e.message || e);
    return null;
  } finally {
    try {
      fs.unlinkSync(tmpFile);
    } catch {}
  }
}

export function parseDocument(source: string): ParseNode | null {
  if (language) {
    const Parser = require('tree-sitter');
    const parser = new Parser();
    parser.setLanguage(language);
    const tree = parser.parse(source);
    return convertNode(tree.rootNode);
  }
  return parseDocumentWithCliSync(source);
}

export function findNodes(root: ParseNode, type: string): ParseNode[] {
  const results: ParseNode[] = [];
  function walk(node: ParseNode) {
    if (node.type === type) results.push(node);
    for (const child of node.children) walk(child);
  }
  walk(root);
  return results;
}

export function nodeAtPosition(
  root: ParseNode,
  line: number,
  character: number
): ParseNode | null {
  let best: ParseNode | null = null;
  function walk(node: ParseNode) {
    const start = node.startPosition;
    const end = node.endPosition;
    if (start.row < line || (start.row === line && start.column <= character)) {
      if (end.row > line || (end.row === line && end.column >= character)) {
        best = node;
        for (const child of node.children) walk(child);
      }
    }
  }
  walk(root);
  return best;
}
