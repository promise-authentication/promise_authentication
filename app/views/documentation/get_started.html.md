# Integration

<%= name %> implements convention over configuration.

To get going, all you have to do, is to redirect your users to

    https://promiseauthentication.org?client_id=example.com

Now, <%= name %> will ensure the user is authenticated, and redirect the user to

    https://example.com/authenticate?idToken=[A signed JWT token]

The content of the JWT-token will have the following content:

    {
      aud: "example.com",
      iss: "promiseauthentication.org",
      sub: "a-unique-id-for-this-provider",
      iat: 1583842620
    }

It is important for you to regard the ID of this user as _both_ the `iss` and the `sub` as <%= name %> might delegate the authentication to a third party, which will be evident from the `iss` attribute.

We recommend concatenating the two so you treat this as the user ID:

    promiseauthentication.org|a-unique-id-for-this-provider

To verify the issuer, which you must do, use the well-knowns from https://promiseauthentication.org/.well-known.

