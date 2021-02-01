import json
from pathlib import Path

BASEPATH = Path('..')
REPOSITORIES = ["core", "multilib", "nonfree", "testing"]

def read_spkgbuild(filepath):
    result = {}
    with filepath.open() as lines:
        for line in lines:
            key, eq, value = line.strip().partition('=')
            if eq and key in ['name', 'version']:
                result[key] = value
    return result

def main():
    packages = []
    for repository in REPOSITORIES:
        print(repository)
        for filepath in (BASEPATH / repository).glob('*/spkgbuild'):
            info = read_spkgbuild(filepath)
            info["repo"] = repository
            packages.append(info)

    with open('packages.json', 'w') as outfile:
        json.dump(packages, outfile)

if __name__ == "__main__":
    main()