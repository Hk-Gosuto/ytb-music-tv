#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="${SCRIPT_DIR}/Sources/YTBMusicTVClient"
ASSET_CATALOG="${SCRIPT_DIR}/Assets.xcassets"
BUILD_DIR="${BUILD_DIR:-${SCRIPT_DIR}/build}"
CONFIGURATION="${CONFIGURATION:-Release}"

PRODUCT_NAME="${PRODUCT_NAME:-YTBMusicTV}"
DISPLAY_NAME="${DISPLAY_NAME:-YTB Music TV}"
BUNDLE_ID="${BUNDLE_ID:-com.ytb.music.tv}"
APP_ICON_NAME="${APP_ICON_NAME:-App Icon & Top Shelf Image}"
VERSION="${VERSION:-0.1.0}"
BUILD_NUMBER="${BUILD_NUMBER:-1}"
TVOS_DEPLOYMENT_TARGET="${TVOS_DEPLOYMENT_TARGET:-17.0}"
BUILD_FOR_SIMULATOR="${BUILD_FOR_SIMULATOR:-0}"

if [[ "${BUILD_FOR_SIMULATOR}" == "1" ]]; then
  SDK="${SDK:-appletvsimulator}"
  TARGET_TRIPLE="${ARCH:-arm64}-apple-tvos${TVOS_DEPLOYMENT_TARGET}-simulator"
  PLATFORM_DIR_NAME="AppleTVSimulator"
  SUPPORTED_PLATFORM="AppleTVSimulator"
else
  SDK="${SDK:-appletvos}"
  TARGET_TRIPLE="${ARCH:-arm64}-apple-tvos${TVOS_DEPLOYMENT_TARGET}"
  PLATFORM_DIR_NAME="AppleTVOS"
  SUPPORTED_PLATFORM="AppleTVOS"
fi

SDK_PATH="$(xcrun --sdk "${SDK}" --show-sdk-path)"
SDK_VERSION="$(xcrun --sdk "${SDK}" --show-sdk-version)"
SWIFTC="$(xcrun --sdk "${SDK}" --find swiftc)"
ACTOOL="$(xcrun --find actool)"
CODESIGN="$(xcrun --find codesign)"
APPINTENTS_PROCESSOR="$(xcrun --find appintentsmetadataprocessor)"
PLIST_BUDDY="/usr/libexec/PlistBuddy"

APP_DIR="${BUILD_DIR}/${CONFIGURATION}-${PLATFORM_DIR_NAME}/${PRODUCT_NAME}.app"
PAYLOAD_ROOT="${BUILD_DIR}/ipa"
PAYLOAD_DIR="${PAYLOAD_ROOT}/Payload"
IPA_PATH="${OUTPUT_IPA:-${BUILD_DIR}/${PRODUCT_NAME}-tvOS.ipa}"
PROFILE_PLIST="${BUILD_DIR}/profile.plist"
GENERATED_ENTITLEMENTS="${BUILD_DIR}/${PRODUCT_NAME}.entitlements"
CONST_VALUES="${BUILD_DIR}/${PRODUCT_NAME}.swiftconstvalues"
CONST_PROTOCOLS="${BUILD_DIR}/${PRODUCT_NAME}-const-extract-protocols.json"
SOURCE_LIST="${BUILD_DIR}/${PRODUCT_NAME}-sources.txt"
CONST_VALUES_LIST="${BUILD_DIR}/${PRODUCT_NAME}-const-values.txt"
ASSET_INFO_PLIST="${BUILD_DIR}/${PRODUCT_NAME}-asset-info.plist"
ASSET_ACTOOL_RESULT="${BUILD_DIR}/${PRODUCT_NAME}-actool-result.plist"

SIGN_IDENTITY="${SIGN_IDENTITY:-}"
PROVISIONING_PROFILE="${PROVISIONING_PROFILE:-}"
ENTITLEMENTS="${ENTITLEMENTS:-}"
AD_HOC_SIGN="${AD_HOC_SIGN:-0}"

bundle_id_matches_profile() {
  local bundle_id="$1"
  local profile_pattern="$2"

  if [[ "${profile_pattern}" == "*" || "${profile_pattern}" == "${bundle_id}" ]]; then
    return 0
  fi

  if [[ "${profile_pattern}" == *".*" ]]; then
    local prefix="${profile_pattern%.*}"
    [[ "${bundle_id}" == "${prefix}."* ]]
    return
  fi

  return 1
}

if [[ ! -d "${SOURCE_DIR}" ]]; then
  echo "Source directory not found: ${SOURCE_DIR}" >&2
  exit 1
fi

if [[ "${AD_HOC_SIGN}" == "1" && -z "${SIGN_IDENTITY}" ]]; then
  SIGN_IDENTITY="-"
fi

rm -rf "${APP_DIR}" "${PAYLOAD_ROOT}" "${PROFILE_PLIST}" "${GENERATED_ENTITLEMENTS}" \
  "${CONST_VALUES}" "${CONST_PROTOCOLS}" "${SOURCE_LIST}" "${CONST_VALUES_LIST}" \
  "${ASSET_INFO_PLIST}" "${ASSET_ACTOOL_RESULT}"
