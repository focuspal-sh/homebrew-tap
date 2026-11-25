#!/usr/bin/env python3
"""
Updates Homebrew Formula version, tarball release URL, and SHA-256 checksum.
Used during automated releases in GitHub Actions.
"""

import os
import re
import sys


def main():
    if len(sys.argv) < 2:
        print("Usage: update-formula.py <formula_path>")
        sys.exit(1)

    formula_path = sys.argv[1]
    version = os.environ.get("VERSION")
    tag_name = os.environ.get("TAG_NAME")
    tarball = os.environ.get("TARBALL")
    sha256 = os.environ.get("SHA256")

    if not os.path.exists(formula_path):
        print(f"Skipping: {formula_path} does not exist")
        return

    with open(formula_path, "r", encoding="utf-8") as f:
        content = f.read()

    if version:
        content = re.sub(r'version \".*?\"', f'version "{version}"', content)

    if tag_name and tarball:
        content = re.sub(
            r'releases/download/.*?/(focuspal|focus-guardian|lockin)-v.*?-arm64\.tar\.gz',
            f'releases/download/{tag_name}/{tarball}',
            content,
        )

    if sha256:
        content = re.sub(r'sha256 \".*?\"', f'sha256 "{sha256}"', content)

    with open(formula_path, "w", encoding="utf-8") as f:
        f.write(content)

    print(f"✅ Successfully updated {formula_path}: version={version}, sha256={sha256}")


if __name__ == "__main__":
    main()

