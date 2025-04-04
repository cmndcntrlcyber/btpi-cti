# CTI Platform API Examples

This guide provides examples of using the APIs of the various CTI platform components.

## Overview

The CTI platform components expose APIs that can be used for automation, integration, and extending functionality:

- **TheHive API**: For managing cases, tasks, observables, and alerts
- **Cortex API**: For submitting observables for analysis and retrieving results
- **MISP API**: For managing events, attributes, and tags
- **GRR API**: For managing clients, flows, and hunts

## Authentication

### TheHive Authentication

TheHive uses API keys for authentication. To generate an API key:

1. Log in to TheHive
2. Go to your user profile
3. Click "Create API Key"
4. Copy the generated API key

Use the API key in your requests:

```bash
curl -H "Authorization: Bearer YOUR_API_KEY" http://localhost:9000/api/case
```

### Cortex Authentication

Cortex also uses API keys for authentication. To generate an API key:

1. Log in to Cortex
2. Go to "Users"
3. Click on your user
4. Click "Reveal API Key" or "Generate API Key"
5. Copy the generated API key

Use the API key in your requests:

```bash
curl -H "Authorization: Bearer YOUR_API_KEY" http://localhost:9001/api/analyzer
```

### MISP Authentication

MISP uses authentication keys for API access. To find your authentication key:

1. Log in to MISP
2. Go to "Event Actions" > "Automation"
3. Copy your authentication key

Use the authentication key in your requests:

```bash
curl -H "Authorization: YOUR_API_KEY" http://localhost:8080/events
```

### GRR Authentication

GRR uses API tokens for authentication. To generate an API token:

1. Log in to GRR
2. Go to "Settings" > "API Keys"
3. Click "Generate New API Token"
4. Copy the generated token

Use the token in your requests:

```bash
curl -H "Authorization: Bearer YOUR_API_TOKEN" http://localhost:8000/api/clients
```

## TheHive API Examples

### Create a Case

```python
import requests
import json

api_key = "YOUR_API_KEY"
url = "http://localhost:9000/api/case"

headers = {
    "Authorization": f"Bearer {api_key}",
    "Content-Type": "application/json"
}

case_data = {
    "title": "Suspicious Email",
    "description": "User received a suspicious email with attachment",
    "severity": 2,
    "tlp": 2,
    "tags": ["phishing", "email"]
}

response = requests.post(url, headers=headers, data=json.dumps(case_data))
print(response.json())
```

### Add an Observable to a Case

```python
import requests
import json

api_key = "YOUR_API_KEY"
case_id = "CASE_ID"
url = f"http://localhost:9000/api/case/{case_id}/observable"

headers = {
    "Authorization": f"Bearer {api_key}",
    "Content-Type": "application/json"
}

observable_data = {
    "dataType": "mail",
    "data": "suspicious@example.com",
    "message": "Sender of the suspicious email",
    "tlp": 2,
    "ioc": True,
    "tags": ["phishing", "sender"]
}

response = requests.post(url, headers=headers, data=json.dumps(observable_data))
print(response.json())
```

### Create a Task in a Case

```python
import requests
import json

api_key = "YOUR_API_KEY"
case_id = "CASE_ID"
url = f"http://localhost:9000/api/case/{case_id}/task"

headers = {
    "Authorization": f"Bearer {api_key}",
    "Content-Type": "application/json"
}

task_data = {
    "title": "Analyze Email Headers",
    "description": "Extract and analyze email headers to determine origin",
    "status": "Waiting",
    "owner": "analyst@example.com"
}

response = requests.post(url, headers=headers, data=json.dumps(task_data))
print(response.json())
```

### Create an Alert

