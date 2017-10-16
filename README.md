# Kong External Token OAUTH 2.0

A Kong plugin, that let you use an external Oauth 2.0 provider's token to protect your API.

## Description

KONG has bundled a plugin to implement a full OAUTH 2.0 provider. This plugin instead let you use a
third party OAUTH 2.0 provider to protect your API/site. Plugin validate token from request headers
(Authorization: Bearer TOKEN)

It will then request user info (specified in the configuration) and add some header to let be used
by your `upstream` service.

The plugin will periodically check for token validity. You can configure the time period through
a configuration parameter, in seconds.


## Installation

    $ luarocks install etoauth

To make Kong aware that it has to look for the new plugin, you'll have to add it to the custom_plugins
property in your configuration file (kong.conf).

```yaml
custom_plugins:
    - etoauth
```

Remember to restart Kong.



## Configuration

You can add the plugin with the following request:

```bash
$ curl -X POST http://kong:8001/apis/{api}/plugins \
    --data "name=etoauth" \
    --data "config.token_url=https://oauth.something.net/openid-connect/userinfo" \
    --data "config.client_id=SOME_CLEINT_ID" \
    --data "config.client_secret=SOME_SECRET_KEY"
```

| Form Parameter | default | description |
| --- 						| --- | --- |
| `name` 					        | | plugin name `external-oauth` |
| `config.token_url` 		  | | url of the oauth provider used to retrieve user information and also check the validity of the access token |
| `config.client_id` 		  | | OAUTH Client Id |
| `config.client_secret` 	| | OAUTH Client Secret |
| `config.user_keys` <br /> <small>Optional</small>		| `username,email` | keys to extract from the `user_url` endpoint returned json, they will also be added to the headers of the upstream server as `X-OAUTH-XXX` |
| `config.user_info_periodic_check` 		  | 60 | time in seconds between token checks |

In addition to the `user_keys` will be added a `X-OAUTH-TOKEN` header with the access token of the provider.

## Author
Vladimir Gagin

## License

Copyright 2017 Vladimir Gagin

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
limitations under the License.
