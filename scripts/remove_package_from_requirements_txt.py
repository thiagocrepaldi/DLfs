from distutils.core import run_setup
import argparse

parser = argparse.ArgumentParser()
parser.add_argument("requirements", help="requirements.txt file  to be parsed")
parser.add_argument("--no-onnx", action="store_true", help="When True, remore onnx from output")
parser.add_argument("--no-onnxruntime", action="store_true", help="When True, remore onnxruntime from output")
parser.add_argument("--no-protobuf", action="store_true", help="When True, remore protobuf from output")
parser.add_argument("--no-torch", action="store_true", help="When True, remore pytorch from output")
parser.add_argument("--no-torchvision", action="store_true", help="When True, remore torchvision from output")

args = parser.parse_args()

def remove_package(target, pkgs):
    result = []
    for pkg in pkgs:
        if (pkg == target or
            pkg.startswith(target+"=") or
            pkg.startswith(target+">") or
            pkg.startswith(target+"<")):
            continue
        result.append(pkg)
    return result

with open(args.requirements) as file:
    lines = [line.rstrip() for line in file]

with open(args.requirements, mode="w") as file:
    if args.no_onnx:
        lines = remove_package("onnx", lines)
        lines = remove_package("onnx-weekly", lines)
    if args.no_onnxruntime:
        lines = remove_package("onnxruntime", lines)
        lines = remove_package("onnxruntime_training", lines)
    if args.no_protobuf:
        lines = remove_package("protobuf", lines)
    if args.no_torch:
        lines = remove_package("torch", lines)
    if args.no_torchvision:
        lines = remove_package("torchvision", lines)
    file.write('\n'.join(lines))
    file.write('\n')