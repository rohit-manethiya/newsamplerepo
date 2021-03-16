public with sharing class DataDeployer {
    private static final String ADVANCED_DEPLOYMENT_RECORD_TYPE_ID = Schema.SObjectType.Deployment__c.getRecordTypeInfosByDeveloperName()
        .get('Advanced_multi_step')
        .getRecordTypeId();
    private static final String DEPLOYMENT_NAME = 'Data Deploy';
    private static final String STEP_NAME = 'Step 1';
    private static final String DATA_TEMPLATE_TYPE = 'Data Template';
    private static final String SCHEDULED_STATUS = 'Scheduled';

    private DataDeployRequest deployRequest;

    private Deployment__c dataDeployment;

    private Id currentOrgCredential {
        get {
            if (currentOrgCredential == null) {
                String orgId = UserInfo.getOrganizationId() + '_' + UserInfo.getUserId();
                List<Org__c> orgs = [
                    SELECT Id
                    FROM Org__c
                    WHERE Validated_Date__c != NULL AND SFDC_Org_ID__c = :orgId
                    WITH SECURITY_ENFORCED
                    LIMIT 1
                ];
                if (orgs.isEmpty()) {
                    throw new DataDeployerException(Label.Error_Getting_Current_Org_Credential);
                }
                currentOrgCredential = orgs[0].Id;
            }
            return currentOrgCredential;
        }
        set;
    }

    public DataDeployer(DataDeployRequest deployRequest) {
        List<String> errors = validateRequest(deployRequest);
        if (!errors.isEmpty()) {
            throw new DataDeployerException(String.join(errors, ', '));
        }
        this.deployRequest = deployRequest;
    }

    public Id execute() {
        this.dataDeployment = createDeployment();

        createStep();

        if (this.deployRequest.getDeployNow() == true) {
            setDeploymentToScheduled();

            if (this.deployRequest.getDestinationType() == DataDeployRequest.Destination.DATASET) {
                setDataSetLastGeneratedDate();
            }

            deploy();
        }

        return this.dataDeployment.Id;
    }

    private List<String> validateRequest(DataDeployRequest request) {
        List<String> errors = new List<String>();
        if (request.getSourceType() == null) {
            errors.add(Label.Data_Source_Required);
        }
        if (request.getDestinationType() == null) {
            errors.add(Label.Data_Destination_Required);
        }
        if (request.getSourceType() == DataDeployRequest.Source.ENVIRONMENT && request.getDataTemplateId() == null) {
            errors.add(Label.Data_Template_Id_Required);
        }
        if (request.getSourceType() == DataDeployRequest.Source.DATASET && request.getSourceDataSetId() == null) {
            errors.add(Label.Source_Data_Set_Id_Required);
        }
        if (request.getSourceType() == DataDeployRequest.Source.BRANCH && request.getSourceBranchName() == null) {
            errors.add(Label.Source_Branch_Name_Required);
        }
        if (request.getDestinationType() == DataDeployRequest.Destination.DATASET && request.getDestinationDataSetId() == null) {
            errors.add(Label.Destination_Data_Set_Id_Required);
        }
        if (request.getDestinationType() == DataDeployRequest.Destination.BRANCH && request.getDestinationBranchName() == null) {
            errors.add(Label.Destination_Branch_Name_Required);
        }
        return errors;
    }

    private Deployment__c createDeployment() {
        Id sourceCrendentialId = this.deployRequest.getSourceCredentialId() != null
            ? this.deployRequest.getSourceCredentialId()
            : currentOrgCredential;

        Deployment__c dataDeployment = new Deployment__c(
            Name = DEPLOYMENT_NAME,
            From_Org__c = sourceCrendentialId,
            RecordTypeId = ADVANCED_DEPLOYMENT_RECORD_TYPE_ID
        );

        Utilities.Secure_DML(dataDeployment, Utilities.DML_Action.INS, Schema.SObjectType.Deployment__c);

        Id destinationCredentialId = this.deployRequest.getDestinationCredentialId() != null
            ? this.deployRequest.getDestinationCredentialId()
            : dataDeployment.From_Org__c;

        Destination_Org__c destinationOrg = new Destination_Org__c(Deployment__c = dataDeployment.Id, To_Org__c = destinationCredentialId);

        Utilities.Secure_DML(destinationOrg, Utilities.DML_Action.INS, Schema.SObjectType.Destination_Org__c);

        return dataDeployment;
    }

    private void createStep() {
        String dataJson = generateDataJson();

        String stepName = getStepName();

        Step__c dataTemplateStep = new Step__c(
            dataJson__c = dataJson,
            Deployment__c = this.dataDeployment.Id,
            Name = stepName,
            Type__c = DATA_TEMPLATE_TYPE
        );

        Utilities.Secure_DML(dataTemplateStep, Utilities.DML_Action.INS, Schema.SObjectType.Step__c);
    }

    private String generateDataJson() {
        DataStepData data = new DataStepData(this.deployRequest);
        return JSON.serialize(data, true);
    }

    private String getStepName() {
        String stepName = STEP_NAME;
        if (this.deployRequest.getDestinationType() == DataDeployRequest.Destination.DATASET) {
            List<Data_Set__c> dataSets = [
                SELECT Name
                FROM Data_Set__c
                WHERE Id = :this.deployRequest.getDestinationDataSetId()
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];
            if (!dataSets.isEmpty()) {
                Data_Set__c destinationDataSet = dataSets[0];
                stepName = 'Generate ' + destinationDataSet.Name;
            }
        }
        return stepName;
    }

    private void setDeploymentToScheduled() {
        Deployment__c updatedDeployment = new Deployment__c(
            Id = this.dataDeployment.Id,
            Status__c = SCHEDULED_STATUS,
            Date__c = System.now(),
            Deployment_command_sent__c = null
        );

        Utilities.Secure_DML(updatedDeployment, Utilities.DML_Action.UPD, Schema.SObjectType.Deployment__c);
    }

    private void setDataSetLastGeneratedDate() {
        Data_Set__c updatedDataSet = new Data_Set__c(Id = this.deployRequest.getDestinationDataSetId(), Last_Generated_Date__c = System.now());

        Utilities.Secure_DML(updatedDataSet, Utilities.DML_Action.UPD, Schema.SObjectType.Data_Set__c);
    }

    private void deploy() {
        DeployAPI.deploy(new List<Id>{ this.dataDeployment.Id }, null);
    }

    public class DataDeployerException extends Exception {
    }
}