# CTI Platform User Guide

This guide provides instructions for using the CTI (Cyber Threat Intelligence) platform.

## Overview

The CTI platform integrates multiple tools to provide a comprehensive environment for threat intelligence, incident response, and threat hunting:

- **TheHive**: Security incident response platform
- **Cortex**: Observable analysis engine
- **GRR**: Live forensics and incident response framework
- **Kasm Workspaces**: Browser isolation and virtual desktop environment

## Accessing the Platform

Each component of the CTI platform can be accessed through its web interface:

- TheHive: http://localhost:9000
- Cortex: http://localhost:9001
- GRR: http://localhost:8001
- Kasm Workspaces: https://localhost:443
- Portainer: http://localhost:9000

## Using TheHive

TheHive is the central incident response platform where you can create and manage cases, tasks, and observables.

### Creating a Case

1. Log in to TheHive
2. Click on "New Case" in the top right corner
3. Fill in the case details:
   - Title: A descriptive title for the case
   - TLP: Traffic Light Protocol level (e.g., TLP:AMBER)
   - Severity: The severity of the case
   - Tags: Relevant tags for categorization
4. Click "Create" to create the case

### Adding Observables

1. Open a case
2. Click on the "Observables" tab
3. Click "Add Observable"
4. Select the observable type (e.g., IP, domain, file hash)
5. Enter the observable value
6. Add any relevant tags
7. Click "Add" to add the observable to the case

### Analyzing Observables with Cortex

1. Open a case
2. Go to the "Observables" tab
3. Select one or more observables
4. Click "Run Analyzers"
5. Select the analyzers you want to run
6. Click "Run Selected Analyzers"
7. Wait for the analysis to complete
8. Click on the analysis results to view the details

### Creating Tasks

1. Open a case
2. Go to the "Tasks" tab
3. Click "Add Task"
4. Enter a title and description for the task
5. Assign the task to a user
6. Set a deadline if needed
7. Click "Add" to create the task

## Using GRR

GRR is used for remote live forensics and incident response.

### Deploying GRR Clients

1. Log in to GRR
2. Click on "Manage Binaries"
3. Download the appropriate client installer for your endpoints
4. Deploy the client to your endpoints using your preferred method

### Collecting Data from Endpoints

1. Log in to GRR
2. Search for a client by hostname or IP
3. Click on the client to open its details
4. Click on "Start New Flows"
5. Select the type of data you want to collect (e.g., "File Finder", "Memory Analysis")
6. Configure the flow parameters
7. Click "Launch" to start the collection

### Analyzing Collected Data

1. Open a client
2. Click on "Manage Flows"
3. Find the completed flow
4. Click on the flow to view the results
5. Export the results if needed for further analysis

## Using Kasm Workspaces

Kasm Workspaces provides isolated browser and desktop environments for secure threat hunting and analysis.

### Accessing Workspaces

1. Log in to Kasm Workspaces
2. Select a workspace from the available options:
   - Threat Hunting Workspace
   - Malware Analysis Workspace
   - OSINT Investigation Workspace
3. Click on the workspace to launch it

### Threat Hunting Workspace

The Threat Hunting workspace includes:

- Multiple browsers for secure browsing
- OSINT tools (Shodan, Censys, etc.)
- Integration with TheHive and Cortex
- Analysis utilities

### Malware Analysis Workspace

The Malware Analysis workspace includes:

- Sandboxed environment for malware analysis
- Reverse engineering tools (Ghidra, radare2)
- Static and dynamic analysis tools
- Integration with VirusTotal and other services

### OSINT Investigation Workspace

The OSINT workspace includes:

- Multiple browsers including Tor
- OSINT tools (SpiderFoot, Maltego, etc.)
- Social media investigation tools
- Data collection and analysis utilities

## Workflow Examples

### Incident Response Workflow

1. Receive an alert or report of a potential security incident
2. Create a new case in TheHive with the initial information
3. Add observables (e.g., suspicious IPs, domains, file hashes)
4. Analyze observables using Cortex
5. Use GRR to collect evidence from affected endpoints
6. Create and assign tasks to team members
7. Document findings and actions in the case
8. Document and share threat intelligence internally
9. Close the case when resolved

### Threat Hunting Workflow

1. Launch the Threat Hunting workspace in Kasm
2. Research current threats and TTPs
3. Develop hunting hypotheses
4. Use GRR to search for indicators across endpoints
5. Analyze findings and collect evidence
6. If a threat is found, create a case in TheHive
7. Document the hunting process and results
8. Share findings with the team

## Tips and Best Practices

- **Regular Updates**: Keep all platform components updated using the update script
- **Backup Data**: Regularly backup your data using the backup script
- **Documentation**: Document all cases, events, and findings thoroughly
- **Collaboration**: Use TheHive's collaboration features to work effectively as a team
- **Automation**: Use the API to automate repetitive tasks
- **Security**: Always use the isolated Kasm workspaces for analyzing suspicious content
- **Training**: Regularly train team members on using the platform effectively
