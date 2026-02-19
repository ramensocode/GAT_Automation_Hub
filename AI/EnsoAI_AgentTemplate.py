import os
import requests
import json
import sys
 
# ------------------------------------------------------------
# 1.  Put your own values here (or load them from env-vars)
# ------------------------------------------------------------
APIM_BASE_URL = "https://v1api-apim-test-eus.azure-api.net"   # no trailing “/”
SUBSCRIPTION_KEY = "75ada9078d8d47e58d73f93624cad989"         # from Product › Subscriptions
API_VERSION = "2024-05-01-preview"                            # same as you set in APIM
 
# ------------------------------------------------------------
# 2.  Compose the request
# ------------------------------------------------------------
url = f"{APIM_BASE_URL}/4.1/chat/completions?api-version={API_VERSION}"
 
headers = {
    "Ocp-Apim-Subscription-Key": SUBSCRIPTION_KEY,
    "Content-Type": "application/json"
}
 
payload = {
    "model": "gpt-4.1",
    "messages": [
            {
                "role": "system",
                "content": 'You are an Data validation and Structuring assisstant, when user gives a data, if it is a JSON, clean the JSON and return only the JSON data without any explanation. If the data is not in JSON format, extract the useful information and structure it into a JSON format with appropriate key-value pairs. Always return only the JSON data without any additional text or explanation. The JSON should be well-formed and valid. Use Nested JSON objects or arrays where appropriate to represent complex data structures.'
            },
            {
                "role": "user",
                "content": '"[\n  {\n    \"vulnerability\": \"CVE-2026-22797\",\n    \"severity\": \"Critical\",\n    \"score\": 9.9,\n    \"platform\": \"OpenStack\",\n    \"recommendation\": \"Upgrade Keystonemiddleware to 10.7.2, 10.9.1, or 10.12.1 or later to address the input sanitization flaw allowing privilege escalation via forged identity headers.\"\n  },\n  {\n    \"vulnerability\": \"CVE-2026-23838\",\n    \"severity\": \"High\",\n    \"score\": 8.7,\n    \"platform\": \"SQLite (Tandoor Recipes via NixOS)\",\n    \"recommendation\": \"Upgrade Tandoor Recipes to version 26.05 or later and ensure the SQLite database is stored in a protected subdirectory outside of publicly accessible media directories.\"\n  },\n  {\n    \"vulnerability\": \"CVE-2025-52659\",\n    \"severity\": \"Low\",\n    \"score\": 2.8,\n    \"platform\": \"HCL Aion\",\n    \"recommendation\": \"Prevent cacheable HTTP responses for sensitive or dynamic content by adjusting cache-control headers and reviewing server configuration.\"\n  },\n  {\n    \"vulnerability\": \"CVE-2025-52660\",\n    \"severity\": \"Low\",\n    \"score\": 2.7,\n    \"platform\": \"HCL Aion\",\n    \"recommendation\": \"Implement file upload restrictions and content validation to prevent unauthorized uploads and potential code execution.\"\n  },\n  {\n    \"vulnerability\": \"CVE-2025-52661\",\n    \"severity\": \"Low\",\n    \"score\": 2.4,\n    \"platform\": \"HCL Aion\",\n    \"recommendation\": \"Configure JWT token expiry durations to reasonable values to minimize misuse risk and rotate compromised tokens promptly.\"\n  },\n  {\n    \"vulnerability\": \"CVE-2025-55249\",\n    \"severity\": \"Low\",\n    \"score\": 3.5,\n    \"platform\": \"HCL Aion\",\n    \"recommendation\": \"Add standard security response headers to all HTTP responses to strengthen protection against common web-based attacks.\"\n  },\n  {\n    \"vulnerability\": \"CVE-2025-55251\",\n    \"severity\": \"Low\",\n    \"score\": 3.1,\n    \"platform\": \"HCL Aion\",\n    \"recommendation\": \"Enforce restrictions and validation on file uploads to prevent malicious file execution or system compromise.\"\n  },\n  {\n    \"vulnerability\": \"CVE-2025-55250\",\n    \"severity\": \"Low\",\n    \"score\": 1.8,\n    \"platform\": \"HCL Aion\",\n    \"recommendation\": \"Suppress or sanitize technical error messages to avoid leaking sensitive information and review error handling procedures.\"\n  },\n  {\n    \"vulnerability\": \"CVE-2025-55252\",\n    \"severity\": \"Low\",\n    \"score\": 3.1,\n    \"platform\": \"HCL Aion\",\n    \"recommendation\": \"Implement a strong password policy to prevent the use of weak and easily guessable passwords.\"\n  },\n  {\n    \"vulnerability\": \"CVE-2026-0610\",\n    \"severity\": \"Unknown\",\n    \"score\": null,\n    \"platform\": \"Devolutions Server\",\n    \"recommendation\": \"Apply vendor patches to mitigate SQL injection risks and validate user input in remote sessions.\"\n  },\n  {\n    \"vulnerability\": \"CVE-2026-1007\",\n    \"severity\": \"Unknown\",\n    \"score\": null,\n    \"platform\": \"Devolutions Server\",\n    \"recommendation\": \"Update to a patched version and review IP deny rule implementation to prevent authorization bypass.\"\n  },\n  {\n    \"vulnerability\": \"CVE-2026-0899\",\n    \"severity\": \"Unknown\",\n    \"score\": null,\n    \"platform\": \"Google Chrome (V8)\",\n    \"recommendation\": \"Update Chrome to version 144.0.7559.59 or later to address out-of-bounds memory access vulnerability.\"\n  },\n  {\n    \"vulnerability\": \"CVE-2026-0901\",\n    \"severity\": \"Unknown\",\n    \"score\": null,\n    \"platform\": \"Google Chrome (Android)\",\n    \"recommendation\": \"Upgrade Chrome on Android to 144.0.7559.59 or later to remediate UI spoofing vulnerabilities.\"\n  },\n  {\n    \"vulnerability\": \"CVE-2026-0903\",\n    \"severity\": \"Unknown\",\n    \"score\": null,\n    \"platform\": \"Google Chrome (Windows)\",\n    \"recommendation\": \"Update Chrome on Windows to 144.0.7559.59 or later to ensure dangerous file type protections are in place.\"\n  },\n  {\n    \"vulnerability\": \"CVE-2026-0904\",\n    \"severity\": \"Unknown\",\n    \"score\": null,\n    \"platform\": \"Google Chrome\",\n    \"recommendation\": \"Upgrade Chrome to 144.0.7559.59 or later to address digital credentials UI spoofing risks.\"\n  },\n  {\n    \"vulnerability\": \"CVE-2026-0905\",\n    \"severity\": \"Unknown\",\n    \"score\": null,\n    \"platform\": \"Google Chrome\",\n    \"recommendation\": \"Update Chrome to latest version and review network log access controls to prevent sensitive information leakage.\"\n  },\n  {\n    \"vulnerability\": \"CVE-2026-0906\",\n    \"severity\": \"Unknown\",\n    \"score\": null,\n    \"platform\": \"Google Chrome (Android)\",\n    \"recommendation\": \"Upgrade Chrome on Android to 144.0.7559.59 or later to mitigate omnibox spoofing risks.\"\n  },\n  {\n    \"vulnerability\": \"CVE-2026-0907\",\n    \"severity\": \"Unknown\",\n    \"score\": null,\n    \"platform\": \"Google Chrome\",\n    \"recommendation\": \"Update Chrome to 144.0.7559.59 or later to address Split View UI spoofing vulnerability.\"\n  },\n  {\n    \"vulnerability\": \"CVE-2026-0908\",\n    \"severity\": \"Unknown\",\n    \"score\": null,\n    \"platform\": \"Google Chrome\",\n    \"recommendation\": \"Upgrade Chrome to 144.0.7559.59 or later to remediate use-after-free vulnerability in ANGLE.\"\n  },\n  {\n    \"vulnerability\": \"CVE-2025-29847\",\n    \"severity\": \"Unknown\",\n    \"score\": null,\n    \"platform\": \"Apache Linkis\",\n    \"recommendation\": \"Update Linkis to latest version and sanitize URL parameters to prevent unauthorized file access via JDBC encoding.\"\n  },\n  {\n    \"vulnerability\": \"CVE-2025-59355\",\n    \"severity\": \"Unknown\",\n    \"score\": null,\n    \"platform\": \"Apache Linkis\",\n    \"recommendation\": \"Upgrade to latest Linkis version and restrict logging of sensitive information on base64 decoding failures.\"\n  },\n  {\n    \"vulnerability\": \"Weaponized Invite Enabled Calendar Data Theft via Google Gemini\",\n    \"severity\": \"Other\",\n    \"score\": null,\n    \"platform\": \"Google Gemini\",\n    \"recommendation\": \"Review calendar invite permissions and event handling logic to prevent unauthorized data exposure via event summaries.\"\n  }\n]"'
            }
        ],
    # "messages": [
    #     {
    #         "role": "user",
    #         "content": "Why is the sky blue?"
    #     }
    # ],
    "temperature": 0.7,
    "top_p": 0.95,
    "max_tokens": 10000,
    "frequency_penalty": 0,
    "presence_penalty": 0,
    "stop": None,
    "stream": False
}
 