if [[ "${BUILD_FOR_SIMULATOR}" != "1" ]]; then
  rm -f "${IPA_PATH}"
fi
mkdir -p "${APP_DIR}" "${PAYLOAD_DIR}" "$(dirname "${IPA_PATH}")"

cat > "${APP_DIR}/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleDisplayName</key>
  <string>${DISPLAY_NAME}</string>
  <key>CFBundleExecutable</key>
  <string>${PRODUCT_NAME}</string>
  <key>CFBundleIdentifier</key>
  <string>${BUNDLE_ID}</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>${PRODUCT_NAME}</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>${VERSION}</string>
  <key>CFBundleSupportedPlatforms</key>
  <array>
    <string>${SUPPORTED_PLATFORM}</string>
  </array>
  <key>CFBundleVersion</key>
  <string>${BUILD_NUMBER}</string>
  <key>DTPlatformName</key>
  <string>${SDK}</string>
  <key>DTPlatformVersion</key>
  <string>${SDK_VERSION}</string>
  <key>DTSDKName</key>
  <string>${SDK}${SDK_VERSION}</string>
  <key>LSRequiresIPhoneOS</key>
  <true/>
  <key>ITSAppUsesNonExemptEncryption</key>
  <false/>
  <key>MinimumOSVersion</key>
  <string>${TVOS_DEPLOYMENT_TARGET}</string>
  <key>NSAppTransportSecurity</key>
  <dict>
    <key>NSAllowsLocalNetworking</key>
    <true/>
  </dict>
  <key>NSLocalNetworkUsageDescription</key>
  <string>YTB Music TV connects to the media server on your local network.</string>
  <key>UIApplicationSupportsIndirectInputEvents</key>
  <true/>
  <key>UIBackgroundModes</key>
  <array>
    <string>audio</string>
  </array>
  <key>UIDeviceFamily</key>
  <array>
    <integer>3</integer>
  </array>
  <key>UISupportedInterfaceOrientations</key>
  <array>
    <string>UIInterfaceOrientationLandscapeLeft</string>
    <string>UIInterfaceOrientationLandscapeRight</string>
  </array>
</dict>
</plist>
PLIST

if [[ -d "${ASSET_CATALOG}" ]]; then
  echo "Compiling asset catalog..."
  set +e
  "${ACTOOL}" \
    --compile "${APP_DIR}" \
    --platform "${SDK}" \
    --minimum-deployment-target "${TVOS_DEPLOYMENT_TARGET}" \
    --target-device tv \
    --app-icon "${APP_ICON_NAME}" \
    --output-partial-info-plist "${ASSET_INFO_PLIST}" \
    --skip-app-store-deployment \
    --warnings \
    --errors \
    --notices \
    "${ASSET_CATALOG}" > "${ASSET_ACTOOL_RESULT}"
  actool_status=$?
  set -e

  if [[ "${actool_status}" -ne 0 || ! -f "${APP_DIR}/Assets.car" ]]; then
    echo "Asset catalog compilation did not produce Assets.car." >&2
    cat "${ASSET_ACTOOL_RESULT}" >&2
    exit 1
  fi

  if [[ -f "${ASSET_INFO_PLIST}" ]]; then
    "${PLIST_BUDDY}" -c "Merge ${ASSET_INFO_PLIST}" "${APP_DIR}/Info.plist"
  fi
fi

sources=()
while IFS= read -r -d '' source_file; do
  sources+=("${source_file}")
done < <(find "${SOURCE_DIR}" -name '*.swift' -print0 | sort -z)

if [[ "${#sources[@]}" -eq 0 ]]; then
  echo "No Swift sources found in ${SOURCE_DIR}" >&2
  exit 1
fi

echo "Building ${PRODUCT_NAME}.app for AppleTVOS ${SDK_VERSION}..."
printf '%s\n' '["AnyResolverProviding","AppEntity","AppEnum","AppExtension","AppIntent","AppIntentsPackage","AppShortcutProviding","AppShortcutsProvider","DynamicOptionsProvider","EntityQuery","ExtensionPointDefining","IntentValueQuery","Resolver","TransientEntity","_AssistantIntentsProvider","_GenerativeFunctionExtractable","_IntentValueRepresentable"]' > "${CONST_PROTOCOLS}"
"${SWIFTC}" \
  -sdk "${SDK_PATH}" \
  -target "${TARGET_TRIPLE}" \
  -O \
  -whole-module-optimization \
  -module-name "${PRODUCT_NAME}" \
  -Xfrontend -const-gather-protocols-file \
  -Xfrontend "${CONST_PROTOCOLS}" \
  -emit-const-values-path "${CONST_VALUES}" \
  -emit-executable \
  -o "${APP_DIR}/${PRODUCT_NAME}" \
  "${sources[@]}"

printf '%s\n' "${sources[@]}" > "${SOURCE_LIST}"
printf '%s\n' "${CONST_VALUES}" > "${CONST_VALUES_LIST}"

