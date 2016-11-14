# DOPc

DOPc combines DOPi and DOPv in one tools and exposes a REST API.

## Requirements

See `Gemfile` for ruby version and gems.

## Quickstart

1. Set up Ruby environmnent: RVM, Bundler, etc.
1. Setup database: `bundle exec rake db:migrate`
1. Start server: `bundle exec bin/rails s`
1. Start Delayed::Job to start processing plan executions: `bundle exec bin/delayed_job start`
1. Schedule old job executions: `bundle exec rake dopc:schedule`

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

**5xx Server Error**

Returned if something unexpected goes wrong on the server side.

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

Update an existing plan, creating a new version. The plan with the name taken
from the content must already exist on the server.

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

If the plan can not be added, e.g. it does not yet exist.

| Type | Property | Description | Required |
| --- | --- | --- | --- |
| String | error | Error message | yes |

#### DELETE /v1/plans/{name}

Delete a plan with all its versions.

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

#### PUT /v1/plans/{name}/reset

Reset the state of a plan.

**Path Parameters**

| Type | Parameter | Description | Required |
| --- | --- | --- | --- |
| String | name | Name of the plan | yes |

**Request Body**

| Type | Property | Description | Required |
| --- | --- | --- | --- |
| Boolean | force | Force the state reset | yes |

**200 Success**

| Type | Property | Description | Required |
| --- | --- | --- | --- |
| String | name | Name of the plan that was reset | yes |

**422 Unprocessable Entity**

If the request is invalid.

| Type | Property | Description | Required |
| --- | --- | --- | --- |
| String | error | Error message | yes |

**404 Not Found**

If the plan was not found.

| Type | Property | Description | Required |
| --- | --- | --- | --- |
| String | error | Error message | yes |

#### GET /v1/plans/{name}/state

Get current DOPi state of a plan.

**Path Parameters**

| Type | Parameter | Description | Required |
| --- | --- | --- | --- |
| String | name | Name of the plan | yes |

**200 Success**

| Type | Property | Description | Required |
| --- | --- | --- | --- |
| String | state | State of the plan, newline formatted | yes |

**404 Not Found**

If the plan was not found.

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

**Path Parameters**

| Type | Parameter | Description | Required |
| --- | --- | --- | --- |
| Integer | id | ID of an execution | yes |

**200 OK**

| Type | Property | Description | Required |
| --- | --- | --- | --- |
| Integer | id | ID of the execution | yes |
| String | plan | Plan to execute | yes |
| String | task | Task to execute | yes |
| String | stepset | Stepset to execute instead of default | yes |
| String | status | Execution status | yes |
| String | log | Execution log, mostly only in error case | yes |

**404 Not Found**

If the specified execution was not found.

| Type | Property | Description | Required |
| --- | --- | --- | --- |
| String | error | Error message | yes |

#### DELETE /v1/executions/{id}

Remove an execution.

**Path Parameters**

| Type | Parameter | Description | Required |
| --- | --- | --- | --- |
| Integer | id | ID of an execution | yes |

**200 OK**

Returns the removed execution. See GET for the response body format.

**404 Not Found**

If the specified execution was not found.

| Type | Property | Description | Required |
| --- | --- | --- | --- |
| String | error | Error message | yes |

**409 Conflict**

If the specified execution is running and can not be removed.

| Type | Property | Description | Required |
| --- | --- | --- | --- |
| String | error | Error message | yes |

#### POST /v1/executions

Execute a plan. Creates a job to execute the plan in the background.

**Request Body**

| Type | Property | Description | Required |
| --- | --- | --- | --- |
| String | plan | The name of the plan to execute | yes |
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

#### DELETE /v1/executions

Remove executions.

**Request Body**

| Type | Property | Description | Required |
| --- | --- | --- | --- |
| String | plan | If specified then only executions of this plan are removed | no |
| Array of strings | statuses | Executions with a status matching any string of this list are removed | yes |

**200 OK**

Returns the removed executions. See GET operation for individual executions for the response body format.

**422 Unprocessable Entity**

If any of the specified statuses is invalid.

| Type | Property | Description | Required |
| --- | --- | --- | --- |
| String | error | Error message | yes |

## Implementation

* Plans are executed in background with Delayed::Job.
* Scheduling plan executions is done everytime a new execution is added or an
  execution finishes.
* When restarting scheduling must be done manually with the `dopc:schedule`
  rake task.
* Plans are managed with the plan store from dop_common, nothing is stored in
  the local database. Plans and executions are connected only by the plan name
  (no IDs).
* Only one execution for a specific plan can be running or queued at a time.

## Caveats

* Service is not protected by any sort of authentication or authorization, this
  is left to the setup (e.g. basic auth with Apache httpd).

## Todo

* Ensure calling DOPi/DOPv from DOPc works exactly the same as calling them
  directly (command line args, config files, logging, etc.)
* Running DOPv: Where to put disk DB file?
* Running DOPv currently fails
* Running DOPi currently fails
* Test recovering failed workers

## Authors

* Anselm Strauss <Anselm.Strauss@swisscom.com>
