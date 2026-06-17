# Diamond Transfer

**LAN-first file sharing for nearby devices. Direct transfer when it is simple, Diamond Cloud when a group needs a shared local drop zone.**

Diamond Transfer is a native macOS prototype for local-network file transfer, designed with a roadmap toward iOS and Android. It combines LocalSend-style peer-to-peer transfer, AirDrop-like nearby discovery, and Diamond Cloud, a shared local session where one device becomes the Wi-Fi server for everyone nearby.

> Independent project. Diamond Transfer is not affiliated with LocalSend, Apple AirDrop, or Apple.

## Why Diamond Transfer

Most file transfer tools are either one-to-one senders or cloud drives. Diamond Transfer sits between them:

- Use **Direct Transfer** for quick device-to-device sending.
- Use **Diamond Cloud** when multiple devices need the same shared session.
- Use **One-Time Files** when files should disappear from Diamond Cloud after selected devices have opened them.
- Keep everything **local-first** on the same Wi-Fi before adding any remote cloud layer.

## Key Features

| Area | What it does |
| --- | --- |
| Nearby discovery | Finds Diamond Transfer peers and Diamond Cloud sessions on the same Wi-Fi with Bonjour/mDNS. |
| Direct transfer | Keeps a LocalSend-style peer target for one-to-one transfers. |
| Diamond Cloud | Lets one device act as a shared local server for multiple devices. |
| Dual identity | A Diamond Cloud host remains discoverable as both a peer and a shared session. |
| Storage quota | Shows available disk space and lets the host cap session storage. |
| Local folder | Stores shared files in a visible local folder chosen by the user. |
| One-time files | Allows the sender to choose visible devices; deletes after all selected devices open the file. |
| macOS menu bar | Closing the main window hides the Dock icon while the menu bar item stays alive. |
| Custom icon | Uses the Diamond Transfer black-and-white logo for the app and menu bar template icon. |

## Current Prototype

The current macOS demo already implements real LAN discovery plumbing:

- `Network.framework` Bonjour/mDNS browser on `_diamondtransfer._tcp`
- Always-on peer advertisement
- Diamond Cloud advertisement when the shared session starts
- A protocol draft for `hello`, `joinHub`, `uploadIntent`, `fileViewed`, and `fileDeleted`
- Native SwiftUI macOS shell with Dock/menu-bar behavior

File payload transfer is still simulated in UI state. The next implementation step is the real control + payload pipeline:

```text
joinHub -> uploadIntent -> uploadAccepted -> file stream -> fileViewed -> fileDeleted
```

## Screens and Workflows

### Direct Peer Transfer

Each app instance advertises a peer node. Nearby devices can discover it and use it as a direct transfer target.

### Diamond Cloud

One device can start Diamond Cloud. Other devices see it under shared sessions and can join the same local drop zone.

### One-Time Files

A sender can mark a file as one-time and choose which Diamond Cloud devices can see it. Diamond Cloud tracks viewed state per selected device and deletes the file after everyone in that target set opens it.

## Multilingual Overview

- [中文功能介绍](docs/features.zh-CN.md)
- [English feature overview](docs/features.en.md)
- [日本語の機能紹介](docs/features.ja.md)
- [LAN protocol draft](docs/lan-protocol.md)

## Search Keywords

LAN file sharing, local network file transfer, Wi-Fi file transfer, LocalSend alternative, AirDrop alternative, peer-to-peer file transfer, nearby device discovery, Bonjour mDNS, macOS file sharing, Diamond Cloud session, one-time files, private local cloud, local-first file transfer.

## Run

```bash
./script/build_and_run.sh
```

Build only:

```bash
env CLANG_MODULE_CACHE_PATH="$PWD/.build/clang-module-cache" SWIFT_MODULECACHE_PATH="$PWD/.build/swift-module-cache" swift build
```

## Roadmap

- Real TCP control channel
- Real file-byte streaming
- Chunked transfer and resume support
- iOS client
- Android client
- Cross-platform protocol compatibility tests
- Optional end-to-end encryption
