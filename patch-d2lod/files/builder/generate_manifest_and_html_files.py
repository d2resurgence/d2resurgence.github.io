import os
import zlib
import json
from datetime import datetime, timezone

# Define file names to ignore CRC
file_names_to_ignore_crc = [
    "d2gl.ini",
    "d2fps.ini",
    "SGD2FreeResolution.json",
    "bh_settings.cfg",
    "bh.cfg" # Added with config generator - if they want to re-sync default they should delete bh.cfg and update
]

# Define file names to exclude from manifest and HTML generation
file_names_to_exclude = [
    "index.html",
    "manifest.json"
]

def compute_crc(file_path):
    crc = 0
    with open(file_path, 'rb') as f:
        while chunk := f.read(4096):
            crc = zlib.crc32(chunk, crc)
    return format(crc & 0xFFFFFFFF, '08x')

def get_file_details(file_path):
    stat = os.stat(file_path)
    ignore_crc = os.path.basename(file_path) in file_names_to_ignore_crc
    return {
        'name': os.path.basename(file_path),
        'crc': compute_crc(file_path) if not ignore_crc else '',
        'last_modified': datetime.fromtimestamp(stat.st_mtime, timezone.utc).strftime('%Y-%m-%dT%H:%M:%S.%fZ'),
        'content_length': stat.st_size,
        'ignore_crc': ignore_crc,
        'deprecated': False
    }

def generate_html_index(folder_path, files):
    html_content = f"""<html>
<head><title>Index of {folder_path}</title></head>
<body>
<h1>Index of {folder_path}</h1><hr><pre>
<a href="../index.html">../</a>
"""
    for file in files:
        if file['name'] not in file_names_to_exclude:
            file_link = f"{file['name']}/" if os.path.isdir(os.path.join(folder_path, file['name'])) else file['name']
            last_modified = file.get('last_modified', 'N/A')
            content_length = file.get('content_length', 'N/A')
            html_content += f"<a href='{file_link}'>{file['name']}</a>\t\t\t{last_modified} \t\t\t{content_length}\n"
    html_content += "</pre><hr></body></html>"
    return html_content

def process_folder(folder_path):
    files = [f for f in os.listdir(folder_path) if os.path.isfile(os.path.join(folder_path, f)) and f not in file_names_to_exclude]
    file_details = [get_file_details(os.path.join(folder_path, f)) for f in files]
    
    subfolders = [f for f in os.listdir(folder_path) if os.path.isdir(os.path.join(folder_path, f))]

    new_manifest = {
        'files': file_details
    }

    new_html_content = generate_html_index(folder_path, file_details + [{'name': f} for f in subfolders])

    manifest_path = os.path.join(folder_path, 'manifest.json')
    index_path = os.path.join(folder_path, 'index.html')

    update_files = False

    if os.path.exists(manifest_path):
        with open(manifest_path, 'r') as f:
            existing_manifest = json.load(f)
        if existing_manifest != new_manifest:
            update_files = True
    else:
        update_files = True

    if os.path.exists(index_path):
        with open(index_path, 'r') as f:
            existing_html_content = f.read()
        if existing_html_content != new_html_content:
            update_files = True
    else:
        update_files = True

    if update_files:
        with open(manifest_path, 'w') as f:
            json.dump(new_manifest, f, indent=4)
        with open(index_path, 'w') as f:
            f.write(new_html_content)

    for subfolder in subfolders:
        process_folder(os.path.join(folder_path, subfolder))

if __name__ == "__main__":
    process_folder(os.path.join(os.environ['GITHUB_WORKSPACE'], 'patch-d2lod/files/resurgence-patches'))
