# Diamond Transfer LAN Protocol Draft

## Transport Layers

Diamond Transfer separates LAN behavior into three layers:

1. Discovery: Bonjour/mDNS on `_diamondtransfer._tcp`.
2. Control: TCP JSON envelopes for Diamond Cloud session and file metadata.
3. Payload: future file-byte transfer, either length-prefixed TCP streams or chunked upload streams.

The current macOS demo implements layer 1 and defines layer 2 message shapes. File payloads are still simulated in UI state.

## Node Model

Every app instance can advertise more than one node:

- Peer node: always advertised while the app is running.
- Diamond Cloud node: advertised only while Diamond Cloud is enabled.

This lets one device appear as both:

- a direct transfer target
- a shared Diamond Cloud session host

## Bonjour Service

Service type:

```text
_diamondtransfer._tcp
```

Service name format:

```text
DT|<role>|<compact-uuid>|<device-kind>
```

Example:

```text
DT|hub|4F1C2B0A3D224E089C38797D361F6A13|mac
```

TXT records are published as optional metadata:

- `protocol`: `dt-lan-1`
- `node`: full UUID
- `role`: `peer` or `hub`
- `name`: display name
- `kind`: device kind

The current implementation parses the service name first so discovery does not depend on platform-specific TXT parsing.

## Control Messages

All control messages use `LANEnvelope`:

```json
{
  "protocolVersion": "dt-lan-1",
  "messageID": "UUID",
  "type": "hello",
  "senderID": "UUID",
  "sentAt": "ISO-8601 date",
  "payload": {}
}
```

Initial message types:

- `hello`
- `joinHub`
- `leaveHub`
- `hubSnapshot`
- `uploadIntent`
- `uploadAccepted`
- `uploadRejected`
- `fileViewed`
- `fileDeleted`

## One-Time File Rule

For a one-time file:

1. Sender chooses `visibleToDeviceIDs`.
2. Diamond Cloud only shows the file to those devices and the sender's own sent state.
3. A target device sends `fileViewed` when opening it.
4. Diamond Cloud deletes the file when every device in `visibleToDeviceIDs` has viewed it.
5. Devices that join Diamond Cloud later are not automatically added to the target set.

This is a Diamond Cloud retention rule, not DRM. It does not claim to prevent screenshots, external recording, or copying after viewing.
