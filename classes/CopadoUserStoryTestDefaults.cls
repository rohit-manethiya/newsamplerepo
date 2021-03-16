@IsTest
public with sharing class CopadoUserStoryTestDefaults {
    public with sharing class PipelineDefaults extends AbstractTestData {
        public ITestDefaults setFieldDefaults() {
            Map<Schema.SObjectField, Object> defaults = new Map<Schema.SObjectField, Object>{
                Deployment_Flow__c.Name => 'MyPipeline',
                Deployment_Flow__c.Active__c => true,
                Deployment_Flow__c.Main_Branch__c => 'master'
            };
            testDataFieldDefaultsByObject.put(Deployment_Flow__c.SObjectType, defaults);
            return this;
        }
    }
    public with sharing class PipelineConnectionDefaults extends AbstractTestData {
        public ITestDefaults setFieldDefaults() {
            Map<Schema.SObjectField, Object> defaults = new Map<Schema.SObjectField, Object>{};
            testDataFieldDefaultsByObject.put(Deployment_Flow_Step__c.SObjectType, defaults);
            return this;
        }
    }
    public with sharing class UserStoryDefaults extends AbstractTestData {
        public ITestDefaults setFieldDefaults() {
            // getRecordTypeInfosByDeveloperName does not use namespace
            Id userStoryRecordTypeId = Schema.SObjectType.User_Story__c.getRecordTypeInfosByDeveloperName().get('User_Story').getRecordTypeId();
            Map<Schema.SObjectField, Object> defaults = new Map<Schema.SObjectField, Object>{
                User_Story__c.RecordTypeId => userStoryRecordTypeId,
                User_Story__c.User_Story_Title__c => 'My new User Story'
            };
            testDataFieldDefaultsByObject.put(User_Story__c.SObjectType, defaults);
            return this;
        }
    }
    public with sharing class ProjectDefaults extends AbstractTestData {
        public ITestDefaults setFieldDefaults() {
            Map<Schema.SObjectField, Object> defaults = new Map<Schema.SObjectField, Object>{
                Project__c.Name => 'MyProject',
                Project__c.Index_Metadata__c => false
            };
            testDataFieldDefaultsByObject.put(Project__c.SObjectType, defaults);
            return this;
        }
    }
    public with sharing class ReleaseDefaults extends AbstractTestData {
        public ITestDefaults setFieldDefaults() {
            Map<Schema.SObjectField, Object> defaults = new Map<Schema.SObjectField, Object>{ Release__c.Name => 'MyNextRelease' };
            testDataFieldDefaultsByObject.put(Release__c.SObjectType, defaults);
            return this;
        }
    }
    public with sharing class GitRepositoryDefaults extends AbstractTestData {
        public ITestDefaults setFieldDefaults() {
            Map<Schema.SObjectField, Object> defaults = new Map<Schema.SObjectField, Object>{
                Git_Repository__c.Name => 'MyGitRepo',
                Git_Repository__c.Source_Format__c => 'Metadata',
                Git_Repository__c.Git_Provider__c => 'Github',
                Git_Repository__c.URI__c => 'https://github.com/UserName/MyGitRepo.git',
                Git_Repository__c.Branch_Base_URL__c => 'https://github.com/UserName/borrar/tree/',
                Git_Repository__c.Commit_Base_URL__c => 'https://github.com/UserName/borrar/commit/',
                Git_Repository__c.Pull_Request_Base_URL__c => 'https://github.com/UserName/borrar/',
                Git_Repository__c.Tag_Base_URL__c => 'https://github.com/UserName/borrar/tags/'
            };
            testDataFieldDefaultsByObject.put(Git_Repository__c.SObjectType, defaults);
            return this;
        }
    }
    public with sharing class GitOrgCommitDefaults extends AbstractTestData {
        public ITestDefaults setFieldDefaults() {
            Map<Schema.SObjectField, Object> defaults = new Map<Schema.SObjectField, Object>{ Git_Org_Commit__c.Status__c => 'Complete' };
            testDataFieldDefaultsByObject.put(Git_Org_Commit__c.SObjectType, defaults);
            return this;
        }
    }
    public with sharing class UserStoryCommitDefaults extends AbstractTestData {
        public ITestDefaults setFieldDefaults() {
            Map<Schema.SObjectField, Object> defaults = new Map<Schema.SObjectField, Object>{};
            testDataFieldDefaultsByObject.put(User_Story_Commit__c.SObjectType, defaults);
            return this;
        }
    }
    public with sharing class TestScriptDefaults extends AbstractTestData {
        public ITestDefaults setFieldDefaults() {
            Map<Schema.SObjectField, Object> defaults = new Map<Schema.SObjectField, Object>{
                Test_Script__c.Status__c => 'Ready for testing',
                Test_Script__c.Test_Title__c => 'Test Title',
                Test_Script__c.Introduction__c => 'Test Introduction',
                Test_Script__c.Test_Description__c => 'Test Description',
                Test_Script__c.Prerequisites__c => 'Test Prerequisites',
                Test_Script__c.Expected_Result__c => 'Test Expected Result'
            };
            testDataFieldDefaultsByObject.put(Test_Script__c.SObjectType, defaults);
            return this;
        }
    }

    public class TestScriptStepDefaults extends AbstractTestData {
        public ITestDefaults setFieldDefaults() {
            Map<Schema.SObjectField, Object> defaults = new Map<Schema.SObjectField, Object>{
                Test_Script_Step__c.Step_Title__c => 'Step title',
                Test_Script_Step__c.Order__c => 1,
                Test_Script_Step__c.Action_Description__c => 'action',
                Test_Script_Step__c.Expected_Result__c => 'expected result'
            };

            testDataFieldDefaultsByObject.put(Test_Script_Step__c.SObjectType, defaults);
            return this;
        }
    }

    public with sharing class TestRunDefaults extends AbstractTestData {
        public ITestDefaults setFieldDefaults() {
            Map<Schema.SObjectField, Object> defaults = new Map<Schema.SObjectField, Object>{
                Test_Run__c.Status__c => 'Ready for testing',
                Test_Run__c.Type__c => 'Peer-Review',
                Test_Run__c.Test_Phase__c => 'Developer',
                Test_Run__c.Overall_Test_Comments__c => 'Overall Test Comments'
            };
            testDataFieldDefaultsByObject.put(Test_Run__c.SObjectType, defaults);
            return this;
        }
    }
    public class SprintDefaults extends AbstractTestData {
        public ITestDefaults setFieldDefaults() {
            Map<Schema.SObjectField, Object> defaults = new Map<Schema.SObjectField, Object>{ Sprint__c.Name => 'Sprint' };
            testDataFieldDefaultsByObject.put(Sprint__c.SObjectType, defaults);
            return this;
        }
    }
    public class DeploymentDefaults extends AbstractTestData {
        public ITestDefaults setFieldDefaults() {
            Map<Schema.SObjectField, Object> defaults = new Map<Schema.SObjectField, Object>{ Deployment__c.Name => 'Deployment' };
            testDataFieldDefaultsByObject.put(Deployment__c.SObjectType, defaults);
            return this;
        }
    }
    public class DeploymentStepDefaults extends AbstractTestData {
        public ITestDefaults setFieldDefaults() {
            Map<Schema.SObjectField, Object> defaults = new Map<Schema.SObjectField, Object>{ Step__c.Name => 'Deployment Step' };
            testDataFieldDefaultsByObject.put(Step__c.SObjectType, defaults);
            return this;
        }
    }
    public class DeploymentTaskDefaults extends AbstractTestData {
        public ITestDefaults setFieldDefaults() {
            Map<Schema.SObjectField, Object> defaults = new Map<Schema.SObjectField, Object>();
            testDataFieldDefaultsByObject.put(Deployment_Task__c.SObjectType, defaults);
            return this;
        }
    }
}