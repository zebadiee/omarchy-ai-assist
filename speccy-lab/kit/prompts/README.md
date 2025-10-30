# Speccy-Kit Prompt Framework

The Speccy-Kit Prompt Framework provides a comprehensive, modular system for AI-assisted development across multiple domains and contexts.

## Architecture

The framework is organized into three main categories:

### Base Prompts (`base/`)
Core expertise areas that form the foundation of development assistance:

- **[developer.md](base/developer.md)** - General software development expertise
- **[architect.md](base/architect.md)** - System design and architecture guidance
- **[reviewer.md](base/reviewer.md)** - Code review methodology and best practices

### Specialized Prompts (`specialized/`)
Domain-specific expertise for different technology areas:

- **[frontend.md](specialized/frontend.md)** - Modern web development and UI/UX
- **[backend.md](specialized/backend.md)** - Server-side development and APIs
- **[devops.md](specialized/devops.md)** - Infrastructure automation and deployment
- **[security.md](specialized/security.md)** - Security engineering and vulnerability mitigation

### Context Prompts (`context/`)
Situational assistance for specific development scenarios:

- **[debugging.md](context/debugging.md)** - Systematic troubleshooting and problem-solving
- **[optimization.md](context/optimization.md)** - Performance improvement and bottleneck analysis
- **[refactoring.md](context/refactoring.md)** - Code structure improvement and maintainability
- **[documentation.md](context/documentation.md)** - Technical writing and documentation creation

## Usage Guidelines

### Selecting the Right Prompt

1. **Start with Base Prompts** for general development tasks
2. **Use Specialized Prompts** for technology-specific questions
3. **Apply Context Prompts** for specific development scenarios

### Combining Prompts

The framework is designed to work synergistically:

```
Base Developer Knowledge + Specialized Domain + Context Scenario
```

Examples:
- `developer.md` + `backend.md` + `debugging.md` = Backend debugging assistance
- `architect.md` + `security.md` + `documentation.md` = Security architecture documentation
- `reviewer.md` + `frontend.md` + `optimization.md` = Frontend performance review

### Prompt Structure

Each prompt follows a consistent structure:

1. **Role Definition** - Clear definition of expertise and responsibilities
2. **Expertise Areas** - Specific domains and technical knowledge
3. **Guidelines** - Best practices and methodological approaches
4. **Common Patterns** - Reusable solutions and code examples
5. **Output Format** - Standardized response structure
6. **Examples** - Practical application scenarios
7. **Constraints** - Boundaries and principles to follow

## Integration with Speccy-Kit Tools

The prompt framework integrates seamlessly with Speccy-Kit development tools:

### Code Generation with Templates
- Use specialized prompts to generate language-specific code
- Apply context prompts for specific development scenarios
- Ensure adherence to architectural patterns from base prompts

### Code Review Integration
- Leverage reviewer.md for systematic code analysis
- Use specialized prompts for technology-specific validation
- Apply context prompts for targeted improvement areas

### Documentation Generation
- Combine architecture and specialized prompts for API documentation
- Use context prompts for specific documentation types
- Ensure consistent style and structure

## Customization and Extension

### Adding New Prompts

Follow the established structure when creating new prompts:

1. **Determine Category** - Base, Specialized, or Context
2. **Define Role and Expertise** - Clear scope and capabilities
3. **Follow Structure** - Use the established template format
4. **Include Examples** - Provide practical usage scenarios
5. **Maintain Consistency** - Follow formatting and style guidelines

### Modifying Existing Prompts

- **Update Examples** - Keep code examples current and tested
- **Expand Expertise** - Add new technologies and methodologies
- **Refine Guidelines** - Incorporate lessons learned and best practices
- **Improve Examples** - Add new scenarios and edge cases

## Quality Assurance

### Review Process

1. **Content Accuracy** - Verify technical accuracy and current best practices
2. **Example Validation** - Test code examples and ensure they work
3. **Consistency Check** - Maintain consistent terminology and formatting
4. **Completeness Review** - Ensure comprehensive coverage of the domain
5. **Usability Testing** - Validate effectiveness in real scenarios

### Maintenance Schedule

- **Monthly Review** - Check for outdated information and examples
- **Quarterly Updates** - Incorporate new technologies and methodologies
- **Annual Overhaul** - Comprehensive review and restructuring
- **Continuous Improvement** - Incorporate user feedback and lessons learned

## Best Practices

### For Users

1. **Read the Full Prompt** - Understand the complete context and capabilities
2. **Provide Clear Context** - Include relevant project details and constraints
3. **Specify Output Format** - Request appropriate format for your needs
4. **Iterate and Refine** - Provide feedback to improve response quality
5. **Combine Prompts** - Use multiple prompts for complex scenarios

### For Contributors

1. **Follow Standards** - Maintain consistent structure and formatting
2. **Test Examples** - Ensure all code examples are functional
3. **Document Changes** - Keep track of modifications and improvements
4. **Seek Feedback** - Validate changes with the community
5. **Maintain Quality** - Uphold high standards for content accuracy

## Getting Started

1. **Explore Base Prompts** - Understand the foundational expertise
2. **Identify Specialization** - Choose relevant specialized prompts
3. **Select Context** - Apply appropriate context prompts for scenarios
4. **Combine and Customize** - Create effective prompt combinations
5. **Provide Feedback** - Help improve the framework through usage

## Community and Support

The Speccy-Kit Prompt Framework is an open-source project. Contributions, feedback, and suggestions are welcome through the standard community channels.

---

*This framework is part of the Speccy-Kit open-source development toolkit. For more information, see the main [Speccy-Kit documentation](../SPECCY_KIT.md).*