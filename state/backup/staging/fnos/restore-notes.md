# fnOS Restore Notes

Generated: 2026-05-15T21:45:13+08:00
Source root: /opt/fnos-media

Contents in this directory are intended for configuration-level recovery of fnOS-hosted services.
Included:
- manifests/
- bin/
- reports/
- selected service config trees: media-stack, docker-stack, easytier, openclaw-governance, openclaw-channels
- high-value local state: hermes-openwebui/data, cliproxyapi/auths, cliproxyapi/config.yaml, channels/*, fnos-media-stack/
- homarr anonymous appdata volume when HOMARR_APPDATA_SOURCE is provided
- minimal OpenClaw runtime config files only

Excluded from this backup:
- backup archives
- logs
- large media/download payloads already stored on NAS
- caches and temporary files not needed for rebuild
- OpenClaw workspace trees already backed up separately
