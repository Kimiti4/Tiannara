import os
import re

def main():
    print("Running extract_all_phases.py...")
    
    if not os.path.exists('final.txt'):
        print("Error: final.txt not found in workspace!")
        return

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
                path_candidate = match.group(1).strip()
                # Skip paths that represent directories or are empty
                if path_candidate.endswith('/') or path_candidate.endswith('\\'):
                    continue
                current_path = path_candidate
                current_code = []
                in_code_block = False
                continue
                
        if current_path:
            if line.strip().startswith('```'):
                if not in_code_block:
                    in_code_block = True
                    continue
                else:
                    in_code_block = False
                    blocks.append((current_path, '\n'.join(current_code)))
                    current_path = None
                    continue
                
            if in_code_block:
                current_code.append(line)

    print(f"Found {len(blocks)} raw code blocks in final.txt.")
    
    written_count = 0
    target_keywords = [
        "phase8", "phase9", "phase10", "phase11", "phase13", "phase14",
        "phase15", "phase16", "phase17", "phase18", "phase19",
        "category", "simulation"
    ]
    
    for path, code in blocks:
        normalized_path = path.replace('\\', '/')
        if normalized_path.endswith('/') or normalized_path.endswith('\\'):
            continue
            
        is_target = any(kw in normalized_path.lower() for kw in target_keywords)
        
        if not is_target and (normalized_path.startswith("test/") or normalized_path.startswith("config/")):
            is_target = True
            
        if is_target:
            dest_path = os.path.join('tiannara_runtime', path)
            dest_dir = os.path.dirname(dest_path)
            
            # Additional double check to avoid writing to direct folder paths
            if dest_path.endswith('/') or dest_path.endswith('\\') or os.path.isdir(dest_path):
                continue
                
            os.makedirs(dest_dir, exist_ok=True)
            
            with open(dest_path, 'w', encoding='utf-8') as dest_f:
                dest_f.write(code)
                
            print(f"  Written: {dest_path} ({len(code.split('\n'))} lines)")
            written_count += 1
            
    print(f"Successfully extracted {written_count} files into tiannara_runtime!")

if __name__ == '__main__':
    main()
