# Localproxy agent

This agent handles aws tunnel notifications such that when a tunnel is created against the destination device, the device spawns an instance of the aws localproxy to connect to the tunnel

## Requirements
- docker 20+
- localproxy binary installed on the remote device

### Client Certificates

In order to connect to the aws cloud services you need to install the client certificate that aws provides you when creating a Thing device in the "Iot core" services section.
Download those certificates and pass the path to each certificate file to the installation script using the correct flags, see the help page of the installation script for more informations.

## Run the agent manually
```bash
yarn start
```

## Systemd Installation

Run the `install.sh` script to install the agent as systemd service. See `./install.sh -h` for more informations.

```bash
sudo ./install.sh OPTIONS
```

## Uninstall systemd service

To purge the service from the host machine:
```bash
sudo ./install.sh --uninstall
rm -rf <installation-path> # this path was provided during the installation phase, see the help page of the script to know the default path
```