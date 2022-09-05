# Localproxy agent

This agent handles aws tunnel notifications such that when a tunnel is created against the destination device, the device spawns an instance of the aws localproxy to connect to the tunnel

## Requirements
- node 16+
- yarn 1.22.19+
- localproxy binary installed on the remote device

## Setup
```bash
yarn install
```

## Run
```bash
yarn start
```