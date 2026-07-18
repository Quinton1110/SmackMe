#!/usr/bin/env python3
"""Generate SmackMeRebuild.xcodeproj/project.pbxproj"""

import os
import uuid

def gen_id():
    return uuid.uuid4().hex.upper()[:24]

PROJECT_DIR = "/Users/quinton/code/SmackMe/SmackMeRebuild"
SOURCE_DIR  = os.path.join(PROJECT_DIR, "SmackMeRebuild")

# ── Collect files ─────────────────────────────────────────────────────────────
SWIFT_FILES = [
    ("AppDelegate.swift",                       "AppDelegate.swift"),
    ("SceneDelegate.swift",                     "SceneDelegate.swift"),
    ("Controllers/MainMenuViewController.swift","MainMenuViewController.swift"),
    ("Controllers/GameViewController.swift",    "GameViewController.swift"),
    ("Models/GameModels.swift",                 "GameModels.swift"),
    ("Models/GameEngine.swift",                 "GameEngine.swift"),
    ("Utilities/GestureManager.swift",          "GestureManager.swift"),
    ("Utilities/AudioManager.swift",            "AudioManager.swift"),
]

images_dir  = os.path.join(SOURCE_DIR, "Images")
sounds_dir  = os.path.join(SOURCE_DIR, "Sounds")

image_files = sorted(f for f in os.listdir(images_dir) if f.lower().endswith(".png"))
sound_files = sorted(f for f in os.listdir(sounds_dir) if not f.lower().endswith(".ttf"))
font_files  = sorted(f for f in os.listdir(sounds_dir) if f.lower().endswith(".ttf"))

def safe_key(s):
    for c in ".&- ()[]":
        s = s.replace(c, "_")
    return s

# ── Generate IDs ──────────────────────────────────────────────────────────────
I = {}
for name in [
    "project","main_group","products_group","source_group",
    "controllers_group","models_group","utilities_group",
    "images_group","sounds_group",
    "target","app_product",
    "sources_phase","resources_phase","frameworks_phase",
    "proj_config_list","target_config_list",
    "proj_debug","proj_release","target_debug","target_release",
    "info_plist_ref","assets_catalog_ref","assets_catalog_build",
    "launchscreen_ref","launchscreen_build",
]:
    I[name] = gen_id()

for path, _ in SWIFT_FILES:
    k = safe_key(path)
    I[f"ref_{k}"]   = gen_id()
    I[f"build_{k}"] = gen_id()

for fname in image_files:
    k = safe_key(f"img_{fname}")
    I[f"ref_{k}"]   = gen_id()
    I[f"build_{k}"] = gen_id()

for fname in sound_files:
    k = safe_key(f"snd_{fname}")
    I[f"ref_{k}"]   = gen_id()
    I[f"build_{k}"] = gen_id()

for fname in font_files:
    k = safe_key(f"fnt_{fname}")
    I[f"ref_{k}"]   = gen_id()
    I[f"build_{k}"] = gen_id()

# ── pbxproj helpers ───────────────────────────────────────────────────────────
def q(s):
    """Quote if the string contains characters that need quoting in pbxproj"""
    if any(c in s for c in ' &()[]+-=,;@#$%^*!?<>|\\`~\'"'):
        return f'"{s}"'
    return s

def file_type(fname):
    ext = fname.rsplit(".", 1)[-1].lower() if "." in fname else ""
    return {
        "swift":    "sourcecode.swift",
        "png":      "image.png",
        "jpg":      "image.jpeg",
        "wav":      "audio.wav",
        "mp3":      "audio.mpeg",
        "m4a":      "audio.m4a",
        "ttf":      "file",
        "plist":    "text.plist.xml",
        "xcassets": "folder.assetcatalog",
        "storyboard": "file.storyboard",
        "xib":      "file.xib",
    }.get(ext, "file")

# ── Build the .pbxproj content ────────────────────────────────────────────────
L = []
def W(*args): L.extend(args)

