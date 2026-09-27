#!/usr/bin/env python3
"""Use LLVM for scoped reports; enforce coverage and retain reusable inputs."""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / "Package/Sources"


def load_scope(path, source):
    scope = json.loads(path.read_text())
    unit = scope["unit"]
    integration = scope["integration"]
    if len(unit) != len(set(unit)) or set(unit) & set(integration):
        raise ValueError("Duplicate or overlapping coverage classification")
    actual = {str(p.relative_to(source)) for p in source.rglob("*.swift")}
    classified = set(unit) | set(integration)
    if actual != classified:
        raise ValueError(f"Coverage scope mismatch: unclassified={sorted(actual - classified)}, missing={sorted(classified - actual)}")
    if not unit or not all(isinstance(reason, str) and reason.strip() for reason in integration.values()):
        raise ValueError("Empty unit scope or missing integration rationale")
    threshold = scope["minimumLinePercent"]
    if isinstance(threshold, bool) or not isinstance(threshold, (int, float)) or not 0 < threshold <= 100:
        raise ValueError("Invalid coverage threshold")
    return scope


def read_metrics(export, source, expected):
    document = json.loads(export.read_text())
    if document.get("type") != "llvm.coverage.json.export":
        raise ValueError("Expected LLVM coverage export")
    metrics = {}
    source = source.resolve()
    for dataset in document["data"]:
        for item in dataset["files"]:
            try:
                relative = str(Path(item["filename"]).resolve().relative_to(source))
            except ValueError:
                continue
            if relative in metrics:
                raise ValueError(f"Duplicate coverage entry: {relative}")
            line = item["summary"]["lines"]
            count, covered = line["count"], line["covered"]
            if any(isinstance(v, bool) or not isinstance(v, int) for v in (count, covered)) or not 0 <= covered <= count:
                raise ValueError(f"Invalid line counters: {relative}")
            metrics[relative] = {"covered": covered, "count": count}
    if set(metrics) != set(expected):
        raise ValueError(f"Coverage export mismatch: absent={sorted(set(expected) - set(metrics))}, extra={sorted(set(metrics) - set(expected))}")
    return metrics


def aggregate(metrics):
    metrics = list(metrics)
    covered = sum(item["covered"] for item in metrics)
    count = sum(item["count"] for item in metrics)
    if count == 0:
        raise ValueError("No executable lines measured")
    return {"covered": covered, "count": count, "percent": covered * 100 / count}


def report(scope, metrics):
    total = aggregate(metrics[path] for path in scope["unit"])
    modules = {}
    for module in sorted({path.split("/")[0] for path in scope["unit"]}):
        modules[module] = aggregate(metrics[path] for path in scope["unit"] if path.startswith(module + "/"))
    return {
        "unit": total,
        "wholePackageUnitRun": aggregate(metrics.values()),
        "modules": modules,
        "files": metrics,
        "scope": scope,
        "passed": total["covered"] * 100 >= scope["minimumLinePercent"] * total["count"],
    }


def markdown(result):
    lines = ["# Unit coverage", ""]
    if "reused" in result:
        mode = "Re-rendered saved measurement; tests were not rerun" if result["reused"] else "Fresh unit-test measurement"
        lines += [f"{mode}. Inputs: `{result['inputDirectory']}`.", ""]
    lines += ["| Scope | Covered / executable lines | Coverage |", "|---|---:|---:|"]
    for name, value in [("Unit scope", result["unit"]), *result["modules"].items(), ("Whole package (unit run only)", result["wholePackageUnitRun"])]:
        lines.append(f"| {name} | {value['covered']} / {value['count']} | {value['percent']:.2f}% |")
    lines += ["", "## Files", "", "| File | Kind | Covered / executable lines |", "|---|---|---:|"]
    for name, value in sorted(result["files"].items()):
        kind = "unit" if name in result["scope"]["unit"] else "integration/UI"
        lines.append(f"| {name} | {kind} | {value['covered']} / {value['count']} |")
    lines += ["", "## Integration/UI exclusions", ""]
    lines += [f"- `{name}`: {reason}" for name, reason in sorted(result["scope"]["integration"].items())]
    return "\n".join(lines) + "\n"


def source_hashes():
    paths = [ROOT / "Package/Package.swift"]
    paths += sorted(SOURCE.rglob("*.swift"))
    paths += sorted((ROOT / "Package/Tests").rglob("*.swift"))
    return {str(path.relative_to(ROOT)): digest(path) for path in paths}


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def retain_inputs(scratch, run):
    profiles = list(scratch.glob("*/debug/codecov/default.profdata"))
    binaries = list(scratch.glob("*/debug/MacPowerSchedulerPackageTests.xctest/Contents/MacOS/MacPowerSchedulerPackageTests"))
    if len(profiles) != 1 or len(binaries) != 1:
        raise ValueError("Expected one matching SwiftPM coverage binary/profile pair")
    files = {"binary": "tests-binary", "profile": "default.profdata"}
    for key, source in [("binary", binaries[0]), ("profile", profiles[0])]:
        shutil.copy2(source, run / files[key])
    inputs = {**files, "sourceHashes": source_hashes(),
              "artifactHashes": {name: digest(run / name) for name in files.values()}}
    (run / "inputs.json").write_text(json.dumps(inputs, indent=2) + "\n")


def verify_inputs(run):
    inputs = json.loads((run / "inputs.json").read_text())
    if inputs["sourceHashes"] != source_hashes():
        raise ValueError("Package sources/tests changed since measurement; run make test-coverage")
    for key in ("binary", "profile"):
        name = inputs[key]
        if Path(name).name != name or digest(run / name) != inputs["artifactHashes"][name]:
            raise ValueError(f"Coverage input changed: {key}")
    return inputs


