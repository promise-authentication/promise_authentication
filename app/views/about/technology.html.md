# Let's talk about technology.

These are the proposed technologies that <%= name %> will rely on.

## JWT

<%= name %> will communicate with relying parties via signed JWT tokens. This allows relying parties to verify that a token is in fact signed by <%= name %>.

[Read about JWT standard](https://tools.ietf.org/html/rfc7519)

## Xsalsa20

Is used to encrypt users vaults which contain their identifiers for relying parties.

Emails will also be encrypted using Xsalsa20 such that <%= name %> will have no emails persisted in clear text in any data storage.

## SHA-512

Passwords will be hashed with a salt using SHA-512 before being persisted.

## DNS

When relying parties wants to configure <%= name %> they provide at file located at a specific URL relative to their domain. Thereby assuming that the DNS is a secure system.
