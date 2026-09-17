import os
import re

def main():
    with open('final.txt', 'r', encoding='utf-8') as f:
        content = f.read()

    # Find all blocks of the form:
    # ### 📄 `path` or ### `path` or similar
    # followed by ```elixir
    # code
    # ```
    # Let's do a more robust parse by looking for lines starting with '###' and having backticks,
    # and then tracking subsequent lines until the next '###' or end of file.
    
    lines = content.split('\n')
    current_path = None
    current_code = []
    in_code_block = False
    blocks = []
    
    for i, line in enumerate(lines):
        # Detect file path header
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
                
    print(f"Total code blocks found: {len(blocks)}")
    for path, code in blocks:
        code_lines = code.split('\n')
        print(f"{path}: {len(code_lines)} lines")

if __name__ == '__main__':
    main()
