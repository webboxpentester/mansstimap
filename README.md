# mansstimap
# SSTI Manager - Advanced SSTI Detection & Exploitation Framework

A comprehensive Server-Side Template Injection (SSTI) management tool for Termux and Linux. Automate your SSTI testing with multiple scan modes, custom payloads, and intelligent detection.

## 🎯 Features
- **8 Scan Modes** (Fast, Deep, Aggressive, Nuclear, OS Command, File Read, Custom, Batch)
- **Multi-Engine Detection** (Jinja2, Twig, Freemarker, Velocity, Smarty, and more)
- **Automatic Exploitation** - OS command execution & file read capabilities
- **Batch Scanning** - Test multiple URLs from a file
- **Multiple Output Formats** - Text, JSON, or Both
- **Proxy Support** - Use Burp Suite, OWASP ZAP, or custom proxies
- **Random User-Agent** - Avoid detection
- **Request Delays** - Be gentle on target servers

## 🚀 Quick Start
```bash
git clone https://github.com/yourusername/ssti-manager
cd ssti-manager
chmod +x sstimap_advanced.sh
./sstimap_advanced.sh
