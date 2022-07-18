# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Changed
- Compat compat now includes version 4

## [1.0.0] - 2020-07-12
### Added
- CI via GitHubActions
- Documentation via Documenter.jl and GitHubActions
- Codecoverage via GitHubActions and Codecov
- Test for testing that the syntax works with plain symbols on a line.
- TagBot and CompatHelper GitHubActions

### Changed
- Simplified README.md, pointing to documentation for more details.

### Fixed
- The syntax broke when using simple symbols instead of more complex expression per line. This is now fixed.

## [0.1.1] - 2020-04-04
### Added
- support for specifying a wrapper, which is applied to each container (defaults to identity)

## [0.1.0] - 2020-01-16

initial release
