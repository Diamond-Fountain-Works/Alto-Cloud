# Alto Cloud LAN Protocol Draft

## Layers

Alto Cloud separates LAN behavior into three layers:

1. Discovery: Bonjour/mDNS on `_altocloud._tcp`.
2. Control: TCP JSON envelopes for Shared Cloud membership and file metadata.
3. Payload: future length-prefixed or chunked file streams.

The current prototype implements discovery and the initial message model. File bytes are still simulated.

## Node Roles

- `peer`: always advertised while Alto Cloud is running; used by Quick Send.
- `sharedCloud`: advertised only while a Shared Cloud session is active.

One device can therefore appear as both a Quick Send target and a Shared Cloud host.

## Bonjour Identity

Service type:

```text
_altocloud._tcp
```

Service-name format:

```text
AC|<role>|<compact-uuid>|<device-kind>
```

Example:

```text
AC|sharedCloud|4F1C2B0A3D224E089C38797D361F6A13|mac
```

TXT records include:

- `protocol`
- `node`
- `role`
- `name`
- `kind`

## Protocol Version

```text
ac-lan-1
```

## Control Messages

- `hello`
- `joinSharedCloud`
- `leaveSharedCloud`
- `sharedCloudSnapshot`
- `uploadIntent`
- `uploadAccepted`
- `uploadRejected`
- `fileViewed`
- `fileDeleted`

Every envelope carries a protocol version, message ID, message type, sender ID, timestamp, and typed payload.

## One-Time Drop Rule

For a One-Time Drop:

1. The sender chooses `visibleToDeviceIDs`.
2. Shared Cloud only exposes the file to those devices and the sender.
3. A target device sends `fileViewed` when opening it.
4. Shared Cloud deletes the file after every selected target has opened it.
5. Devices joining later are not automatically added to the target set.

This is a retention rule, not DRM. It does not prevent screenshots, external recording, or copying after the file is opened.
