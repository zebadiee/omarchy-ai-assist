[Unit]
Description=<<NAME>>
After=network-online.target

[Service]
Type=simple
User=<<USER>>
Group=<<GROUP>>
WorkingDirectory=<<WORKDIR>>
ExecStart=<<BINARY>> <<ARGS>>
Restart=on-failure
RestartSec=2

# Hardening
NoNewPrivileges=yes
PrivateTmp=yes
ProtectSystem=strict
ProtectHome=true
PrivateDevices=yes
RestrictSUIDSGID=yes
MemoryDenyWriteExecute=yes
ReadWritePaths=<<WRITE_DIRS>>
ProtectKernelTunables=yes
ProtectKernelModules=yes
ProtectControlGroups=yes
RestrictNamespaces=yes
LockPersonality=yes
RestrictRealtime=yes
IPAddressDeny=any
CapabilityBoundingSet=
AmbientCapabilities=
SystemCallFilter=@system-service @resources @basic-io
UMask=027
# Drop privileges if root is unavoidable:
User=<<USER>>
Group=<<GROUP>>

[Install]
WantedBy=default.target