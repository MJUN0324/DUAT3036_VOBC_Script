# DUAT3036_VOBC_Script

# CBTC Railway Maintenance Tools

A collection of PowerShell scripts designed to support railway maintenance and troubleshooting activities for CBTC (Communication-Based Train Control) equipment. The tools assist with MRU configuration, locomotive Ethernet configuration, network connectivity testing, and VOBC syslog collection.

## Repository Structure

```text
.
├── MRU/
│   └── MRU_Deployment_Tool.ps1
│
├── VOBC/
│   ├── Loco
│       ├── IP_Loco_Configuration.ps1
│       └── Loco_Ping_Test.ps1
│   ├── PassengerTrain
│       ├── IP_Configuration.ps1
│       └── PassengerTrain_Ping_Test.ps1
│   └──summary_ping.bat
│
├── Syslog/
│   └── Get_VOBC_Syslog_Tool.ps1
│
└── README.md
```

## Tools and Features

### 1. MRU

**Script:** `MRU/MRU_Deployment_Tool.ps1`

Extracts certificates from the MRU (Mobile Radio Unit) and configures the MRU for deployment.

**Key functions:**
- Extract MRU certificates.
- Configure MRU settings for deployment.

### 2. VOBC / Loco

Tools for configuring network settings and verifying connectivity between locomotive equipment.

#### IP Loco Configuration

**Script:** `VOBC/Loco/IP_Loco_Configuration.ps1`

Configures the FLMD Ethernet IPv4 settings.

**Key functions:**
- Configure Ethernet IPv4 settings for FLMD.
- Apply the required network configuration.

#### Loco Ping Test

**Script:** `VOBC/Loco/Loco_Ping_Test.ps1`

Tests network connectivity between the Loco MRU and CBTC equipment.

**Key functions:**
- Ping each CBTC equipment endpoint from the Loco MRU.
- Check network reachability.
- Assist with network connectivity troubleshooting.

### 3. VOBC / PassengerTrain

Tools for configuring network settings and verifying connectivity between passenger train equipment.

#### Passenger Train IP Configuration

**Script:** `VOBC/PassengerTrain/IP_Configuration.ps1`

Configures the FLMD Ethernet IPv4 settings.

**Key functions:**
- Configure Ethernet IPv4 settings for FLMD.
- Apply the required network configuration.

#### Passenger Train Ping Test

**Script:** `VOBC/PassengerTrain/PassengerTrain_Ping_Test.ps1`

Tests network connectivity between the Passenger Train Network Switches and CBTC equipment.

**Key functions:**
- Ping each CBTC equipment endpoint from the Passenger Train Network Switch 1 and Network Switch 2.
- Check network reachability.
- Assist with network connectivity troubleshooting.

### 4. Syslog

#### Get VOBC Syslog Tool

**Script:** `Syslog/Get_VOBC_Syslog_Tool.ps1`

Collects syslog files from VOBC (Vehicle On-Board Controller) equipment.

**Key functions:**
- Retrieve syslog files from VOBC equipment.
- Gather logs for fault investigation and troubleshooting.

## Requirements

- Windows operating system.
- Windows PowerShell compatible with the individual scripts.
- Appropriate permissions to access and configure the target railway equipment.
- Network connectivity to the relevant equipment, where required.

Additional dependencies, configuration files, and access requirements may vary by script.

## Usage

1. Clone or download this repository to the designated workstation.
2. Open PowerShell with the appropriate permissions.
3. Navigate to the relevant script directory.
4. Review the script and configure any required parameters or equipment-specific settings.
5. Execute the script according to its implementation and operational instructions.

Example:

```powershell
cd .\MRU
.\MRU_Deployment_Tool.ps1
```

Refer to each script's parameters and implementation for specific execution instructions.

## Operational Notes

- Verify equipment identifiers, IP addresses, and configuration parameters before execution.
- Ensure that the correct target equipment is selected before applying configuration changes.
- Follow applicable railway maintenance procedures and authorization requirements.
- Back up relevant configuration files and certificates before making changes, where applicable.
- Handle certificates, configuration data, and syslog files according to applicable security requirements.

## Disclaimer

These tools are intended to support authorized railway equipment configuration, maintenance, and troubleshooting. Always validate the target equipment and follow the relevant operational procedures before running any script.