W("// !$*UTF8*$!",
  "{",
  "\tarchiveVersion = 1;",
  "\tclasses = {",
  "\t};",
  "\tobjectVersion = 56;",
  "\tobjects = {",
  "")

# ── PBXBuildFile ──────────────────────────────────────────────────────────────
W("/* Begin PBXBuildFile section */")

# Swift
for path, name in SWIFT_FILES:
    k = safe_key(path)
    W(f"\t\t{I[f'build_{k}']} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {I[f'ref_{k}']} /* {name} */; }};")

# Assets catalog
W(f"\t\t{I['assets_catalog_build']} /* Assets.xcassets in Resources */ = {{isa = PBXBuildFile; fileRef = {I['assets_catalog_ref']} /* Assets.xcassets */; }};")

# Images
for fname in image_files:
    k = safe_key(f"img_{fname}")
    W(f"\t\t{I[f'build_{k}']} /* {fname} in Resources */ = {{isa = PBXBuildFile; fileRef = {I[f'ref_{k}']} /* {fname} */; }};")

# Sounds
for fname in sound_files:
    k = safe_key(f"snd_{fname}")
    W(f"\t\t{I[f'build_{k}']} /* {fname} in Resources */ = {{isa = PBXBuildFile; fileRef = {I[f'ref_{k}']} /* {fname} */; }};")

# Fonts
for fname in font_files:
    k = safe_key(f"fnt_{fname}")
    W(f"\t\t{I[f'build_{k}']} /* {fname} in Resources */ = {{isa = PBXBuildFile; fileRef = {I[f'ref_{k}']} /* {fname} */; }};")

W("/* End PBXBuildFile section */", "")

# ── PBXFileReference ──────────────────────────────────────────────────────────
W("/* Begin PBXFileReference section */")

# Product app
W(f"\t\t{I['app_product']} /* SmackMeRebuild.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = SmackMeRebuild.app; sourceTree = BUILT_PRODUCTS_DIR; }};")

# Info.plist
W(f"\t\t{I['info_plist_ref']} /* Info.plist */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = \"<group>\"; }};")

# Assets catalog
W(f"\t\t{I['assets_catalog_ref']} /* Assets.xcassets */ = {{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Assets.xcassets; sourceTree = \"<group>\"; }};")

# Swift
for path, name in SWIFT_FILES:
    k  = safe_key(path)
    ft = file_type(name)
    # path relative to the SmackMeRebuild source group
    W(f"\t\t{I[f'ref_{k}']} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = {ft}; path = {q(name)}; sourceTree = \"<group>\"; }};")

# Images (path is relative to Images group which has path=Images)
for fname in image_files:
    k = safe_key(f"img_{fname}")
    W(f"\t\t{I[f'ref_{k}']} /* {fname} */ = {{isa = PBXFileReference; lastKnownFileType = image.png; path = {q(fname)}; sourceTree = \"<group>\"; }};")

# Sounds (path is relative to Sounds group which has path=Sounds)
for fname in sound_files:
    k  = safe_key(f"snd_{fname}")
    ft = file_type(fname)
    W(f"\t\t{I[f'ref_{k}']} /* {fname} */ = {{isa = PBXFileReference; lastKnownFileType = {ft}; path = {q(fname)}; sourceTree = \"<group>\"; }};")

# Fonts (path is relative to Sounds group which has path=Sounds)
for fname in font_files:
    k = safe_key(f"fnt_{fname}")
    W(f"\t\t{I[f'ref_{k}']} /* {fname} */ = {{isa = PBXFileReference; lastKnownFileType = file; path = {q(fname)}; sourceTree = \"<group>\"; }};")

W("/* End PBXFileReference section */", "")

# ── PBXFrameworksBuildPhase ───────────────────────────────────────────────────
W("/* Begin PBXFrameworksBuildPhase section */",
  f"\t\t{I['frameworks_phase']} /* Frameworks */ = {{",
  "\t\t\tisa = PBXFrameworksBuildPhase;",
  "\t\t\tbuildActionMask = 2147483647;",
  "\t\t\tfiles = (",
  "\t\t\t);",
  "\t\t\trunOnlyForDeploymentPostprocessing = 0;",
  "\t\t};",
  "/* End PBXFrameworksBuildPhase section */", "")

