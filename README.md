# WatchtowerServer

This application is meant to be used with the [Watchtower project](https://github.com/johnnewman/watchtower) and acts as the command center for any number of Watchtower cameras. It can communicate with all upstream Watchtower instances using a simple API and will coalesce all responses into a single JSON payload. It also monitors all Watchtower instances for any changes in their configurations that may affect routing.

This project is composed of two Docker containers: `server` and `vapor`. The `vapor` container is built with Vapor, a Swift server-side framework. It is served connections via the `server` container, which is running nginx. Individual Watchtower instances will automatically connect to WatchtowerServer at five minute intervals to report any address or hostname changes.

By using the provided [install script](setup/install.sh), a daemon will be installed that can automatically update the nginx configuration and restart the container when any changes to the upstream Watchtower instances are detected. This way, as clients are added, removed, or updated, your nginx configuration stays dynamic and up-to-date. This is done using [Leaf](https://docs.vapor.codes/4.0/leaf/overview/), which will render a new nginx configuraiton template and export it to the daemon, which will then reload the container.

The `server` container will proxy traffic directly to an upstream Watchtower instance if a camera name is provided in the path, like "myserver/camera1/api/status". Without a camera name in the path, like "myserver/api/status", connections will be proxied to the `vapor` container and relayed to all cameras.

Neither container runs as root.

### API

- GET `/api/status` requests the status of all downstream cameras and combines their responses into one payload.
- GET `/api/start` starts all cameras on the network.
- GET `/api/stop` stops all cameras on the network.
- GET `/api/cameras` returns info saved all cameras on the network.
- POST `/api/cameras` create or update an existing camera, possibly rendering a new nginx template.
- GET `/api/cameras/:id` request info on a single saved camera
- DELETE `/api/cameras/:id` delete a camera, generating a new nginx template.

### Configuration

Once installation is complete, check out the  [.env file](.env) file, which houses all configuration options for WatchtowerServer.

Before starting the containers, TLS certs and keys will need to be added to the `certs/` folder. The names of each of these files can be configured in the .env file. Without these files, WatchtowerServer will not run.
- For encrypting traffic with external connections, upload a TLS cert and key to the `certs/server/` folder.
- For authenticating external client connections, upload a Certificate Authority cert to the `certs/server/` folder.
- For proxying requests to upstream Watchtower instances, add a client cert and key to the `certs/client/` folder. This will be used for authenticating with Watchtower instances.
- For verifying the SSL certificate of upstream Watchtower instances, upload a CA cert to `certs/client/`.
