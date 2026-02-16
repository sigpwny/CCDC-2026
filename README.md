# MWCCDC / MACCDC / RMCCDC Defender Toolkit
A collection of Ansible scripts for setting up comprehensive monitoring and Splunk for all regions using the midwest environment during the Collegiate Cyber Defense Competition, courtesy of red team. If you find this helpful and would like to show your support, give this a star and buy John a drink during regionals.

## Deployment
1. Install Ansible and required collections
```bash
sudo apt install python3-pip
pipx ensurepath
pipx install ansible
pipx inject ansible pywinrm
ansible-galaxy collection install ansible.windows community.windows
```
3. Modify IP addresses and credentials in your [hosts file](inventory/testing/hosts) as necessary
   - For simplicity sake, these scripts do not use a vault to store credentials, since these are already disclosed in the team packet.
5. Validate connectivity to hosts
```bash
ansible linux -m ping
ansible windows -m win_ping
```
6. Run the main playbook
```bash
ansible-playbook main.yml
```

## Recommended Strategy
1. Create alerts for stopping scored services
2. Create alerts for changes to files required by scored services
3. Create dashboards and visualizations to assist you with threat hunting
  - Given a process ID, can you get a full process tree? Can you see what other processes were created by that one?

### Planned Improvements
- Ingest Palo Alto, Cisco FTP, and VyOS logs
- Using the Splunk Stream add-on, collect network events
  - Replace current DNS logging with this, since the logs aren't properly parsed

## What You Get
All of the following data will be forwarded and available for you to view in Splunk.

There are three indexes you'll have access to:
- linux - everything related to Linux hosts
- windows - everything related to Windows hosts
- services - everything related to scored services

### Linux
_See [linux-inputs.conf](files/linux-inputs.conf)_

#### Security Enhancements
- process creation (execve) logging with audit
- folder auditing with audit - see [Monitored Directories](#Monitored%20Directories)

#### Collected Logs
Core OS logs
- /var/log/auth.log
- /var/log/secure
- /var/log/messages
- /var/log/syslog
- /var/log/kern.log

Package manager logs
- /var/log/yum.log
- /var/log/apt/history.log

Security and firewall logs
- /var/log/audit.log
- /var/log/ufw.log
- /var/log/firewalld

### Windows
_See [windows-inputs.conf](files/linux-inputs.conf)_

#### Security Enhancements
- process creation logging
- PowerShell logging
- network logon auditing
- lateral movement (WinRM and WMI) logging
- scheduled task logging
- sensitive registry key access auditing
```
HKLM:\SAM
HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\JD
HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\Skew1
HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\GBG
HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\Data
```
- DNS logging, both in log file and Microsoft-Windows-DNSServer/Analytical channel
- folder auditing - see [Monitored Directories](#Monitored%20Directories)

#### Collected Logs
Standard Event Logs
- System
- Security
- Application

Security and firewall logs
- Microsoft-Windows-Sysmon/Operational
  - Sysmon is not installed, but if you choose to install and configure it, logs will be sent and properly parsed in Splunk.
- Microsoft-Windows-Windows Defender/Operational

PowerShell logs
- Microsoft-Windows-PowerShell/Operational

Scheduled task logs
- Microsoft-Windows-TaskScheduler/Operational

Additional lateral movement (SMB, WinRM, WMI) logs
- Microsoft-Windows-SMBServer/Operational
- Microsoft-Windows-WinRM/Operational
- Microsoft-Windows-WMI-Activity/Operational

### Services

#### Monitored Directories
View these in the linux and windows indexes, _not_ in the security index
- Web: C:\inetpub\wwwroot
- FTP: C:\FTPSITE
- E-commerce: /var/www/html/opencart/upload

#### Collected Logs
DNS logs
- C:\Windows\System32\dns\dns*.log

Web logs
- C:\inetpub\logs\LogFiles\W3SVC*\*.log

FTP logs
- C:\inetpub\logs\LogFiles\FTPSVC*\*.log

E-commerce (OpenCart) logs
- /var/log/apache2/access.log
- /var/log/apache2/error.log
- /var/log/apache2/opencart-access-log
- /var/log/apache2/opencart-error-log
- /var/log/mysql/error.log

SMTP and POP3 logs
- /var/log/maillog

Splunk logs
- /opt/splunk/var/log/splunk/splunkd_ui_access.log
- also consider checking other logs provided in the _internal index
