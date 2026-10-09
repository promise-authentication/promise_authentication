# Contributing to Promise

Promise is a non-profit single sign-on service run by Foreningen Promise, a
Danish association. Thank you for helping build it.

## License

The code in this repository is licensed under the GNU Affero General Public
License v3.0 (AGPL-3.0), see [LICENSE](LICENSE). By contributing, you agree
that your contribution is licensed under the same license. You keep the
copyright to your own work: Foreningen Promise does not ask contributors to
assign copyright or to sign a contributor license agreement.

## Developer Certificate of Origin

Every commit must be signed off, certifying the
[Developer Certificate of Origin 1.1](https://developercertificate.org):

```
git commit -s
```

This adds a `Signed-off-by: Your Name <you@example.com>` line to the commit
message. It states that you wrote the code, or otherwise have the right to
submit it, under AGPL-3.0. Pull requests with unsigned commits are not merged.

## How to contribute

- Open an issue or a draft pull request early, so we can talk before you
  invest a lot of time.
- Keep pull requests small and focused on one change.
- Run the test suite before you push.
- Local setup is described in [README.md](README.md).

## Running your own instance

You are welcome to run your own instance. That is part of the design:
promiseauthentication.org can send a user to the user's own instance.

If you change the code and let other people use your instance, AGPL-3.0
requires you to offer them the source code under the same license. If you
build something good, please offer it upstream as a pull request. The terms
for instances that take part in the Promise network are published on
https://promiseauthentication.org/about/organisation.