```python
import requests
import json

api_key = "YOUR_API_KEY"
url = "http://localhost:9000/api/alert"

headers = {
    "Authorization": f"Bearer {api_key}",
    "Content-Type": "application/json"
}

alert_data = {
    "title": "Malware Detected",
    "description": "Malware detected on workstation",
    "type": "malware",
    "source": "EDR",
    "sourceRef": "alert-123",
    "severity": 3,
    "tlp": 2,
    "tags": ["malware", "endpoint"],
    "artifacts": [
        {
            "dataType": "hash",
            "data": "5f2b7f0b75b4b1b9b2c5d5e7f8a9b0c1",
            "message": "MD5 hash of the malware"
        },
        {
            "dataType": "hostname",
            "data": "infected-host",
            "message": "Hostname of the infected machine"
        }
    ]
}

response = requests.post(url, headers=headers, data=json.dumps(alert_data))
print(response.json())
```

### Search for Cases

```python
import requests
import json

api_key = "YOUR_API_KEY"
url = "http://localhost:9000/api/case/_search"

headers = {
    "Authorization": f"Bearer {api_key}",
    "Content-Type": "application/json"
}

search_data = {
    "query": {
        "_string": "tags:phishing"
    },
    "range": "all",
    "sort": [{"_createdAt": "desc"}]
}

response = requests.post(url, headers=headers, data=json.dumps(search_data))
print(response.json())
```

## Cortex API Examples

### List Available Analyzers

```python
import requests

api_key = "YOUR_API_KEY"
url = "http://localhost:9001/api/analyzer"

headers = {
    "Authorization": f"Bearer {api_key}"
}

response = requests.get(url, headers=headers)
print(response.json())
```

### Run an Analyzer on an Observable

```python
import requests
import json

api_key = "YOUR_API_KEY"
url = "http://localhost:9001/api/analyzer/ANALYZER_ID/run"

headers = {
    "Authorization": f"Bearer {api_key}",
    "Content-Type": "application/json"
}

data = {
    "data": "suspicious@example.com",
    "dataType": "mail",
    "tlp": 2,
    "message": "Analyze this email address"
}

response = requests.post(url, headers=headers, data=json.dumps(data))
print(response.json())
```

### Get Analysis Results

```python
import requests

api_key = "YOUR_API_KEY"
job_id = "JOB_ID"
url = f"http://localhost:9001/api/job/{job_id}/report"

headers = {
    "Authorization": f"Bearer {api_key}"
}

response = requests.get(url, headers=headers)
print(response.json())
```

## MISP API Examples

### Create an Event

```python
import requests
import json

api_key = "YOUR_API_KEY"
url = "http://localhost:8080/events"

headers = {
    "Authorization": api_key,
    "Content-Type": "application/json",
    "Accept": "application/json"
}

event_data = {
    "Event": {
        "info": "Phishing Campaign",
        "threat_level_id": 2,
        "analysis": 1,
        "distribution": 0,
        "date": "2023-01-15",
        "published": False,
        "Attribute": [
            {
                "type": "email-src",
                "category": "Payload delivery",
                "value": "malicious@example.com",
                "to_ids": True
            },
            {
                "type": "url",
                "category": "Payload delivery",
                "value": "https://malicious-site.example.com",
                "to_ids": True
            }
        ],
        "Tag": [
            {"name": "phishing"},
            {"name": "tlp:amber"}
        ]
    }
}

response = requests.post(url, headers=headers, data=json.dumps(event_data))
print(response.json())
```

### Add an Attribute to an Event

```python
import requests
import json

api_key = "YOUR_API_KEY"
event_id = "EVENT_ID"
url = f"http://localhost:8080/attributes/add/{event_id}"

headers = {
    "Authorization": api_key,
    "Content-Type": "application/json",
    "Accept": "application/json"
}

attribute_data = {
    "Attribute": {
        "type": "ip-dst",
        "category": "Network activity",
        "value": "192.168.1.1",
        "to_ids": True,
        "comment": "C2 server IP address"
    }
}

response = requests.post(url, headers=headers, data=json.dumps(attribute_data))
print(response.json())
```

### Search for Events

