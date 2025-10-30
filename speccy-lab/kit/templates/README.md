# Speccy-Kit Project Templates

This directory contains project templates for common development patterns. Each template includes a complete project structure with best practices, configurations, and tooling setup.

## Available Templates

### 🌐 Web Application (`web-app/`)
**Modern web application with React, TypeScript, and best practices**

- **Tech Stack**: Next.js 14, TypeScript, Tailwind CSS, React 18
- **Features**:
  - Responsive design with Tailwind CSS
  - TypeScript for type safety
  - ESLint and Prettier configuration
  - Jest and React Testing Library
  - Pre-commit hooks with Husky
  - SEO optimization
  - Performance optimization
  - Accessibility features

**Use Case**: Full-stack web applications, SPAs, progressive web apps

### 🚀 REST API (`api-rest/`)
**RESTful API with Node.js, Express, TypeScript, and best practices**

- **Tech Stack**: Node.js, Express.js, TypeScript, Prisma ORM
- **Features**:
  - Express.js with TypeScript
  - Prisma ORM for database management
  - JWT authentication and authorization
  - Swagger/OpenAPI documentation
  - Input validation with Joi
  - Error handling and logging
  - Rate limiting and security middleware
  - Docker containerization

**Use Case**: Backend APIs, microservices, data services

### ⚙️ CLI Tool (`cli-tool/`)
**Command-line interface tool with Node.js, TypeScript, and best practices**

- **Tech Stack**: Node.js, Commander.js, Inquirer, Chalk
- **Features**:
  - Commander.js for command parsing
  - Interactive prompts with Inquirer
  - Colored terminal output with Chalk
  - Configuration management
  - Logging and debugging
  - Help system and documentation
  - NPM package publishing ready

**Use Case**: Development tools, automation scripts, utilities

### 📚 Library (`library/`)
**Reusable library with TypeScript and best practices**

- **Tech Stack**: TypeScript, Rollup, Jest
- **Features**:
  - TypeScript for type safety
  - Multiple output formats (ESM, CJS, UMD)
  - Comprehensive test coverage
  - API documentation generation
  - NPM package publishing
  - Semantic versioning
  - Tree-shaking support

**Use Case**: Reusable components, utility libraries, SDKs

### 🔧 Microservice (`microservice/`)
**Microservice with Node.js, Express, and containerization**

- **Tech Stack**: Node.js, Express.js, Docker, Kubernetes
- **Features**:
  - Express.js with TypeScript
  - Docker containerization
  - Kubernetes deployment manifests
  - Service discovery
  - Health checks
  - Monitoring and logging
  - Circuit breaker pattern
  - API gateway integration

**Use Case**: Microservices, distributed systems, cloud services

### 📄 Static Site (`static-site/`)
**Static site generator with modern build tools**

- **Tech Stack**: Next.js, TypeScript, Tailwind CSS, MDX
- **Features**:
  - Static site generation
  - MDX for content authoring
  - Tailwind CSS for styling
  - SEO optimization
  - Performance optimization
  - Deployment to Vercel/Netlify
  - Content management integration

**Use Case**: Blogs, documentation sites, portfolios, marketing sites

## Template Structure

Each template follows a consistent structure:

```
template-name/
├── template.json           # Template configuration and metadata
├── files/                  # Template files with Handlebars variables
│   ├── package.json.hbs    # Package configuration
│   ├── README.md.hbs       # Project documentation
│   ├── .gitignore.hbs      # Git ignore file
│   └── ...                 # Other template files
├── scripts/                # Setup and build scripts
├── docs/                   # Template documentation
└── examples/               # Usage examples
```

## Using Templates

### Via CLI Tool

```bash
# Initialize a new web application
speccy init web-app my-project

# Initialize a REST API
speccy init api-rest my-api --template postgres

# Initialize a CLI tool
speccy init cli-tool my-tool --author "Your Name"
```

### Manual Setup

1. **Choose a template** based on your project needs
2. **Copy template files** to your project directory
3. **Replace variables** in template files (Handlebars syntax)
4. **Install dependencies** with `npm install`
5. **Configure environment** variables and settings
6. **Run setup commands** for the specific template

## Template Variables

Templates use Handlebars syntax for variable substitution:

```handlebars
{{projectName}}     # Project name (e.g., "my-app")
{{description}}     # Project description
{{author}}          # Author name
{{license}}         # License type
{{version}}         # Project version
{{date}}            # Current date
{{year}}            # Current year
```

## Customization

### Adding New Templates

1. Create a new directory in `templates/`
2. Create a `template.json` configuration file
3. Add template files with `.hbs` extension
4. Include setup scripts and documentation
5. Update the template registry

### Modifying Existing Templates

1. Navigate to the template directory
2. Modify `template.json` for configuration changes
3. Update template files in the `files/` directory
4. Test changes with sample projects
5. Update documentation

## Best Practices

### Template Design

- **Modular Structure**: Separate concerns into logical directories
- **Configuration Driven**: Use `template.json` for all configuration
- **Variable Substitution**: Use Handlebars for dynamic content
- **Documentation**: Include comprehensive README files
- **Examples**: Provide usage examples and tutorials

### File Organization

- **Consistent Naming**: Use kebab-case for directories and files
- **Logical Grouping**: Group related files together
- **Clear Documentation**: Document each file's purpose
- **Version Control**: Include appropriate `.gitignore` files
- **Environment Config**: Separate environment-specific settings

## Contributing

We welcome contributions to improve existing templates or add new ones:

1. **Fork the repository**
2. **Create a new branch** for your changes
3. **Follow template guidelines** and best practices
4. **Test thoroughly** with sample projects
5. **Submit a pull request** with detailed description

## Template Maintenance

- **Regular Updates**: Keep dependencies and tools up to date
- **Security Audits**: Regularly scan for vulnerabilities
- **Compatibility Testing**: Test with different Node.js versions
- **Documentation Updates**: Keep docs current with changes
- **Community Feedback**: Incorporate user suggestions

## Support

For template-related issues:

1. **Check existing issues** in the repository
2. **Create a new issue** with detailed description
3. **Include template name** and error details
4. **Provide reproduction steps** if possible

---

*Templates are part of the Speccy-Kit open-source development toolkit. For more information, see the main [Speccy-Kit documentation](../SPECCY_KIT.md).*