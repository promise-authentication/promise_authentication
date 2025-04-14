# Running locally:

We're using Docker. To run the app locally, you need to have Docker installed.

Make sure you have the network:

```bash
docker network create promise-network
```

Then, run the following command to start the app:

```bash
docker compose up -d --build
```

Also make sure the KMS is running. You can find that here: https://github.com/promise-authentication/promise_key_registry
