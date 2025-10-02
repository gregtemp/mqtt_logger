#!/bin/bash

# MQTT Logger Installation Script
# Usage: ./install.sh -u username

# Default values
USERNAME=""
SERVICE_NAME="mqtt-logger.service"

# Parse command line arguments
while getopts "u:" opt; do
    case $opt in
        u)
            USERNAME="$OPTARG"
            ;;
        \?)
            echo "Usage: $0 -u username"
            echo "  -u username: Specify the user to run the service (required)"
            exit 1
            ;;
    esac
done

# Check if username was provided
if [ -z "$USERNAME" ]; then
    echo "Error: Username is required"
    echo "Usage: $0 -u username"
    echo "  -u username: Specify the user to run the service (required)"
    exit 1
fi

# Get the current directory (where the script is located)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVICE_FILE="$SCRIPT_DIR/$SERVICE_NAME"

echo "MQTT Logger Installation Script"
echo "================================"
echo "Username: $USERNAME"
echo "Installation directory: $SCRIPT_DIR"
echo ""

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then
    echo "This script needs to be run with sudo privileges."
    echo "Please run: sudo $0 $@"
    exit 1
fi

# Check if the service file exists
if [ ! -f "$SERVICE_FILE" ]; then
    echo "Error: Service file not found at $SERVICE_FILE"
    exit 1
fi

# Check if the main.py file exists
if [ ! -f "$SCRIPT_DIR/main.py" ]; then
    echo "Error: main.py not found at $SCRIPT_DIR/main.py"
    exit 1
fi

# Check if the user exists
if ! id "$USERNAME" &>/dev/null; then
    echo "Error: User '$USERNAME' does not exist"
    exit 1
fi

# Create a temporary service file with the correct paths
TEMP_SERVICE="/tmp/mqtt-logger.service"
cat > "$TEMP_SERVICE" << EOF
[Unit]
Description=MQTT Logger
After=mosquitto.service
Wants=mosquitto.service
Requires=network.target

[Service]
Type=simple
User=$USERNAME
Group=$USERNAME
WorkingDirectory=$SCRIPT_DIR
Environment=PATH=$SCRIPT_DIR/venv/bin
ExecStart=$SCRIPT_DIR/venv/bin/python $SCRIPT_DIR/main.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

echo "Installing MQTT Logger service..."

# Copy the service file to systemd directory
cp "$TEMP_SERVICE" "/etc/systemd/system/$SERVICE_NAME"

# Set proper permissions
chmod 644 "/etc/systemd/system/$SERVICE_NAME"

# Reload systemd daemon
systemctl daemon-reload

# Enable the service
systemctl enable "$SERVICE_NAME"

echo "Service installed successfully!"
echo ""
echo "To start the service:"
echo "  sudo systemctl start $SERVICE_NAME"
echo ""
echo "To check status:"
echo "  sudo systemctl status $SERVICE_NAME"
echo ""
echo "To view logs:"
echo "  sudo journalctl -u $SERVICE_NAME -f"
echo ""
echo "To stop the service:"
echo "  sudo systemctl stop $SERVICE_NAME"
echo ""
echo "To disable the service:"
echo "  sudo systemctl disable $SERVICE_NAME"

# Clean up temporary file
rm -f "$TEMP_SERVICE"
