public with sharing class DataDeployRequest {
    public enum Source {
        ENVIRONMENT,
        DATASET,
        BRANCH
    }

    public enum Destination {
        ENVIRONMENT,
        DATASET,
        BRANCH
    }

    private Id dataTemplateId;
    private DataDeployRequest.Source sourceType;
    private DataDeployRequest.Destination destinationType;
    private Id sourceCredentialId;
    private Id destinationCredentialId;
    private Id sourceDataSetId;
    private Id destinationDataSetId;
    private String sourceBranchName;
    private String destinationBranchName;
    private Boolean deployNow;

    public DataDeployRequest() {
        this.deployNow = false;
    }

    public Id getDataTemplateId() {
        return this.dataTemplateId;
    }

    public DataDeployRequest dataTemplateId(Id dataTemplateId) {
        this.dataTemplateId = dataTemplateId;
        return this;
    }

    public DataDeployRequest.Source getSourceType() {
        return this.sourceType;
    }

    public DataDeployRequest sourceType(String sourceType) {
        this.sourceType = sourceTypeFromString(sourceType);
        return this;
    }

    public DataDeployRequest sourceType(DataDeployRequest.Source sourceType) {
        this.sourceType = sourceType;
        return this;
    }

    public DataDeployRequest.Destination getDestinationType() {
        return this.destinationType;
    }

    public DataDeployRequest destinationType(String destinationType) {
        this.destinationType = destinationTypeFromString(destinationType);
        return this;
    }

    public DataDeployRequest destinationType(DataDeployRequest.Destination destinationType) {
        this.destinationType = destinationType;
        return this;
    }

    public Id getSourceCredentialId() {
        return this.sourceCredentialId;
    }

    public DataDeployRequest sourceCredentialId(Id sourceCredentialId) {
        this.sourceCredentialId = sourceCredentialId;
        return this;
    }

    public Id getDestinationCredentialId() {
        return this.destinationCredentialId;
    }

    public DataDeployRequest destinationCredentialId(Id destinationCredentialId) {
        this.destinationCredentialId = destinationCredentialId;
        return this;
    }

    public Id getSourceDataSetId() {
        return this.sourceDataSetId;
    }

    public DataDeployRequest sourceDataSetId(Id sourceDataSetId) {
        this.sourceDataSetId = sourceDataSetId;
        return this;
    }

    public Id getDestinationDataSetId() {
        return this.destinationDataSetId;
    }

    public DataDeployRequest destinationDataSetId(Id destinationDataSetId) {
        this.destinationDataSetId = destinationDataSetId;
        return this;
    }

    public String getSourceBranchName() {
        return this.sourceBranchName;
    }

    public DataDeployRequest sourceBranchName(String sourceBranchName) {
        this.sourceBranchName = sourceBranchName;
        return this;
    }

    public String getDestinationBranchName() {
        return this.destinationBranchName;
    }

    public DataDeployRequest destinationBranchName(String destinationBranchName) {
        this.destinationBranchName = destinationBranchName;
        return this;
    }

    public Boolean getDeployNow() {
        return this.deployNow;
    }

    public DataDeployRequest deployNow(Boolean deployNow) {
        this.deployNow = deployNow;
        return this;
    }

    public static DataDeployRequest.Source sourceTypeFromString(String value) {
        DataDeployRequest.Source source;
        for (DataDeployRequest.Source sourceOption : DataDeployRequest.Source.values()) {
            if (sourceOption.name() == value) {
                source = sourceOption;
                break;
            }
        }
        return source;
    }

    public static DataDeployRequest.Destination destinationTypeFromString(String value) {
        DataDeployRequest.Destination destination;
        for (DataDeployRequest.Destination destinationOption : DataDeployRequest.Destination.values()) {
            if (destinationOption.name() == value) {
                destination = destinationOption;
                break;
            }
        }
        return destination;
    }
}