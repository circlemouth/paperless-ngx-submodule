# setup_lemonade.ps1
# Pulls the required models and starts the server.
# Assumes 'lemonade-server' is in the PATH.

Write-Host "Pulling models..."
lemonade-server pull gpt-oss-20b-FLM
lemonade-server pull Qwen3-4B-VL-FLM

Write-Host "Starting Lemonade server on port 8001..."
# Start in a new window or background if possible, but for now just run it.
# The user might want to run this manually or as a service.
Write-Host "Run the following command to start the server:"
Write-Host "lemonade-server serve --port 8001"

# Uncomment to run immediately:
# lemonade-server serve --port 8001
