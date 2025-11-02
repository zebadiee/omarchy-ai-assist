# Systemd Service Units Configuration

## Service Unit Structure

Systemd service units define how services are managed by the system. A basic service file has three main sections:

```ini
[Unit]
Description=My Custom Service
After=network.target
Wants=network.target

[Service]
Type=simple
ExecStart=/usr/bin/my-service
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

## Unit Section Configuration

The [Unit] section contains metadata about the service:

```ini
[Unit]
Description=Web Application Server
Documentation=https://docs.example.com
After=network.target network-online.target
Wants=network-online.target
Requires=mysql.service
OnFailure=notify-failure@%n.service
```

### Common Unit Directives

- `Description=`: Human-readable description
- `Documentation=`: URLs to documentation
- `Requires=`: Dependencies that must be running
- `Wants=`: Dependencies that should be running (not required)
- `After=`: Start order (start after these units)
- `Before=`: Start order (start before these units)
- `OnFailure=`: Action to take on failure

## Service Section Configuration

The [Service] section defines how the service runs:

### Service Types

```ini
# Simple service (main process is the service)
[Service]
Type=simple
ExecStart=/usr/bin/nginx -g 'daemon off;'

# Forking service (creates child process)
[Service]
Type=forking
ExecStart=/usr/sbin/sshd -D $OPTIONS
PIDFile=/run/sshd.pid

# One-shot service (does a single task and exits)
[Service]
Type=oneshot
ExecStart=/usr/local/bin/backup-database
RemainAfterExit=yes

# DBus service (activates when DBus requests it)
[Service]
Type=dbus
BusName=org.example.MyService
ExecStart=/usr/bin/my-dbus-service
```

### Service Lifecycle Management

```ini
[Service]
# Restart configuration
Restart=always
RestartSec=10
StartLimitInterval=60
StartLimitBurst=3

# Timeouts
TimeoutStartSec=90
TimeoutStopSec=30
TimeoutSec=300

# Resource limits
MemoryMax=512M
TasksMax=100
CPUQuota=50%
```

### Security Hardening

```ini
[Service]
# Basic sandboxing
PrivateTmp=yes
ProtectSystem=strict
ProtectHome=yes
NoNewPrivileges=yes
ProtectKernelTunables=yes
ProtectKernelModules=yes
ProtectControlGroups=yes

# File system protection
ReadWritePaths=/var/lib/myapp /var/log/myapp
ReadOnlyPaths=/etc/myapp
InaccessiblePaths=/root /home

# Network restrictions
PrivateNetwork=yes
IPAddressDeny=any
IPAddressAllow=localhost
```

## User and Group Management

```ini
[Service]
# Run as specific user
User=myapp
Group=myapp

# Supplemental groups
SupplementaryGroups=audio video

# Environment variables
Environment=NODE_ENV=production
EnvironmentFile=/etc/myapp/environment
Environment=PORT=8080
Environment=HOST=0.0.0.0
```

## Working Directory and Pre/Post Commands

```ini
[Service]
WorkingDirectory=/opt/myapp

# Pre-start commands
ExecStartPre=/usr/bin/mkdir -p /var/log/myapp
ExecStartPre=/usr/bin/chown myapp:myapp /var/log/myapp

# Post-start commands
ExecStartPost=/usr/bin/logger "Service started successfully"

# Pre-stop commands
ExecStopPost=/usr/bin/logger "Service stopped"
```

## Install Section

The [Install] section defines how the service is enabled:

```ini
[Install]
# Start in multi-user mode
WantedBy=multi-user.target

# Start in graphical mode
WantedBy=graphical.target

# Required by other units
RequiredBy=other-service.target

# Optional dependency
WantedBy=some-other.service
```

## Example: Web Application Service

```ini
[Unit]
Description=My Web Application
After=network.target mysql.service
Wants=mysql.service

[Service]
Type=simple
User=webapp
Group=webapp
WorkingDirectory=/opt/webapp

# Environment
Environment=NODE_ENV=production
Environment=PORT=3000
EnvironmentFile=/opt/webapp/.env

# Execution
ExecStart=/usr/bin/node server.js
ExecReload=/bin/kill -HUP $MAINPID
Restart=always
RestartSec=10

# Security
PrivateTmp=yes
ProtectSystem=strict
NoNewPrivileges=yes
ReadWritePaths=/opt/webapp/logs

# Resource limits
MemoryMax=1G
CPUQuota=80%

[Install]
WantedBy=multi-user.target
```

## Example: Database Service

```ini
[Unit]
Description=MySQL Database Server
After=network.target
Documentation=man:mysqld(8)
Documentation=https://dev.mysql.com/doc/refman/en/