```python
import requests
import json

api_key = "YOUR_API_KEY"
url = "http://localhost:8080/events/restSearch"

headers = {
    "Authorization": api_key,
    "Content-Type": "application/json",
    "Accept": "application/json"
}

search_data = {
    "returnFormat": "json",
    "tags": ["phishing"],
    "limit": 10,
    "page": 1
}

response = requests.post(url, headers=headers, data=json.dumps(search_data))
print(response.json())
```

## GRR API Examples

### List Clients

```python
import requests

api_token = "YOUR_API_TOKEN"
url = "http://localhost:8000/api/clients"

headers = {
    "Authorization": f"Bearer {api_token}"
}

response = requests.get(url, headers=headers)
print(response.json())
```

### Start a Flow on a Client

```python
import requests
import json

api_token = "YOUR_API_TOKEN"
client_id = "CLIENT_ID"
url = f"http://localhost:8000/api/clients/{client_id}/flows"

headers = {
    "Authorization": f"Bearer {api_token}",
    "Content-Type": "application/json"
}

flow_data = {
    "flow": {
        "name": "FileFinder",
        "args": {
            "paths": ["/etc/passwd", "/etc/shadow"],
            "action": "DOWNLOAD"
        }
    }
}

response = requests.post(url, headers=headers, data=json.dumps(flow_data))
print(response.json())
```

### Get Flow Results

```python
import requests

api_token = "YOUR_API_TOKEN"
client_id = "CLIENT_ID"
flow_id = "FLOW_ID"
url = f"http://localhost:8000/api/clients/{client_id}/flows/{flow_id}/results"

headers = {
    "Authorization": f"Bearer {api_token}"
}

response = requests.get(url, headers=headers)
print(response.json())
```

## Integration Examples

### TheHive to MISP Integration

This example shows how to export a case from TheHive to MISP:

```python
import requests
import json

# TheHive API details
thehive_api_key = "YOUR_THEHIVE_API_KEY"
thehive_url = "http://localhost:9000"
case_id = "CASE_ID"

# MISP API details
misp_api_key = "YOUR_MISP_API_KEY"
misp_url = "http://localhost:8080"

# Get case details from TheHive
thehive_headers = {
    "Authorization": f"Bearer {thehive_api_key}",
    "Content-Type": "application/json"
}

case_response = requests.get(f"{thehive_url}/api/case/{case_id}", headers=thehive_headers)
case_data = case_response.json()

# Get observables from the case
observables_response = requests.get(f"{thehive_url}/api/case/{case_id}/observable", headers=thehive_headers)
observables_data = observables_response.json()

# Create event in MISP
misp_headers = {
    "Authorization": misp_api_key,
    "Content-Type": "application/json",
    "Accept": "application/json"
}

# Convert TheHive case to MISP event
misp_event = {
    "Event": {
        "info": case_data["title"],
        "threat_level_id": case_data["severity"],
        "analysis": 1,
        "distribution": 0,
        "date": case_data["createdAt"].split("T")[0],
        "published": False,
        "Attribute": [],
        "Tag": []
    }
}

# Add tags from TheHive case
for tag in case_data.get("tags", []):
    misp_event["Event"]["Tag"].append({"name": tag})

# Add TLP tag
tlp_map = {0: "tlp:white", 1: "tlp:green", 2: "tlp:amber", 3: "tlp:red"}
misp_event["Event"]["Tag"].append({"name": tlp_map.get(case_data.get("tlp", 2), "tlp:amber")})

# Convert TheHive observables to MISP attributes
for observable in observables_data:
    # Map TheHive dataType to MISP type and category
    misp_type = "other"
    misp_category = "Other"
    
    if observable["dataType"] == "ip":
        misp_type = "ip-dst"
        misp_category = "Network activity"
    elif observable["dataType"] == "domain":
        misp_type = "domain"
        misp_category = "Network activity"
    elif observable["dataType"] == "url":
        misp_type = "url"
        misp_category = "Network activity"
    elif observable["dataType"] == "mail":
        misp_type = "email-src"
        misp_category = "Payload delivery"
    elif observable["dataType"] == "hash":
        if len(observable["data"]) == 32:
            misp_type = "md5"
        elif len(observable["data"]) == 40:
            misp_type = "sha1"
        elif len(observable["data"]) == 64:
            misp_type = "sha256"
        misp_category = "Artifacts dropped"
    
    # Create MISP attribute
    attribute = {
        "type": misp_type,
        "category": misp_category,
        "value": observable["data"],
        "to_ids": observable.get("ioc", False),
        "comment": observable.get("message", "")
    }
    
    misp_event["Event"]["Attribute"].append(attribute)

# Create the event in MISP
event_response = requests.post(f"{misp_url}/events", headers=misp_headers, data=json.dumps(misp_event))
print(event_response.json())
```