XCODE_BUILD_VERSION="$(xcodebuild -version | awk '/Build version/ { print $3 }')"
TOOLCHAIN_DIR="$(xcode-select -p)/Toolchains/XcodeDefault.xctoolchain"
echo "Extracting App Intents metadata..."
"${APPINTENTS_PROCESSOR}" \
  --output "${APP_DIR}/Metadata.appintents" \
  --toolchain-dir "${TOOLCHAIN_DIR}" \
  --module-name "${PRODUCT_NAME}" \
  --sdk-root "${SDK_PATH}" \
  --xcode-version "${XCODE_BUILD_VERSION}" \
  --platform-family "AppleTV" \
  --deployment-target "${TVOS_DEPLOYMENT_TARGET}" \
  --target-triple "${TARGET_TRIPLE}" \
  --source-file-list "${SOURCE_LIST}" \
  --swift-const-vals-list "${CONST_VALUES_LIST}" \
  --deployment-aware-processing \
  --force

cat > "${APP_DIR}/PkgInfo" <<PKGINFO
APPL????
PKGINFO

if [[ "${BUILD_FOR_SIMULATOR}" != "1" && -n "${PROVISIONING_PROFILE}" ]]; then
  if [[ ! -f "${PROVISIONING_PROFILE}" ]]; then
    echo "Provisioning profile not found: ${PROVISIONING_PROFILE}" >&2
    exit 1
  fi
  echo "Embedding provisioning profile: ${PROVISIONING_PROFILE}"
  cp "${PROVISIONING_PROFILE}" "${APP_DIR}/embedded.mobileprovision"

  /usr/bin/security cms -D -i "${PROVISIONING_PROFILE}" > "${PROFILE_PLIST}"
  /usr/bin/plutil -extract Entitlements xml1 -o "${GENERATED_ENTITLEMENTS}" "${PROFILE_PLIST}"

  profile_name="$("${PLIST_BUDDY}" -c 'Print :Name' "${PROFILE_PLIST}" 2>/dev/null || true)"
  profile_platforms="$("${PLIST_BUDDY}" -c 'Print :Platform' "${PROFILE_PLIST}" 2>/dev/null || true)"
  profile_app_id="$("${PLIST_BUDDY}" -c 'Print :Entitlements:application-identifier' "${PROFILE_PLIST}" 2>/dev/null || true)"
  profile_bundle_pattern="${profile_app_id#*.}"

  echo "Profile name: ${profile_name:-unknown}"
  echo "Profile platforms: ${profile_platforms//$'\n'/ }"
  echo "Profile App ID: ${profile_app_id:-unknown}"

  if [[ "${profile_platforms}" != *"AppleTVOS"* && "${profile_platforms}" != *"tvOS"* ]]; then
    echo "Warning: profile platform does not look like tvOS. Device install may fail." >&2
  fi

  if [[ -z "${profile_app_id}" || "${profile_bundle_pattern}" == "${profile_app_id}" ]]; then
    echo "Warning: could not read application-identifier from provisioning profile." >&2
  elif ! bundle_id_matches_profile "${BUNDLE_ID}" "${profile_bundle_pattern}"; then
    echo "Provisioning profile App ID does not match BUNDLE_ID." >&2
    echo "  profile: ${profile_bundle_pattern}" >&2
    echo "  bundle:  ${BUNDLE_ID}" >&2
    echo "Set BUNDLE_ID to match the profile, or generate a tvOS profile for ${BUNDLE_ID}." >&2
    exit 1
  fi

  if [[ -z "${ENTITLEMENTS}" ]]; then
    ENTITLEMENTS="${GENERATED_ENTITLEMENTS}"
  fi
fi

if [[ "${BUILD_FOR_SIMULATOR}" == "1" ]]; then
  echo "Ad-hoc signing simulator app..."
  "${CODESIGN}" --force --sign - --timestamp=none "${APP_DIR}"
elif [[ -n "${SIGN_IDENTITY}" ]]; then
  sign_args=(--force --sign "${SIGN_IDENTITY}" --timestamp=none)
  if [[ -n "${ENTITLEMENTS}" ]]; then
    if [[ ! -f "${ENTITLEMENTS}" ]]; then
      echo "Entitlements file not found: ${ENTITLEMENTS}" >&2
      exit 1
    fi
    sign_args+=(--entitlements "${ENTITLEMENTS}")
  fi
  echo "Signing ${PRODUCT_NAME}.app with identity: ${SIGN_IDENTITY}"
  "${CODESIGN}" "${sign_args[@]}" "${APP_DIR}"
else
  echo "Skipping codesign. The IPA must be signed before installing on a real Apple TV."
fi

if [[ "${BUILD_FOR_SIMULATOR}" == "1" ]]; then
  echo "Simulator app written to: ${APP_DIR}"
  exit 0
fi

cp -R "${APP_DIR}" "${PAYLOAD_DIR}/${PRODUCT_NAME}.app"

echo "Packaging IPA..."
(
  cd "${PAYLOAD_ROOT}"
  /usr/bin/zip -qry "${IPA_PATH}" Payload
)

echo "IPA written to: ${IPA_PATH}"