# ── PBXGroup ─────────────────────────────────────────────────────────────────
W("/* Begin PBXGroup section */")

# Main (root) group
W(f"\t\t{I['main_group']} = {{",
  "\t\t\tisa = PBXGroup;",
  "\t\t\tchildren = (",
  f"\t\t\t\t{I['source_group']} /* SmackMeRebuild */,",
  f"\t\t\t\t{I['products_group']} /* Products */,",
  "\t\t\t);",
  "\t\t\tsourceTree = \"<group>\";",
  "\t\t};")

# Products group
W(f"\t\t{I['products_group']} /* Products */ = {{",
  "\t\t\tisa = PBXGroup;",
  "\t\t\tchildren = (",
  f"\t\t\t\t{I['app_product']} /* SmackMeRebuild.app */,",
  "\t\t\t);",
  "\t\t\tname = Products;",
  "\t\t\tsourceTree = \"<group>\";",
  "\t\t};")

# Source group (SmackMeRebuild/)
_appdelegate_ref = I[f'ref_{safe_key("AppDelegate.swift")}']
_scenedelegate_ref = I[f'ref_{safe_key("SceneDelegate.swift")}']
W(f"\t\t{I['source_group']} /* SmackMeRebuild */ = {{",
  "\t\t\tisa = PBXGroup;",
  "\t\t\tchildren = (",
  f"\t\t\t\t{_appdelegate_ref} /* AppDelegate.swift */,",
  f"\t\t\t\t{_scenedelegate_ref} /* SceneDelegate.swift */,",
  f"\t\t\t\t{I['info_plist_ref']} /* Info.plist */,",
  f"\t\t\t\t{I['assets_catalog_ref']} /* Assets.xcassets */,",
  f"\t\t\t\t{I['controllers_group']} /* Controllers */,",
  f"\t\t\t\t{I['models_group']} /* Models */,",
  f"\t\t\t\t{I['utilities_group']} /* Utilities */,",
  f"\t\t\t\t{I['images_group']} /* Images */,",
  f"\t\t\t\t{I['sounds_group']} /* Sounds */,",
  "\t\t\t);",
  "\t\t\tname = SmackMeRebuild;",
  "\t\t\tpath = SmackMeRebuild;",
  "\t\t\tsourceTree = \"<group>\";",
  "\t\t};")

# Controllers group
ctrl_refs = [safe_key(p) for p, _ in SWIFT_FILES if p.startswith("Controllers/")]
W(f"\t\t{I['controllers_group']} /* Controllers */ = {{",
  "\t\t\tisa = PBXGroup;",
  "\t\t\tchildren = (")
for path, name in SWIFT_FILES:
    if path.startswith("Controllers/"):
        k = safe_key(path)
        W(f"\t\t\t\t{I[f'ref_{k}']} /* {name} */,")
W("\t\t\t);",
  "\t\t\tpath = Controllers;",
  "\t\t\tsourceTree = \"<group>\";",
  "\t\t};")

# Models group
W(f"\t\t{I['models_group']} /* Models */ = {{",
  "\t\t\tisa = PBXGroup;",
  "\t\t\tchildren = (")
for path, name in SWIFT_FILES:
    if path.startswith("Models/"):
        k = safe_key(path)
        W(f"\t\t\t\t{I[f'ref_{k}']} /* {name} */,")
W("\t\t\t);",
  "\t\t\tpath = Models;",
  "\t\t\tsourceTree = \"<group>\";",
  "\t\t};")

# Utilities group
W(f"\t\t{I['utilities_group']} /* Utilities */ = {{",
  "\t\t\tisa = PBXGroup;",
  "\t\t\tchildren = (")
for path, name in SWIFT_FILES:
    if path.startswith("Utilities/"):
        k = safe_key(path)
        W(f"\t\t\t\t{I[f'ref_{k}']} /* {name} */,")