### GRR to TheHive Integration

This example shows how to send GRR findings to TheHive as an alert:

```python
import requests
import json
from datetime import datetime

# GRR API details
grr_api_token = "YOUR_GRR_API_TOKEN"
grr_url = "http://localhost:8000"
client_id = "CLIENT_ID"
flow_id = "FLOW_ID"

# TheHive API details
thehive_api_key = "YOUR_THEHIVE_API_KEY"
thehive_url = "http://localhost:9000"

# Get flow results from GRR
grr_headers = {
    "Authorization": f"Bearer {grr_api_token}"
}

results_response = requests.get(f"{grr_url}/api/clients/{client_id}/flows/{flow_id}/results", headers=grr_headers)
results_data = results_response.json()

# Get client details from GRR
client_response = requests.get(f"{grr_url}/api/clients/{client_id}", headers=grr_headers)
client_data = client_response.json()

# Create alert in TheHive
thehive_headers = {
    "Authorization": f"Bearer {thehive_api_key}",
    "Content-Type": "application/json"
}

# Convert GRR results to TheHive alert
alert_data = {
    "title": f"GRR Finding: {results_data.get('flow', {}).get('name', 'Unknown')}",
    "description": f"Results from GRR flow {flow_id} on client {client_id}",
    "type": "grr",
    "source": "GRR",
    "sourceRef": f"grr-{flow_id}",
    "severity": 2,
    "tlp": 2,
    "tags": ["grr", "automated"],
    "artifacts": []
}

# Add client information
alert_data["artifacts"].append({
    "dataType": "hostname",
    "data": client_data.get("hostname", "unknown"),
    "message": "Client hostname"
})

alert_data["artifacts"].append({
    "dataType": "ip",
    "data": client_data.get("last_ip", "0.0.0.0"),
    "message": "Client IP address"
})

# Add flow results as artifacts
for result in results_data.get("items", []):
    # This is a simplified example - you would need to parse the actual results
    # based on the flow type and structure
    
    if "stat" in result:
        # File finder result
        alert_data["artifacts"].append({
            "dataType": "file",
            "data": result["stat"]["pathspec"]["path"],
            "message": f"File found: {result['stat']['pathspec']['path']}"
        })
    elif "hash" in result:
        # Hash result
        alert_data["artifacts"].append({
            "dataType": "hash",
            "data": result["hash"]["sha256"],
            "message": f"SHA256 hash of file"
        })

# Create the alert in TheHive
alert_response = requests.post(f"{thehive_url}/api/alert", headers=thehive_headers, data=json.dumps(alert_data))
print(alert_response.json())
```

## Automation Examples

### Scheduled Threat Intelligence Updates

This example shows a script that could be scheduled to run periodically to fetch the latest threat intelligence from MISP and create alerts in TheHive:

