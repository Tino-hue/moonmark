// MoonHighlight — TypeScript type definitions for Node.js binding
// Provides type information for the tree-sitter grammar API

declare module 'moonhighlight' {
  import { SyntaxNode, Tree, Language, Parser } from 'tree-sitter';

  interface MoonBitLanguage {
    language: Language;
    parse(source: string, options?: { includedRanges?: Array<{ startIndex: number; endIndex: number }> }): Tree;
    nodeTypeNames: string[];
  }

  const moonbit: MoonBitLanguage;
  export default moonbit;
}