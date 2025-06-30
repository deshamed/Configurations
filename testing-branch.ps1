# Setup-AmneziaVPN.ps1
# Run as Administrator

# Step 1: Check for Docker
Write-Host "🔍 Checking for Docker Desktop..."
if (!(Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Docker not found. Downloading Docker Desktop installer..."
    Invoke-WebRequest -Uri "https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe" -OutFile "$env:TEMP\DockerInstaller.exe"
    Start-Process -FilePath "$env:TEMP\DockerInstaller.exe" -Wait
    Write-Host "✅ Please restart your PC after Docker finishes installing. Then rerun this script."
    exit
} else {
    Write-Host "✅ Docker is already installed."
}

# Step 2: Run Amnezia VPN Docker Container
Write-Host "🐳 Setting up Amnezia VPN Docker container..."
docker pull amnezia/amnezia:latest

# Remove old container if it exists
if (docker ps -a --format "{{.Names}}" | Select-String "amnezia-vpn-server") {
    docker rm -f amnezia-vpn-server
}

# Run new container
docker run -d --name amnezia-vpn-server `
  -p 51820:51820/udp `
  -p 8388:8388 `
  -p 8388:8388/udp `
  -p 443:443 `
  amnezia/amnezia:latest

Start-Sleep -Seconds 5

# Step 3: Extract client config JSON
Write-Host "📦 Exporting VPN config..."
$clientConfig = docker exec amnezia-vpn-server cat /root/client.json

# Step 4: Save config to Desktop
$configPath = "$env:USERPROFILE\Desktop\amnezia-client-config.json"
$clientConfig | Out-File -Encoding utf8 -FilePath $configPath
Write-Host "✅ VPN config saved to your Desktop as: amnezia-client-config.json"

Write-Host "`n👉 Now open the Amnezia VPN Client, click **Import**, and select that file to connect!"
Write-Host "🎉 You're ready to bypass bans with your own stealth VPN."
