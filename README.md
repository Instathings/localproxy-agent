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

### Client Certificates

In order to connect to the aws cloud services you need to install the client certificate that aws provides you when creating a Thing device in the "Iot core" services section.
Download those certificates and put them in a directory into your file system. The agent uses the same file names that aws uses for each certificate.

```
private key => <deviceName>.private.key
public key => <device>.public.key
server certificate => <deviceName>.cert.pem
root certificate => root-CA.crt
```

So create a directory and move all certificates inside that
```bash
deviceName="xxx"
mkdir certs
mv "$deviceName"* root-CA.crt certs
```

This path is gonna be passed to the agent so that it can read all the certificates needed to connect.

## Run
```bash
yarn start
```