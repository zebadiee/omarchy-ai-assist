import sys
import json
import hashlib

def main():
    if len(sys.argv) != 7:
        print("Usage: python chunker.py <file_path> <pack_id> <max_chars> <overlap> <temp_file> <root_dir>")
        sys.exit(1)

    file_path = sys.argv[1]
    pack_id = sys.argv[2]
    max_chars = int(sys.argv[3])
    overlap = int(sys.argv[4])
    temp_file = sys.argv[5]
    root_dir = sys.argv[6]

    with open(file_path, 'r') as f:
        content = f.read()

    sha = hashlib.sha256(content.encode('utf-8')).hexdigest()
    rel_path = file_path.replace(root_dir, '').lstrip('/')

    chunks = []
    start = 0
    while start < len(content):
        end = start + max_chars
        if end > len(content):
            end = len(content)
        
        chunk = content[start:end]
        chunks.append(chunk)
        
        start += max_chars - overlap

    with open(temp_file, 'a') as f:
        for chunk in chunks:
            data = {
                'pack_id': pack_id,
                'source': rel_path,
                'sha256': sha,
                'text': chunk
            }
            f.write(json.dumps(data) + '\n')

if __name__ == '__main__':
    main()