# ------------------------------------------------------------
# 3.  Send the call and show the response
# ------------------------------------------------------------
# resp = requests.post(url, headers=headers, json=payload, timeout=60)
# resp.raise_for_status()          # raises if we did *not* get 2xx/3xx
# print(json.dumps(resp.json(), indent=2))

resp = requests.post(url, headers=headers, json=payload, timeout=60)
resp.raise_for_status()

# Extract and parse the content
api_response = resp.json()
choice = api_response["choices"][0]
content = choice["message"]["content"]
finish_reason = choice.get("finish_reason", "unknown")

# Log token usage for monitoring
usage = api_response.get("usage", {})
prompt_tokens = usage.get("prompt_tokens", 0)
completion_tokens = usage.get("completion_tokens", 0)
total_tokens = usage.get("total_tokens", 0)

print(f"INFO: Token Usage - Prompt: {prompt_tokens}, Completion: {completion_tokens}, Total: {total_tokens}", file=sys.stderr)
print(f"INFO: Finish Reason: {finish_reason}", file=sys.stderr)

# Check if response was truncated
if finish_reason == "length":
    print(f"WARNING: Response truncated due to token limit (max_tokens={payload['max_tokens']})", file=sys.stderr)
    print(f"WARNING: Partial data received. Processing may be incomplete. Consider increasing max_tokens.", file=sys.stderr)