W("\t\t\t);",
  "\t\t\tpath = Utilities;",
  "\t\t\tsourceTree = \"<group>\";",
  "\t\t};")

# Images group
W(f"\t\t{I['images_group']} /* Images */ = {{",
  "\t\t\tisa = PBXGroup;",
  "\t\t\tchildren = (")
for fname in image_files:
    k = safe_key(f"img_{fname}")
    W(f"\t\t\t\t{I[f'ref_{k}']} /* {fname} */,")
W("\t\t\t);",
  "\t\t\tpath = Images;",
  "\t\t\tsourceTree = \"<group>\";",
  "\t\t};")

# Sounds group (includes font)
W(f"\t\t{I['sounds_group']} /* Sounds */ = {{",
  "\t\t\tisa = PBXGroup;",
  "\t\t\tchildren = (")
for fname in sound_files:
    k = safe_key(f"snd_{fname}")
    W(f"\t\t\t\t{I[f'ref_{k}']} /* {fname} */,")
for fname in font_files:
    k = safe_key(f"fnt_{fname}")
    W(f"\t\t\t\t{I[f'ref_{k}']} /* {fname} */,")
W("\t\t\t);",
  "\t\t\tpath = Sounds;",
  "\t\t\tsourceTree = \"<group>\";",
  "\t\t};")

W("/* End PBXGroup section */", "")

# ── PBXNativeTarget ───────────────────────────────────────────────────────────
W("/* Begin PBXNativeTarget section */",
  f"\t\t{I['target']} /* SmackMeRebuild */ = {{",
  "\t\t\tisa = PBXNativeTarget;",
  f"\t\t\tbuildConfigurationList = {I['target_config_list']} /* Build configuration list for PBXNativeTarget \"SmackMeRebuild\" */;",
  "\t\t\tbuildPhases = (",
  f"\t\t\t\t{I['sources_phase']} /* Sources */,",
  f"\t\t\t\t{I['resources_phase']} /* Resources */,",
  f"\t\t\t\t{I['frameworks_phase']} /* Frameworks */,",
  "\t\t\t);",
  "\t\t\tbuildRules = (",
  "\t\t\t);",
  "\t\t\tdependencies = (",
  "\t\t\t);",
  "\t\t\tname = SmackMeRebuild;",
  "\t\t\tproductName = SmackMeRebuild;",
  f"\t\t\tproductReference = {I['app_product']} /* SmackMeRebuild.app */;",
  "\t\t\tproductType = \"com.apple.product-type.application\";",
  "\t\t};",
  "/* End PBXNativeTarget section */", "")

# ── PBXProject ────────────────────────────────────────────────────────────────
W("/* Begin PBXProject section */",
  f"\t\t{I['project']} /* Project object */ = {{",
  "\t\t\tisa = PBXProject;",
  "\t\t\tattributes = {",
  "\t\t\t\tBuildIndependentTargetsInParallel = 1;",
  "\t\t\t\tLastUpgradeCheck = 1600;",
  "\t\t\t\tTargetAttributes = {",
  f"\t\t\t\t\t{I['target']} = {{",
  "\t\t\t\t\t\tCreatedOnToolsVersion = 16.0;",
  "\t\t\t\t\t};",
  "\t\t\t\t};",
  "\t\t\t};",
  f"\t\t\tbuildConfigurationList = {I['proj_config_list']} /* Build configuration list for PBXProject \"SmackMeRebuild\" */;",
  "\t\t\tcompatibilityVersion = \"Xcode 14.0\";",
  "\t\t\tdevelopmentRegion = en;",
  "\t\t\thasScannedForEncodings = 0;",
  "\t\t\tknownRegions = (",
  "\t\t\t\ten,",
  "\t\t\t\tBase,",
  "\t\t\t);",
  f"\t\t\tmainGroup = {I['main_group']};",
  f"\t\t\tproductRefGroup = {I['products_group']} /* Products */;",
  "\t\t\tprojectDirPath = \"\";",
  "\t\t\tprojectRoot = \"\";",
  "\t\t\ttargets = (",
  f"\t\t\t\t{I['target']} /* SmackMeRebuild */,",
  "\t\t\t);",
  "\t\t};",
  "/* End PBXProject section */", "")

