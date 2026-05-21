import * as path from 'path';

const Parser = require('tree-sitter');

let language: any = null;
try {
  const binding = require(path.join(__dirname, '../../bindings/node/moonhighlight.node'));
  language = Parser.Language.load(binding);
} catch (e) {
  console.warn('[moonbit-ls] Native parser not built. Run build in root to compile the Node binding.');
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

export function parseDocument(source: string): ParseNode | null {
  if (!language) return null;
  const parser = new Parser();
  parser.setLanguage(language);
  const tree = parser.parse(source);
  return convertNode(tree.rootNode);
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

export function nodeAtPosition(root: ParseNode, line: number, character: number): ParseNode | null {
  let best: ParseNode | null = null;
  function walk(node: ParseNode) {
    const start = node.startPosition;
    const end = node.endPosition;
    if (
      start.row < line || (start.row === line && start.column <= character)
    ) {
      if (
        end.row > line || (end.row === line && end.column >= character)
      ) {
        best = node;
        for (const child of node.children) walk(child);
      }
    }
  }
  walk(root);
  return best;
}
