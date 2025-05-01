import hashlib
import os

def compute_file_hash(filepath):
    """Compute and return the SHA256 hash of a file."""
    sha256_hash = hashlib.sha256()
    with open(filepath, "rb") as f:
        for byte_block in iter(lambda: f.read(4096), b""):
            sha256_hash.update(byte_block)
    return sha256_hash.hexdigest()

def check_redundant_files_in_folder(folder_path):
    """Check for files with identical SHA256 hashes in the given folder and its subfolders, excluding certain files and folders."""
    # Extensions to ignore
    ignored_extensions = ['.aaa', '.editor', '.scn', '.meta', '.geo', '.sh', '.sc', '.def', '.txt', '.fsb', '.vsb']
    hashes = {}

    for root, dirs, files in os.walk(folder_path, topdown=True):
        # Exclude .git directory
        dirs[:] = [d for d in dirs if d != '.git']
        dirs[:] = [d for d in dirs if d != 'core']

        for filename in files:
            if any(filename.endswith(ext) for ext in ignored_extensions):
                continue  # Skip files with ignored extensions

            filepath = os.path.join(root, filename)
            file_hash = compute_file_hash(filepath)
            if file_hash in hashes:
                hashes[file_hash].append(filepath)
            else:
                hashes[file_hash] = [filepath]

    # Filter out unique files, leaving only duplicates
    duplicates = {hash: paths for hash, paths in hashes.items() if len(paths) > 1}

    if duplicates:
        print("Found files with identical SHA256 signatures:")
        for file_hash, paths in duplicates.items():
            print(f"\nSHA256: {file_hash}")
            for path in paths:
                print(f" - {path}")
    else:
        print("No duplicate files found.")

# Example usage
if __name__ == "__main__":
    check_redundant_files_in_folder('../../assets/')
    # input("Press Enter to exit...")  # Wait for a keypress at the end
