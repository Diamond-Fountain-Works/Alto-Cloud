# Alto Cloud Feature Overview

**Alto Cloud is a LAN-first native file-sharing app: use Quick Send between two nearby devices, or start a Shared Cloud for a group.**

Alto Cloud is designed for homes, meetings, classrooms, studios, and production sites where devices need to exchange files quickly without accounts or an internet cloud.

## Product Model

Alto Cloud = **Quick Send + optional Shared Cloud sessions**.

- **Quick Send** is one-to-one nearby delivery.
- **Shared Cloud** is a temporary local sharing space hosted by one device.
- **One-Time Drop** is deleted after every selected recipient opens it.

## Core Features

| Feature | Behavior |
| --- | --- |
| Same-Wi-Fi discovery | Discovers Alto Cloud devices with Bonjour/mDNS. |
| Quick Send | Keeps each device available as a direct delivery target. |
| Shared Cloud | Turns one device into a local server for a group session. |
| Dual identity | A Shared Cloud host remains available through Quick Send. |
| Storage quota | Limits how much local disk a Shared Cloud can consume. |
| Visible local folder | Lets the host choose where shared files are stored. |
| One-Time Drop | Restricts visibility and deletes after all selected devices open the file. |

## Shared Cloud Storage

Before starting a Shared Cloud, the host can review available disk capacity, choose a folder, and set a session quota. Shared files remain on the host device rather than being uploaded to a public cloud.

## One-Time Drop Rule

The sender chooses the target devices. Devices that join later do not automatically receive access. Alto Cloud removes the drop only after every selected target has opened it.

This is a retention rule, not DRM. It does not prevent screenshots, external recording, or copying after a file is opened.

## LAN Foundation

- Service type: `_altocloud._tcp`
- Always-on Quick Send peer node
- Additional Shared Cloud node while the session is active
- One Mac can appear as both a Quick Send target and a Shared Cloud host

The current prototype implements discovery and simulated file state. Real control-channel and payload streaming are the next engineering steps.
