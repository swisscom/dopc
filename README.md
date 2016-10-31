# DOPc

DOPc combines DOPi and DOPv in one tools and exposes a REST API.

## Requirements

See `Gemfile` for ruby version and gems.

## Quickstart

1. Set up Ruby environmnent: RVM, Bundler, etc.
1. Setup database: `bundle exec rake db:migrate`
1. Start server: `bundle exec bin/rails s`

## Configuration

DOPc will use configuration settings from DOPi/DOPv wherever possible.

See `config/initializers/01_settings/01_defaults.rb` for custom DOPc settings.
Create a local file named `02_local.rb` in the same directory to overwrite
settings. The file is ignored by Git.

## API Specification

### General Errors

**406 Not acceptable**

Returned if the client does set an `Accept` HTTP header that does not accept
`application/json` format. All answers are in JSON format and the client must
accept it.

**415 Unsupported media type**

Returned if the `Content-Type` HTTP header is set and does not equal
`application/json`. All payload data sent must be in JSON format and the
content type header must indicate so if not empty.

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
| String | &nbsp;&nbsp;- name | Name of the plan | no |

#### GET /v1/plans/{name}

Get content of a plan.

**Path Parameters**

| Type | Parameter | Description | Required |
| --- | --- | --- | --- |
| String | name | Name of the plan | yes |

**Request Body**

| Type | Property | Description | Required |
| --- | --- | --- | --- |
| String | version | Version string, if not specified then 'latest' is assumed. | no |

**200 OK**

| Type | Property | Description | Required |
| --- | --- | --- | --- |
| String | content | Base64 encoded string with YAML content of the plan | yes |

**404 Not Found**

If the specified plan or version was not found.

| Type | Property | Description | Required |
| --- | --- | --- | --- |
| String | error | Error message | yes |

#### GET /v1/plans/{name}/versions

Get a list of all versions of a plan.

**Path Parameters**

| Type | Parameter | Description | Required |
| --- | --- | --- | --- |
| String | name | Name of the plan | yes |

**200 OK**

| Type | Property | Description | Required |
| --- | --- | --- | --- |
| Array | versions | List of all versions | yes |
| String | &nbsp;&nbsp;- name | Name of the version | no |

**404 Not Found**

If the specified plan was not found.

| Type | Property | Description | Required |
| --- | --- | --- | --- |
| String | error | Error message | yes |

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

**422 Unprocessable Entity**

If the content can not be loaded.

| Type | Property | Description | Required |
| --- | --- | --- | --- |
| String | error | Error message | yes |

**400 Bad Request**

If the plan can not be added, e.g. it already exists or is invalid.

| Type | Property | Description | Required |
| --- | --- | --- | --- |
| String | error | Error message | yes |

#### PUT /v1/plans

Update an existing plan, creating a new version.

**Request Body**

| Type | Property | Description | Required |
| --- | --- | --- | --- |
| String | content | Base64 encoded string with YAML content of the plan | yes |

**200 Success**

| Type | Property | Description | Required |
| --- | --- | --- | --- |
| String | name | Name of the plan | yes |

**422 Unprocessable Entity**

If the content can not be loaded.

| Type | Property | Description | Required |
| --- | --- | --- | --- |
| String | error | Error message | yes |

**400 Bad Request**

If the plan can not be added, e.g. the name in the content does not match.

| Type | Property | Description | Required |
| --- | --- | --- | --- |
| String | error | Error message | yes |

#### DELETE /v1/plans/{name}

Delete a plan (and all its versions).

**Path Parameters**

| Type | Parameter | Description | Required |
| --- | --- | --- | --- |
| String | name | Name of the plan | yes |

**200 OK**

| Type | Property | Description | Required |
| --- | --- | --- | --- |
| String | name | Name of plan that was deleted | yes |

**404 Not Found**

If the specified plan was not found.

| Type | Property | Description | Required |
| --- | --- | --- | --- |
| String | error | Error message | yes |

#### GET /v1/executions

Get list of all executions.

**200 OK**

| Type | Property | Description | Required |
| --- | --- | --- | --- |
| Array | executions: | List of all executions | yes |
| Integer | &nbsp;&nbsp;- id | ID of the execution | yes |
| String | &nbsp;&nbsp;- plan | Plan to execute | yes |
| String | &nbsp;&nbsp;- task | Task to execute | yes |
| String | &nbsp;&nbsp;- stepset | Stepset to execute instead of default | yes |
| String | &nbsp;&nbsp;- status | Execution status | yes |
| String | &nbsp;&nbsp;- log | Execution log, mostly only in error case | yes |

#### GET /v1/executions/{id}

Get an execution.

**200 OK**

| Type | Property | Description | Required |
| --- | --- | --- | --- |
| Integer | id | ID of the execution | yes |
| String | plan | Plan to execute | yes |
| String | task | Task to execute | yes |
| String | stepset | Stepset to execute instead of default | yes |
| String | status | Execution status | yes |
| String | log | Execution log, mostly only in error case | yes |

#### POST /v1/executions

Execute a plan. Creates a job to execute the plan in the background.

**Request Body**

| Type | Property | Description | Required |
| --- | --- | --- | --- |
| String | plan | The plan to execute | yes |
| String | task | Task to execute, must be one of: deploy, undeploy, run or setup (deploy + run). | yes |
| String | stepset | Stepset to run instead of the default, for DOPi | no |

**201 Created**

| Type | Property | Description | Required |
| --- | --- | --- | --- |
| Integer | id | ID of the created execution | yes |

**422 Unprocessable Entity**

If request body has errors.

| Type | Property | Description | Required |
| --- | --- | --- | --- |
| String | error | Error message | yes |

## Implementation

TODO

## Caveats

* Service is not protected by any sort of authentication or authorization, this
  is left to the setup (e.g. basic auth with Apache httpd).
* Plan add/removal is not thread-safe, waiting for new plan store
  implementation in dop-common.

## Todo

* Ensure calling DOPi/DOPv from DOPc works exactly the same as calling them
  directly (command line args, config files, logging, etc.)
* Check log clutter and verbose execution during tests
* Mocking DOPi/DOPv for testing
* Review what to return besides error messages in error cases
* How to notice/recover when workers fail and stop

## Authors

* Anselm Strauss <Anselm.Strauss@swisscom.com>