```python
import requests
import json
from datetime import datetime, timedelta

# MISP API details
misp_api_key = "YOUR_MISP_API_KEY"
misp_url = "http://localhost:8080"

# TheHive API details
thehive_api_key = "YOUR_THEHIVE_API_KEY"
thehive_url = "http://localhost:9000"

# Get events from MISP that were created or updated in the last 24 hours
misp_headers = {
    "Authorization": misp_api_key,
    "Content-Type": "application/json",
    "Accept": "application/json"
}

yesterday = (datetime.now() - timedelta(days=1)).strftime("%Y-%m-%d")

search_data = {
    "returnFormat": "json",
    "date": yesterday,
    "limit": 100,
    "page": 1
}

events_response = requests.post(f"{misp_url}/events/restSearch", headers=misp_headers, data=json.dumps(search_data))
events_data = events_response.json()

# Create alerts in TheHive for each MISP event
thehive_headers = {
    "Authorization": f"Bearer {thehive_api_key}",
    "Content-Type": "application/json"
}

for event in events_data["response"]:
    # Create alert data
    alert_data = {
        "title": f"MISP Event: {event['Event']['info']}",
        "description": f"New or updated event from MISP: {event['Event']['info']}",
        "type": "misp",
        "source": "MISP",
        "sourceRef": f"misp-{event['Event']['id']}",
        "severity": int(event['Event']['threat_level_id']),
        "tlp": 2,  # Default to TLP:AMBER
        "tags": [],
        "artifacts": []
    }
    
    # Add tags
    for tag in event['Event'].get('Tag', []):
        alert_data["tags"].append(tag['name'])
        
        # Set TLP based on tags
        if tag['name'] == "tlp:white":
            alert_data["tlp"] = 0
        elif tag['name'] == "tlp:green":
            alert_data["tlp"] = 1
        elif tag['name'] == "tlp:amber":
            alert_data["tlp"] = 2
        elif tag['name'] == "tlp:red":
            alert_data["tlp"] = 3
    
    # Add attributes as artifacts
    for attribute in event['Event'].get('Attribute', []):
        # Map MISP types to TheHive dataTypes
        dataType = "other"
        
        if attribute['type'] in ["ip-src", "ip-dst"]:
            dataType = "ip"
        elif attribute['type'] in ["domain", "hostname"]:
            dataType = "domain"
        elif attribute['type'] == "url":
            dataType = "url"
        elif attribute['type'] in ["email-src", "email-dst"]:
            dataType = "mail"
        elif attribute['type'] in ["md5", "sha1", "sha256"]:
            dataType = "hash"
        elif attribute['type'] == "filename":
            dataType = "filename"
        
        # Create artifact
        artifact = {
            "dataType": dataType,
            "data": attribute['value'],
            "message": attribute.get('comment', ''),
            "tags": []
        }
        
        # Add tags from attribute
        for tag in attribute.get('Tag', []):
            artifact["tags"].append(tag['name'])
        
        alert_data["artifacts"].append(artifact)
    
    # Create the alert in TheHive
    alert_response = requests.post(f"{thehive_url}/api/alert", headers=thehive_headers, data=json.dumps(alert_data))
    print(f"Created alert for MISP event {event['Event']['id']}: {alert_response.status_code}")
```

### Automated Response Playbook

This example shows a script that could be triggered when a new alert is created in TheHive to automatically perform initial triage and response actions:

