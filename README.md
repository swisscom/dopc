# DOPc

DOPc combines DOPi and DOPv in one tools and exposes a REST API.

## Requirements

## Quickstart

TODO

## Configuration

See `config/initializers/settings/01_defaults.rb` for custom DOPc settings.
Create a local file named `02_local.rb` in the same directory to overwrite
settings. The file is ignored by Git.

## Caveats

* Service is not protected by any sort of authentication or authorization, this
  is left to the setup (e.g. basic auth with Apache httpd).

## Authors

* Anselm Strauss <Anselm.Strauss@swisscom.com>
