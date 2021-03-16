@IsTest
private with sharing class TestDynamicVariablesInterpreter {
    private static final String STANDARD_USER = 'test_user@myorg.com';
    @TestSetup
    static void makeData() {
        TestUtilities.enableLicenses(2, 2, 2, 2, 2, 30);
        ITestDefaults userCreation = new CopadoSetupTestDefaults.UserDefaults().createRunAsUsers().executeDML();
    }

    @IsTest
    static void testGetDynamicVariablesInterpreted() {
        User standardUser = [SELECT Username FROM User WHERE Username = :STANDARD_USER LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, false, false, false, false);

        System.runAs(standardUser) {
            Settings__c setting = Settings__c.getOrgDefaults();
            setting.CryptoKey__c = EncodingUtil.base64Encode(Crypto.generateAesKey(256));
            upsert setting;

            Personal_Settings__c personalSetting = Personal_Settings__c.getInstance();
            personalSetting.API_Key__c = DeployAPI.encryptAPIKey('testApiKey');
            upsert personalSetting;

            ITestDefaults environmentDefaults = new CopadoSetupTestDefaults.EnvironmentDefaults()
                .setFieldDefaults()
                .setFieldValue(Environment__c.SObjectType, Environment__c.Name, 'Copado')
                .setDataSize(Environment__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CopadoSetupTestDefaults.EnvironmentDefaults.class)
                .setFieldValue(Environment__c.SObjectType, Environment__c.Name, 'Production')
                .setFieldValue(Environment__c.SObjectType, Environment__c.Org_ID__c, 'testOrgId')
                .setDataSize(Environment__c.SObjectType, 1)
                .generateDefaults()
                .executeDML();

            Environment__c copadoEnvironment;
            Environment__c productionEnvironment;

            for (Environment__c env : (List<Environment__c>) environmentDefaults.getTestData(Environment__c.SObjectType)) {
                switch on env.Name {
                    when 'Copado 0' {
                        copadoEnvironment = env;
                    }
                    when 'Production 0' {
                        productionEnvironment = env;
                    }
                }
            }

            String sfdcOrgId = UserInfo.getOrganizationId() + '_' + UserInfo.getUserId();
            ITestDefaults orgCredentialDefaults = new CopadoSetupTestDefaults.OrgCredentialDefaults()
                .setFieldDefaults()
                .setFieldValue(Org__c.SObjectType, Org__c.Name, 'Copado')
                .setFieldValue(Org__c.SObjectType, Org__c.Environment__c, copadoEnvironment.Id)
                .setFieldValue(Org__c.SObjectType, Org__c.Default_Credential__c, true)
                .setFieldValue(Org__c.SObjectType, Org__c.Validated_Date__c, System.now())
                .setFieldValue(Org__c.SObjectType, Org__c.SFDC_Org_ID__c, sfdcOrgId)
                .setDataSize(Org__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CopadoSetupTestDefaults.OrgCredentialDefaults.class)
                .setFieldValue(Org__c.SObjectType, Org__c.Name, 'Production')
                .setFieldValue(Org__c.SObjectType, Org__c.Environment__c, productionEnvironment.Id)
                .setFieldValue(Org__c.SObjectType, Org__c.Default_Credential__c, true)
                .setDataSize(Org__c.SObjectType, 1)
                .generateDefaults()
                .executeDML();

            Org__c copadoOrg = new Org__c();
            Org__c productionOrg = new Org__c();

            for (Org__c org : (List<Org__c>) orgCredentialDefaults.getTestData(Org__c.SObjectType)) {
                switch on org.Name {
                    when 'Copado 0' {
                        copadoOrg = org;
                    }
                    when 'Production 0' {
                        productionOrg = org;
                    }
                }
            }

            ITestDefaults deploymentDefaults = new CopadoUserStoryTestDefaults.DeploymentDefaults()
                .setFieldDefaults()
                .setFieldValue(Deployment__c.SObjectType, Deployment__c.From_Org__c, productionOrg.Id)
                .setDataSize(Deployment__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CopadoUserStoryTestDefaults.DeploymentStepDefaults.class)
                .setFieldValue(Step__c.SObjectType, Step__c.Status__c, 'Pending')
                .setFieldValue(Step__c.SObjectType, Step__c.Type__c, 'Salesforce Flow')
                .setFieldValue(Step__c.SObjectType, Step__c.DataJson__c, '{"flowApiName": "TestFlow","type":"wait","flowParameters":[]}')
                .setDataSize(Step__c.SObjectType, 1)
                .setSObjectRelation(
                    Step__c.SObjectType,
                    Deployment__c.SObjectType,
                    new Map<Schema.SObjectField, Integer>{ Step__c.Deployment__c => 1 }
                )
                .generateDefaults()
                .executeDML();

            Deployment__c deployment = (Deployment__c) deploymentDefaults.getTestData(Deployment__c.SObjectType)[0];

            Destination_Org__c destinationOrg = testMethodUtilities.create(deployment.Id, 'Pending', productionOrg.Id);
            insert destinationOrg;

            Step__c salesforceFlowStep = (Step__c) deploymentDefaults.getTestData(Step__c.SObjectType)[0];

            Deployment_Job__c deploymentJob = [
                SELECT
                    Destination_Org__r.To_Org__r.Environment__r.Org_ID__c,
                    Step__r.Deployment__r.From_Org__r.Environment__r.Org_ID__c,
                    Step__r.Deployment__r.Promotion__c
                FROM Deployment_Job__c
                WHERE Step__c = :salesforceFlowStep.Id AND Destination_org__c = :destinationOrg.Id
            ];

            final Map<String, Object> parameterValuesByName = new Map<String, Object>{
                'Copado Org Id' => '{!CopadoOrg.OrgId}',
                'Copado Org Credential Id' => '{!CopadoOrg.CredentialId}',
                'Copado Org Api Key' => '{!CopadoOrg.ApiKey}',
                'Source Org Id' => '{!Source.OrgId}',
                'Source Credential Id' => '{!Source.CredentialId}',
                'Destination Org Id' => '{!Destination.OrgId}',
                'Destination Credential Id' => '{!Destination.CredentialId}',
                'Deployment Id' => '{!Deployment.Id}',
                'Deployment Job Id' => '{!Deployment.JobId}',
                'Promotion Id' => '{!Promotion.Id}',
                'Resume URL' => '{!ResumeURL}'
            };

            Test.startTest();
            final Map<String, Object> parameterValuesInterpretedByName = DynamicVariablesInterpreter.getDynamicVariablesInterpreted(
                deploymentJob,
                parameterValuesByName
            );
            Test.stopTest();

            // Prepare data for assertions
            final String resumeUrl =
                Settings.server_url +
                '/json/v1/webhook/resumeDeployment/' +
                deploymentJob.Id +
                '?api_key=' +
                DynamicVariablesInterpreter.currentUserApiKey +
                '&deploymentId=' +
                deploymentJob.Step__r.Deployment__r.Id;

            System.assertEquals(
                parameterValuesInterpretedByName.get('Copado Org Id'),
                UserInfo.getOrganizationId(),
                'Copado Organization Id should match'
            );
            System.assertEquals(
                parameterValuesInterpretedByName.get('Copado Org Credential Id'),
                [SELECT Id FROM Org__c WHERE Name = 'Copado 0']
                .Id,
                'Copado Org Credential Id should match'
            );
            System.assertEquals(
                parameterValuesInterpretedByName.get('Copado Org Api Key'),
                DynamicVariablesInterpreter.currentUserApiKey,
                'User Api Key should match'
            );
            System.assertEquals(
                parameterValuesInterpretedByName.get('Destination Org Id'),
                deploymentJob.Destination_Org__r.To_Org__r.Environment__r.Org_ID__c,
                'Destination Organization Id should match'
            );
            System.assertEquals(
                parameterValuesInterpretedByName.get('Destination Credential Id'),
                deploymentJob.Destination_Org__r.To_Org__r.Id,
                'Destination Org Credential Id should match'
            );
            System.assertEquals(
                parameterValuesInterpretedByName.get('Source Org Id'),
                deploymentJob.Step__r.Deployment__r.From_Org__r.Environment__r.Org_ID__c,
                'Source Organization Id should match'
            );
            System.assertEquals(
                parameterValuesInterpretedByName.get('Source Credential Id'),
                deploymentJob.Step__r.Deployment__r.From_Org__r.Id,
                'Source Org Credential Id should match'
            );
            System.assertEquals(
                parameterValuesInterpretedByName.get('Deployment Id'),
                deploymentJob.Step__r.Deployment__r.Id,
                'Deployment Id should match'
            );
            System.assertEquals(parameterValuesInterpretedByName.get('Resume URL'), resumeUrl, 'ResumeURL should match');
            System.assertEquals(parameterValuesInterpretedByName.get('Deployment Job Id'), deploymentJob.Id, 'Deployment Job Id should match');
            System.assertEquals(
                parameterValuesInterpretedByName.get('Promotion Id'),
                deploymentJob.Step__r.Deployment__r.Promotion__c,
                'Promotion Id should match'
            );
        }
    }
}