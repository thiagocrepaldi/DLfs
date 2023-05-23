import parsesetup
import argparse

def parse_setup_py(setup_file):
    return parsesetup.parse_setup(setup_file, trusted=True)

def remove_torch(pkgs):
    result = []
    for pkg in pkgs:
        if pkg == "torch" or pkg.startswith("torch=") or pkg.startswith("torch>") or pkg.startswith("torch<"):
            continue
        result.append(pkg)
    return result

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("setup", help="setup.py to be parsed")
    parser.add_argument("filename", help="Save requirements file at the specified fully qualified path")
    parser.add_argument("--include-extras", action="store_true", help="When True, extras_require is included in the output")
    parser.add_argument("--no-torch", action="store_true", help="When True, remore pytorch from output")
    args = parser.parse_args()

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("setup", help="setup.py to be parsed")
    parser.add_argument("filename", help="Save requirements file at the specified fully qualified path")
    parser.add_argument("--include-extras", action="store_true", help="When True, extras_require is included in the output")
    parser.add_argument("--no-torch", action="store_true", help="When True, remore pytorch from output")
    args = parser.parse_args()

    with open(args.filename, mode="w") as file:
        result = parse_setup_py(args.setup)
        requires = result["install_requires"] if "install_requires" in result.keys() else []
        if args.no_torch:
            requires = remove_torch(requires)

        file.write('\n'.join(requires))
        file.write('\n')
        if args.include_extras and "extras_require" in result.keys():
            extras = []
            for _, v in result["extras_require"].items():
                extras += v
            if args.no_torch:
                extras = remove_torch(extras)
            file.write('\n'.join(extras))
            file.write('\n')

if __name__ == "__main__":
    main()