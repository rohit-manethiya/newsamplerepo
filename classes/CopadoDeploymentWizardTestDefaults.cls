@IsTest
public with sharing class CopadoDeploymentWizardTestDefaults {
    public with sharing class GitCommitDefaults extends AbstractTestData {
        public ITestDefaults setFieldDefaults() {
            Map<Schema.SObjectField, Object> defaults = new Map<Schema.SObjectField, Object> {
                Git_Commit__c.Commit_Id__c => 'gccmm',
                Git_Commit__c.Commit_Date__c => Datetime.now().date()
            };
            testDataFieldDefaultsByObject.put(Git_Commit__c.SObjectType, defaults);
            return this;
        }
    }

    public with sharing class GitBackupDefaults extends AbstractTestData {
        public ITestDefaults setFieldDefaults() {
            Map<Schema.SObjectField, Object> defaults = new Map<Schema.SObjectField, Object> {
                Git_Backup__c.Name => 'My git snapshot'
            };
            testDataFieldDefaultsByObject.put(Git_Backup__c.SObjectType, defaults);
            return this;
        }
    }

    public with sharing class GitOrgCommitDefaults extends AbstractTestData {
        public ITestDefaults setFieldDefaults() {
            Map<Schema.SObjectField, Object> defaults = new Map<Schema.SObjectField, Object> {
                Git_Org_Commit__c.Commit_Id__c => 'cmm',
                Git_Org_Commit__c.Commit_Date__c => Datetime.now().date()
            };
            testDataFieldDefaultsByObject.put(Git_Org_Commit__c.SObjectType, defaults);
            return this;
        }
    }

    public with sharing class DataTemplateDefaults extends AbstractTestData {
        public ITestDefaults setFieldDefaults() {
            Map<Schema.SObjectField, Object> defaults = new Map<Schema.SObjectField, Object> {
                Data_Template__c.Name => 'My data template',
                Data_Template__c.Description__c => 'Functional test data template',
                Data_Template__c.Main_Object__c => 'Account',
                Data_Template__c.Attachment_Options__c => 'Insert attachments',
                Data_Template__c.Continue_on_Error__c => 'Continue deployment until blocker issue',
                Data_Template__c.Active__c => true
            };
            testDataFieldDefaultsByObject.put(Data_Template__c.SObjectType, defaults);
            return this;
        }
    }
}