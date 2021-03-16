global with sharing class DeployDataAction {
    global with sharing class Request {
        @InvocableVariable(label='Data Template Id' description='Required if source type is Environment' required=false)
        global String dataTemplateId;
        @InvocableVariable(
            label='Source type'
            description='Possible values: Enum options in DataDeployer.Source (i.e. Environment, Data Set, Branch)'
            required=false
        )
        global String sourceType;
        @InvocableVariable(
            label='Destination type'
            description='Possible values: Enum options in DataDeployer.Destination (i.e. Environment, Data Set, Branch)'
            required=false
        )
        global String destinationType;
        @InvocableVariable(label='Source Credential Id' description='If not specified, current Org Credential will be used' required=false)
        global String sourceCredentialId;
        @InvocableVariable(label='Destination Credential Id' description='If not specified, current Org Credential will be used' required=false)
        global String destinationCredentialId;
        @InvocableVariable(label='Source Data Set Id' description='Required if source type is Data Set' required=false)
        global String sourceDataSetId;
        @InvocableVariable(label='Destination Data Set Id' description='Required if destination type is Data Set' required=false)
        global String destinationDataSetId;
        @InvocableVariable(label='Source Branch name' description='Required if source type is Branch' required=false)
        global String sourceBranchName;
        @InvocableVariable(label='Destination Branch name' description='Required if destination type is Branch' required=false)
        global String destinationBranchName;
        @InvocableVariable(label='Execute Immediately' description='Default is false' required=false)
        global Boolean deployNow;
    }

    @InvocableMethod(
        label='Deploy Data'
        description='Deploy data using Data Templates/Data Sets. This method creates a multi-step deployment with a Data Template step and (optionally) executes it. It returns the deployment Id.'
    )
    global static List<Id> execute(List<DeployDataAction.Request> requests) {
        List<Id> deploymentIds = new List<Id>();

        for (DeployDataAction.Request request : requests) {
            DataDeployRequest deployRequest = new DataDeployRequest()
                .dataTemplateId(String.isNotBlank(request.dataTemplateId) ? request.dataTemplateId : null)
                .sourceType(request.sourceType)
                .sourceCredentialId(String.isNotBlank(request.sourceCredentialId) ? request.sourceCredentialId : null)
                .sourceDataSetId(String.isNotBlank(request.sourceDataSetId) ? request.sourceDataSetId : null)
                .sourceBranchName(request.sourceBranchName)
                .destinationType(request.destinationType)
                .destinationCredentialId(String.isNotBlank(request.destinationCredentialId) ? request.destinationCredentialId : null)
                .destinationDataSetId(String.isNotBlank(request.destinationDataSetId) ? request.destinationDataSetId : null)
                .destinationBranchName(request.destinationBranchName)
                .deployNow(request.deployNow);

            Id deploymentId = new DataDeployer(deployRequest).execute();

            deploymentIds.add(deploymentId);
        }

        return deploymentIds;
    }
}