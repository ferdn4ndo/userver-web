# Contributing to uServer-Web

Thank you for your interest in contributing to uServer-Web! This document provides guidelines and instructions for contributing to this project.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Pull Request Process](#pull-request-process)
- [Coding Standards](#coding-standards)
- [Testing](#testing)
- [Documentation](#documentation)

## Code of Conduct

By participating in this project, you agree to maintain a respectful and inclusive environment for everyone. Please be kind and courteous to others, and avoid any form of harassment or discrimination.

## Getting Started

1. Fork the repository on GitHub
2. Clone your fork locally
3. Set up the development environment using the setup script:
   ```bash
   ./scripts/userver.sh setup
   ```
4. Create a new branch for your feature or bug fix:
   ```bash
   git checkout -b feature/your-feature-name
   ```

## Development Workflow

1. Make your changes in your feature branch
2. Run tests to ensure your changes don't break existing functionality:
   ```bash
   ./scripts/userver.sh test
   ```
3. Commit your changes with a descriptive commit message:
   ```bash
   git commit -m "Add feature: your feature description"
   ```
4. Push your changes to your fork:
   ```bash
   git push origin feature/your-feature-name
   ```
5. Create a Pull Request from your fork to the main repository

## Pull Request Process

1. Ensure your code passes all tests
2. Update the README.md with details of changes if applicable
3. Update the documentation if necessary
4. The PR should work in all supported environments (Linux, macOS, Windows with WSL)
5. Your PR will be reviewed by maintainers, who may request changes
6. Once approved, your PR will be merged

## Coding Standards

### Shell Scripts

- All shell scripts should be compatible with Bash
- Use ShellCheck to validate your scripts
- Follow the [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- Use meaningful variable and function names
- Add comments for complex logic
- Use proper error handling

### Docker and Docker Compose

- Use specific versions for base images
- Minimize the number of layers in Dockerfiles
- Follow best practices for Docker Compose files
- Ensure services are properly configured for security

## Testing

The project includes several types of tests:

- **Unit Tests**: Test individual functions and components
- **Integration Tests**: Test interactions between components
- **End-to-End Tests**: Test the entire system

To run tests:

```bash
# Run all tests
./scripts/userver.sh test

# Run specific test types
./scripts/userver.sh test --unit-tests
./scripts/userver.sh test --integration
./scripts/userver.sh test --e2e
./scripts/userver.sh test --shellcheck
```

## Documentation

- Keep the README.md up to date
- Document all scripts and their options
- Add comments to complex code sections
- Update the documentation when adding new features or changing existing ones

Thank you for contributing to uServer-Web!
