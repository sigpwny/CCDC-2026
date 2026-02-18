# CCDC-2026

Ideas:
- EDR install scripts
    - includes both Elastic and Wazuh
    - need one for linux and windows
- AD password rotation
    - Should exclude machine accounts and krbtgt by default
    - Should upload securely to a remote (like scuffedsrv)
- Backup access
    - This way we can log in even if AD goes down
    - Maybe install openSSH server and set up pubkey authentication on all the windows boxes? Could have a second local admin account for this purpose
- Script to bring up host firewall
    - This is to block all inbound while we do setup or disaster recovery
    - Should have one for Windows (netsh) and linux (iptables?)
- Run nmap from external to determine exposure
    - Can have this auto-parse (-oX XML) to see if we have an overly exposed attack surface compared to the essentials
    - Maybe run this on a cron? Where to put it? What subnets to scan? One per subnet?
- File integrity monitoring script
    - To save time on the inject
- Beacon hunter
    - This one is really important, maybe spool output via scheduled task like hollow hunter
- Unfucker (TM)
    - Restores GPOs and registry keys that destroy Windows Defender / Firewall / Updates
- Site Backups
    - Should we back up websites? FTP configs? Anything we missed?