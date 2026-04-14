import os

def fix_opacity_in_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    modified = False
    new_content = ""
    idx = 0
    target = ".withOpacity("

    while True:
        pos = content.find(target, idx)
        if pos == -1:
            new_content += content[idx:]
            break

        # We found ".withOpacity("
        new_content += content[idx:pos]
        
        # Start of arguments
        arg_start = pos + len(target)
        paren_count = 1
        curr = arg_start
        
        while curr < len(content) and paren_count > 0:
            if content[curr] == '(':
                paren_count += 1
            elif content[curr] == ')':
                paren_count -= 1
            curr += 1
            
        if paren_count == 0:
            # Successfully matched parentheses
            extracted_arg = content[arg_start:curr-1]
            # Replace with .withValues(alpha: extracted_arg)
            new_content += f".withValues(alpha: {extracted_arg})"
            idx = curr
            modified = True
        else:
            # Failed to match (e.g. EOF), just append and move on
            new_content += target
            idx = pos + len(target)

    if modified:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"Fixed {filepath}")

def main():
    lib_dir = '/Users/user/Desktop/GP/int_clean/lib'
    for root, dirs, files in os.walk(lib_dir):
        for file in files:
            if file.endswith('.dart'):
                filepath = os.path.join(root, file)
                fix_opacity_in_file(filepath)

if __name__ == "__main__":
    main()
