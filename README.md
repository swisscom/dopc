# DOPc

DOPc combines DOPi and DOPv in one tools and exposes a REST API.

## Requirements

See `Gemfile`.

## Quickstart

1. Run `bundle exec bin/rails s`

## Configuration

DOPc will use configuration settings from DOPi/DOPv wherever possible.

See `config/initializers/settings/01_defaults.rb` for custom DOPc settings.
Create a local file named `02_local.rb` in the same directory to overwrite
settings. The file is ignored by Git.

## API Specification

### Version 1

* Client must accept `application/json` (`Accept` header)
* Submitted payload must be `application/json` (`Content-Type` header)

#### GET /v1/ping

Ping the service.

**200 OK**

| Type | Property | Description | Required |
| --- | --- | --- | --- |
| String | pong | Contains value `pong` | yes |

#### GET /v1/plans

Get list of all plans.

**200 OK**

| Type | Property | Description | Required |
| --- | --- | --- | --- |
| Array | plans | List of all plans | yes |
| String | &nbsp;&nbsp;name | Name of the plan | no |

#### POST /v1/plans

Add a new plan.

**Request Body**

| Type | Property | Description | Required |
| --- | --- | --- | --- |
| String | content | Base64 encoded string with YAML content of the plan | yes |

**201 Created**

| Type | Property | Description | Required |
| --- | --- | --- | --- |
| String | name | Name of the plan | yes |

**409 Conflict**

If the plan already exists.

| Type | Property | Description | Required |
| --- | --- | --- | --- |
| String | error | Error message | yes |

**422 Unprocessable Entity**

If plan content is not valid or plan could not be added.

| Type | Property | Description | Required |
| --- | --- | --- | --- |
| String | error | Error message | yes |

#### DELETE /v1/plans/{name}

Delete a plan.

**Request Parameters**

| Type | Property | Description | Required |
| --- | --- | --- | --- |
| String | name | Name of the plan | yes |

**200 OK**

| Type | Property | Description | Required |
| --- | --- | --- | --- |
| String | name | Name of plan that was deleted | yes |

**404 Not Found**

If specified plan was not found.

| Type | Property | Description | Required |
| --- | --- | --- | --- |
| String | error | Error message | yes |

#### GET /v1/plans/{name}/check

Check if the plan is valid.

**Request Parameters**

| Type | Property | Description | Required |
| --- | --- | --- | --- |
| String | name | Name of the plan | yes |

**200 OK**

| Type | Property | Description | Required |
| --- | --- | --- | --- |
| Boolean | valid | Whether the plan is valid or not | yes |

**404 Not Found**

If specified plan was not found.

| Type | Property | Description | Required |
| --- | --- | --- | --- |
| String | error | Error message | yes |

#### POST /v1/plans/{name}/run

Run a plan. Creates a job to run the plan in the background.

**Request Parameters**

| Type | Property | Description | Required |
| --- | --- | --- | --- |
| String | name | Name of the plan | yes |

**201 Created**

| Type | Property | Description | Required |
| --- | --- | --- | --- |

**404 Not Found**

If specified plan was not found.

| Type | Property | Description | Required |
| --- | --- | --- | --- |
| String | error | Error message | yes |

## Caveats

* Service is not protected by any sort of authentication or authorization, this
  is left to the setup (e.g. basic auth with Apache httpd).

## Todo

* Ensure calling DOPi/DOPv from DOPc works exactly the same as calling them
  directly (command line args, config files, logging, etc.)
* Check log clutter and verbose execution during tests

## Authors

* Anselm Strauss <Anselm.Strauss@swisscom.com>
