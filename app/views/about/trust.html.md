# Let's talk about trust

Authentication is all about trust.

Trust is humbling. Trust should not be taken for granted.

When using <%= name %> you show trust. A lot. We do not take that lightly.

<%= name %> embraces that humans are fallible. The trust required to provide centralized global authentication is unfathomable by any human being.

To trust <%= name %>, you have to believe that the human beings behind can

- protect the [cryptographic secrets](#secrets)
- [write code](#oss) that will leak no data

Besides that, you have to place trust in the infrastructure of the existing internet and mathematics. So you have to believe that

- [ES512](#es512) is safe
- [Xsalsa20](#xsalsa20) is safe
- [HTTPS](#https) is safe

While that is plenty, I still want to emphasize that you do _not_ have to trust any human being being able to control their greed or curiosity.

Even _if_ someone on the inside wanted to be evil, they wouldn't be able to steal or sell any data about you.

Even _if_ someone managed to gain access to secured systems, they wouldn't be able to get access to any of your data.

### <a name="secrets">Secret key</a>

The secret key used to sign JWT-tokens must be kept safe. It's the basis for the trust between <%= name %> and the relying parties.

If this is compromised, it would be possible to impersonate anyone on any relying party.

So this is basically the Achilles' heel of <%= name %>.

### <a name="es512">ES512</a>

<%= name %> uses ECDSA P-521 SHA-512[<%= external_icon -%>](https://tools.ietf.org/html/rfc7515#appendix-A.4 "Read about the signing algorithm here") (ES512) to sign JWT tokens. If this is not safe, it will be possible to impersonate anyone on any relying party.

