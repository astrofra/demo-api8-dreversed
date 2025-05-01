import os
import json

def find_referenced_images_in_scn(scn_file):
    """Extract referenced image paths from a .scn file."""
    referenced_images = set()
    try:
        with open(scn_file, 'r') as file:
            scn_data = json.load(file)
            referenced_images.update(find_paths(scn_data))
    except Exception as e:
        print(f"Error reading or parsing {scn_file}: {e}")
    return referenced_images

def find_paths(data_structure):
    """Recursively search for "path" keys in JSON data structure."""
    paths = set()
    if isinstance(data_structure, dict):
        for key, value in data_structure.items():
            if key == "path" and isinstance(value, str):
                paths.add(value)
            else:
                paths.update(find_paths(value))
    elif isinstance(data_structure, list):
        for item in data_structure:
            paths.update(find_paths(item))
    return paths

def find_unreferenced_images(folder_path):
    """Find image files that are not referenced in any .scn file, excluding specific folders."""
    # Extensions to search for
    image_extensions = ['.png', '.jpg', '.jpeg']
    # Collect all referenced images from .scn files
    all_referenced_images = set()
    # Collect all image files
    all_image_files = set()

    for root, dirs, files in os.walk(folder_path, topdown=True):
        # Exclude 'core' directory
        dirs[:] = [d for d in dirs if d != 'core' and not root.endswith('core')]
        dirs[:] = [d for d in dirs if d != 'qr' and not root.endswith('qr')]

        for file in files:
            filepath = os.path.join(root, file)
            if file.endswith('.scn'):
                all_referenced_images.update(find_referenced_images_in_scn(filepath))
            elif any(file.endswith(ext) for ext in image_extensions):
                # Adjust the filepath to match the format in .scn files if necessary
                relative_path = os.path.relpath(filepath, folder_path)
                all_image_files.add(relative_path.replace("\\", "/"))

    # Filter out referenced images
    unreferenced_images = all_image_files - all_referenced_images

    return unreferenced_images

# Example usage
if __name__ == "__main__":
    unreferenced_images = find_unreferenced_images('../../assets/')
    if unreferenced_images:
        print("Unreferenced image files:")
        for image in unreferenced_images:
            print(image)
    else:
        print("No unreferenced image files found.")
