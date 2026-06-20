# YTB Music TV tvOS Client

This is the first SwiftUI source for the Apple TV client.

Create a new Xcode `tvOS App` target, then add the Swift files from `Sources/YTBMusicTVClient` to the target.

First slice responsibilities:

- store and edit the server base URL
- discover nearby servers over UDP and connect automatically when no server is saved
- associate with a server using its six-digit device code
- store the issued server access token
- apply feature and playback settings immediately
- show separate connection, association and YouTube session states
- browse Search, Explore and Library sections
- own player state, queue, history, shuffle, repeat, likes and progress locally
- request a stateless stream URL for the selected media
- play server-provided `playbackUrl` values with `AVPlayer`
- handle next/previous, seek, skip-disliked behavior and end-of-item advancement locally
- expose system media commands and an App Intent destination shortcut

The tvOS client intentionally does not know how to log in to YouTube Music, parse YouTube pages, resolve media signatures, or bypass ads. Public server features remain available without a YouTube session.

Local type check:

```bash
xcrun --sdk appletvos swiftc -typecheck -target arm64-apple-tvos26.4 Sources/YTBMusicTVClient/*.swift
```

Build an unsigned IPA:

```bash
./build-ipa.sh
```

Build and sign a simulator `.app` during UI debugging:

```bash
BUILD_FOR_SIMULATOR=1 CONFIGURATION=Debug ./build-ipa.sh
```

The simulator app is written to `build/Debug-AppleTVSimulator/YTBMusicTV.app`. The script extracts and embeds App Intents metadata for both simulator and device builds.

The default output is `build/YTBMusicTV-tvOS.ipa`. It must be signed before installing on a real Apple TV.

Useful overrides:

```bash
BUNDLE_ID=com.example.ytbmusictv OUTPUT_IPA=build/YTBMusicTV.ipa ./build-ipa.sh
AD_HOC_SIGN=1 ./build-ipa.sh
SIGN_IDENTITY="Apple Development: Your Name" PROVISIONING_PROFILE=/path/to/profile.mobileprovision ./build-ipa.sh
```

For real Apple TV installation, the IPA must contain an `embedded.mobileprovision` generated for tvOS, and the profile App ID must match `BUNDLE_ID`.
If installation fails with `0xe8008015`, rebuild with the matching profile:

```bash
BUNDLE_ID=com.example.ytbmusictv \
PROVISIONING_PROFILE=/path/to/tvos-profile.mobileprovision \
SIGN_IDENTITY="Apple Development: Your Name" \
./build-ipa.sh
```

When `PROVISIONING_PROFILE` is set, the script embeds it, extracts entitlements from it, and checks the profile App ID against `BUNDLE_ID` before packaging.
