#!/usr/bin/env python3
"""Deterministic native Xcode project, using only Python's standard library.

The generated project is checked in. Regenerate only when changing target layout.
"""
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
objects = {}


def oid(name):
    return hashlib.sha256(name.encode()).hexdigest()[:24].upper()


def obj(key_name, isa, **fields):
    key = oid(key_name)
    objects[key] = {"isa": isa, **fields}
    return key


def file(path, kind):
    return obj(path, "PBXFileReference", lastKnownFileType=kind, path=path, sourceTree="<group>")


configs = {mode: file(f"Configurations/{mode}.xcconfig", "text.xcconfig") for mode in ["Debug", "Release"]}
plist = file("Configurations/com.antonioruffolo.MacPowerScheduler.helper.plist", "text.plist.xml")
package = obj("package", "XCLocalSwiftPackageReference", relativePath="Package")
targets = []
products = []
sources = []
specs = [
    ("Helper", "MacPowerSchedulerHelper", "Helper/main.swift", "PowerScheduleService", "com.apple.product-type.tool", "com.antonioruffolo.MacPowerScheduler.helper"),
    ("CLI", "powerschedulectl", "CLI/main.swift", "PowerScheduleCLI", "com.apple.product-type.tool", "com.antonioruffolo.MacPowerScheduler.cli"),
    ("MacPowerScheduler", "MacPowerScheduler", "App/MacPowerSchedulerApp.swift", "PowerScheduleUI", "com.apple.product-type.application", "com.antonioruffolo.MacPowerScheduler"),
]
for name, product, source, library, product_type, bundle in specs:
    is_app = product_type.endswith("application")
    source_ref = file(source, "sourcecode.swift")
    sources.append(source_ref)
    extension = ".app" if is_app else ""
    product_ref = obj(name + "product", "PBXFileReference", explicitFileType="wrapper.application" if is_app else "compiled.mach-o.executable", path=product + extension, sourceTree="BUILT_PRODUCTS_DIR")
    products.append(product_ref)
    source_build = obj(name + "sourcebuild", "PBXBuildFile", fileRef=source_ref)
    phases = [obj(name + "sources", "PBXSourcesBuildPhase", buildActionMask="2147483647", files=[source_build], runOnlyForDeploymentPostprocessing="0")]
    libraries = []
    framework_files = []
    if library:
        dep = obj(name + "lib", "XCSwiftPackageProductDependency", package=package, productName=library)
        libraries.append(dep)
        framework_files.append(obj(name + "frameworkbuild", "PBXBuildFile", productRef=dep))
    phases.append(obj(name + "frameworks", "PBXFrameworksBuildPhase", buildActionMask="2147483647", files=framework_files, runOnlyForDeploymentPostprocessing="0"))
    dependencies = []
    if is_app:
        phases.insert(0, obj("swiftlint", "PBXShellScriptBuildPhase", buildActionMask="2147483647", files=[], inputPaths=[], outputPaths=[], name="SwiftLint", shellPath="/bin/bash", shellScript='set -euo pipefail\nbash "$SRCROOT/Tools/lint.sh"\n', alwaysOutOfDate="1", runOnlyForDeploymentPostprocessing="0"))
        asset_ref = file("App/AppIcon.icon", "folder.iconcomposer.icon")
        sources.append(asset_ref)
        asset_build = obj("assetbuild", "PBXBuildFile", fileRef=asset_ref)
        phases.append(obj("resources", "PBXResourcesBuildPhase", buildActionMask="2147483647", files=[asset_build], runOnlyForDeploymentPostprocessing="0"))
        for dep_name in ["Helper", "CLI"]:
            proxy = obj(dep_name + "proxy", "PBXContainerItemProxy", containerPortal=oid("project"), proxyType="1", remoteGlobalIDString=oid(dep_name + "target"), remoteInfo=dep_name)
            dependencies.append(obj(dep_name + "targetdep", "PBXTargetDependency", target=oid(dep_name + "target"), targetProxy=proxy))
        embedded = [obj(n + "embed", "PBXBuildFile", fileRef=oid(n + "product"), settings={"ATTRIBUTES": ["CodeSignOnCopy"]}) for n in ["Helper", "CLI"]]
        phases.append(obj("embedtools", "PBXCopyFilesBuildPhase", buildActionMask="2147483647", dstPath="", dstSubfolderSpec="6", files=embedded, name="Embed Helper and CLI", runOnlyForDeploymentPostprocessing="0"))
        plist_build = obj("plistbuild", "PBXBuildFile", fileRef=plist)
        phases.append(obj("embedplist", "PBXCopyFilesBuildPhase", buildActionMask="2147483647", dstPath="Contents/Library/LaunchDaemons", dstSubfolderSpec="1", files=[plist_build], name="Embed LaunchDaemon", runOnlyForDeploymentPostprocessing="0"))
    target_configs = []
    for mode in ["Debug", "Release"]:
        settings = {"PRODUCT_NAME": product, "PRODUCT_BUNDLE_IDENTIFIER": bundle, "GENERATE_INFOPLIST_FILE": "YES", "ENABLE_DEBUG_DYLIB": "NO"}
        if is_app:
            settings.update({"ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon", "INFOPLIST_KEY_CFBundleDisplayName": "MacPowerScheduler", "INFOPLIST_KEY_LSApplicationCategoryType": "public.app-category.utilities", "INFOPLIST_KEY_NSPrincipalClass": "NSApplication", "LD_RUNPATH_SEARCH_PATHS": ["$(inherited)", "@executable_path/../Frameworks"]})
        else:
            settings.update({"CREATE_INFOPLIST_SECTION_IN_BINARY": "YES", "SKIP_INSTALL": "YES", "LD_RUNPATH_SEARCH_PATHS": ["$(inherited)", "@executable_path/../Frameworks"]})
        target_configs.append(obj(name + mode, "XCBuildConfiguration", baseConfigurationReference=configs[mode], buildSettings=settings, name=mode))
    config_list = obj(name + "configlist", "XCConfigurationList", buildConfigurations=target_configs, defaultConfigurationIsVisible="0", defaultConfigurationName="Release")
    targets.append(obj(name + "target", "PBXNativeTarget", buildConfigurationList=config_list, buildPhases=phases, buildRules=[], dependencies=dependencies, name=name, packageProductDependencies=libraries, productName=product, productReference=product_ref, productType=product_type))

