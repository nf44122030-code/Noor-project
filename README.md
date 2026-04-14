# Intellix (Clean Architecture)

This version of the Intellix App uses a Feature-First Clean Architecture.

## Structure
- **lib/core/**: Shared utilities, theme, and configuration.
- **lib/features/**: Feature-specific code.
  - **auth**: Authentication (Login, Signup, etc.)
  - **home**: Home screen and dashboard
  - **profile**: User profile
  - **trends**: Analytics and charts

## Features
- Scalable folder structure
- Separated concerns (Data, Domain, Presentation)