# ── PBXResourcesBuildPhase ────────────────────────────────────────────────────
W("/* Begin PBXResourcesBuildPhase section */",
  f"\t\t{I['resources_phase']} /* Resources */ = {{",
  "\t\t\tisa = PBXResourcesBuildPhase;",
  "\t\t\tbuildActionMask = 2147483647;",
  "\t\t\tfiles = (")
W(f"\t\t\t\t{I['assets_catalog_build']} /* Assets.xcassets in Resources */,")
for fname in image_files:
    k = safe_key(f"img_{fname}")
    W(f"\t\t\t\t{I[f'build_{k}']} /* {fname} in Resources */,")
for fname in sound_files:
    k = safe_key(f"snd_{fname}")
    W(f"\t\t\t\t{I[f'build_{k}']} /* {fname} in Resources */,")
for fname in font_files:
    k = safe_key(f"fnt_{fname}")
    W(f"\t\t\t\t{I[f'build_{k}']} /* {fname} in Resources */,")
W("\t\t\t);",
  "\t\t\trunOnlyForDeploymentPostprocessing = 0;",
  "\t\t};",
  "/* End PBXResourcesBuildPhase section */", "")

# ── PBXSourcesBuildPhase ─────────────────────────────────────────────────────
W("/* Begin PBXSourcesBuildPhase section */",
  f"\t\t{I['sources_phase']} /* Sources */ = {{",
  "\t\t\tisa = PBXSourcesBuildPhase;",
  "\t\t\tbuildActionMask = 2147483647;",
  "\t\t\tfiles = (")
for path, name in SWIFT_FILES:
    k = safe_key(path)
    W(f"\t\t\t\t{I[f'build_{k}']} /* {name} in Sources */,")
W("\t\t\t);",
  "\t\t\trunOnlyForDeploymentPostprocessing = 0;",
  "\t\t};",
  "/* End PBXSourcesBuildPhase section */", "")

# ── XCBuildConfiguration ─────────────────────────────────────────────────────
PROJECT_DEBUG_SETTINGS = """\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tCLANG_ANALYZER_NONNULL = YES;
\t\t\t\tCLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
\t\t\t\tCLANG_CXX_LANGUAGE_STANDARD = "gnu++17";
\t\t\t\tCLANG_ENABLE_MODULES = YES;
\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;
\t\t\t\tCLANG_ENABLE_OBJC_WEAK = YES;
\t\t\t\tCLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
\t\t\t\tCLANG_WARN_BOOL_CONVERSION = YES;
\t\t\t\tCLANG_WARN_COMMA = YES;
\t\t\t\tCLANG_WARN_CONSTANT_CONVERSION = YES;
\t\t\t\tCLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
\t\t\t\tCLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
\t\t\t\tCLANG_WARN_DOCUMENTATION_COMMENTS = YES;
\t\t\t\tCLANG_WARN_EMPTY_BODY = YES;
\t\t\t\tCLANG_WARN_ENUM_CONVERSION = YES;
\t\t\t\tCLANG_WARN_INFINITE_RECURSION = YES;
\t\t\t\tCLANG_WARN_INT_CONVERSION = YES;
\t\t\t\tCLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
\t\t\t\tCLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
\t\t\t\tCLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
\t\t\t\tCLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
\t\t\t\tCLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
\t\t\t\tCLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
\t\t\t\tCLANG_WARN_STRICT_PROTOTYPES = YES;
\t\t\t\tCLANG_WARN_SUSPICIOUS_MOVE = YES;
\t\t\t\tCLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
\t\t\t\tCLANG_WARN_UNREACHABLE_CODE = YES;
\t\t\t\tCLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
\t\t\t\tCOPY_PHASE_STRIP = NO;
\t\t\t\tDEBUG_INFORMATION_FORMAT = dwarf;
\t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;
\t\t\t\tENABLE_TESTABILITY = YES;
\t\t\t\tGCC_C_LANGUAGE_STANDARD = gnu11;
\t\t\t\tGCC_DYNAMIC_NO_PIC = NO;
\t\t\t\tGCC_NO_COMMON_BLOCKS = YES;
\t\t\t\tGCC_OPTIMIZATION_LEVEL = 0;
\t\t\t\tGCC_PREPROCESSOR_DEFINITIONS = ("DEBUG=1","$(inherited)",);
\t\t\t\tGCC_WARN_64_TO_32_BIT_CONVERSION = YES;
\t\t\t\tGCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
\t\t\t\tGCC_WARN_UNDECLARED_SELECTOR = YES;
\t\t\t\tGCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
\t\t\t\tGCC_WARN_UNUSED_FUNCTION = YES;
\t\t\t\tGCC_WARN_UNUSED_VARIABLE = YES;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 16.0;
\t\t\t\tMTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
\t\t\t\tMTL_FAST_MATH = YES;
\t\t\t\tONLY_ACTIVE_ARCH = YES;
\t\t\t\tSDKROOT = iphoneos;
\t\t\t\tSWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;
\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-Onone";"""

