@IsTest
public with sharing class CopadoPipelineWizardTestDefaults {
    public with sharing class GitRepositoryDefaults extends AbstractTestData {
        public ITestDefaults setFieldDefaults() {
            Map<Schema.SObjectField, Object> defaults = new Map<Schema.SObjectField, Object>{
                Git_Repository__c.Name => 'MyGitRepo',
                Git_Repository__c.Source_Format__c => 'Metadata'
            };
            testDataFieldDefaultsByObject.put(Git_Repository__c.SObjectType, defaults);
            return this;
        }
    }

    public with sharing class SensitiveInformationDefaults extends AbstractTestData {
        public ITestDefaults setFieldDefaults() {
            Map<Schema.SObjectField, Object> defaults = new Map<Schema.SObjectField, Object>{
                Sensitive_Information__c.Username__c => 'UserName',
                Sensitive_Information__c.Password__c => DeployAPI.encryptAPIKey('password')
            };
            testDataFieldDefaultsByObject.put(Sensitive_Information__c.SObjectType, defaults);
            return this;
        }
    }
}