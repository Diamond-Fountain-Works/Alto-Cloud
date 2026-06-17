# Diamond Transfer Feature Overview

**Diamond Transfer is a LAN-first native file sharing app: direct peer transfer when two devices just need to send files, and Diamond Cloud sessions when a group needs a shared local drop zone.**

It is not a traditional cloud drive. It is built for local, fast, controlled file exchange between nearby devices on the same Wi-Fi network.

## Product Positioning

Diamond Transfer = peer-to-peer transfer + optional shared Diamond Cloud sessions.

It is designed for:

- Sharing photos, videos, and documents between personal devices
- Collecting files from multiple people in a meeting
- Classroom and workshop file exchange
- Photo shoot and studio workflows where a Mac, NAS, or desktop becomes a local drop zone
- Local transfer without cloud accounts or public internet routing

## Feature Matrix

| Feature | Description |
| --- | --- |
| Nearby discovery | Discovers Diamond Transfer devices on the same Wi-Fi with Bonjour/mDNS. |
| Direct transfer | Keeps a LocalSend-style one-to-one transfer path. |
| Diamond Cloud | Lets one device become a local server for a shared session. |
| Dual identity | A Diamond Cloud host is still visible as a direct peer. |
| Storage quota | Shows available disk space and caps Diamond Cloud session storage. |
| Local folder | Stores shared files in a visible local folder chosen by the host. |
| One-time files | Sender chooses visible devices; Diamond Cloud deletes after every target device opens the file. |
| macOS menu bar | Closing the main window hides the Dock icon while the menu bar item remains available. |
| Native app shell | Current prototype is a SwiftUI macOS app. |

## Direct Peer Transfer

Every app instance publishes a peer node on the local network. Other devices can discover it and use it as a direct transfer target.

Best for:

- Mac to iPhone
- Android to Mac
- Laptop to laptop

## Diamond Cloud

Any device can start Diamond Cloud. When active, that device has two roles:

- **Peer**: still discoverable for direct transfer
- **Diamond Cloud server**: a local sharing server for a group session

Other devices see:

- **Nearby Devices**
- **Shared Diamond Cloud sessions**

## Diamond Cloud Storage Control

Before starting a Diamond Cloud session, the host can review and configure:

- Available disk space
- local folder location
- Maximum storage quota for this session

This prevents Diamond Cloud from consuming unlimited local disk space.

## One-Time Files

Before upload, a sender can mark a file as one-time.

Rules:

- The sender selects which Diamond Cloud devices can see the file
- Only selected devices see it in their file list
- The file is marked with a red “一次性文件” label
- Diamond Cloud records viewed state for every target device
- After every selected device opens the file, Diamond Cloud deletes it
- Devices that join later do not automatically get access to old one-time files

This is a Diamond Cloud retention rule, not DRM. It does not claim to block screenshots, external recording, or copying after viewing.

## Current Prototype Status

The current macOS demo already implements real LAN discovery and advertisement:

- `Network.framework` with Bonjour/mDNS
- Service type: `_diamondtransfer._tcp`
- Always-on peer node
- Additional Diamond Cloud node when the shared session starts
- One Mac can appear as both a direct peer and a Diamond Cloud host

File-byte transfer is still simulated in UI state. The next step is a real TCP control channel and streaming payload transfer.

## Technical Keywords

LAN file sharing, Wi-Fi file transfer, LocalSend alternative, AirDrop alternative, peer-to-peer transfer, Diamond Cloud session, Bonjour, mDNS, Network.framework, one-time files, private local cloud, local-first file transfer.