[Service]
Type=notify
User=mysql
Group=mysql

# Configuration
ExecStartPre=/usr/bin/mysqld_pre_systemd
ExecStart=/usr/sbin/mysqld
ExecStartPost=/usr/bin/mysqld_post_systemd
LimitNOFILE=infinity

# Security
PrivateTmp=yes
ProtectSystem=strict
ProtectHome=yes
NoNewPrivileges=yes

# File system
ReadWritePaths=/var/lib/mysql /var/log/mysql
ReadOnlyPaths=/etc/mysql

[Install]
WantedBy=multi-user.target
```

## Example: Background Worker Service

```ini
[Unit]
Description=Background Task Worker
After=network.target redis.service
Wants=redis.service

[Service]
Type=simple
User=worker
Group=worker
WorkingDirectory=/opt/worker

# Environment
Environment=QUEUE=default
Environment=CONCURRENCY=4
EnvironmentFile=/opt/worker/.env

# Execution with supervisor
ExecStart=/usr/bin/supervisord -c /opt/worker/supervisord.conf
ExecStop=/usr/bin/supervisorctl shutdown
Restart=always
RestartSec=5

# Resource limits
MemoryMax=512M
TasksMax=50
CPUQuota=50%

# Security
PrivateTmp=yes
ProtectSystem=strict
NoNewPrivileges=yes
ReadWritePaths=/opt/worker/tmp /var/log/worker

[Install]
WantedBy=multi-user.target
```

## Timer Service Configuration

Timer units replace cron for scheduled tasks:

```ini
[Unit]
Description=Daily Backup Service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/backup-database
User=backup
Group=backup

[Install]
WantedBy=multi-user.target
```

Corresponding timer unit:

```ini
[Unit]
Description=Run backup daily
Requires=backup.service

[Timer]
OnCalendar=daily
Persistent=true
AccuracySec=1h

[Install]
WantedBy=timers.target
```

## Socket-Activated Services

Socket activation starts services only when needed:

```ini
[Unit]
Description=My Socket Service

[Service]
Type=notify
ExecStart=/usr/bin/my-service
StandardInput=socket
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

Corresponding socket unit:

```ini
[Unit]
Description=My Service Socket

[Socket]
ListenStream=8080
Accept=yes
Service=my-service.service

[Install]
WantedBy=sockets.target
```

## Service Dependencies and Ordering

Understanding service relationships:

```ini
[Unit]
# Strong dependency (must succeed)
Requires=database.service
After=database.service

# Weak dependency (best effort)
Wants=cache.service
After=cache.service

# Reverse dependency
Before=shutdown.target

# Conditional requirements
BindTo=network.target
Requires=network-online.target
After=network-online.target

# Part of a target
PartOf=multi-user.target
```

## Resource Management

### Memory Limits

```ini
[Service]
MemoryMax=2G
MemoryHigh=1.5G
MemorySwapMax=0
MemoryLimit=1G
```

### CPU Limits

```ini
[Service]
CPUQuota=50%
CPUQuotaPeriodSec=10ms
CPUSchedulingPolicy=idle
Nice=10
```

### I/O Limits

```ini
[Service]
IOReadBandwidthMax=/dev/sda 10M
IOWriteBandwidthMax=/dev/sda 5M
IOSchedulingClass=best-effort
IOSchedulingPriority=4
```

## Troubleshooting Services

### Common Service Issues

1. **Service fails to start**: Check logs with `journalctl -u service-name`
2. **Permission denied**: Verify user/group and file permissions
3. **Port already in use**: Check with `ss -tlnp | grep port`
4. **Missing dependencies**: Verify required services are running

### Debugging Commands

```bash
# Check service status
systemctl status my-service

# View service logs
journalctl -u my-service -f

# Check service configuration
systemd-analyze verify my-service.service

# Test service start
systemd-run --unit=test-service /path/to/command

# Check dependencies
systemctl list-dependencies my-service
```

### Service Performance Monitoring

```bash
# Resource usage
systemctl status my-service
systemd-cgtop

# Performance metrics
systemctl show my-service -p CPUUsageNSec,MemoryCurrent,TasksCurrent

# Service limits
systemctl show my-service -p MemoryLimit,CPUQuota
```

## Best Practices

1. **Security First**: Always use sandboxing and least privilege
2. **Resource Limits**: Set appropriate memory and CPU limits
3. **Dependencies**: Clearly define required vs optional dependencies
4. **Restart Strategy**: Configure appropriate restart policies
5. **Logging**: Ensure proper log configuration and rotation
6. **Documentation**: Include meaningful descriptions and documentation links
7. **Testing**: Always test service units before deploying to production
