public with sharing class CCDFullCycleTestDefaults {
    public class SeleniumSettingDefaults extends AbstractTestData {
        public ITestDefaults setFieldDefaults() {
            Map<Schema.SObjectField, Object> defaults = new Map<Schema.SObjectField, Object>{
                Selenium_Settings__c.Name => 'uucka Quick Test Settings',
                Selenium_Settings__c.Provider__c => 'Custom/Other',
                Selenium_Settings__c.Webdriver_URL__c => 'https://webdriver.copado.com',
                Selenium_Settings__c.Selected_Platforms__c => '[copado]chrome'
            };
            testDataFieldDefaultsByObject.put(Selenium_Settings__c.SObjectType, defaults);
            return this;
        }
    }

    public class GitRepositoryDefaults extends AbstractTestData {
        public ITestDefaults setFieldDefaults() {
            Map<Schema.SObjectField, Object> defaults = new Map<Schema.SObjectField, Object>{ Git_Repository__c.Name => 'gitRepo' };
            testDataFieldDefaultsByObject.put(Git_Repository__c.SObjectType, defaults);
            return this;
        }
    }

    public class StaticCodeAnalysisSettingDefaults extends AbstractTestData {
        public ITestDefaults setFieldDefaults() {
            Map<Schema.SObjectField, Object> defaults = new Map<Schema.SObjectField, Object>{
                Static_Code_Analysis_Settings__c.Name => 'CodeScans',
                Static_Code_Analysis_Settings__c.RecordTypeId => Schema.SObjectType.Static_Code_Analysis_Settings__c.getRecordTypeInfosByDeveloperName()
                    .get('PMD')
                    .getRecordTypeId(),
                Static_Code_Analysis_Settings__c.CodeScan_Token__c => 'CodeScanTokenTest'
            };
            testDataFieldDefaultsByObject.put(Static_Code_Analysis_Settings__c.SObjectType, defaults);
            return this;
        }
    }
    //need to update
    //Git_Repository__c
    //Static_Code_Analysis_Settings__c
    public class PipelineDefaults extends AbstractTestData {
        public ITestDefaults setFieldDefaults() {
            Map<Schema.SObjectField, Object> defaults = new Map<Schema.SObjectField, Object>{
                Deployment_Flow__c.Name => 'CBM flow',
                Deployment_Flow__c.Active__c => true,
                Deployment_Flow__c.Main_Branch__c => 'master'
            };
            testDataFieldDefaultsByObject.put(Deployment_Flow__c.SObjectType, defaults);
            return this;
        }
    }
    //need to update
    //Deployment_Flow__c
    public class ProjectDefaults extends AbstractTestData {
        public ITestDefaults setFieldDefaults() {
            Map<Schema.SObjectField, Object> defaults = new Map<Schema.SObjectField, Object>{ Project__c.Name => 'test project' };
            testDataFieldDefaultsByObject.put(Project__c.SObjectType, defaults);
            return this;
        }
    }
    public class EnvironmentDefaults extends AbstractTestData {
        public ITestDefaults setFieldDefaults() {
            Map<Schema.SObjectField, Object> defaults = new Map<Schema.SObjectField, Object>{
                Environment__c.Name => 'Dev1 Environment',
                Environment__c.Type__c => 'Production/Developer'
            };
            testDataFieldDefaultsByObject.put(Environment__c.SObjectType, defaults);
            return this;
        }
    }
    //need to update
    //Environment__c
    public class OrgCredentialDefaults extends AbstractTestData {
        public ITestDefaults setFieldDefaults() {
            Map<Schema.SObjectField, Object> defaults = new Map<Schema.SObjectField, Object>{
                Org__c.Name => 'Dev1',
                Org__c.Org_Type__c => 'Sandbox',
                Org__c.Token__c => null,
                Org__c.Username__c => null,
                Org__c.Validated_Date__c => System.now()
            };
            testDataFieldDefaultsByObject.put(Org__c.SObjectType, defaults);
            return this;
        }
    }
    //need to update
    //Environment__c
    //Selenium_Settings__c
    public class SeleniumTestGroupDefaults extends AbstractTestData {
        public ITestDefaults setFieldDefaults() {
            Map<Schema.SObjectField, Object> defaults = new Map<Schema.SObjectField, Object>{
                Selenium_Test_Group__c.Name => 'Regression Test - ',
                Selenium_Test_Group__c.Type__c => 'Regression Test',
                Selenium_Test_Group__c.Description__c => 'Test Quality gate',
                Selenium_Test_Group__c.Manage_Test_Runs_manually__c => false
            };
            testDataFieldDefaultsByObject.put(Selenium_Test_Group__c.SObjectType, defaults);
            return this;
        }
    }
    //need to update
    //Source_Environment__c
    //Destination_Environment__c
    //Deployment_Flow__c
    public class PipelineConnectionDefaults extends AbstractTestData {
        public ITestDefaults setFieldDefaults() {
            Map<Schema.SObjectField, Object> defaults = new Map<Schema.SObjectField, Object>{ Deployment_Flow_Step__c.branch__c => 'dev1' };
            testDataFieldDefaultsByObject.put(Deployment_Flow_Step__c.SObjectType, defaults);
            return this;
        }
    }
    //need to update
    //Environment__c
    //Org_Credential__c
    //Project__c
    public class UserStoryDefaults extends AbstractTestData {
        public ITestDefaults setFieldDefaults() {
            Map<Schema.SObjectField, Object> defaults = new Map<Schema.SObjectField, Object>{
                User_Story__c.User_Story_Title__c => 'prevent duplicate for forward promotion control',
                User_Story__c.Promote_Change__c => true,
                User_Story__c.Exclude_From_CBM__c => false,
                User_Story__c.Status__c => 'Ready for Testing'
            };
            testDataFieldDefaultsByObject.put(User_Story__c.SObjectType, defaults);
            return this;
        }
    }
    //need to update
    //Promotion_Behavior__c(optional)
    //Back_Promotion_Behavior__c(optional)
    public class ConnectionBehaviorDefaults extends AbstractTestData {
        public ITestDefaults setFieldDefaults() {
            Map<Schema.SObjectField, Object> defaults = new Map<Schema.SObjectField, Object>{
                Connection_Behavior__c.Name => 'CCD',
                Connection_Behavior__c.Promotion_Behavior__c => 'Automated',
                Connection_Behavior__c.Back_Promotion_Behavior__c => 'Automated'
            };
            testDataFieldDefaultsByObject.put(Connection_Behavior__c.SObjectType, defaults);
            return this;
        }
    }
    public class MetadataGroupDefaults extends AbstractTestData {
        public ITestDefaults setFieldDefaults() {
            Map<Schema.SObjectField, Object> defaults = new Map<Schema.SObjectField, Object>{ Metadata_Group__c.Name => 'apex test' };
            testDataFieldDefaultsByObject.put(Metadata_Group__c.SObjectType, defaults);
            return this;
        }
    }
    //need to update
    //Metadata_Group__c
    //Type__c(optional)
    //Operator__c(optional)
    //Value__c(optional)
    public class MetadataGroupItemDefaults extends AbstractTestData {
        public ITestDefaults setFieldDefaults() {
            Map<Schema.SObjectField, Object> defaults = new Map<Schema.SObjectField, Object>{
                Metadata_Group_Item__c.Type__c => 'ApexClass',
                Metadata_Group_Item__c.Operator__c => 'All',
                Metadata_Group_Item__c.Value__c => ''
            };
            testDataFieldDefaultsByObject.put(Metadata_Group_Item__c.SObjectType, defaults);
            return this;
        }
    }
    //need to update
    //Connection_Behavior__c
    //Metadata_Group__c
    //Static_Code_Analysis_Settings__c(optional)
    public class QualityGateDefaults extends AbstractTestData {
        public ITestDefaults setFieldDefaults() {
            Map<Schema.SObjectField, Object> defaults = new Map<Schema.SObjectField, Object>{
                Quality_Gate__c.Name => 'apex test',
                Quality_Gate__c.Type__c => 'Apex Test with Validation',
                Quality_Gate__c.Test_Level__c => 'No Test Run',
                Quality_Gate__c.Execution_Sequence__c => 'Before'
            };
            testDataFieldDefaultsByObject.put(Quality_Gate__c.SObjectType, defaults);
            return this;
        }
    }
    //need to update
    //Project__c
    //Connection_Behavior__c
    //Source_Org_Credential__c
    //Source_Environment__c
    public class PromotionDefaults extends AbstractTestData {
        public ITestDefaults setFieldDefaults() {
            Map<Schema.SObjectField, Object> defaults = new Map<Schema.SObjectField, Object>{
                Promotion__c.Status__c => 'Completed',
                Promotion__c.Send_Deployment_Complete_email__c => true
            };
            testDataFieldDefaultsByObject.put(Promotion__c.SObjectType, defaults);
            return this;
        }
    }
    //need to update
    //User_Story__c
    //Promotion__c
    public class PromotedUserStoryDefaults extends AbstractTestData {
        public ITestDefaults setFieldDefaults() {
            Map<Schema.SObjectField, Object> defaults = new Map<Schema.SObjectField, Object>{
                Promoted_User_Story__c.Name => 'Promoted User Story: '
            };
            testDataFieldDefaultsByObject.put(Promoted_User_Story__c.SObjectType, defaults);
            return this;
        }
    }
}