```python
import requests
import json
import time

# TheHive API details
thehive_api_key = "YOUR_THEHIVE_API_KEY"
thehive_url = "http://localhost:9000"

# Cortex API details
cortex_api_key = "YOUR_CORTEX_API_KEY"
cortex_url = "http://localhost:9001"

# GRR API details
grr_api_token = "YOUR_GRR_API_TOKEN"
grr_url = "http://localhost:8000"

# TheHive headers
thehive_headers = {
    "Authorization": f"Bearer {thehive_api_key}",
    "Content-Type": "application/json"
}

# Get new alerts from TheHive
alerts_response = requests.get(f"{thehive_url}/api/alert?range=all&sort=-date", headers=thehive_headers)
alerts_data = alerts_response.json()

# Process each alert
for alert in alerts_data:
    # Skip alerts that have already been imported or are older than 1 hour
    if alert.get("status") == "Imported" or time.time() - alert.get("date", 0)/1000 > 3600:
        continue
    
    print(f"Processing alert: {alert['title']}")
    
    # Create a case from the alert
    case_data = {
        "title": alert["title"],
        "description": alert["description"],
        "severity": alert["severity"],
        "tlp": alert["tlp"],
        "tags": alert["tags"],
        "tasks": [
            {"title": "Initial Triage", "status": "InProgress"},
            {"title": "Collect Evidence", "status": "Waiting"},
            {"title": "Analyze Artifacts", "status": "Waiting"},
            {"title": "Containment Actions", "status": "Waiting"}
        ]
    }
    
    case_response = requests.post(f"{thehive_url}/api/case", headers=thehive_headers, data=json.dumps(case_data))
    case = case_response.json()
    
    print(f"Created case: {case['title']} (ID: {case['id']})")
    
    # Import alert into the case
    import_response = requests.post(f"{thehive_url}/api/alert/{alert['id']}/markAsRead", headers=thehive_headers)
    import_response = requests.post(f"{thehive_url}/api/alert/{alert['id']}/createCase", headers=thehive_headers)
    
    # Get observables from the case
    observables_response = requests.get(f"{thehive_url}/api/case/{case['id']}/observable", headers=thehive_headers)
    observables = observables_response.json()
    
    # Run Cortex analyzers on observables
    cortex_headers = {
        "Authorization": f"Bearer {cortex_api_key}",
        "Content-Type": "application/json"
    }
    
    # Get list of analyzers
    analyzers_response = requests.get(f"{cortex_url}/api/analyzer", headers=cortex_headers)
    analyzers = analyzers_response.json()
    
    # Map of dataTypes to analyzers
    analyzer_map = {
        "ip": ["MaxMind_GeoIP", "OTXQuery", "VirusTotal_GetReport"],
        "domain": ["Dns", "OTXQuery", "VirusTotal_GetReport"],
        "url": ["VirusTotal_GetReport", "URLhaus"],
        "mail": ["EmailRep"],
        "hash": ["VirusTotal_GetReport", "MISP_Search"]
    }
    
    # Run appropriate analyzers on each observable
    for observable in observables:
        dataType = observable.get("dataType")
        
        if dataType in analyzer_map:
            for analyzer_name in analyzer_map[dataType]:
                # Find the analyzer ID
                analyzer_id = None
                for analyzer in analyzers:
                    if analyzer["name"] == analyzer_name and dataType in analyzer["dataTypeList"]:
                        analyzer_id = analyzer["id"]
                        break
                
                if analyzer_id:
                    # Run the analyzer
                    job_data = {
                        "data": observable["data"],
                        "dataType": dataType,
                        "tlp": observable.get("tlp", 2)
                    }
                    
                    job_response = requests.post(f"{cortex_url}/api/analyzer/{analyzer_id}/run", headers=cortex_headers, data=json.dumps(job_data))
                    print(f"Running {analyzer_name} on {observable['data']}: {job_response.status_code}")
    
    # If there are any hostname or IP observables, check GRR for matching clients
    grr_headers = {
        "Authorization": f"Bearer {grr_api_token}"
    }
    
    for observable in observables:
        if observable.get("dataType") in ["ip", "hostname"]:
            # Search for clients in GRR
            search_term = observable["data"]
            clients_response = requests.get(f"{grr_url}/api/clients?query={search_term}", headers=grr_headers)
            clients = clients_response.json()
            
            if clients:
                # Add a comment to the observable
                comment_data = {
                    "message": f"Found matching GRR clients: {', '.join([client['hostname'] for client in clients])}"
                }
                
                comment_response = requests.post(f"{thehive_url}/api/case/{case['id']}/observable/{observable['id']}/comment", headers=thehive_headers, data=json.dumps(comment_data))
                
                # Create a task to investigate the clients
                task_data = {
                    "title": f"Investigate GRR client: {clients[0]['hostname']}",
                    "description": f"Investigate the GRR client {clients[0]['hostname']} ({clients[0]['client_id']}) that matches the observable {observable['data']}",
                    "status": "Waiting"
                }
                
                task_response = requests.post(f"{thehive_url}/api/case/{case['id']}/task", headers=thehive_headers, data=json.dumps(task_data))
                print(f"Created task to investigate GRR client: {task_response.status_code}")
    
    # Update the initial triage task
    tasks_response = requests.get(f"{thehive_url}/api/case/{case['id']}/task", headers=thehive_headers)
    tasks = tasks_response.json()
    
    for task in tasks:
        if task["title"] == "Initial Triage":
            task_data = {
                "status": "Completed",
                "description": "Automated initial triage completed:\n\n" +
                               "- Created case from alert\n" +
                               "- Ran Cortex analyzers on observables\n" +
                               "- Checked for matching GRR clients\n\n" +
                               "Next steps: Review analysis results and proceed with evidence collection."
            }
            
            task_update_response = requests.patch(f"{thehive_url}/api/case/task/{task['id']}", headers=thehive_headers, data=json.dumps(task_data))
            print(f"Updated initial triage task: {task_update_response.status_code}")
            break
```

