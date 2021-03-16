public with sharing class DataTemplateDeploymentValidationResult {
    public static final String ATTACHMENT_NAME = 'Data Template Validation Result';

    private List<ValidationError> errors;

    public DataTemplateDeploymentValidationResult() {
        this.errors = new List<ValidationError>();
    }

    public DataTemplateDeploymentValidationResult addError(String environment, String objectName, String message) {
        addError(new ValidationError(environment, objectName, message));
        return this;
    }

    public DataTemplateDeploymentValidationResult addError(ValidationError error) {
        addErrors(new List<ValidationError>{ error });
        return this;
    }

    public DataTemplateDeploymentValidationResult addErrors(List<ValidationError> errors) {
        this.errors.addAll(errors);
        return this;
    }

    public List<ValidationError> getErrors() {
        return this.errors;
    }

    public with sharing class ValidationError {
        public String environment { get; private set; }
        public String objectName { get; private set; }
        public String message { get; private set; }

        public ValidationError(String environment, String objectName, String message) {
            this.environment = environment;
            this.objectName = objectName;
            this.message = message;
        }
    }
}