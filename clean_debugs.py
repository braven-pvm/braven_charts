#!/usr/bin/env python3
"""
Safely remove debugPrint statements from Dart files.
Handles both single-line and multi-line debugPrint calls.
"""

import re
import sys


def remove_debugprints(content):
    """
    Remove all debugPrint() calls from Dart code.
    Handles multiline calls properly using regex.
    """
    # Pattern matches debugPrint with optional whitespace,
    # then captures everything until the closing );
    # The (?s) flag makes . match newlines
    pattern = r"^\s*debugPrint\((?s:.*?)\);\s*$"

    lines = content.split("\n")
    result_lines = []
    i = 0

    while i < len(lines):
        line = lines[i]

        # Check if line starts with debugPrint
        if "debugPrint(" in line:
            # Collect lines until we find the closing );
            debug_block = [line]
            paren_depth = line.count("(") - line.count(")")

            # If statement closes on same line
            if ");" in line and paren_depth <= 0:
                # Single line debugPrint - skip it
                i += 1
                continue

            # Multi-line debugPrint - collect all lines
            i += 1
            while i < len(lines) and (paren_depth > 0 or ");" not in lines[i]):
                debug_block.append(lines[i])
                paren_depth += lines[i].count("(") - lines[i].count(")")
                i += 1

            # Add the closing line if we found it
            if i < len(lines) and ");" in lines[i]:
                debug_block.append(lines[i])
                i += 1

            # Skip this entire block (don't add to result)
            continue

        # Not a debugPrint line - keep it
        result_lines.append(line)
        i += 1

    return "\n".join(result_lines)


def main():
    file_path = r"lib\src_plus\rendering\chart_render_box.dart"

    # Read file
    with open(file_path, "r", encoding="utf-8") as f:
        content = f.read()

    original_lines = len(content.split("\n"))

    # Remove debugPrints
    cleaned = remove_debugprints(content)

    new_lines = len(cleaned.split("\n"))

    # Write back
    with open(file_path, "w", encoding="utf-8") as f:
        f.write(cleaned)

    print(f"Removed {original_lines - new_lines} lines")
    print(f"Original: {original_lines} lines, New: {new_lines} lines")


if __name__ == "__main__":
    main()