## Best Practices

### Error Handling

Always include proper error handling in your API scripts:

```python
try:
    response = requests.post(url, headers=headers, data=json.dumps(data))
    response.raise_for_status()  # Raise an exception for HTTP errors
    result = response.json()
    # Process the result
except requests.exceptions.RequestException as e:
    print(f"Request error: {e}")
except json.JSONDecodeError as e:
    print(f"JSON decode error: {e}")
except Exception as e:
    print(f"Unexpected error: {e}")
```

### Rate Limiting

Be mindful of API rate limits and implement appropriate throttling:

```python
import time

def make_api_request(url, headers, data=None):
    max_retries = 3
    retry_delay = 1  # seconds
    
    for attempt in range(max_retries):
        try:
            if data:
                response = requests.post(url, headers=headers, data=json.dumps(data))
            else:
                response = requests.get(url, headers=headers)
            
            if response.status_code == 429:  # Too Many Requests
                retry_after = int(response.headers.get("Retry-After", retry_delay))
                print(f"Rate limited. Waiting {retry_after} seconds...")
                time.sleep(retry_after)
                continue
            
            response.raise_for_status()
            return response
            
        except requests.exceptions.RequestException as e:
            if attempt < max_retries - 1:
                print(f"Request failed: {e}. Retrying in {retry_delay} seconds...")
                time.sleep(retry_delay)
                retry_delay *= 2  # Exponential backoff
            else:
                raise
    
    return None
```

### Authentication Security

Store API keys securely and never hardcode them in your scripts:

```python
import os
from dotenv import load_dotenv

# Load API keys from environment variables
load_dotenv()

thehive_api_key = os.getenv("THEHIVE_API_KEY")
cortex_api_key = os.getenv("CORTEX_API_KEY")
misp_api_key = os.getenv("MISP_API_KEY")
grr_api_token = os.getenv("GRR_API_TOKEN")

# Check if keys are available
if not thehive_api_key:
    raise ValueError("TheHive API key not found in environment variables")
```

### Logging

Implement proper logging in your scripts:

```python
import logging

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    filename='api_script.log'
)

logger = logging.getLogger('cti_api')

try:
    # API call
    response = requests.post(url, headers=headers, data=json.dumps(data))
    response.raise_for_status()
    logger.info(f"Successfully created case: {response.json().get('title')}")
except Exception as e:
    logger.error(f"Error in API call: {str(e)}")
```

## Conclusion

This guide provides examples of using the APIs of the various CTI platform components. You can use these examples as a starting point for developing your own integrations and automations.

For more detailed information about each API, refer to the official documentation:

- TheHive API: https://github.com/TheHive-Project/TheHiveDocs/blob/master/api/api-guide.md
- Cortex API: https://github.com/TheHive-Project/CortexDocs/blob/master/api/api-guide.md
- MISP API: https://www.circl.lu/doc/misp/automation/
- GRR API: https://grr-doc.readthedocs.io/en/latest/investigating-with-grr/automation-with-api.html
