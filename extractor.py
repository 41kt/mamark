import os
import re

dump_path = r"d:\Flutter_project\mamark\update.md"
base_dir = r"d:\Flutter_project\mamark"

allowed_dirs_exact = [
    'lib/core/providers/',
    'lib/core/widgets/',
    'lib/core/presentation/',
    'lib/core/router/'
]

with open(dump_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

current_file = None
current_content = []
in_code_block = False

for line in lines:
    m = re.match(r'^##\s+`?([\w\.\/\-]+)`?', line)
    if m and not in_code_block:
        current_file = m.group(1).strip()
        continue
    
    if current_file and line.startswith('```dart'):
        in_code_block = True
        current_content = []
        continue
        
    if current_file and line.startswith('```yaml'):
        in_code_block = True
        current_content = []
        continue
        
    if current_file and line.startswith('```sql'):
        in_code_block = True
        current_content = []
        continue
    
    if in_code_block and line.startswith('```'):
        in_code_block = False
        
        current_file = current_file.replace('\\', '/')
        
        is_allowed = any(current_file.startswith(ad) for ad in allowed_dirs_exact)
        if not is_allowed:
            current_file = None
            continue

        full_path = os.path.normpath(os.path.join(base_dir, current_file))
        os.makedirs(os.path.dirname(full_path), exist_ok=True)
        with open(full_path, 'w', encoding='utf-8', newline='\n') as out_f:
            out_f.write("".join(current_content))
        print(f"Extracted: {current_file}")
        current_file = None
        continue
        
    if in_code_block:
        current_content.append(line)

print("Extraction complete.")