elif finish_reason == "stop":
    print(f"INFO: Response completed successfully (not truncated)", file=sys.stderr)

try:
    # Handle both string and already-parsed content
    if isinstance(content, str):
        parsed_data = json.loads(content)
    elif isinstance(content, list):
        parsed_data = content
    else:
        raise ValueError(f"Unexpected content type: {type(content)}")
    
    # Log count for verification
    if isinstance(parsed_data, list):
        print(f"INFO: Processed {len(parsed_data)} vulnerabilities", file=sys.stderr)
    else:
        print(f"WARNING: Expected array of vulnerabilities, got {type(parsed_data)}", file=sys.stderr)
    
    # Save to file for Ansible consumption
    output_file = "ai_structured_data.json"
    with open(output_file, 'w') as f:
        json.dump(parsed_data, f, indent=2)
    
    # Output clean JSON to stdout (Ansible can capture this)
    print(json.dumps(parsed_data, indent=2))
    
except (json.JSONDecodeError, ValueError) as e:
    print(f"ERROR: Failed to parse AI response: {e}", file=sys.stderr)
    print(f"Content type: {type(content)}", file=sys.stderr)
    if isinstance(content, str):
        print(f"Raw content (first 500 chars): {content[:500]}", file=sys.stderr)
    # Save raw response for debugging
    with open("ai_error_response.json", 'w') as f:
        json.dump(api_response, f, indent=2)
    sys.exit(1)