def llvm_reports(scope, inputs_run, run):
    inputs = verify_inputs(inputs_run)
    common = [str(inputs_run / inputs["binary"]), f"-instr-profile={inputs_run / inputs['profile']}"]
    unit_sources = [str(SOURCE / name) for name in scope["unit"]]
    all_sources = unit_sources + [str(SOURCE / name) for name in scope["integration"]]
    with (run / "llvm.log").open("w") as log:
        for name, sources in [("unit", unit_sources), ("package", all_sources)]:
            command = ["xcrun", "llvm-cov", "export", *common, "--sources", *sources]
            with (run / f"{name}.json").open("w") as output:
                subprocess.run(command, check=True, stdout=output, stderr=log, cwd=ROOT)
        with (run / "unit.txt").open("w") as output:
            subprocess.run(["xcrun", "llvm-cov", "report", *common, "--sources", *unit_sources],
                           check=True, stdout=output, stderr=log, cwd=ROOT)
        subprocess.run(["xcrun", "llvm-cov", "show", *common, "-format=html",
                        f"-output-dir={run / 'html'}", "-project-title=MacPowerScheduler unit coverage",
                        "--sources", *unit_sources], check=True, stdout=log, stderr=log, cwd=ROOT)
    verify_inputs(inputs_run)
    unit = read_metrics(run / "unit.json", SOURCE, scope["unit"])
    all_metrics = read_metrics(run / "package.json", SOURCE, set(scope["unit"]) | set(scope["integration"]))
    if any(unit[name] != all_metrics[name] for name in unit):
        raise ValueError("Scoped and package exports disagree")
    result = report(scope, all_metrics)
    # The threshold must agree with LLVM's own filtered total, not a custom scope calculation.
    native = json.loads((run / "unit.json").read_text())["data"][0]["totals"]["lines"]
    if any(native[key] != result["unit"][key] for key in ("count", "covered")):
        raise ValueError("LLVM total disagrees with classified files")
    result["unit"] = {key: native[key] for key in ("covered", "count", "percent")}
    result["inputDirectory"] = str(inputs_run.relative_to(ROOT))
    return result


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--reuse", metavar="RUN", help="Re-render saved inputs without tests; RUN may be 'latest'")
    args = parser.parse_args(argv)
    output = ROOT / ".build/Coverage"
    output.mkdir(parents=True, exist_ok=True)
    # Retain evidence, but dispose of the large build tree after this run.
    run = Path(tempfile.mkdtemp(prefix="unit-", dir=output))
    try:
        scope = load_scope(ROOT / "Tools/unit-coverage-scope.json", SOURCE)
        if args.reuse:
            inputs_run = (ROOT / json.loads((output / "latest.json").read_text())["inputDirectory"]
                          if args.reuse == "latest" else Path(args.reuse).resolve())
            result = llvm_reports(scope, inputs_run, run)
            result["reused"] = True
        else:
            initial_hashes = source_hashes()
            with tempfile.TemporaryDirectory(prefix="build-", dir=run) as scratch:
                measure(scope, run, Path(scratch))
                if initial_hashes != source_hashes():
                    raise ValueError("Package sources/tests changed during measurement")
                retain_inputs(Path(scratch), run)
                result = llvm_reports(scope, run, run)
            result["reused"] = False
    except (subprocess.CalledProcessError, ValueError, OSError, KeyError) as error:
        failure = {"passed": False, "status": "failed", "runDirectory": str(run.relative_to(ROOT)), "error": str(error)}
        (output / "latest.json").write_text(json.dumps(failure, indent=2) + "\n")
        (output / "latest.md").write_text("# Unit coverage\n\nRun failed; no passing coverage result. See latest.json for the error and tests.log/llvm.log if started.\n")
        raise
    result["runDirectory"] = str(run.relative_to(ROOT))
    (run / "summary.json").write_text(json.dumps(result, indent=2) + "\n")
    (run / "summary.md").write_text(markdown(result))
    (output / "latest.json").write_text(json.dumps(result, indent=2) + "\n")
    (output / "latest.md").write_text(markdown(result) + f"\n[LLVM HTML report]({run.name}/html/index.html)\n")
    print((run / "unit.txt").read_text())
    print(f"HTML: {run / 'html/index.html'}\nReused measurement: {result['reused']}")
    if not result["passed"]:
        raise SystemExit(f"Unit coverage is below {scope['minimumLinePercent']}%")


def measure(scope, run, scratch):
    # Fresh scratch paths prevent previous integration runs or stale profiles from inflating the result.
    command = ["swift", "test", "--package-path", str(ROOT / "Package"), "--scratch-path", str(scratch),
               "--enable-code-coverage", "--skip", "PowerSchedule(Adapter|Snapshot)Tests"]
    with (run / "tests.log").open("w") as log:
        subprocess.run(command, check=True, cwd=ROOT, stdout=log, stderr=subprocess.STDOUT)
    exports = list(scratch.glob("*/debug/codecov/MacPowerScheduler.json"))
    if len(exports) != 1:
        raise ValueError(f"Expected one fresh coverage export, found {len(exports)}")
    read_metrics(exports[0], SOURCE, set(scope["unit"]) | set(scope["integration"]))
    (run / "coverage.json").write_bytes(exports[0].read_bytes())


if __name__ == "__main__":
    main()
