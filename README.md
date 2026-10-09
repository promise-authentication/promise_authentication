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

## License

Copyright (C) 2020-2026 Foreningen Promise (CVR 45656438).

This program is free software: you can redistribute it and/or modify it
under the terms of the GNU Affero General Public License as published by
the Free Software Foundation, version 3. See [LICENSE](LICENSE).

Client libraries that relying parties embed, such as
[omniauth-promise](https://github.com/promise-authentication/omniauth-promise),
are MIT-licensed so that AGPL never reaches your own application.

Contributions are welcome under the same license, with a signed-off commit.
See [CONTRIBUTING.md](CONTRIBUTING.md).

## Trademark

"Promise", "Promise Authentication" and the Promise logo identify the service
run by Foreningen Promise at https://promiseauthentication.org. You may run
your own instance of this software and call it a Promise instance. You may
not present your instance as Foreningen Promise or as the official service,
and you may not use the name or logo in a way that suggests endorsement by
the association without its written consent.
