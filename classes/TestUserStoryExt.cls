@IsTest
public with sharing class TestUserStoryExt {

    @TestSetup static void setupTestData() {
        TestUtilities.setTestSettingsEE();
    }

    @IsTest static void userStoryHeader() {
        TestUtilities tu = new TestUtilities();

        // Create user record
        tu.insertSObject('User', new Map<String, Object>{
                'ProfileId' => [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
                'LastName' => 'LastName',
                'Email' => 'test1@test1.com',
                'Username' => 'puser000@amamama.com' + System.currentTimeMillis(),
                'CompanyName' => 'TEST',
                'Title' => 'title',
                'Alias' => 'alias',
                'TimeZoneSidKey' => 'America/Los_Angeles',
                'EmailEncodingKey' => 'UTF-8',
                'LanguageLocaleKey' => 'en_US',
                'LocaleSidKey' => 'en_US'
        });

        TestUtilities.assignLicense(String.valueOf(tu.item('User', 0).get('Username')), true, true, true, true, true);

        // Create current sprint record
        tu.insertSObject('Sprint__c', new Map<String, Object>{
                'Name' => 'Sprint 2',
                'Start_Date__c' => Date.today().addDays(-8),
                'End_Date__c' => Date.today().addDays(8)
        });

        // Create environments record
        tu.createSObject('Environment__c', new Map<String, Object>{
                'Name' => 'Dev1',
                'org_id__c' => 'SFDC_OrgId'
        });
        tu.createSObject('Environment__c', new Map<String, Object>{
                'Name' => 'Dev2',
                'org_id__c' => 'SFDC_OrgId2'
        });
        tu.createSObject('Environment__c', new Map<String, Object>{
                'Name' => 'Int',
                'org_id__c' => 'SFDC_OrgId3'
        });
        tu.createSObject('Environment__c', new Map<String, Object>{
                'Name' => 'UAT',
                'org_id__c' => 'SFDC_OrgId4'
        });
        tu.createSObject('Environment__c', new Map<String, Object>{
                'Name' => 'Prod',
                'org_id__c' => 'SFDC_OrgId5'
        });
        insert new List<SObject>{
                tu.item('Environment__c', 0), tu.item('Environment__c', 1), tu.item('Environment__c', 2), tu.item('Environment__c', 3), tu.item('Environment__c', 4)
        };

        // Create org credentials record
        tu.createSObject('Org__c', new Map<String, Object>{
                'Name' => 'OrgDev1',
                'Org_Type__c' => 'Sandbox',
                'SFDC_Org_ID__c' => 'SFDC_OrgId',
                'Token__c' => null,
                'Username__c' => null,
                'Validated_Date__c' => system.now(),
                'Environment__c' => tu.item('Environment__c', 0).Id
        });
        tu.createSObject('Org__c', new Map<String, Object>{
                'Name' => 'OrgDev2',
                'Org_Type__c' => 'Sandbox',
                'SFDC_Org_ID__c' => 'SFDC_OrgId2',
                'Token__c' => null,
                'Username__c' => null,
                'Validated_Date__c' => System.now(),
                'Environment__c' => tu.item('Environment__c', 1).Id
        });
        tu.createSObject('Org__c', new Map<String, Object>{
                'Name' => 'OrgInt',
                'Org_Type__c' => 'Sandbox',
                'SFDC_Org_ID__c' => 'SFDC_OrgId3',
                'Token__c' => null,
                'Username__c' => null,
                'Validated_Date__c' => System.now(),
                'Environment__c' => tu.item('Environment__c', 2).Id
        });
        tu.createSObject('Org__c', new Map<String, Object>{
                'Name' => 'OrgUAT',
                'Org_Type__c' => 'Sandbox',
                'SFDC_Org_ID__c' => 'SFDC_OrgId4',
                'Token__c' => null,
                'Username__c' => null,
                'Validated_Date__c' => System.now(),
                'Environment__c' => tu.item('Environment__c', 3).Id
        });
        tu.createSObject('Org__c', new Map<String, Object>{
                'Name' => 'OrgProd',
                'Org_Type__c' => 'Production',
                'SFDC_Org_ID__c' => 'SFDC_OrgId5',
                'Token__c' => null,
                'Username__c' => null,
                'Validated_Date__c' => System.now(),
                'Environment__c' => tu.item('Environment__c', 4).Id
        });
        insert new List<SObject>{
                tu.item('Org__c', 0), tu.item('Org__c', 1), tu.item('Org__c', 2), tu.item('Org__c', 3), tu.item('Org__c', 4)
        };

        // Create deployment flow record
        tu.insertSObject('Deployment_Flow__c', new Map<String, Object>{
                'Name' => 'Deployment Flow',
                'Active__c' => true
        });

        // Create deployment flow steps record
        tu.createSObject('Deployment_Flow_Step__c', new Map<String, Object>{
                'Source_Environment__c' => tu.item('Environment__c', 0).Id,
                'Destination_Environment__c' => tu.item('Environment__c', 2).Id,
                'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id
        });
        tu.createSObject('Deployment_Flow_Step__c', new Map<String, Object>{
                'Source_Environment__c' => tu.item('Environment__c', 1).Id,
                'Destination_Environment__c' => tu.item('Environment__c', 2).Id,
                'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id
        });
        tu.createSObject('Deployment_Flow_Step__c', new Map<String, Object>{
                'Source_Environment__c' => tu.item('Environment__c', 2).Id,
                'Destination_Environment__c' => tu.item('Environment__c', 3).Id,
                'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id
        });
        tu.createSObject('Deployment_Flow_Step__c', new Map<String, Object>{
                'Source_Environment__c' => tu.item('Environment__c', 3).Id,
                'Destination_Environment__c' => tu.item('Environment__c', 4).Id,
                'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id
        });
        insert new List<SObject>{
                tu.item('Deployment_Flow_Step__c', 0), tu.item('Deployment_Flow_Step__c', 1), tu.item('Deployment_Flow_Step__c', 2), tu.item('Deployment_Flow_Step__c', 3)
        };

        // Create project record
        tu.insertSObject('Project__c', new Map<String, Object>{
                'Name' => 'My project',
                'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id
        });

        // Create 28 user story to fill sobjectlist
        tu.insertSObjects('User_Story__c', 28, new Map<String, Object>{
                'User_Story_Title__c' => 'us-0000000',
                'Status__c' => 'Approved',
                'Sprint__c' => tu.item('Sprint__c', 0).Id,
                'Story_Points_SFDC__c' => 2,
                'Project__c' => tu.item('Project__c', 0).Id,
                'Environment__c' => tu.item('Environment__c', 0).Id
        });

        System.runAs((User) tu.item('User', 0)) {
            Test.startTest();
            Test.setCurrentPage(Page.UserStory);
            ApexPages.StandardController sc = new ApexPages.StandardController(tu.item('User_Story__c', 0));
            UserStoryExt controller = new UserStoryExt(sc);

            controller.getDeploymentFlowSteps();
            System.assertEquals(null, controller.userStoriesAheadBehindTitle);
            Test.stopTest();
        }
    }

    @IsTest static void testRelatedAlerts() {
        TestUtilities tu = new TestUtilities();
        tu.insertSObjects('User_Story__c', 1, new Map<String, Object>{
                'User_Story_Title__c' => 'Test No Changes',
                'Status__c' => 'Approved',
                'Story_Points_SFDC__c' => 2
        });

        tu.insertSObject('Org__c', new Map<String, Object>{
                'Name' => 'OrgProdNoCommit',
                'Org_Type__c' => 'Production',
                'SFDC_Org_ID__c' => 'SFDC_OrgId56',
                'Token__c' => null,
                'Username__c' => null,
                'Validated_Date__c' => System.now()
        });

        tu.insertSObjects('Git_Org_Commit__c', 1, new Map<String, Object>{
                'Status__c' => 'No changes',
                'Org__c' => tu.item('Org__c', 0).Id
        });

        tu.insertSObjects('User_Story_Commit__c', 1, new Map<String, Object>{
                'User_Story__c' => tu.item('User_Story__c', 0).Id,
                'Snapshot_Commit__c' => tu.item('Git_Org_Commit__c', 0).Id
        });

        Test.startTest();
        UserStoryExt ext1 = new UserStoryExt(new ApexPages.StandardController(tu.item('User_Story__c', 0)));
        System.assertEquals(true, testMethodUtilities.hasMessage(Label.COMMIT_NO_CHANGES));
        Test.stopTest();
    }

}