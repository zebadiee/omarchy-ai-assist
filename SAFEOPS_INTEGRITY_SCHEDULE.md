# SafeOps Weekly Integrity Self-Test

## Schedule
**Frequency:** Weekly (cron: 0 2 * * 0 - Sunday 2AM)

## Test Suite
```bash
#!/bin/bash
# /usr/local/bin/safeops-weekly-check.sh
DATE=$(date +%Y%m%d)
LOG="/var/log/safeops-weekly-$DATE.log"

echo "=== SafeOps Weekly Integrity Check - $DATE ===" | tee $LOG

echo "1. Testing rm -rf / block..." | tee -a $LOG
printf '#!/usr/bin/env bash\nrm -rf /\n' > /tmp/bad.sh && chmod +x /tmp/bad.sh
if ./tools/safe_run.sh /tmp/bad.sh 2>/dev/null; then
  echo "❌ FAIL: rm -rf / not blocked" | tee -a $LOG
else
  echo "✅ OK: rm -rf / blocked" | tee -a $LOG
fi
rm -f /tmp/bad.sh

echo "2. Testing secret guard..." | tee -a $LOG
echo "-----BEGIN OPENSSH PRIVATE KEY-----" > bad.key 2>/dev/null
if git add bad.key 2>/dev/null && git commit -m "test secret" 2>/dev/null; then
  echo "❌ FAIL: secret commit not blocked" | tee -a $LOG
  git reset HEAD bad.key 2>/dev/null || true
else
  echo "✅ OK: secret commit blocked" | tee -a $LOG
fi
rm -f bad.key

echo "3. Status dashboard..." | tee -a $LOG
safeops-status | tee -a $LOG

echo "=== Weekly Check Complete ===" | tee -a $LOG

# Email results (optional)
# cat $LOG | mail -s "SafeOps Weekly Check $DATE" admin@example.com
```

## Installation
```bash
# Install weekly check
sudo cp SAFEOPS_INTEGRITY_SCHEDULE.md /usr/local/bin/safeops-weekly-check.sh
sudo chmod +x /usr/local/bin/safeops-weekly-check.sh
sudo crontab -l | { cat; echo "0 2 * * 0 /usr/local/bin/safeops-weekly-check.sh"; } | sudo crontab -
```

## Results Archive
- Latest: `/var/log/safeops-weekly-$(date +%Y%m%d).log`
- History: `/var/log/safeops-weekly-*.log`
- Alert on any ❌ FAIL results