PROJECT_RELEASE_SETTINGS = """\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tCLANG_ANALYZER_NONNULL = YES;
\t\t\t\tCLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
\t\t\t\tCLANG_CXX_LANGUAGE_STANDARD = "gnu++17";
\t\t\t\tCLANG_ENABLE_MODULES = YES;
\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;
\t\t\t\tCLANG_ENABLE_OBJC_WEAK = YES;
\t\t\t\tCLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
\t\t\t\tCLANG_WARN_BOOL_CONVERSION = YES;
\t\t\t\tCLANG_WARN_COMMA = YES;
\t\t\t\tCLANG_WARN_CONSTANT_CONVERSION = YES;
\t\t\t\tCLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
\t\t\t\tCLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
\t\t\t\tCLANG_WARN_DOCUMENTATION_COMMENTS = YES;
\t\t\t\tCLANG_WARN_EMPTY_BODY = YES;
\t\t\t\tCLANG_WARN_ENUM_CONVERSION = YES;
\t\t\t\tCLANG_WARN_INFINITE_RECURSION = YES;
\t\t\t\tCLANG_WARN_INT_CONVERSION = YES;
\t\t\t\tCLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
\t\t\t\tCLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
\t\t\t\tCLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
\t\t\t\tCLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
\t\t\t\tCLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
\t\t\t\tCLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
\t\t\t\tCLANG_WARN_STRICT_PROTOTYPES = YES;
\t\t\t\tCLANG_WARN_SUSPICIOUS_MOVE = YES;
\t\t\t\tCLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
\t\t\t\tCLANG_WARN_UNREACHABLE_CODE = YES;
\t\t\t\tCLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
\t\t\t\tCOPY_PHASE_STRIP = NO;
\t\t\t\tDEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
\t\t\t\tENABLE_NS_ASSERTIONS = NO;
\t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;
\t\t\t\tGCC_C_LANGUAGE_STANDARD = gnu11;
\t\t\t\tGCC_NO_COMMON_BLOCKS = YES;
\t\t\t\tGCC_WARN_64_TO_32_BIT_CONVERSION = YES;
\t\t\t\tGCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
\t\t\t\tGCC_WARN_UNDECLARED_SELECTOR = YES;
\t\t\t\tGCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
\t\t\t\tGCC_WARN_UNUSED_FUNCTION = YES;
\t\t\t\tGCC_WARN_UNUSED_VARIABLE = YES;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 16.0;
\t\t\t\tMTL_FAST_MATH = YES;
\t\t\t\tSDKROOT = iphoneos;
\t\t\t\tSWIFT_COMPILATION_MODE = wholemodule;
\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-O";
\t\t\t\tVALIDATE_PRODUCT = YES;"""

