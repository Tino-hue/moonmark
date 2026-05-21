import subprocess, re, os

def run_parse(code):
    with open('__t__.mbt','w') as f: f.write(code)
    r = subprocess.run(['.\\tree-sitter.exe','parse','__t__.mbt'], capture_output=True, text=True)
    os.remove('__t__.mbt')
    lines = r.stdout.strip().split('\n')
    return '\n'.join([re.sub(r'\s+\[\d+,\s*\d+\]\s+-\s+\[\d+,\s*\d+\]','',line) for line in lines])

tests = [
    ('Arrow expression', 'fn main {\n  let f = x => x + 1\n}\n'),
    ('Arrow expression with block', 'fn main {\n  let g = x => { x * 2 }\n}\n'),
]

with open('test/corpus/basic.txt','r',encoding='utf-8') as f:
    orig = f.read().rstrip()

out = orig
for name, code in tests:
    ast = run_parse(code)
    out += '\n\n==================\n' + name + '\n==================\n\n'
    out += code + '\n---\n\n' + ast + '\n'

with open('test/corpus/basic.txt','w',encoding='utf-8') as f:
    f.write(out)
print('Added', len(tests), 'tests')
