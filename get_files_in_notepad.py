import os

# Path to your Flutter project's lib directory
lib_folder = "C:/mm_aasociates/MMAssociates/lib"

# Output file where everything will be saved
output_file = "all_lib_code.txt"

with open(output_file, "w", encoding="utf-8") as out_file:
    for root, dirs, files in os.walk(lib_folder):
        for file in files:
            if file.endswith(".dart"):  # Include only Dart files
                file_path = os.path.join(root, file)
                out_file.write(f"\n===== {os.path.relpath(file_path, lib_folder)} =====\n\n")
                with open(file_path, "r", encoding="utf-8") as f:
                    out_file.write(f.read())
                    out_file.write("\n\n")
                    
print(f"All Dart files have been written to {output_file}")
