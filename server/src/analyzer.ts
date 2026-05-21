import { ParseNode, findNodes, nodeAtPosition } from './parser';
import {
  CompletionItem,
  CompletionItemKind,
  Definition,
  Hover,
  DocumentSymbol,
  SymbolKind,
  Range,
  Location,
} from 'vscode-languageserver/node';

export interface SymbolInfo {
  name: string;
  kind: 'function' | 'variable' | 'parameter' | 'type';
  range: Range;
}

export interface DiagnosticInfo {
  message: string;
  severity: 'error' | 'warning';
  range: Range;
}

function nodeRange(node: ParseNode): Range {
  return {
    start: { line: node.startPosition.row, character: node.startPosition.column },
    end: { line: node.endPosition.row, character: node.endPosition.column },
  };
}

export function analyze(root: ParseNode): { symbols: SymbolInfo[]; diagnostics: DiagnosticInfo[] } {
  const symbols: SymbolInfo[] = [];
  const diagnostics: DiagnosticInfo[] = [];

  const funcDecls = findNodes(root, 'function_declaration');
  for (const decl of funcDecls) {
    const idNode = findNodes(decl, 'identifier')[0];
    if (idNode?.text) {
      symbols.push({ name: idNode.text, kind: 'function', range: nodeRange(decl) });
    }
  }

  const valueDecls = findNodes(root, 'value_declaration');
  for (const decl of valueDecls) {
    const idNode = decl.children.find(c => c.type === 'identifier') ||
                   decl.children.find(c => c.type === 'identifier_pattern')?.children[0];
    if (idNode?.text) {
      symbols.push({ name: idNode.text, kind: 'variable', range: nodeRange(decl) });
    }
  }

  const errorNodes = findNodes(root, 'ERROR');
  for (const err of errorNodes) {
    diagnostics.push({ message: 'Syntax error', severity: 'error', range: nodeRange(err) });
  }

  return { symbols, diagnostics };
}

export function getCompletions(root: ParseNode, _line: number, _character: number): CompletionItem[] {
  const { symbols } = analyze(root);
  return symbols.map(s => ({
    label: s.name,
    kind: s.kind === 'function' ? CompletionItemKind.Function : CompletionItemKind.Variable,
  }));
}

export function getDefinition(root: ParseNode, line: number, character: number): Definition | undefined {
  const target = nodeAtPosition(root, line, character);
  if (!target || target.type !== 'identifier') return undefined;

  const { symbols } = analyze(root);
  const matches = symbols.filter(s => s.name === target.text);
  if (matches.length === 0) return undefined;

  // TODO: return proper URI from document context
  return matches.map(s => Location.create('file://placeholder', s.range));
}

export function getHover(root: ParseNode, line: number, character: number): Hover | undefined {
  const target = nodeAtPosition(root, line, character);
  if (!target) return undefined;

  const { symbols } = analyze(root);
  const sym = symbols.find(s => s.name === target.text);
  if (!sym) return undefined;

  return {
    contents: {
      kind: 'markdown',
      value: `**${sym.name}** \`${sym.kind}\``,
    },
  };
}

export function getDocumentSymbols(root: ParseNode): DocumentSymbol[] {
  const { symbols } = analyze(root);
  return symbols.map(s => ({
    name: s.name,
    kind: s.kind === 'function' ? SymbolKind.Function : SymbolKind.Variable,
    range: s.range,
    selectionRange: s.range,
  }));
}
