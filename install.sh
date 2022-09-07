# args for current script
export BROKER_HOST=""
export CLIENT_ID=""
export REGION=""
export DEVICE_NAME=""
#certs
export PRIVKEY_FILE=""
export PUBKEY_FILE=""
export CA_FILE=""
export CERT_FILE=""

user="$USER"
INSTALLATION_PATH="/opt/localproxy-agent"
UNINSTALL_MODE=0

# global vars
service_filename="localproxy-agent.service"

function usage() {
    local code=0
    if [ ! -z "$1" ]; then code=$1; fi
    echo "$0 OPTIONS"
    echo "OPTIONS"
    echo "    --broker-host, -b         hostname of the aws broker"
    echo "    --client-id, -i           client id for mqtt connection"
    echo "    --region, -r              aws region (such as eu-west-1)"
    echo "    --key-file, -k            path to the private key file"
    echo "    --pubkey-file, -P         path to the public key file"
    echo "    --ca-file, -c             path to the root ca file"
    echo "    --cert-file, -C           path to the cert file"
    echo "    --device-name, -n         name of the iot core thing created in aws"
    echo "    --help, -h                display this help message"
    echo "    --install-path, -p        (default: /opt/localproxy-agent) the installation folder where the agent source code will be installed"
    echo "    --user, -u                (default: root) the linux user of the device to use to run the systemd service"
    echo "    --uninstall, -U           uninstall mode, uninstalls the service and related files"
    echo
    exit $code
}

function parseArgv() {
    while true; do
        case "$1" in
            --broker-host | -b) BROKER_HOST="$2"; shift 2; ;;
            --client-id | -i) CLIENT_ID="$2"; shift 2; ;;
            --region | -r) REGION="$2"; shift 2; ;;
            --key-file | -k) PRIVKEY_FILE="$2"; shift 2; ;;
            --pubkey-file | -P) PUBKEY_FILE="$2"; shift 2; ;;
            --ca-file | -c) CA_FILE="$2"; shift 2; ;;
            --cert-file | -C) CERT_FILE="$2"; shift 2; ;;
            --device-name | -n) DEVICE_NAME="$2"; shift 2; ;;
            --help | -h) usage; ;;
            --install-path | -p) INSTALLATION_PATH="$2"; shift 2; ;;
            --user | -u) user="$2"; shift 2; ;;
            --uninstall | -U) UNINSTALL_MODE=1; shift; ;;
            --) shift; break; ;;
            *) break;
        esac
    done
}

function validateFlags() {
    if [ $UNINSTALL_MODE -eq 1 ]; then return; fi
    if [ -z "$BROKER_HOST" ]; then echo "option BROKER_HOST is missing"; usage 1; fi
    if [ -z "$CLIENT_ID" ]; then echo "option CLIENT_ID is missing"; usage 1; fi
    if [ -z "$REGION" ]; then echo "option REGION is missing"; usage 1; fi
    if [ -z "$DEVICE_NAME" ]; then echo "option DEVICE_NAME is missing"; usage 1; fi
    if [ -z "$PRIVKEY_FILE" ]; then echo "option PRIVKEY_FILE is missing"; usage 1; fi
    if [ -z "$PUBKEY_FILE" ]; then echo "option PUBKEY_FILE is missing"; usage 1; fi
    if [ -z "$CA_FILE" ]; then echo "option CA_FILE is missing"; usage 1; fi
    if [ -z "$CERT_FILE" ]; then echo "option CERT_FILE is missing"; usage 1; fi
}

function applySystemdReplacements() {
    echo "customizing systemd file..."
    local file="$1"
    cp localproxy-agent.service "$file"
    sed -i "s|\${{BROKER_HOST}}|${BROKER_HOST}|g" "$file"
    sed -i "s|\${{CLIENT_ID}}|$CLIENT_ID|g" "$file"
    sed -i "s|\${{REGION}}|$REGION|g" "$file"
    sed -i "s|\${{PRIVKEY_FILE}}|$PRIVKEY_FILE|g" "$file"
    sed -i "s|\${{PUBKEY_FILE}}|$PUBKEY_FILE|g" "$file"
    sed -i "s|\${{CA_FILE}}|$CA_FILE|g" "$file"
    sed -i "s|\${{CERT_FILE}}|$CERT_FILE|g" "$file"
    sed -i "s|\${{DEVICE_NAME}}|$DEVICE_NAME|g" "$file"
    sed -i "s|\${{USER}}|$user|g" "$file"
    sed -i "s|\${{INSTALLATION_PATH}}|$INSTALLATION_PATH|g" "$file"
}

function uninstallSystemdService() {
    echo "uninstalling systemd service..."
    if [ -z "$service_filename" ]; then echo "service file name is empty"; exit 1; fi
    systemctl stop "$service_filename"
    systemctl disable "$service_filename"
    rm -rf "/etc/systemd/system/$service_filename"* 2>/dev/null
    rm -rf "/usr/lib/systemd/system/$service_filename"* 2>/dev/null
    systemctl daemon-reload
    rm -rf "$INSTALLATION_PATH"
    docker rmi -f "localproxy-agent" 2>/dev/null
    echo "service successfully uninstalled"
}

function installSystemdService() {
    echo "installing systemd service"
    local temp="/tmp/copy.service"
    applySystemdReplacements "$temp"
    cp -f "$temp" "/etc/systemd/system/$service_filename"
    # rm "$temp"
    systemctl enable "$service_filename"
    systemctl start "$service_filename"
}

function removeBuildContainer() {
    local container="$1"
    docker stop "$container"
    docker rm -f "$container"
}

function installSource() {
    rm -rf "$INSTALLATION_PATH"
    mkdir -p "$INSTALLATION_PATH"
    local image="localproxy-agent"
    docker build --no-cache -t "$image" .
    container_id="$(docker run -d "$image" sleep infinity)"
    sleep 3
    docker cp "$container_id:/app/build" "$INSTALLATION_PATH/build"
    docker cp "$container_id:/app/package.json" "$INSTALLATION_PATH/package.json"
    docker cp "$container_id:/app/node_modules" "$INSTALLATION_PATH/node_modules"
    # chown after node modules installation
    chown -R "$user" "$INSTALLATION_PATH"
    chmod u+rwx "$INSTALLATION_PATH"
    removeBuildContainer "$container_id" 2>/dev/null
}

function main() {
    parseArgv $@
    validateFlags
    if [ `id -u` -ne 0 ]; then echo "must run as root"; exit 1; fi
    uninstallSystemdService
    if [ $UNINSTALL_MODE -eq 1 ]; then exit; fi
    installSource
    installSystemdService
}

main $@