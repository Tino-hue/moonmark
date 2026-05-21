import subprocess
import os
import re

def run_parse(code):
    with open('__temp__.mbt', 'w') as f:
        f.write(code)
    result = subprocess.run(['.\\tree-sitter.exe', 'parse', '__temp__.mbt'],
                          capture_output=True, text=True)
    os.remove('__temp__.mbt')
    lines = result.stdout.strip().split('\n')
    cleaned = []
    for line in lines:
        line = re.sub(r'\s+\[\d+,\s*\d+\]\s+-\s+\[\d+,\s*\d+\]', '', line)
        cleaned.append(line)
    return '\n'.join(cleaned)

tests = [
    ('Derive clause on struct', '#[derive]\npub struct Point[T] {\n  x : T\n  y : T\n} derive(Show, Eq)\n'),
    ('Derive clause on enum', 'enum Color {\n  Red\n  Green\n} derive(Show)\n'),
    ('Derive clause on trait', 'pub trait Show {\n  fn to_string(self) -> String\n} derive(ToJson)\n'),
    ('Impl for trait', 'impl Show for Point {\n  pub fn to_string(self) -> String {\n    ""\n  }\n}\n'),
    ('Impl with block', 'impl Array with {\n  pub fn sum(self) -> Int {\n    0\n  }\n}\n'),
    ('Labelled parameter with default', 'fn foo(~x : Int, y = 1) { }\n'),
    ('Labelled parameter shorthand', 'fn bar(~z) { }\n'),
    ('For loop with tuple pattern', 'fn main {\n  for (a, b) in list { }\n}\n'),
    ('For loop with wildcard', 'fn main {\n  for _ in list { }\n}\n'),
    ('While with nobreak', 'fn main {\n  while true {\n    break\n  } nobreak {\n    ()\n  }\n}\n'),
    ('For loop with nobreak', 'fn main {\n  for a in list {\n    break\n  } nobreak {\n    0\n  }\n}\n'),
    ('Loop with nobreak', 'fn main {\n  loop {\n    break\n  } nobreak {\n    0\n  }\n}\n'),
]

with open('test/corpus/basic.txt', 'r', encoding='utf-8') as f:
    original = f.read().rstrip()

output = original
for name, code in tests:
    ast = run_parse(code)
    output += '\n\n==================\n' + name + '\n==================\n\n'
    output += code
    output += '\n---\n\n'
    output += ast
    output += '\n'

with open('test/corpus/basic.txt', 'w', encoding='utf-8') as f:
    f.write(output)

print('Done, added', len(tests), 'tests')
