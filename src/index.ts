import aws from 'aws-iot-device-sdk';
import { ChildProcessWithoutNullStreams, spawn } from 'child_process';

interface AwsLocalProxyConf {
    deviceName: string;
    certsPath: string;
    clientId: string;
    region: string;
    brokerHost: string;
}

interface NotificationPayload {
    clientAccessToken: string;
    clientMode: string;
    region: string;
    services: string[]
}

class AwsLocalProxySpawner {

    private _init = false;
    protected device: aws.device;
    protected opts: AwsLocalProxyConf;
    protected child: ChildProcessWithoutNullStreams;

    constructor(opts: AwsLocalProxyConf, autostart = false) {
        this.opts = opts;
        this.device = new aws.device({
            host: opts.brokerHost,
            keyPath: `${opts.certsPath}/${opts.deviceName}.private.key`,
            certPath: `${opts.certsPath}/${opts.deviceName}.cert.pem`,
            caPath: `${opts.certsPath}/root-CA.crt`,
            clientId: opts.clientId,
            region: opts.region
        })
        if (autostart) this.start()
    }

    start() {
        if (this._init) return
        console.log("spawner class starting")
        this.device
            .on('connect', this.onConnected.bind(this))
            .on('error', (err) => console.error("client error:", err))
            .on('close', () => console.log("connection to remote broker closed"))
            .on('reconnect', () => console.log("reconnecting to remote broker..."))
            .on('offline', () => console.log("client offline"))
    }

    protected onConnected() {
        console.log("handler class connected to remote broker")
        if (this._init) return
        const topic = `$aws/things/${this.opts.deviceName}/tunnels/notify`
        this.device.subscribe(topic, { qos: 0 })
        this.device.on('message', this.messageHandler.bind(this));
        this._init = true;
    }

    protected async messageHandler(topic: string, buffer) {
        const servicesErrorString = "only one service is supported and must be ssh";
        if (this.child) return
        try {
            const message = JSON.parse(buffer.toString()) as NotificationPayload;
            console.log("message arrived:")
            console.log(JSON.stringify(message, null, 4))
            if (
                message.services.length > 1 ||
                (message.services.length === 1 && message.services[0].toLocaleLowerCase() !== "ssh")
            ) {
                throw Error(servicesErrorString)
            }
            this.child = await spawn(
                "localproxy", [
                "-t", message.clientAccessToken,
                "-r", this.opts.region,
                "-d", "localhost:22"
            ],
                { env: process.env }
            )
            this.child.stderr.on('data', data => console.error(data))
            this.child.stdout.on('data', data => console.log(data))
            this.child.on('exit', code => {
                console[code === 0 ? "log" : "error"]("localproxy exited with code", code);
                this.child = null;
            })
        } catch (e) {
            console.error(e)
        }
    }
}