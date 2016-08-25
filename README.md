# DOPc

DOPc combines DOPi and DOPv in one tools and exposes a REST API.

## Requirements

See `Gemfile`.

## Quickstart

1. Run `bundle exec bin/rails s`

## Configuration

See `config/initializers/settings/01_defaults.rb` for custom DOPc settings.
Create a local file named `02_local.rb` in the same directory to overwrite
settings. The file is ignored by Git.

## API Specification

### Version 1

* Client must accept `application/json` (`Accept` header)
* Submitted payload must be `application/json` (`Content-Type` header)

#### GET /v1/plans

Get list of all plans.

**200 OK**

| Type | Property | Description | Required |
| --- | --- | --- | --- |
| Array | plans | List of all plans | yes |
| String | &nbsp;&nbsp;name | Name of plan | no |

#### POST /v1/plans

Add a new plan.

**Request Body**

| Type | Property | Description | Required |
| --- | --- | --- | --- |
| String | content | Base64 encoded string with YAML content of the plan | yes |

**200 OK**

| Type | Property | Description | Required |
| --- | --- | --- | --- |
| String | name | Name of plan | yes |

**422 Unprocessable Entity**

If plan content is not valid or plan could not be added.

| Type | Property | Description | Required |
| --- | --- | --- | --- |
| String | error | Error message | yes |

## Caveats

* Service is not protected by any sort of authentication or authorization, this
  is left to the setup (e.g. basic auth with Apache httpd).

## Authors

* Anselm Strauss <Anselm.Strauss@swisscom.com>
