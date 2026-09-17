import re

def main():
    with open('final.txt', 'r', encoding='utf-8') as f:
        content = f.read()

    lines = content.split('\n')
    current_path = None
    current_code = []
    in_code_block = False
    blocks = []
    
    for i, line in enumerate(lines):
        if line.strip().startswith('###'):
            match = re.search(r'`([^`]+)`', line)
            if match:
                current_path = match.group(1).strip()
                current_code = []
                in_code_block = False
                continue
                
        if current_path:
            if line.strip().startswith('```elixir'):
                in_code_block = True
                continue
            elif line.strip().startswith('```') and in_code_block:
                in_code_block = False
                blocks.append((current_path, '\n'.join(current_code)))
                current_path = None
                continue
                
            if in_code_block:
                current_code.append(line)
                
    # Filter and check Phase 15, 16, 17, 18, 19
    for path, code in blocks:
        if any(f"phase{n}" in path for n in [15, 16, 17, 18, 19]) or "tiarnara/phase18" in path:
            print(f"File: {path} ({len(code.split('\n'))} lines)")
            # Print the first 5 lines of the code to see the module name
            first_lines = [l for l in code.split('\n')[:5] if l.strip()]
            print("  Start:", " | ".join(first_lines))

if __name__ == '__main__':
    main()
