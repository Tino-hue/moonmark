import {
  createConnection,
  TextDocuments,
  ProposedFeatures,
  InitializeParams,
  TextDocumentSyncKind,
  CompletionItem,
  DiagnosticSeverity,
  DocumentSymbol,
  StreamMessageReader,
  StreamMessageWriter,
} from 'vscode-languageserver/node';
import { TextDocument } from 'vscode-languageserver-textdocument';
import { parseDocument } from './parser';
import {
  analyze,
  getCompletions,
  getDefinition,
  getHover,
  getDocumentSymbols,
} from './analyzer';

const connection = process.argv.includes('--stdio') || process.argv.includes('--node-ipc')
  ? createConnection(ProposedFeatures.all)
  : createConnection(
      ProposedFeatures.all,
      new StreamMessageReader(process.stdin),
      new StreamMessageWriter(process.stdout)
    );
const documents: TextDocuments<TextDocument> = new TextDocuments(TextDocument);

connection.onInitialize((params: InitializeParams) => {
  return {
    capabilities: {
      textDocumentSync: TextDocumentSyncKind.Incremental,
      completionProvider: { resolveProvider: false },
      definitionProvider: true,
      hoverProvider: true,
      documentSymbolProvider: true,
    },
  };
});

documents.onDidChangeContent(change => {
  const text = change.document.getText();
  const tree = parseDocument(text);
  if (!tree) return;

  const { diagnostics } = analyze(tree);
  connection.sendDiagnostics({
    uri: change.document.uri,
    diagnostics: diagnostics.map(d => ({
      range: d.range,
      message: d.message,
      severity: d.severity === 'error' ? DiagnosticSeverity.Error : DiagnosticSeverity.Warning,
      source: 'moonbit-ls',
    })),
  });
});

connection.onCompletion(params => {
  const doc = documents.get(params.textDocument.uri);
  if (!doc) return [];
  const tree = parseDocument(doc.getText());
  if (!tree) return [];
  return getCompletions(tree, params.position.line, params.position.character);
});

connection.onDefinition(params => {
  const doc = documents.get(params.textDocument.uri);
  if (!doc) return undefined;
  const tree = parseDocument(doc.getText());
  if (!tree) return undefined;
  return getDefinition(tree, params.position.line, params.position.character);
});

connection.onHover(params => {
  const doc = documents.get(params.textDocument.uri);
  if (!doc) return undefined;
  const tree = parseDocument(doc.getText());
  if (!tree) return undefined;
  return getHover(tree, params.position.line, params.position.character);
});

connection.onDocumentSymbol(params => {
  const doc = documents.get(params.textDocument.uri);
  if (!doc) return [];
  const tree = parseDocument(doc.getText());
  if (!tree) return [];
  return getDocumentSymbols(tree);
});

documents.listen(connection);
connection.listen();
