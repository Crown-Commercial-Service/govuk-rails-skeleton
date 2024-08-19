# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [6.1.1] - 2024-08-22

### Security

- Various dependency updates

## [6.1.0] - 2024-07-11

### Added

- Upgrade ruby version to v3.3.3 ([PR 4423](https://github.com/Crown-Commercial-Service/crown-marketplace/pull/4423))
- FMFR-1400 - Update the healthcheck route to check for the apps status ([PR 4421](https://github.com/Crown-Commercial-Service/crown-marketplace/pull/4421))
- Replace existing code with new components from ccs-frontend ([PR 4413](https://github.com/Crown-Commercial-Service/crown-marketplace/pull/4413))
- FMFR-1399 - Use ccs frontend for the shared assets ([PR 4383](https://github.com/Crown-Commercial-Service/crown-marketplace/pull/4383))
- FMFR-1398 - Use propshaft to build assets ([PR 4363](https://github.com/Crown-Commercial-Service/crown-marketplace/pull/4363))

### Fixed

- Fix issue where higher environments would try to run old migration but could not ([PR 4452](https://github.com/Crown-Commercial-Service/crown-marketplace/pull/4452))

### Security

- Various dependency updates

## [6.0.1] - 2024-05-30

### Fixed

- FMFR-1397 - Update email from support@ to the correct info@ ([PR 4351](https://github.com/Crown-Commercial-Service/crown-marketplace/pull/4351))

### Security

- Various dependency updates

## [6.0.0] - 2024-05-02

### Added

- FMFR-1396 - Make the telephone number a number input ([PR 4317](https://github.com/Crown-Commercial-Service/crown-marketplace/pull/4317))
- Upgrade ruby to v3.3.1 ([PR 4316](https://github.com/Crown-Commercial-Service/crown-marketplace/pull/4316))
- Update to GOV.UK Frontend v5.3  [PR 4294](https://github.com/Crown-Commercial-Service/crown-marketplace/pull/4294)
- Update ruby to v3.3.0 ([PR 4253](https://github.com/Crown-Commercial-Service/crown-marketplace/pull/4253))
- Update the browserslist DB ([PR 4216](https://github.com/Crown-Commercial-Service/crown-marketplace/pull/4216))
- Upgrade Rails to v7.1 ([PR 4028](https://github.com/Crown-Commercial-Service/crown-marketplace/pull/4028))
- Ensure shakapacker GEM and NODE versions match ([PR 4196](https://github.com/Crown-Commercial-Service/crown-marketplace/pull/4196))
- Rename cookie_preferences cookie to cookie_preferences_cmp so that it does not conflict with corporate website ([PR 4108](https://github.com/Crown-Commercial-Service/crown-marketplace/pull/4108))
- FMFR-1392 - Migrate to CCS Frontend Helpers - Simple helpers ([PR 4051](https://github.com/Crown-Commercial-Service/crown-marketplace/pull/4051))
- FMFR-1392 - Migrate to CCS Frontend Helpers - Tag and Phase banner ([PR 4052](https://github.com/Crown-Commercial-Service/crown-marketplace/pull/4052))
- FMFR-1392 - Migrate to CCS Frontend Helpers - Header and Footer ([PR 4053](https://github.com/Crown-Commercial-Service/crown-marketplace/pull/4053))
- FMFR-1392 - Migrate to CCS Frontend Helpers - Cookie banner ([PR 4054](https://github.com/Crown-Commercial-Service/crown-marketplace/pull/4054))
- FMFR-1392 - Migrate to CCS Frontend Helpers - Pagination ([PR 4055](https://github.com/Crown-Commercial-Service/crown-marketplace/pull/4055))
- FMFR-1392 - Migrate to CCS Frontend Helpers - Button ([PR 4056](https://github.com/Crown-Commercial-Service/crown-marketplace/pull/4056))
- FMFR-1392 - Migrate to CCS Frontend Helpers - Dashboard Section ([PR 4057](https://github.com/Crown-Commercial-Service/crown-marketplace/pull/4057))
- FMFR-1392 - Migrate to CCS Frontend Helpers - Table ([PR 4058](https://github.com/Crown-Commercial-Service/crown-marketplace/pull/4058))
- FMFR-1392 - Migrate to CCS Frontend Helpers - Summary list ([PR 4059](https://github.com/Crown-Commercial-Service/crown-marketplace/pull/4059))
- FMFR-1392 - Migrate to CCS Frontend Helpers - From helpers ([PR 4075](https://github.com/Crown-Commercial-Service/crown-marketplace/pull/4075))
- FMFR-1392 - Migrate to CCS Frontend Helpers - Authentication ([PR 4076](https://github.com/Crown-Commercial-Service/crown-marketplace/pull/4076))
- FMFR-1392 - Migrate to CCS Frontend Helpers - Clean up ([PR 4077](https://github.com/Crown-Commercial-Service/crown-marketplace/pull/4077))
- FMFR-1372 - Make RM3830 admin section read only ([PR 3704](https://github.com/Crown-Commercial-Service/crown-marketplace/pull/3704))
- FMFR-1372 - Remove buyer and supplier frontend for RM3830 ([PR 3703](https://github.com/Crown-Commercial-Service/crown-marketplace/pull/3703))
- Update rails sass to v6 ([PR 3906](https://github.com/Crown-Commercial-Service/crown-marketplace/pull/3906))

### Security

- Various dependency updates
