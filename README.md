# Crown Marketplace

![GitHub Release](https://img.shields.io/github/release/Crown-Commercial-Service/crown-marketplace.svg?style=flat)

![Test Status](https://github.com/Crown-Commercial-Service/crown-marketplace/actions/workflows/pull_request_ci.yml/badge.svg)
[![Maintainability](https://api.codeclimate.com/v1/badges/37cd5c1a9986ca396884/maintainability)](https://codeclimate.com/github/Crown-Commercial-Service/crown-marketplace/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/37cd5c1a9986ca396884/test_coverage)](https://codeclimate.com/github/Crown-Commercial-Service/crown-marketplace/test_coverage)

**Deployments**
| Environment | Deployment status                                                                                                                                                 |
| ----------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Sandbox     | ![Latest Sandbox deployment](https://github.com/Crown-Commercial-Service/crown-marketplace/actions/workflows/setup_deployment.yml/badge.svg?branch=develop)       |
| CMPDEV      | ![Latest CMPDEV deployment](https://github.com/Crown-Commercial-Service/crown-marketplace/actions/workflows/setup_deployment.yml/badge.svg?branch=main)         |
| Preview     | ![Latest Preview deployment](https://github.com/Crown-Commercial-Service/crown-marketplace/actions/workflows/setup_deployment.yml/badge.svg?branch=preview)       |
| Production  | ![Latest Production deployment](https://github.com/Crown-Commercial-Service/crown-marketplace/actions/workflows/setup_deployment.yml/badge.svg?branch=production) |

This repository contains the code for:
- Facilities Management
- Crown Marketplace admin

For any other services relating to the Crown Marketplace, please view [Crown Marketplace Legacy](https://github.com/Crown-Commercial-Service/crown-marketplace-legacy).

## Prerequisites for installing the project

### MacOS

This guide assumes you have Homebrew installed

#### Check the Ruby version
This is a Ruby on Rails application using ruby version `3.4.1`.
Ensure that, if you are using a ruby environment manager, the correct ruby version is being run in your development environment.

#### Software requirements

Install Postgres and PostGIS.
These are for your local database and can be installed with:

```shell
brew install postgresql
brew install postgis
```

Install Yarn, for managing node modules

```shell
brew install yarn
```

Install Redis, for Sidekiq background jobs

```shell
brew install redis
```

Install geckodriver, which requires the Firefox browser, for the cucumber feature tests

```shell
brew install --cask firefox
brew install geckodriver
```

## Developer setup

First you need to clone the repository and move into the project directory.
Make sure your ruby version is set to the [current version](.ruby-version)

To install dependencies:

```shell
yarn install    # (for the JavaScript and other frontend assets)
bundle install  # (make sure the bundler gem is installed first)
```

To create, migrate & seed the database:  

```shell
bundle exec rake db:setup
```

### Adding address data
To seed your database with address data run the following command

```shell
bundle exec rake db:sample_address_import
```

### Environment variables for development

The application uses the [`dotenv-rails` gem][dotenv-rails] to manage environment variables in `development` and `test` Rails environments which are stored in `.env.*` files in the project's root directory.
See the gem's documentation for an explanation of the precedence of the various files.

If you are new to the project, speak to a developer who should be able to share their `.env.local` with you.

There is more information about environment variables in the [Environment variables](#environment-variables) section of the README

## Run the project

You can run the web application and its background services with:

```shell
bin/dev
```

This will:
- bring up the web application on [localhost:3000](http://localhost:3000)
- watch CSS and JavaScript assets for changes
- run redis and sidekiq for background jobs

If you do not want to run Sidekiq, pass the `--no-sidekiq` to the `bin/dev` command

## Development

### Design & frontend

The design of the app is closely based on the [GOV.UK Design System][] with some minor CCS-related variations.
The project uses and extends the [CCS Frontend][] and [GOV.UK Frontend][] npm packages.

The npm package dependencies are listed in `package.json`, installed using [yarn][], and the exact versions of all dependencies direct/indirect are locked in `yarn.lock`.

For custom SCSS, CSS follows [Block Element Modifier][] conventions.

We use `TypeScript` to write any frontend code and can be found in [app/typescript](app/typescript).
This is transpiled into JavaScript (in the [app/assets/javascripts/dist](app/assets/javascripts/dist) directory) with `yarn`.

### Code

The project is a fairly standard Rails web app. However, there are a few aspects which are somewhat non-standard:

The framework-specific routes and code are all isolated from each other using namespaces with some code shared across frameworks.
In some ways the code for each framework could be considered as a mini web app in its own right and the intention is that it should be relatively easy to extract the code for one framework into a separate Rails app if that was deemed appropriate down the line.

A bunch of other less-variable data is stored in CSV files in the code repository and made available to the application via classes including the `StaticRecord` concern, e.g. `Nuts3Region` which loads its data from `data/nuts3_regions.csv`.

The user journey for each framework is made up of a series of questions which lead the user to an appropriate outcome.
This workflow is modelled by a journey class which inherits from `GenericJourney`, a series of step classes which include the `Steppable` concern, and view templates corresponding to each step.

- In conjunction with its steps, the journey is responsible for interpreting the query string parameters (generated by the answers to previous questions) and determining which is the current step.
- Each step is responsible for determining which step comes next in the journey.
- Most steps correspond to a question page with an HTML form and one or more HTML input elements; a few steps correspond to outcome pages, i.e. the final step in a journey.
- Question-related step classes use the [virtus][] gem to define attributes matching the parameters supplied by the HTML form and [ActiveModel::Validations][] to define validation rules to constrain the values of those inputs.

### Authentication and authorisation

Authentication is implemented using
[OmniAuth](https://github.com/omniauth/omniauth), with one configured
provider:

- [Amazon Cognito](https://aws.amazon.com/cognito/)

This require configuration using [environment variables listed below](#cognito).

Authorisation is implemented by the `Login::CognitoLogin` class.

The folder `data/cognito/email_templates` contains the templates that we use in AWS Cognito for email messaging.
These need to be configured in AWS Cognito and the files are only in this repository as documentation.

### Linting

The [rubocop][] & [rubocop-rspec][] gems are used to enforce standard coding styles.
Some custom "cops" have been defined in [`lib/cop`][lib-cop].
Some "cops" in the standard configuration have been disabled or adjusted in [`.rubocop.yml`][rubocop-yml].
Rubocop linting is run as part of the default Rake task, but can be run individually using `rake rubocop`.

### Testing

#### Unit testing
There is an automated RSpec-based test suite.
The [factory_bot_rails][] gem is used to build valid models for testing.
The [faker][] gem is used to generate realistic, but random test data of various types.

I18n translations are used in specs to reduce their sensitivity to copy changes.

You can run all the unit tests with:
```shell
bundle exec rake
```

To run a specific unit test, use:
```shell
bundle exec rspec /path/to/file_spec.rb
```

All the specs are run as part of the Pull Request and release process

#### Feature testing

We use the [Cucumber][] testing framework to test the frontend functionality with a subset of the test run as part of the CI.

You can run all the feature tests with:
```shell
bundle exec rake cucumber:ok
```

To run a specific feature test, use:
```shell
bundle exec cucumber feature/path/to/feature.feature
```

All the feature tests are run as part of the Pull Request and release process

#### Accessibility testing
We use [Axe Cucumber][] to run accessibility tests but these are not run as part of the CI.

You can run all the accessibility tests with:
```shell
bundle exec rake cucumber:accessibility
```

To run a specific accessibility feature test, use:
```shell
bundle exec cucumber -p accessibility feature/path/to/feature.feature
```


### Code Climate

We use [Code Climate](https://codeclimate.com/github/Crown-Commercial-Service/crown-marketplace) to do two things.

1. We use it to keep an eye on the quality of the code to help point out any code smells

2. We use it to keep track of our test coverage

### Code coverage

Code coverage is measured by [simplecov](https://github.com/colszowka/simplecov)

After running the Rspec tests, open [coverage/index.html](coverage/index.html) in a browser to see the code coverage percentage.

Note that some lines are excluded from simplecov with the `# :nocov:` instruction.

### Managing dependencies
 
We use [dependabot](https://github.com/dependabot) and [Snyk](https://app.snyk.io/org/ccs-wattsa) to help manage our dependencies.

We schedule `dependabot` to run every Sunday night which will get the latest dependency updates.
 
Snyk is used more for analysing security issues and it will raise PRs itself for a developer to analyse.

## Contributing

To contribute to the project, you should checkout a new branch from `main` and make your changes.

Before pushing to the remote, you should squash your commits into a single commit.
This can be done using `git rebase -i main` and changing `pick` to `s` for the commits you want to squash (usually all but the first).
This is not required but it helps keep the commit history fairly neat and tidy

Once you have pushed your changes, you should open a Pull Request on the main branch.
This will run:
- Rubocop
- Unit tests
- Feature test
- Code climate analysis

Once all these have passed, and the PR has been reviewed and approved by another developer, you can merge the PR which will trigger a deployment

## Continuous integration & deployment

We use GitHub actions and AWS to deploy our code.

We have four environments which map to branches on github:
| Environment | Branch      | Description                                                                       |
| ----------- | ----------- | --------------------------------------------------------------------------------- |
| Sandbox     | develop     | Used by developers to try out any changes that will affect the other environments |
| CMPDEV      | main        | The testing environment                                                           |
| Preview     | preview     | Environment that matches production and can be used for any final checks          |
| Production  | production  | The live environment which uses use                                               |

When one of these branches are pushed to, the code will be released to the respective environments in the following process:
- A GitHub action will run the unit and feature test suites against the branch.
- If these tests pass, the AWS pipeline will be triggered using the [CCS AWS Pipeline action][].
  Note, in preview and production you will be asked to review the release before it is deployed.
- If something goes wrong during this phase you should:
  - [investigate the action][]
  - If the test section failed, try re-running them
  - If the deployment section failed, try re-running them
  - If that does not work and you have to release the code you can still do it within [AWS CodePipeline][]
- In AWS we use [AWS CodeBuild][] and [AWS CodePipeline][] to build and deploy the application.
-  A container is built using the `Dockerfile` in this repo, uploaded to the [AWS Elastic Container Registry][], and deployed using [AWS Elastic Container Service][].
- Environment variables for the various containers running on the AWS infrastructure are obtained from the [AWS Systems Manager Parameter Store][aws-parameter-store].
- See the [CMpDevEnvironment][] repository, particularly the [Developer Guide][CMp Developer Guide], for more details.

### Deploying to Preview and Production

We use Pull Requests to manage our deployments to the preview and production environments.

To create a new release:
- From the release commit (nearly always the HEAD of the main branch) checkout a new branch with the release version in the format:
`release-<major>.<minor>.<patch>`
- Update the version number in the VERSION file
- Update the CHANGELOG with a list of the changes and their Pull Requests
- Commit the changes (with the commit message 'Release v<major>.<minor>.<patch>'), push to GitHub and open a Pull Request
- Once this Pull Request has been reviewed and merged a new GitHub release will be created
- Once you have published the release, create a Pull Request of the changes on the `preview` and `production` branches.
- Once the Pull Request has been aproved, merge the Pull Request which will update the `preview/production` branch.

Once all the steps has been followed, the branches will be deployed to preview and preduction as described in [Continuous integration & deployment](#continuous-integration--deployment)


## Environment variables

Environment variables for the `production` Rails environment are currently
obtained from the [AWS Systems Manager Parameter Store][aws-parameter-store].

#### Cognito

- `COGNITO_USER_POOL_SITE`
  - Obtained from "App integration > Domain name" of the AWS Cognito User Pool
  - Leave this blank in development to configure both Cognito & DfE Sign-in to use OmniAuth test mode.
- `COGNITO_USER_POOL_ID`
  - Obtained from the "General settings" of the AWS Cognito User Pool
- `COGNITO_CLIENT_ID`
  - Obtained from the "General settings > App clients" of the AWS Cognito User Pool
- `COGNITO_CLIENT_SECRET`
  - Obtained from the "General settings > App clients" of the AWS Cognito User Pool
- `COGNITO_AWS_REGION`
  - The AWS region the Cognito User Pool was created in
- `SUPPLY_TEACHERS_COGNITO_ENABLED`
  - If present, enable the Cognito sign-in link on the Supply Teachers gateway page

#### Google Analytics

- `GA_TRACKING_ID`
  - Google Analytics is disabled if this is not set
- `GTM_TRACKING_ID`
  - Google Tag Manager is disabled if this is not set

#### Database

The following are used to configure the database, but only in production
environments:

- `CCS_DEFAULT_DB_HOST`
- `CCS_DEFAULT_DB_PORT`
- `CCS_DEFAULT_DB_NAME`
- `CCS_DEFAULT_DB_USER`
- `CCS_DEFAULT_DB_PASSWORD`

#### Log level

- `LOG_LEVEL` can be used to manipulate the log level in production. Set to `'debug'` to see debug output; the default (if not set) is `:info`


[geocoding-key]: https://console.developers.google.com/flows/enableapi?apiid=geocoding_backend&keyType=SERVER_SIDE
[dotenv-rails]: https://github.com/bkeepers/dotenv
[aws-parameter-store]: https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-paramstore.html
[rubocop]: https://github.com/rubocop-hq/rubocop
[rubocop-rspec]: https://github.com/rubocop-hq/rubocop-rspec
[lib-cop]: https://github.com/Crown-Commercial-Service/crown-marketplace/tree/main/lib/cop
[rubocop-yml]: https://github.com/Crown-Commercial-Service/crown-marketplace/blob/main/.rubocop.yml
[feature-specs]: https://github.com/Crown-Commercial-Service/crown-marketplace/tree/main/spec/features
[factory_bot_rails]: https://github.com/thoughtbot/factory_bot_rails
[GOV.UK Frontend]: https://github.com/alphagov/govuk-frontend
[CCS Frontend]: https://github.com/tim-s-ccs/ccs-frontend-project
[yarn]: https://github.com/yarnpkg/yarn
[GOV.UK Design System]: https://design-system.service.gov.uk/
[Block Element Modifier]: http://getbem.com/
[virtus]: https://github.com/solnic/virtus
[ActiveModel::Validations]: https://guides.rubyonrails.org/active_record_validations.html
[capybara]: https://github.com/teamcapybara/capybara
[AWS CodeBuild]: https://aws.amazon.com/codebuild/
[AWS CodePipeline]: https://aws.amazon.com/codepipeline/
[AWS Elastic Container Registry]: https://aws.amazon.com/ecr/
[AWS Elastic Container Service]: https://aws.amazon.com/ecs/
[CMpDevEnvironment]: https://github.com/Crown-Commercial-Service/CMpDevEnvironment
[CMp Developer Guide]: https://github.com/Crown-Commercial-Service/CMpDevEnvironment/blob/develop/docs/ccs_aws_v1-developer_guide.md
[faker]: https://github.com/stympy/faker
[Cucumber]: https://cucumber.io/
[Axe Cucumber]: https://www.deque.com/axe/
[CCS AWS Pipeline action]: https://github.com/Crown-Commercial-Service/ccs-aws-codepipeline-action
[investigate the action]: https://github.com/Crown-Commercial-Service/crown-marketplace/actions/workflows/setup_deployment.yml
[GitHub Release]: https://github.com/Crown-Commercial-Service/crown-marketplace/releases
[release action]: https://github.com/Crown-Commercial-Service/crown-marketplace/actions/workflows/release.yml
