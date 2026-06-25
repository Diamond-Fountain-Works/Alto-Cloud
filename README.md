# Alto Cloud

**Nearby file sharing without the internet. Use Quick Send for one-to-one delivery, or start a Shared Cloud when a group needs the same local drop zone.**

Alto Cloud（高积云）is a native macOS prototype for local-network file sharing, with a roadmap toward iOS and Android. It combines nearby discovery, direct device-to-device delivery, and a temporary shared space hosted by one device on the same Wi-Fi.

> Independent project. Alto Cloud is not affiliated with LocalSend, Apple AirDrop, or Apple.

## Product Language

| Name | Meaning |
| --- | --- |
| **Quick Send** | Fast one-to-one delivery between nearby devices. |
| **Shared Cloud** | A local group space hosted by one nearby device. |
| **One-Time Drop** | A targeted file that is deleted after every selected recipient opens it. |

## Why Alto Cloud

Most file-sharing tools are either one-to-one senders or internet cloud drives. Alto Cloud supports both nearby workflows:

- Use **Quick Send** when one device needs to send directly to another.
- Start a **Shared Cloud** when several devices need the same local sharing session.
- Use a **One-Time Drop** when a file should disappear after all selected recipients open it.
- Keep traffic local-first on the same Wi-Fi, without requiring an internet cloud.

## Key Features

| Area | What it does |
| --- | --- |
| Nearby discovery | Finds Alto Cloud devices and Shared Cloud sessions on the same Wi-Fi with Bonjour/mDNS. |
| Quick Send | Keeps a nearby peer target available for one-to-one delivery. |
| Shared Cloud | Lets one device act as a local sharing server for multiple devices. |
| Dual identity | A Shared Cloud host remains available as a Quick Send target. |
| Storage quota | Shows available disk space and lets the host cap session storage. |
| Local folder | Stores shared files in a visible local folder chosen by the host. |
| One-Time Drop | Limits visibility to selected devices and deletes after every target opens the file. |
| Script Relay | Models Python task dispatch to trusted Mac/iPad execution nodes with approval, permissions, runtime limits, and log return. |
| macOS menu bar | Closing the main window hides the Dock icon while the menu bar item stays alive. |

## Current Prototype

The macOS demo implements the LAN discovery foundation:

- `Network.framework` Bonjour/mDNS browser on `_altocloud._tcp`
- Always-on Quick Send peer advertisement
- Shared Cloud advertisement while a shared session is active
- Protocol messages for `hello`, `joinSharedCloud`, `uploadIntent`, `fileViewed`, and `fileDeleted`
- Script Relay prototype UI for Python task dispatch, local approval, and log-return state
- Native SwiftUI macOS shell with Dock and menu-bar behavior

File payload transfer is still simulated in UI state. The next implementation step is the real control and payload pipeline:

```text
joinSharedCloud -> uploadIntent -> uploadAccepted -> file stream -> fileViewed -> fileDeleted
```

## Workflows

### Quick Send

Each app instance advertises a nearby peer node. Other Alto Cloud devices can discover it and use it as a direct delivery target.

### Shared Cloud

One device starts a Shared Cloud. Other nearby devices can join the same local drop zone while the host controls its folder and storage quota.

### One-Time Drop

The sender selects which devices can see a drop. Alto Cloud records open state for each selected recipient and removes the file after everyone in that target set has opened it.

### Script Relay

A sender can draft a Python script task, choose a trusted execution device, request scoped permissions, and receive execution logs. The current macOS prototype simulates the task lifecycle. Real iPadOS execution requires an embedded Python runtime, sandboxed working directory, manual approval, runtime limits, and file/network permission gates.

## Documentation

- [中文功能介绍](docs/features.zh-CN.md)
- [English feature overview](docs/features.en.md)
- [日本語の機能紹介](docs/features.ja.md)
- [LAN protocol draft](docs/lan-protocol.md)

## Run

```bash
./script/build_and_run.sh
```

Package a local DMG:

```bash
./script/package_dmg.sh
```

Build only:

```bash
env CLANG_MODULE_CACHE_PATH="$PWD/.build/clang-module-cache" SWIFT_MODULECACHE_PATH="$PWD/.build/swift-module-cache" swift build
```

## Roadmap

- Real TCP control channel
- Real file-byte streaming
- Chunked transfer and resume support
- Script Relay protocol hardening and embedded Python runtime research
- iOS client
- Android client
- Cross-platform protocol compatibility tests
- Optional end-to-end encryption