product_group = obj("products", "PBXGroup", children=products, name="Products", sourceTree="<group>")
main_group = obj("main", "PBXGroup", children=sources + list(configs.values()) + [plist, product_group], sourceTree="<group>")
project_configs = [obj("project" + mode, "XCBuildConfiguration", buildSettings={}, name=mode) for mode in ["Debug", "Release"]]
project_list = obj("projectconfigs", "XCConfigurationList", buildConfigurations=project_configs, defaultConfigurationIsVisible="0", defaultConfigurationName="Release")
project = obj("project", "PBXProject", attributes={"LastUpgradeCheck": "2630", "BuildIndependentTargetsInParallel": "YES"}, buildConfigurationList=project_list, compatibilityVersion="Xcode 14.0", developmentRegion="en", hasScannedForEncodings="0", knownRegions=["en", "Base"], mainGroup=main_group, packageReferences=[package], productRefGroup=product_group, projectDirPath="", projectRoot="", targets=targets)


def encode(value, depth=0):
    indent = "\t" * depth
    if isinstance(value, dict):
        return "{\n" + "".join("\t" * (depth + 1) + json.dumps(k) + " = " + encode(v, depth + 1) + ";\n" for k, v in value.items()) + indent + "}"
    if isinstance(value, list):
        return "(\n" + "".join("\t" * (depth + 1) + encode(v, depth + 1) + ",\n" for v in value) + indent + ")"
    return json.dumps(str(value))


project_dir = ROOT / "MacPowerScheduler.xcodeproj"
project_dir.mkdir(exist_ok=True)
(project_dir / "project.pbxproj").write_text("// !$*UTF8*$!\n" + encode({"archiveVersion": "1", "classes": {}, "objectVersion": "56", "objects": objects, "rootObject": project}) + "\n")
workspace = ROOT / "MacPowerScheduler.xcworkspace"
workspace.mkdir(exist_ok=True)
(workspace / "contents.xcworkspacedata").write_text('<?xml version="1.0" encoding="UTF-8"?><Workspace version="1.0"><FileRef location="group:MacPowerScheduler.xcodeproj"/></Workspace>\n')
schemes = project_dir / "xcshareddata/xcschemes"
schemes.mkdir(parents=True, exist_ok=True)


def reference(name, filename):
    return f'<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{oid(name + "target")}" BuildableName="{filename}" BlueprintName="{name}" ReferencedContainer="container:MacPowerScheduler.xcodeproj"/>'


app_ref = reference("MacPowerScheduler", "MacPowerScheduler.app")
(schemes / "MacPowerScheduler.xcscheme").write_text(f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="2630" version="1.3">
 <BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries>
 <BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">{app_ref}</BuildActionEntry>
 </BuildActionEntries></BuildAction>
 <LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugServiceExtension="internal" allowLocationSimulation="NO"><BuildableProductRunnable runnableDebuggingMode="0">{app_ref}</BuildableProductRunnable></LaunchAction>
 <ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO"><BuildableProductRunnable runnableDebuggingMode="0">{app_ref}</BuildableProductRunnable></ProfileAction>
 <AnalyzeAction buildConfiguration="Debug"/>
 <ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
</Scheme>
''')
print("Generated MacPowerScheduler workspace and project.")