TARGET_COMMON = """\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
\t\t\t\tASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tDEVELOPMENT_TEAM = ZGJQ5DZFK2;
\t\t\t\tINFOPLIST_FILE = SmackMeRebuild/Info.plist;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 16.0;
\t\t\t\tLD_RUNPATH_SEARCH_PATHS = ("$(inherited)","@executable_path/Frameworks",);
\t\t\t\tMARKETING_VERSION = 2.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = "com.rebuilt.smackme";
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";"""

W("/* Begin XCBuildConfiguration section */")

# Project Debug
W(f"\t\t{I['proj_debug']} /* Debug */ = {{",
  "\t\t\tisa = XCBuildConfiguration;",
  "\t\t\tbuildSettings = {",
  PROJECT_DEBUG_SETTINGS,
  "\t\t\t};",
  "\t\t\tname = Debug;",
  "\t\t};")

# Project Release
W(f"\t\t{I['proj_release']} /* Release */ = {{",
  "\t\t\tisa = XCBuildConfiguration;",
  "\t\t\tbuildSettings = {",
  PROJECT_RELEASE_SETTINGS,
  "\t\t\t};",
  "\t\t\tname = Release;",
  "\t\t};")

# Target Debug
W(f"\t\t{I['target_debug']} /* Debug */ = {{",
  "\t\t\tisa = XCBuildConfiguration;",
  "\t\t\tbuildSettings = {",
  TARGET_COMMON,
  "\t\t\t};",
  "\t\t\tname = Debug;",
  "\t\t};")

# Target Release
W(f"\t\t{I['target_release']} /* Release */ = {{",
  "\t\t\tisa = XCBuildConfiguration;",
  "\t\t\tbuildSettings = {",
  TARGET_COMMON,
  "\t\t\t};",
  "\t\t\tname = Release;",
  "\t\t};")

W("/* End XCBuildConfiguration section */", "")

# ── XCConfigurationList ───────────────────────────────────────────────────────
W("/* Begin XCConfigurationList section */",
  f"\t\t{I['proj_config_list']} /* Build configuration list for PBXProject \"SmackMeRebuild\" */ = {{",
  "\t\t\tisa = XCConfigurationList;",
  "\t\t\tbuildConfigurations = (",
  f"\t\t\t\t{I['proj_debug']} /* Debug */,",
  f"\t\t\t\t{I['proj_release']} /* Release */,",
  "\t\t\t);",
  "\t\t\tdefaultConfigurationIsVisible = 0;",
  "\t\t\tdefaultConfigurationName = Release;",
  "\t\t};",
  f"\t\t{I['target_config_list']} /* Build configuration list for PBXNativeTarget \"SmackMeRebuild\" */ = {{",
  "\t\t\tisa = XCConfigurationList;",
  "\t\t\tbuildConfigurations = (",
  f"\t\t\t\t{I['target_debug']} /* Debug */,",
  f"\t\t\t\t{I['target_release']} /* Release */,",
  "\t\t\t);",
  "\t\t\tdefaultConfigurationIsVisible = 0;",
  "\t\t\tdefaultConfigurationName = Release;",
  "\t\t};",
  "/* End XCConfigurationList section */", "")

# ── Close ─────────────────────────────────────────────────────────────────────
W("\t};",
  f"\trootObject = {I['project']} /* Project object */;",
  "}")

content = "\n".join(L)

# ── Write output ──────────────────────────────────────────────────────────────
xcodeproj_dir = os.path.join(PROJECT_DIR, "SmackMeRebuild.xcodeproj")
os.makedirs(xcodeproj_dir, exist_ok=True)
out_path = os.path.join(xcodeproj_dir, "project.pbxproj")
with open(out_path, "w", encoding="utf-8") as f:
    f.write(content)

print(f"✅  Generated: {out_path}")
print(f"    Swift files  : {len(SWIFT_FILES)}")
print(f"    Image files  : {len(image_files)}")
print(f"    Sound files  : {len(sound_files)}")
print(f"    Font files   : {len(font_files)}")
