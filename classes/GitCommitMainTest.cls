@IsTest
private with sharing class GitCommitMainTest {
    private static TestUtilities tu = new TestUtilities();

    @TestSetup
    private static void setupData() {
        tu.insertSObject(
            'User',
            new Map<String, Object>{
                'ProfileId' => [SELECT Id FROM Profile WHERE Name = 'System Administrator']
                .Id,
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
            }
        );

        tu.insertSObject(
            'User',
            new Map<String, Object>{
                'ProfileId' => [SELECT Id FROM Profile WHERE Name = 'Standard User']
                .Id,
                'LastName' => 'LastName',
                'Email' => 'test2@test2.com',
                'Username' => 'puser002@amamama.com' + System.currentTimeMillis(),
                'CompanyName' => 'TEST',
                'Title' => 'title2',
                'Alias' => 'alias2',
                'TimeZoneSidKey' => 'America/Los_Angeles',
                'EmailEncodingKey' => 'UTF-8',
                'LanguageLocaleKey' => 'en_US',
                'LocaleSidKey' => 'en_US'
            }
        );

        TestUtilities.enableLicenses(2, 2, 2, 2, 2);
        FeatureManagement.setPackageIntegerValue('CBM_Branches', 2);
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Copado_User'];
        insert new PermissionSetAssignment(AssigneeId = tu.item('User', 0).Id, PermissionSetId = ps.Id);
    }

    /**
     * Open the new git commit page from user story, operation restriction
     */
    @IsTest
    private static void gitCommitPageUSOperationRestriction() {
        User u = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(u.Username), true, true, true, true, true);

        System.runAs(u) {
            // Create current sprint record
            tu.insertSObject(
                'Sprint__c',
                new Map<String, Object>{ 'Name' => 'Sprint 2', 'Start_Date__c' => Date.today().addDays(-8), 'End_Date__c' => Date.today().addDays(8) }
            );

            // Create environments record
            tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'Dev1', 'org_id__c' => 'SFDC_OrgId' });
            tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'Dev2', 'org_id__c' => 'SFDC_OrgId2' });
            tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'Int', 'org_id__c' => 'SFDC_OrgId3' });
            tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'UAT', 'org_id__c' => 'SFDC_OrgId4' });
            tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'Prod', 'org_id__c' => 'SFDC_OrgId5' });
            insert new List<SObject>{
                tu.item('Environment__c', 0),
                tu.item('Environment__c', 1),
                tu.item('Environment__c', 2),
                tu.item('Environment__c', 3),
                tu.item('Environment__c', 4)
            };

            // Create org credentials record
            tu.createSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'OrgDev1',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 0).Id
                }
            );
            tu.createSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'OrgDev2',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId2',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 1).Id
                }
            );
            tu.createSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'OrgInt',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId3',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Default_Credential__c' => true,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 2).Id
                }
            );
            tu.createSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'OrgUAT',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId4',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 3).Id
                }
            );
            tu.createSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'OrgProd',
                    'Org_Type__c' => 'Production',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId5',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 4).Id
                }
            );
            insert new List<SObject>{ tu.item('Org__c', 0), tu.item('Org__c', 1), tu.item('Org__c', 2), tu.item('Org__c', 3), tu.item('Org__c', 4) };

            // Create 1 git repository
            tu.insertSObjects('Git_Repository__c', 1, new Map<String, Object>{ 'Name' => 'test', 'URI__c' => 'http://www.test.uri' });

            // Create deployment flow record
            tu.insertSObject(
                'Deployment_Flow__c',
                new Map<String, Object>{ 'Name' => 'Deployment Flow', 'Active__c' => true, 'Git_Repository__c' => tu.item('Git_Repository__c', 0).Id }
            );

            // Create deployment flow steps record
            tu.createSObject(
                'Deployment_Flow_Step__c',
                new Map<String, Object>{
                    'Source_Environment__c' => tu.item('Environment__c', 0).Id,
                    'Destination_Environment__c' => tu.item('Environment__c', 2).Id,
                    'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id
                }
            );
            tu.createSObject(
                'Deployment_Flow_Step__c',
                new Map<String, Object>{
                    'Source_Environment__c' => tu.item('Environment__c', 1).Id,
                    'Destination_Environment__c' => tu.item('Environment__c', 2).Id,
                    'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id
                }
            );
            tu.createSObject(
                'Deployment_Flow_Step__c',
                new Map<String, Object>{
                    'Source_Environment__c' => tu.item('Environment__c', 2).Id,
                    'Destination_Environment__c' => tu.item('Environment__c', 3).Id,
                    'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id
                }
            );
            tu.createSObject(
                'Deployment_Flow_Step__c',
                new Map<String, Object>{
                    'Source_Environment__c' => tu.item('Environment__c', 3).Id,
                    'Destination_Environment__c' => tu.item('Environment__c', 4).Id,
                    'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id
                }
            );
            insert new List<SObject>{
                tu.item('Deployment_Flow_Step__c', 0),
                tu.item('Deployment_Flow_Step__c', 1),
                tu.item('Deployment_Flow_Step__c', 2),
                tu.item('Deployment_Flow_Step__c', 3)
            };

            // Create project record
            tu.insertSObject(
                'Project__c',
                new Map<String, Object>{ 'Name' => 'My project', 'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id }
            );

            // Create 3 user story to fill sobjectlist
            tu.insertSObjects(
                'User_Story__c',
                3,
                new Map<String, Object>{
                    'User_Story_Title__c' => 'us-0000000',
                    'Status__c' => 'Approved',
                    'Sprint__c' => tu.item('Sprint__c', 0).Id,
                    'Project__c' => tu.item('Project__c', 0).Id,
                    'Environment__c' => tu.item('Environment__c', 0).Id,
                    'Org_Credential__c' => tu.item('Org__c', 0).Id
                }
            );

            // Create 1 git backup
            tu.insertSObjects(
                'Git_Backup__c',
                1,
                new Map<String, Object>{
                    'Name' => 'backupname',
                    'Branch__c' => 'branchName',
                    'Frequency__c' => 'Daily',
                    'Git_Repository__c' => tu.item('Git_Repository__c', 0).Id,
                    'Org__c' => tu.item('Org__c', 0).Id
                }
            );

            // Create git operation restriction
            tu.insertSObjects(
                'Git_Operation_Restriction__c',
                1,
                new Map<String, Object>{ 'SetupOwnerId' => u.Id, 'Git_Operation_Name__c' => 'Destructive Changes', 'Active__c' => true }
            );

            Test.startTest();
            PageReference pReference = Page.GitCommitMain;
            pReference.getParameters().put('userStoryId', tu.item('User_Story__c', 0).Id);
            pReference.getParameters().put('variant', 'userstorycommit');
            Test.setCurrentPage(pReference);

            String mockResponse = '[{"operationType": "RecommitFiles","operationLabel": "Recommit Files","showGrid": true,"showUserStorySelections": true,"showCommitMessage": true,"operationFormElements": [{"label": "Re-Create Feature Branch","name": "recreateFeatureBranch","value": "","type": "checkbox","helpText": "If checked, the existing feature branch will be deleted and the selected components in the grid will be committed in a new feature branch. Previous commits will not be present in the new feature branch. WARNING: Profiles and Permission Sets committed as full in this User Story will be recommitted as in the Commit Files operation. If you want them to be recommitted as full, you need to commit them again using the Full Profiles & Permission Sets git operation."}],"helpText": "When recommitting files, the metadata grid appears with the existing user story selections. You can uncheck the selected components and also select new ones.","helpLink": "https://docs.copado.com/git-operations/recommit-files","pages": "UserStoryCommit","endpoint": "commit","showAdvancedSection":true,"possibleRunningJob":""},{"operationType": "GitDeletion","operationLabel": "Destructive Changes","operationButtonLabel": "Commit Destructive Changes","attachmentName": "Git Deletion","operationFormElements": [{"label": "Org Credential","name": "orgId","type": "orgLookup","helpText": "If changed, the metadata grid will reload with the metadata items of the selected Org Credential."}],"showGrid": true,"editGrid": true,"reloadGridData": true,"showCommitMessage": true,"helpText": "When deleting components, a table appears with a list of User Story Commits with status \'Complete\'. Select the commits you would like to undo and click Undo Commits. When the operation is finished, the status of the selected User Story Commits will be updated to \'Commit Undone\'.","helpLink": "https://docs.copado.com/git-operations/destructive-changes","pages": "GitSnapshotCommit,UserStoryCommit","endpoint": "commit","showAdvancedSection":true,"possibleRunningJob":",GitDeletion,{!snapshotId},true"},{"operationType": "FullProfilePermissionSets","operationLabel": "Full Profiles & Permission Sets","showGrid": true,"gridMetadataTypes": "Profile,PermissionSet","showCommitMessage": true,"helpText": "","helpLink": "https://docs.copado.com/git-operations/commit-full-profiles-and-permission-sets","pages": "GitSnapshotCommit,UserStoryCommit","endpoint": "commit","showAdvancedSection":true,"possibleRunningJob":""},{"operationType": "VlocityDependencies","operationLabel": "","showGrid": false,"gridMetadataTypes": "","showCommitMessage": false,"helpText": "","helpLink": "","pages": "UserStoryCommit","endpoint": "","showAdvancedSection":false,"possibleRunningJob": ",MetadataDependenciesJob,{!userStoryId},true"},{"operationType": "GitCommit","operationLabel": "","showGrid": false,"gridMetadataTypes": "","showCommitMessage": false,"helpText": "Git Commit help","helpLink": "","pages": "UserStoryCommit","endpoint": "","showAdvancedSection":false,"possibleRunningJob": ",GitCommit,{!snapshotId},true"}]';
            MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', mockResponse, null);
            Test.setMock(HttpCalloutMock.class, fakeResponse);
            GitCommit_MainPageController controller = new GitCommit_MainPageController();
            GitCommit_HeaderController headerController = new GitCommit_HeaderController();
            headerController.pageController = controller;
            List<SelectOption> options = headerController.availableOperationList;

            // Assertions
            Set<String> assertOptionValues = new Set<String>{ 'Commit Files', 'Destructive Changes' };
            Set<String> optionValues = new Set<String>();
            for (SelectOption optionsSel : options) {
                optionValues.add(optionsSel.getValue());
            }
            System.assertEquals(0, controller.pageMessagesMap.size());
            System.assertNotEquals(null, controller.pageMessagesMap);
            System.assertEquals(2, controller.operationsMap.size()); // commit and destructive changes
            System.assertEquals(assertOptionValues, optionValues);
            System.assertEquals(1, controller.snapshotList.size());
            System.assertEquals(tu.item('User_Story__c', 0).Id, controller.userStory.Id);
            System.assertEquals(tu.item('Git_Backup__c', 0).Id, controller.snapshot.Id);

            Test.stopTest();
        }
    }

    /**
     * Open the new git commit page from user story with two snapshot for org credential, commit changes
     */
    @IsTest
    private static void gitCommitPageUSIntermediaryAndCommit() {
        User u = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(u.Username), true, true, true, true, true);

        System.runAs(u) {
            // Create current sprint record
            tu.insertSObject(
                'Sprint__c',
                new Map<String, Object>{ 'Name' => 'Sprint 2', 'Start_Date__c' => Date.today().addDays(-8), 'End_Date__c' => Date.today().addDays(8) }
            );

            // Create environments record
            tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'Dev1', 'org_id__c' => 'SFDC_OrgId' });
            tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'Dev2', 'org_id__c' => 'SFDC_OrgId2' });
            tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'Int', 'org_id__c' => 'SFDC_OrgId3' });
            tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'UAT', 'org_id__c' => 'SFDC_OrgId4' });
            tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'Prod', 'org_id__c' => 'SFDC_OrgId5' });
            insert new List<SObject>{
                tu.item('Environment__c', 0),
                tu.item('Environment__c', 1),
                tu.item('Environment__c', 2),
                tu.item('Environment__c', 3),
                tu.item('Environment__c', 4)
            };

            // Create org credentials record
            tu.createSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'OrgDev1',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 0).Id
                }
            );
            tu.createSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'OrgDev2',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId2',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 1).Id
                }
            );
            tu.createSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'OrgInt',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId3',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Default_Credential__c' => true,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 2).Id
                }
            );
            tu.createSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'OrgUAT',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId4',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 3).Id
                }
            );
            tu.createSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'OrgProd',
                    'Org_Type__c' => 'Production',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId5',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Test_Frequency__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 4).Id
                }
            );
            insert new List<SObject>{ tu.item('Org__c', 0), tu.item('Org__c', 1), tu.item('Org__c', 2), tu.item('Org__c', 3), tu.item('Org__c', 4) };

            // Create 1 git repository
            tu.insertSObjects('Git_Repository__c', 1, new Map<String, Object>{ 'Name' => 'test', 'URI__c' => 'http://www.test.uri' });

            // Create deployment flow record
            tu.insertSObject(
                'Deployment_Flow__c',
                new Map<String, Object>{ 'Name' => 'Deployment Flow', 'Active__c' => true, 'Git_Repository__c' => tu.item('Git_Repository__c', 0).Id }
            );

            // Create deployment flow steps record
            tu.createSObject(
                'Deployment_Flow_Step__c',
                new Map<String, Object>{
                    'Source_Environment__c' => tu.item('Environment__c', 0).Id,
                    'Destination_Environment__c' => tu.item('Environment__c', 2).Id,
                    'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id
                }
            );
            tu.createSObject(
                'Deployment_Flow_Step__c',
                new Map<String, Object>{
                    'Source_Environment__c' => tu.item('Environment__c', 1).Id,
                    'Destination_Environment__c' => tu.item('Environment__c', 2).Id,
                    'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id
                }
            );
            tu.createSObject(
                'Deployment_Flow_Step__c',
                new Map<String, Object>{
                    'Source_Environment__c' => tu.item('Environment__c', 2).Id,
                    'Destination_Environment__c' => tu.item('Environment__c', 3).Id,
                    'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id
                }
            );
            tu.createSObject(
                'Deployment_Flow_Step__c',
                new Map<String, Object>{
                    'Source_Environment__c' => tu.item('Environment__c', 3).Id,
                    'Destination_Environment__c' => tu.item('Environment__c', 4).Id,
                    'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id
                }
            );
            insert new List<SObject>{
                tu.item('Deployment_Flow_Step__c', 0),
                tu.item('Deployment_Flow_Step__c', 1),
                tu.item('Deployment_Flow_Step__c', 2),
                tu.item('Deployment_Flow_Step__c', 3)
            };

            // Create project record
            tu.insertSObject(
                'Project__c',
                new Map<String, Object>{
                    'Name' => 'My project',
                    'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id,
                    'Index_Metadata__c' => false
                }
            );

            // Create 3 user story to fill sobjectlist
            tu.insertSObjects(
                'User_Story__c',
                3,
                new Map<String, Object>{
                    'User_Story_Title__c' => 'us-0000000',
                    'Status__c' => 'Approved',
                    'Sprint__c' => tu.item('Sprint__c', 0).Id,
                    'Project__c' => tu.item('Project__c', 0).Id,
                    'Environment__c' => tu.item('Environment__c', 0).Id,
                    'Org_Credential__c' => tu.item('Org__c', 0).Id
                }
            );

            // Create 1 git backup
            tu.insertSObjects(
                'Git_Backup__c',
                2,
                new Map<String, Object>{
                    'Name' => 'backupname',
                    'Branch__c' => 'branchName',
                    'Frequency__c' => null,
                    'Git_Repository__c' => tu.item('Git_Repository__c', 0).Id,
                    'Org__c' => tu.item('Org__c', 0).Id
                }
            );

            Test.startTest();
            PageReference pReference = Page.GitCommitMain;
            pReference.getParameters().put('userStoryId', tu.item('User_Story__c', 0).Id);
            pReference.getParameters().put('variant', 'userstorycommit');
            Test.setCurrentPage(pReference);

            String mockResponse = '[{"operationType": "RecommitFiles","operationLabel": "Recommit Files","showGrid": true,"showUserStorySelections": true,"showCommitMessage": true,"operationFormElements": [{"label": "Re-Create Feature Branch","name": "recreateFeatureBranch","value": "","type": "checkbox","helpText": "If checked, the existing feature branch will be deleted and the selected components in the grid will be committed in a new feature branch. Previous commits will not be present in the new feature branch. WARNING: Profiles and Permission Sets committed as full in this User Story will be recommitted as in the Commit Files operation. If you want them to be recommitted as full, you need to commit them again using the Full Profiles & Permission Sets git operation."}],"helpText": "When recommitting files, the metadata grid appears with the existing user story selections. You can uncheck the selected components and also select new ones.","helpLink": "https://docs.copado.com/git-operations/recommit-files","pages": "UserStoryCommit","endpoint": "commit","showAdvancedSection":true,"possibleRunningJob":""},{"operationType": "GitDeletion","operationLabel": "Destructive Changes","operationButtonLabel": "Commit Destructive Changes","attachmentName": "Git Deletion","operationFormElements": [{"label": "Org Credential","name": "orgId","type": "orgLookup","helpText": "If changed, the metadata grid will reload with the metadata items of the selected Org Credential."}],"showGrid": true,"editGrid": true,"reloadGridData": true,"showCommitMessage": true,"helpText": "When deleting components, a table appears with a list of User Story Commits with status \'Complete\'. Select the commits you would like to undo and click Undo Commits. When the operation is finished, the status of the selected User Story Commits will be updated to \'Commit Undone\'.","helpLink": "https://docs.copado.com/git-operations/destructive-changes","pages": "GitSnapshotCommit,UserStoryCommit","endpoint": "commit","showAdvancedSection":true,"possibleRunningJob":",GitDeletion,{!snapshotId},true"},{"operationType": "FullProfilePermissionSets","operationLabel": "Full Profiles & Permission Sets","showGrid": true,"gridMetadataTypes": "Profile,PermissionSet","showCommitMessage": true,"helpText": "","helpLink": "https://docs.copado.com/git-operations/commit-full-profiles-and-permission-sets","pages": "GitSnapshotCommit,UserStoryCommit","endpoint": "commit","showAdvancedSection":true,"possibleRunningJob":""},{"operationType": "VlocityDependencies","operationLabel": "","showGrid": false,"gridMetadataTypes": "","showCommitMessage": false,"helpText": "","helpLink": "","pages": "UserStoryCommit","endpoint": "","showAdvancedSection":false,"possibleRunningJob": ",MetadataDependenciesJob,{!userStoryId},true"},{"operationType": "GitCommit","operationLabel": "","showGrid": false,"gridMetadataTypes": "","showCommitMessage": false,"helpText": "Git Commit help","helpLink": "","pages": "UserStoryCommit","endpoint": "","showAdvancedSection":false,"possibleRunningJob": ",GitCommit,{!snapshotId},true"}]';
            MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', mockResponse, null);
            Test.setMock(HttpCalloutMock.class, fakeResponse);
            GitCommit_MainPageController controller = new GitCommit_MainPageController();
            System.assertEquals(0, controller.pageMessagesMap.size());
            System.assertNotEquals(null, controller.pageMessagesMap);
            System.assertEquals(4, controller.operationsMap.size());
            System.assertEquals(2, controller.snapshotList.size());
            System.assertEquals(tu.item('User_Story__c', 0).Id, controller.userStory.Id);

            GitCommit_IntermediaryController intermediaryController = new GitCommit_IntermediaryController();
            intermediaryController.pageController = controller;
            pReference.getParameters().put('gitSnapshotId', tu.item('Git_Backup__c', 0).Id);
            PageReference reloadedPage = intermediaryController.populateSnapshotRecord();

            PageReference expectedPage = Page.GitCommitMain;
            expectedPage.getParameters().put('gitSnapshotId', tu.item('Git_Backup__c', 0).Id);
            expectedPage.getParameters().put('userStoryId', tu.item('User_Story__c', 0).Id);
            expectedPage.getParameters().put('variant', 'userstorycommit');
            System.assertEquals(expectedPage.getUrl(), reloadedPage.getUrl());

            GitCommit_HeaderController headerController = new GitCommit_HeaderController();
            headerController.pageController = controller;
            User_Story__c us = [SELECT Name, User_Story_Title__c FROM User_Story__c WHERE Id = :tu.item('User_Story__c', 0).Id];
            String msg = headerController.commitMessage;
            String expectedMsg = us.Name + ': ' + us.User_Story_Title__c;
            System.assertEquals(expectedMsg, msg);
            List<SelectOption> options = headerController.availableOperationList;
            System.assertEquals(4, options.size());

            headerController.deleteMetadataIndex();
            String commitId = GitCommit_HeaderController.createGitOrgCommit(
                'test',
                tu.item('Org__c', 0).Id,
                tu.item('Git_Backup__c', 0).Id,
                'Commit Files'
            );
            System.assertNotEquals(null, commitId);

            pReference.getParameters().put('commitId', commitId);
            PageReference redirectedPage = headerController.goToWaitingForPage();
            System.debug('**f**redirectedPage : ' + redirectedPage);

            PageReference waitingForPage = Page.UserStoryPageWaitingFor;
            waitingForPage.getParameters().put('id', tu.item('User_Story__c', 0).Id);
            waitingForPage.getParameters().put('type', 'co_commitChanges');
            waitingForPage.getParameters().put('ep', headerController.pageController.operationItem.endpoint);
            waitingForPage.getParameters().put('cType', headerController.pageController.operationItem.operationLabel);
            waitingForPage.getParameters().put('cId', commitId);
            System.assertEquals(waitingForPage.getUrl(), redirectedPage.getUrl());
            Test.stopTest();
        }
    }

    /**
     * Open the new git commit page from user story, re commit changes
     */
    @IsTest
    private static void gitCommitPageUSReCommit() {
        User u = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(u.Username), true, true, true, true, true);

        System.runAs(u) {
            // Create current sprint record
            tu.insertSObject(
                'Sprint__c',
                new Map<String, Object>{ 'Name' => 'Sprint 2', 'Start_Date__c' => Date.today().addDays(-8), 'End_Date__c' => Date.today().addDays(8) }
            );

            // Create environments record
            tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'Dev1', 'org_id__c' => 'SFDC_OrgId' });
            tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'Dev2', 'org_id__c' => 'SFDC_OrgId2' });
            tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'Int', 'org_id__c' => 'SFDC_OrgId3' });
            tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'UAT', 'org_id__c' => 'SFDC_OrgId4' });
            tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'Prod', 'org_id__c' => 'SFDC_OrgId5' });
            insert new List<SObject>{
                tu.item('Environment__c', 0),
                tu.item('Environment__c', 1),
                tu.item('Environment__c', 2),
                tu.item('Environment__c', 3),
                tu.item('Environment__c', 4)
            };

            // Create org credentials record
            tu.createSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'OrgDev1',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 0).Id
                }
            );
            tu.createSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'OrgDev2',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId2',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 1).Id
                }
            );
            tu.createSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'OrgInt',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId3',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Default_Credential__c' => true,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 2).Id
                }
            );
            tu.createSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'OrgUAT',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId4',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 3).Id
                }
            );
            tu.createSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'OrgProd',
                    'Org_Type__c' => 'Production',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId5',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Test_Frequency__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 4).Id
                }
            );
            insert new List<SObject>{ tu.item('Org__c', 0), tu.item('Org__c', 1), tu.item('Org__c', 2), tu.item('Org__c', 3), tu.item('Org__c', 4) };

            // Create 1 git repository
            tu.insertSObjects('Git_Repository__c', 1, new Map<String, Object>{ 'Name' => 'test', 'URI__c' => 'http://www.test.uri' });

            // Create deployment flow record
            tu.insertSObject(
                'Deployment_Flow__c',
                new Map<String, Object>{ 'Name' => 'Deployment Flow', 'Active__c' => true, 'Git_Repository__c' => tu.item('Git_Repository__c', 0).Id }
            );

            // Create deployment flow steps record
            tu.createSObject(
                'Deployment_Flow_Step__c',
                new Map<String, Object>{
                    'Source_Environment__c' => tu.item('Environment__c', 0).Id,
                    'Destination_Environment__c' => tu.item('Environment__c', 2).Id,
                    'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id
                }
            );
            tu.createSObject(
                'Deployment_Flow_Step__c',
                new Map<String, Object>{
                    'Source_Environment__c' => tu.item('Environment__c', 1).Id,
                    'Destination_Environment__c' => tu.item('Environment__c', 2).Id,
                    'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id
                }
            );
            tu.createSObject(
                'Deployment_Flow_Step__c',
                new Map<String, Object>{
                    'Source_Environment__c' => tu.item('Environment__c', 2).Id,
                    'Destination_Environment__c' => tu.item('Environment__c', 3).Id,
                    'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id
                }
            );
            tu.createSObject(
                'Deployment_Flow_Step__c',
                new Map<String, Object>{
                    'Source_Environment__c' => tu.item('Environment__c', 3).Id,
                    'Destination_Environment__c' => tu.item('Environment__c', 4).Id,
                    'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id
                }
            );
            insert new List<SObject>{
                tu.item('Deployment_Flow_Step__c', 0),
                tu.item('Deployment_Flow_Step__c', 1),
                tu.item('Deployment_Flow_Step__c', 2),
                tu.item('Deployment_Flow_Step__c', 3)
            };

            // Create project record
            tu.insertSObject(
                'Project__c',
                new Map<String, Object>{
                    'Name' => 'My project',
                    'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id,
                    'Index_Metadata__c' => false
                }
            );

            // Create 3 user story to fill sobjectlist
            tu.insertSObjects(
                'User_Story__c',
                3,
                new Map<String, Object>{
                    'User_Story_Title__c' => 'us-0000000',
                    'Status__c' => 'Approved',
                    'Sprint__c' => tu.item('Sprint__c', 0).Id,
                    'Project__c' => tu.item('Project__c', 0).Id,
                    'Environment__c' => tu.item('Environment__c', 0).Id,
                    'Org_Credential__c' => tu.item('Org__c', 0).Id
                }
            );

            // Create 1 git backup
            tu.insertSObjects(
                'Git_Backup__c',
                1,
                new Map<String, Object>{
                    'Name' => 'backupname',
                    'Branch__c' => 'branchName',
                    'Frequency__c' => null,
                    'Git_Repository__c' => tu.item('Git_Repository__c', 0).Id,
                    'Org__c' => tu.item('Org__c', 0).Id
                }
            );

            // Create 1 git backup
            tu.insertSObjects(
                'User_Story_Metadata__c',
                1,
                new Map<String, Object>{ 'Name' => 'test', 'User_Story__c' => tu.item('User_Story__c', 0).Id }
            );

            Test.startTest();
            PageReference pReference = Page.GitCommitMain;
            pReference.getParameters().put('userStoryId', tu.item('User_Story__c', 0).Id);
            pReference.getParameters().put('variant', 'userstorycommit');
            Test.setCurrentPage(pReference);

            String mockResponse = '[{"operationType": "RecommitFiles","operationLabel": "Recommit Files","showGrid": true,"showUserStorySelections": true,"showCommitMessage": true,"operationFormElements": [{"label": "Re-Create Feature Branch","name": "recreateFeatureBranch","value": "","type": "checkbox","helpText": "If checked, the existing feature branch will be deleted and the selected components in the grid will be committed in a new feature branch. Previous commits will not be present in the new feature branch. WARNING: Profiles and Permission Sets committed as full in this User Story will be recommitted as in the Commit Files operation. If you want them to be recommitted as full, you need to commit them again using the Full Profiles & Permission Sets git operation."}],"helpText": "When recommitting files, the metadata grid appears with the existing user story selections. You can uncheck the selected components and also select new ones.","helpLink": "https://docs.copado.com/git-operations/recommit-files","pages": "UserStoryCommit","endpoint": "commit","showAdvancedSection":true,"possibleRunningJob":""},{"operationType": "GitDeletion","operationLabel": "Destructive Changes","operationButtonLabel": "Commit Destructive Changes","attachmentName": "Git Deletion","operationFormElements": [{"label": "Org Credential","name": "orgId","type": "orgLookup","helpText": "If changed, the metadata grid will reload with the metadata items of the selected Org Credential."}],"showGrid": true,"editGrid": true,"reloadGridData": true,"showCommitMessage": true,"helpText": "When deleting components, a table appears with a list of User Story Commits with status \'Complete\'. Select the commits you would like to undo and click Undo Commits. When the operation is finished, the status of the selected User Story Commits will be updated to \'Commit Undone\'.","helpLink": "https://docs.copado.com/git-operations/destructive-changes","pages": "GitSnapshotCommit,UserStoryCommit","endpoint": "commit","showAdvancedSection":true,"possibleRunningJob":",GitDeletion,{!snapshotId},true"},{"operationType": "FullProfilePermissionSets","operationLabel": "Full Profiles & Permission Sets","showGrid": true,"gridMetadataTypes": "Profile,PermissionSet","showCommitMessage": true,"helpText": "","helpLink": "https://docs.copado.com/git-operations/commit-full-profiles-and-permission-sets","pages": "GitSnapshotCommit,UserStoryCommit","endpoint": "commit","showAdvancedSection":true,"possibleRunningJob":""},{"operationType": "VlocityDependencies","operationLabel": "","showGrid": false,"gridMetadataTypes": "","showCommitMessage": false,"helpText": "","helpLink": "","pages": "UserStoryCommit","endpoint": "","showAdvancedSection":false,"possibleRunningJob": ",MetadataDependenciesJob,{!userStoryId},true"},{"operationType": "GitCommit","operationLabel": "","showGrid": false,"gridMetadataTypes": "","showCommitMessage": false,"helpText": "Git Commit help","helpLink": "","pages": "UserStoryCommit","endpoint": "","showAdvancedSection":false,"possibleRunningJob": ",GitCommit,{!snapshotId},true"}]';
            MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', mockResponse, null);
            Test.setMock(HttpCalloutMock.class, fakeResponse);
            GitCommit_MainPageController controller = new GitCommit_MainPageController();
            System.assertEquals(0, controller.pageMessagesMap.size());
            System.assertNotEquals(null, controller.pageMessagesMap);
            System.assertEquals(4, controller.operationsMap.size());
            System.assertEquals(1, controller.snapshotList.size());
            System.assertEquals(tu.item('User_Story__c', 0).Id, controller.userStory.Id);

            GitCommit_HeaderController headerController = new GitCommit_HeaderController();
            headerController.pageController = controller;
            User_Story__c us = [SELECT Name, User_Story_Title__c FROM User_Story__c WHERE Id = :tu.item('User_Story__c', 0).Id];
            String msg = headerController.commitMessage;
            String expectedMsg = us.Name + ': ' + us.User_Story_Title__c;
            System.assertEquals(expectedMsg, msg);
            List<SelectOption> options = headerController.availableOperationList;
            System.assertEquals(4, options.size());

            headerController.pageController.selectedGitOperation = 'Recommit Files';
            headerController.updateOperationItem();
            System.assertEquals('Recommit Files', headerController.pageController.operationItem.operationLabel);
            for (GitCommit_PageBase.OperationFormElement ofe : headerController.pageController.operationItem.operationFormElements) {
                if (ofe.name == 'recreateFeatureBranch') {
                    ofe.boolValue = true;
                }
            }

            headerController.deleteMetadataIndex();
            String commitId = GitCommit_HeaderController.createGitOrgCommit(
                'test',
                tu.item('Org__c', 0).Id,
                tu.item('Git_Backup__c', 0).Id,
                'Commit Files'
            );
            System.assertNotEquals(null, commitId);

            pReference.getParameters().put('commitId', commitId);
            PageReference redirectedPage = headerController.goToWaitingForPage();

            PageReference waitingForPage = Page.UserStoryPageWaitingFor;
            waitingForPage.getParameters().put('id', tu.item('User_Story__c', 0).Id);
            waitingForPage.getParameters().put('type', 'co_commitChanges');
            waitingForPage.getParameters().put('ep', headerController.pageController.operationItem.endpoint);
            waitingForPage.getParameters().put('sId', tu.item('Git_Backup__c', 0).Id);
            waitingForPage.getParameters().put('cType', headerController.pageController.operationItem.operationLabel);
            waitingForPage.getParameters().put('cId', commitId);
            waitingForPage.getParameters().put('recreateFeatureBranch', 'true');
            System.assertEquals(waitingForPage.getUrl(), redirectedPage.getUrl());
            Test.stopTest();
        }
    }

    /**
     * Open the new git commit page from user story, cancel commit
     */
    @IsTest
    private static void gitCommitPageUSCancel() {
        User u = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(u.Username), true, true, true, true, true);

        System.runAs(u) {
            // Create current sprint record
            tu.insertSObject(
                'Sprint__c',
                new Map<String, Object>{ 'Name' => 'Sprint 2', 'Start_Date__c' => Date.today().addDays(-8), 'End_Date__c' => Date.today().addDays(8) }
            );

            // Create environments record
            tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'Dev1', 'org_id__c' => 'SFDC_OrgId' });
            tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'Dev2', 'org_id__c' => 'SFDC_OrgId2' });
            tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'Int', 'org_id__c' => 'SFDC_OrgId3' });
            tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'UAT', 'org_id__c' => 'SFDC_OrgId4' });
            tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'Prod', 'org_id__c' => 'SFDC_OrgId5' });
            insert new List<SObject>{
                tu.item('Environment__c', 0),
                tu.item('Environment__c', 1),
                tu.item('Environment__c', 2),
                tu.item('Environment__c', 3),
                tu.item('Environment__c', 4)
            };

            // Create org credentials record
            tu.createSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'OrgDev1',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 0).Id
                }
            );
            tu.createSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'OrgDev2',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId2',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 1).Id
                }
            );
            tu.createSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'OrgInt',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId3',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Default_Credential__c' => true,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 2).Id
                }
            );
            tu.createSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'OrgUAT',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId4',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 3).Id
                }
            );
            tu.createSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'OrgProd',
                    'Org_Type__c' => 'Production',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId5',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Test_Frequency__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 4).Id
                }
            );
            insert new List<SObject>{ tu.item('Org__c', 0), tu.item('Org__c', 1), tu.item('Org__c', 2), tu.item('Org__c', 3), tu.item('Org__c', 4) };

            // Create 1 git repository
            tu.insertSObjects('Git_Repository__c', 1, new Map<String, Object>{ 'Name' => 'test', 'URI__c' => 'http://www.test.uri' });

            // Create deployment flow record
            tu.insertSObject(
                'Deployment_Flow__c',
                new Map<String, Object>{ 'Name' => 'Deployment Flow', 'Active__c' => true, 'Git_Repository__c' => tu.item('Git_Repository__c', 0).Id }
            );

            // Create deployment flow steps record
            tu.createSObject(
                'Deployment_Flow_Step__c',
                new Map<String, Object>{
                    'Source_Environment__c' => tu.item('Environment__c', 0).Id,
                    'Destination_Environment__c' => tu.item('Environment__c', 2).Id,
                    'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id
                }
            );
            tu.createSObject(
                'Deployment_Flow_Step__c',
                new Map<String, Object>{
                    'Source_Environment__c' => tu.item('Environment__c', 1).Id,
                    'Destination_Environment__c' => tu.item('Environment__c', 2).Id,
                    'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id
                }
            );
            tu.createSObject(
                'Deployment_Flow_Step__c',
                new Map<String, Object>{
                    'Source_Environment__c' => tu.item('Environment__c', 2).Id,
                    'Destination_Environment__c' => tu.item('Environment__c', 3).Id,
                    'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id
                }
            );
            tu.createSObject(
                'Deployment_Flow_Step__c',
                new Map<String, Object>{
                    'Source_Environment__c' => tu.item('Environment__c', 3).Id,
                    'Destination_Environment__c' => tu.item('Environment__c', 4).Id,
                    'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id
                }
            );
            insert new List<SObject>{
                tu.item('Deployment_Flow_Step__c', 0),
                tu.item('Deployment_Flow_Step__c', 1),
                tu.item('Deployment_Flow_Step__c', 2),
                tu.item('Deployment_Flow_Step__c', 3)
            };

            // Create project record
            tu.insertSObject(
                'Project__c',
                new Map<String, Object>{
                    'Name' => 'My project',
                    'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id,
                    'Index_Metadata__c' => false
                }
            );

            // Create 3 user story to fill sobjectlist
            tu.insertSObjects(
                'User_Story__c',
                3,
                new Map<String, Object>{
                    'User_Story_Title__c' => 'us-0000000',
                    'Status__c' => 'Approved',
                    'Sprint__c' => tu.item('Sprint__c', 0).Id,
                    'Project__c' => tu.item('Project__c', 0).Id,
                    'Environment__c' => tu.item('Environment__c', 0).Id,
                    'Org_Credential__c' => tu.item('Org__c', 0).Id
                }
            );

            // Create 1 git backup
            tu.insertSObjects(
                'Git_Backup__c',
                1,
                new Map<String, Object>{
                    'Name' => 'backupname',
                    'Branch__c' => 'branchName',
                    'Frequency__c' => null,
                    'Git_Repository__c' => tu.item('Git_Repository__c', 0).Id,
                    'Org__c' => tu.item('Org__c', 0).Id
                }
            );

            // Create 1 git backup
            tu.insertSObjects(
                'User_Story_Metadata__c',
                1,
                new Map<String, Object>{ 'Name' => 'test', 'User_Story__c' => tu.item('User_Story__c', 0).Id }
            );

            Test.startTest();
            PageReference pReference = Page.GitCommitMain;
            pReference.getParameters().put('userStoryId', tu.item('User_Story__c', 0).Id);
            pReference.getParameters().put('variant', 'userstorycommit');
            Test.setCurrentPage(pReference);

            String mockResponse = '[{"operationType": "RecommitFiles","operationLabel": "Recommit Files","showGrid": true,"showUserStorySelections": true,"showCommitMessage": true,"operationFormElements": [{"label": "Re-Create Feature Branch","name": "recreateFeatureBranch","value": "","type": "checkbox","helpText": "If checked, the existing feature branch will be deleted and the selected components in the grid will be committed in a new feature branch. Previous commits will not be present in the new feature branch. WARNING: Profiles and Permission Sets committed as full in this User Story will be recommitted as in the Commit Files operation. If you want them to be recommitted as full, you need to commit them again using the Full Profiles & Permission Sets git operation."}],"helpText": "When recommitting files, the metadata grid appears with the existing user story selections. You can uncheck the selected components and also select new ones.","helpLink": "https://docs.copado.com/git-operations/recommit-files","pages": "UserStoryCommit","endpoint": "commit","showAdvancedSection":true,"possibleRunningJob":""},{"operationType": "GitDeletion","operationLabel": "Destructive Changes","operationButtonLabel": "Commit Destructive Changes","attachmentName": "Git Deletion","operationFormElements": [{"label": "Org Credential","name": "orgId","type": "orgLookup","helpText": "If changed, the metadata grid will reload with the metadata items of the selected Org Credential."}],"showGrid": true,"editGrid": true,"reloadGridData": true,"showCommitMessage": true,"helpText": "When deleting components, a table appears with a list of User Story Commits with status \'Complete\'. Select the commits you would like to undo and click Undo Commits. When the operation is finished, the status of the selected User Story Commits will be updated to \'Commit Undone\'.","helpLink": "https://docs.copado.com/git-operations/destructive-changes","pages": "GitSnapshotCommit,UserStoryCommit","endpoint": "commit","showAdvancedSection":true,"possibleRunningJob":",GitDeletion,{!snapshotId},true"},{"operationType": "FullProfilePermissionSets","operationLabel": "Full Profiles & Permission Sets","showGrid": true,"gridMetadataTypes": "Profile,PermissionSet","showCommitMessage": true,"helpText": "","helpLink": "https://docs.copado.com/git-operations/commit-full-profiles-and-permission-sets","pages": "GitSnapshotCommit,UserStoryCommit","endpoint": "commit","showAdvancedSection":true,"possibleRunningJob":""},{"operationType": "VlocityDependencies","operationLabel": "","showGrid": false,"gridMetadataTypes": "","showCommitMessage": false,"helpText": "","helpLink": "","pages": "UserStoryCommit","endpoint": "","showAdvancedSection":false,"possibleRunningJob": ",MetadataDependenciesJob,{!userStoryId},true"},{"operationType": "GitCommit","operationLabel": "","showGrid": false,"gridMetadataTypes": "","showCommitMessage": false,"helpText": "Git Commit help","helpLink": "","pages": "UserStoryCommit","endpoint": "","showAdvancedSection":false,"possibleRunningJob": ",GitCommit,{!snapshotId},true"}]';
            MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', mockResponse, null);
            Test.setMock(HttpCalloutMock.class, fakeResponse);
            GitCommit_MainPageController controller = new GitCommit_MainPageController();
            System.assertEquals(0, controller.pageMessagesMap.size());
            System.assertNotEquals(null, controller.pageMessagesMap);
            System.assertEquals(4, controller.operationsMap.size());
            System.assertEquals(1, controller.snapshotList.size());
            System.assertEquals(tu.item('User_Story__c', 0).Id, controller.userStory.Id);

            GitCommit_HeaderController headerController = new GitCommit_HeaderController();
            headerController.pageController = controller;
            User_Story__c us = [SELECT Name, User_Story_Title__c FROM User_Story__c WHERE Id = :tu.item('User_Story__c', 0).Id];
            String msg = headerController.commitMessage;
            String expectedMsg = us.Name + ': ' + us.User_Story_Title__c;
            System.assertEquals(expectedMsg, msg);
            List<SelectOption> options = headerController.availableOperationList;
            System.assertEquals(4, options.size());
            controller.returnToRecord();
            Test.stopTest();
        }
    }

    /**
     * Open the new git commit page from user story, success refresh cache
     */
    @IsTest
    private static void gitCommitPageUSSuccessRefreshCache() {
        User u = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(u.Username), true, true, true, true, true);

        System.runAs(u) {
            // Create current sprint record
            tu.insertSObject(
                'Sprint__c',
                new Map<String, Object>{ 'Name' => 'Sprint 2', 'Start_Date__c' => Date.today().addDays(-8), 'End_Date__c' => Date.today().addDays(8) }
            );

            // Create environments record
            tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'Dev1', 'org_id__c' => 'SFDC_OrgId' });
            tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'Dev2', 'org_id__c' => 'SFDC_OrgId2' });
            tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'Int', 'org_id__c' => 'SFDC_OrgId3' });
            tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'UAT', 'org_id__c' => 'SFDC_OrgId4' });
            tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'Prod', 'org_id__c' => 'SFDC_OrgId5' });
            insert new List<SObject>{
                tu.item('Environment__c', 0),
                tu.item('Environment__c', 1),
                tu.item('Environment__c', 2),
                tu.item('Environment__c', 3),
                tu.item('Environment__c', 4)
            };

            // Create org credentials record
            tu.createSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'OrgDev1',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 0).Id
                }
            );
            tu.createSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'OrgDev2',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId2',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 1).Id
                }
            );
            tu.createSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'OrgInt',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId3',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Default_Credential__c' => true,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 2).Id
                }
            );
            tu.createSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'OrgUAT',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId4',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 3).Id
                }
            );
            tu.createSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'OrgProd',
                    'Org_Type__c' => 'Production',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId5',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Test_Frequency__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 4).Id
                }
            );
            insert new List<SObject>{ tu.item('Org__c', 0), tu.item('Org__c', 1), tu.item('Org__c', 2), tu.item('Org__c', 3), tu.item('Org__c', 4) };

            // Create 1 git repository
            tu.insertSObjects('Git_Repository__c', 1, new Map<String, Object>{ 'Name' => 'test', 'URI__c' => 'http://www.test.uri' });

            // Create deployment flow record
            tu.insertSObject(
                'Deployment_Flow__c',
                new Map<String, Object>{ 'Name' => 'Deployment Flow', 'Active__c' => true, 'Git_Repository__c' => tu.item('Git_Repository__c', 0).Id }
            );

            // Create deployment flow steps record
            tu.createSObject(
                'Deployment_Flow_Step__c',
                new Map<String, Object>{
                    'Source_Environment__c' => tu.item('Environment__c', 0).Id,
                    'Destination_Environment__c' => tu.item('Environment__c', 2).Id,
                    'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id
                }
            );
            tu.createSObject(
                'Deployment_Flow_Step__c',
                new Map<String, Object>{
                    'Source_Environment__c' => tu.item('Environment__c', 1).Id,
                    'Destination_Environment__c' => tu.item('Environment__c', 2).Id,
                    'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id
                }
            );
            tu.createSObject(
                'Deployment_Flow_Step__c',
                new Map<String, Object>{
                    'Source_Environment__c' => tu.item('Environment__c', 2).Id,
                    'Destination_Environment__c' => tu.item('Environment__c', 3).Id,
                    'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id
                }
            );
            tu.createSObject(
                'Deployment_Flow_Step__c',
                new Map<String, Object>{
                    'Source_Environment__c' => tu.item('Environment__c', 3).Id,
                    'Destination_Environment__c' => tu.item('Environment__c', 4).Id,
                    'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id
                }
            );
            insert new List<SObject>{
                tu.item('Deployment_Flow_Step__c', 0),
                tu.item('Deployment_Flow_Step__c', 1),
                tu.item('Deployment_Flow_Step__c', 2),
                tu.item('Deployment_Flow_Step__c', 3)
            };

            // Create project record
            tu.insertSObject(
                'Project__c',
                new Map<String, Object>{
                    'Name' => 'My project',
                    'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id,
                    'Index_Metadata__c' => false
                }
            );

            // Create 3 user story to fill sobjectlist
            tu.insertSObjects(
                'User_Story__c',
                3,
                new Map<String, Object>{
                    'User_Story_Title__c' => 'us-0000000',
                    'Status__c' => 'Approved',
                    'Sprint__c' => tu.item('Sprint__c', 0).Id,
                    'Project__c' => tu.item('Project__c', 0).Id,
                    'Environment__c' => tu.item('Environment__c', 0).Id,
                    'Org_Credential__c' => tu.item('Org__c', 0).Id
                }
            );

            // Create 1 git backup
            tu.insertSObjects(
                'Git_Backup__c',
                1,
                new Map<String, Object>{
                    'Name' => 'backupname',
                    'Branch__c' => 'branchName',
                    'Frequency__c' => null,
                    'Git_Repository__c' => tu.item('Git_Repository__c', 0).Id,
                    'Org__c' => tu.item('Org__c', 0).Id
                }
            );

            tu.insertSObjects(
                'Attachment',
                1,
                new Map<String, Object>{
                    'Name' => 'MetaData',
                    'ParentId' => tu.item('Org__c', 0).Id,
                    'Body' => Blob.valueOf('[{"n": "ExampleTest", "t": "ApexClass"}]')
                }
            );

            Test.startTest();
            PageReference pReference = Page.GitCommitMain;
            pReference.getParameters().put('gitSnapshotId', tu.item('Git_Backup__c', 0).Id);
            pReference.getParameters().put('userStoryId', tu.item('User_Story__c', 0).Id);
            pReference.getParameters().put('variant', 'userstorycommit');
            Test.setCurrentPage(pReference);

            String mockResponse = '[{"operationType": "RecommitFiles","operationLabel": "Recommit Files","showGrid": true,"showUserStorySelections": true,"showCommitMessage": true,"operationFormElements": [{"label": "Re-Create Feature Branch","name": "recreateFeatureBranch","value": "","type": "checkbox","helpText": "If checked, the existing feature branch will be deleted and the selected components in the grid will be committed in a new feature branch. Previous commits will not be present in the new feature branch. WARNING: Profiles and Permission Sets committed as full in this User Story will be recommitted as in the Commit Files operation. If you want them to be recommitted as full, you need to commit them again using the Full Profiles & Permission Sets git operation."}],"helpText": "When recommitting files, the metadata grid appears with the existing user story selections. You can uncheck the selected components and also select new ones.","helpLink": "https://docs.copado.com/git-operations/recommit-files","pages": "UserStoryCommit","endpoint": "commit","showAdvancedSection":true,"possibleRunningJob":""},{"operationType": "GitDeletion","operationLabel": "Destructive Changes","operationButtonLabel": "Commit Destructive Changes","attachmentName": "Git Deletion","operationFormElements": [{"label": "Org Credential","name": "orgId","type": "orgLookup","helpText": "If changed, the metadata grid will reload with the metadata items of the selected Org Credential."}],"showGrid": true,"editGrid": true,"reloadGridData": true,"showCommitMessage": true,"helpText": "When deleting components, a table appears with a list of User Story Commits with status \'Complete\'. Select the commits you would like to undo and click Undo Commits. When the operation is finished, the status of the selected User Story Commits will be updated to \'Commit Undone\'.","helpLink": "https://docs.copado.com/git-operations/destructive-changes","pages": "GitSnapshotCommit,UserStoryCommit","endpoint": "commit","showAdvancedSection":true,"possibleRunningJob":",GitDeletion,{!snapshotId},true"},{"operationType": "FullProfilePermissionSets","operationLabel": "Full Profiles & Permission Sets","showGrid": true,"gridMetadataTypes": "Profile,PermissionSet","showCommitMessage": true,"helpText": "","helpLink": "https://docs.copado.com/git-operations/commit-full-profiles-and-permission-sets","pages": "GitSnapshotCommit,UserStoryCommit","endpoint": "commit","showAdvancedSection":true,"possibleRunningJob":""},{"operationType": "VlocityDependencies","operationLabel": "","showGrid": false,"gridMetadataTypes": "","showCommitMessage": false,"helpText": "","helpLink": "","pages": "UserStoryCommit","endpoint": "","showAdvancedSection":false,"possibleRunningJob": ",MetadataDependenciesJob,{!userStoryId},true"},{"operationType": "GitCommit","operationLabel": "","showGrid": false,"gridMetadataTypes": "","showCommitMessage": false,"helpText": "Git Commit help","helpLink": "","pages": "UserStoryCommit","endpoint": "","showAdvancedSection":false,"possibleRunningJob": ",GitCommit,{!snapshotId},true"}]';
            MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', mockResponse, null);
            Test.setMock(HttpCalloutMock.class, fakeResponse);
            GitCommit_MainPageController controller = new GitCommit_MainPageController();
            System.assertEquals(0, controller.pageMessagesMap.size());
            System.assertNotEquals(null, controller.pageMessagesMap);
            System.assertEquals(4, controller.operationsMap.size());
            System.assertEquals(1, controller.snapshotList.size());
            System.assertEquals(tu.item('User_Story__c', 0).Id, controller.userStory.Id);

            GitCommit_HeaderController headerController = new GitCommit_HeaderController();
            headerController.pageController = controller;
            User_Story__c us = [SELECT Name, User_Story_Title__c FROM User_Story__c WHERE Id = :tu.item('User_Story__c', 0).Id];
            String msg = headerController.commitMessage;
            String expectedMsg = us.Name + ': ' + us.User_Story_Title__c;
            System.assertEquals(expectedMsg, msg);
            List<SelectOption> options = headerController.availableOperationList;
            System.assertEquals(4, options.size());

            GitCommit_GridController gridController = new GitCommit_GridController();
            gridController.pageController = controller;
            String opName = gridController.operationName;
            System.assertEquals('', opName);
            Boolean startPoller = gridController.startActionPoller;
            System.assertEquals(false, startPoller);
            Boolean showRefreshPromtButton = gridController.showRefreshCachePromtButton;
            System.assertEquals(false, showRefreshPromtButton);
            Boolean refreshSucceeded = gridController.isRefreshCacheSucceeded;
            System.assertEquals(false, refreshSucceeded);

            pReference.getParameters().put('operation', 'refreshCache');
            gridController.initPoller();
            System.assertEquals('refreshCache', gridController.operationName);
            System.assertEquals(true, gridController.startActionPoller);
            System.assertEquals(1, gridController.componentMessagesMap.size());
            System.assertEquals(1, gridController.getComponentMessageSize());
            for (String severity : gridController.componentMessagesMap.keySet()) {
                System.assertEquals('info', severity);
                for (Object obj : gridController.componentMessagesMap.get(severity)) {
                    System.assertEquals(Label.Initializing, obj);
                }
            }

            gridController.pollerHandler();
            System.assertEquals(false, gridController.isRefreshCacheSucceeded);
            System.assertEquals(1, gridController.componentMessagesMap.size());
            System.assertEquals(0, gridController.copadoNotificationList.size());
            System.assertEquals(null, gridController.copadoNotificationId);

            // Create 1 copado notification
            tu.insertSObjects(
                'Copado_Notification__c',
                1,
                new Map<String, Object>{
                    'Type__c' => 'MetadataRetriever',
                    'status__c' => 'Starting',
                    'isSuccess__c' => false,
                    'isFinished__c' => false,
                    'Name' => 'PROGRESS_STATUS_COPADO',
                    'ParentId__c' => tu.item('Org__c', 0).Id
                }
            );

            gridController.pollerHandler();
            System.assertEquals(false, gridController.isRefreshCacheSucceeded);
            System.assertEquals(2, gridController.getComponentMessageSize());
            System.assertEquals(1, gridController.copadoNotificationList.size());
            System.assertEquals(tu.item('Copado_Notification__c', 0).Id, gridController.copadoNotificationId);

            Copado_Notification__c cn = (Copado_Notification__c) tu.item('Copado_Notification__c', 0);
            cn.isFinished__c = true;
            cn.isSuccess__c = true;
            cn.status__c = 'done';
            update cn;
            gridController.pollerHandler();
            System.assertEquals(true, gridController.isRefreshCacheSucceeded);

            gridController.clearMessagesMap();
            System.assertEquals(0, gridController.componentMessagesMap.size());
            System.assertEquals(0, gridController.copadoNotificationList.size());
            System.assertEquals('', gridController.copadoNotificationId);
            System.assertEquals(false, gridController.showCloseVlocityPromtButton);
            System.assertEquals(false, gridController.showRefreshCachePromtButton);
            System.assertEquals(false, gridController.isVlocitySucceeded);
            System.assertEquals(false, gridController.startActionPoller);
            System.assert(gridController.isRecentChangesEnabled, 'Recent changes action should be enabled');
            System.assertEquals(Label.REFRESH_SINCE_LAST_DATE, gridController.refreshHelpTooltipMessage, 'Tooltip meesage should match');
            Test.stopTest();
        }
    }

    /**
     * Open the new git commit page from user story, fail refresh cache
     */
    @IsTest
    private static void gitCommitPageUSFailRefreshCache() {
        User u = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(u.Username), true, true, true, true, true);

        System.runAs(u) {
            // Create current sprint record
            tu.insertSObject(
                'Sprint__c',
                new Map<String, Object>{ 'Name' => 'Sprint 2', 'Start_Date__c' => Date.today().addDays(-8), 'End_Date__c' => Date.today().addDays(8) }
            );

            // Create environments record
            tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'Dev1', 'org_id__c' => 'SFDC_OrgId' });
            tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'Dev2', 'org_id__c' => 'SFDC_OrgId2' });
            tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'Int', 'org_id__c' => 'SFDC_OrgId3' });
            tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'UAT', 'org_id__c' => 'SFDC_OrgId4' });
            tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'Prod', 'org_id__c' => 'SFDC_OrgId5' });
            insert new List<SObject>{
                tu.item('Environment__c', 0),
                tu.item('Environment__c', 1),
                tu.item('Environment__c', 2),
                tu.item('Environment__c', 3),
                tu.item('Environment__c', 4)
            };

            // Create org credentials record
            tu.createSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'OrgDev1',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 0).Id
                }
            );
            tu.createSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'OrgDev2',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId2',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 1).Id
                }
            );
            tu.createSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'OrgInt',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId3',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Default_Credential__c' => true,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 2).Id
                }
            );
            tu.createSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'OrgUAT',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId4',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 3).Id
                }
            );
            tu.createSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'OrgProd',
                    'Org_Type__c' => 'Production',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId5',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Test_Frequency__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 4).Id
                }
            );
            insert new List<SObject>{ tu.item('Org__c', 0), tu.item('Org__c', 1), tu.item('Org__c', 2), tu.item('Org__c', 3), tu.item('Org__c', 4) };

            // Create 1 git repository
            tu.insertSObjects('Git_Repository__c', 1, new Map<String, Object>{ 'Name' => 'test', 'URI__c' => 'http://www.test.uri' });

            // Create deployment flow record
            tu.insertSObject(
                'Deployment_Flow__c',
                new Map<String, Object>{ 'Name' => 'Deployment Flow', 'Active__c' => true, 'Git_Repository__c' => tu.item('Git_Repository__c', 0).Id }
            );

            // Create deployment flow steps record
            tu.createSObject(
                'Deployment_Flow_Step__c',
                new Map<String, Object>{
                    'Source_Environment__c' => tu.item('Environment__c', 0).Id,
                    'Destination_Environment__c' => tu.item('Environment__c', 2).Id,
                    'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id
                }
            );
            tu.createSObject(
                'Deployment_Flow_Step__c',
                new Map<String, Object>{
                    'Source_Environment__c' => tu.item('Environment__c', 1).Id,
                    'Destination_Environment__c' => tu.item('Environment__c', 2).Id,
                    'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id
                }
            );
            tu.createSObject(
                'Deployment_Flow_Step__c',
                new Map<String, Object>{
                    'Source_Environment__c' => tu.item('Environment__c', 2).Id,
                    'Destination_Environment__c' => tu.item('Environment__c', 3).Id,
                    'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id
                }
            );
            tu.createSObject(
                'Deployment_Flow_Step__c',
                new Map<String, Object>{
                    'Source_Environment__c' => tu.item('Environment__c', 3).Id,
                    'Destination_Environment__c' => tu.item('Environment__c', 4).Id,
                    'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id
                }
            );
            insert new List<SObject>{
                tu.item('Deployment_Flow_Step__c', 0),
                tu.item('Deployment_Flow_Step__c', 1),
                tu.item('Deployment_Flow_Step__c', 2),
                tu.item('Deployment_Flow_Step__c', 3)
            };

            // Create project record
            tu.insertSObject(
                'Project__c',
                new Map<String, Object>{
                    'Name' => 'My project',
                    'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id,
                    'Index_Metadata__c' => false
                }
            );

            // Create 3 user story to fill sobjectlist
            tu.insertSObjects(
                'User_Story__c',
                3,
                new Map<String, Object>{
                    'User_Story_Title__c' => 'us-0000000',
                    'Status__c' => 'Approved',
                    'Sprint__c' => tu.item('Sprint__c', 0).Id,
                    'Project__c' => tu.item('Project__c', 0).Id,
                    'Environment__c' => tu.item('Environment__c', 0).Id,
                    'Org_Credential__c' => tu.item('Org__c', 0).Id
                }
            );

            // Create 1 git backup
            tu.insertSObjects(
                'Git_Backup__c',
                1,
                new Map<String, Object>{
                    'Name' => 'backupname',
                    'Branch__c' => 'branchName',
                    'Frequency__c' => null,
                    'Git_Repository__c' => tu.item('Git_Repository__c', 0).Id,
                    'Org__c' => tu.item('Org__c', 0).Id
                }
            );

            Test.startTest();
            PageReference pReference = Page.GitCommitMain;
            pReference.getParameters().put('userStoryId', tu.item('User_Story__c', 0).Id);
            pReference.getParameters().put('variant', 'userstorycommit');
            Test.setCurrentPage(pReference);

            String mockResponse = '[{"operationType": "RecommitFiles","operationLabel": "Recommit Files","showGrid": true,"showUserStorySelections": true,"showCommitMessage": true,"operationFormElements": [{"label": "Re-Create Feature Branch","name": "recreateFeatureBranch","value": "","type": "checkbox","helpText": "If checked, the existing feature branch will be deleted and the selected components in the grid will be committed in a new feature branch. Previous commits will not be present in the new feature branch. WARNING: Profiles and Permission Sets committed as full in this User Story will be recommitted as in the Commit Files operation. If you want them to be recommitted as full, you need to commit them again using the Full Profiles & Permission Sets git operation."}],"helpText": "When recommitting files, the metadata grid appears with the existing user story selections. You can uncheck the selected components and also select new ones.","helpLink": "https://docs.copado.com/git-operations/recommit-files","pages": "UserStoryCommit","endpoint": "commit","showAdvancedSection":true,"possibleRunningJob":""},{"operationType": "GitDeletion","operationLabel": "Destructive Changes","operationButtonLabel": "Commit Destructive Changes","attachmentName": "Git Deletion","operationFormElements": [{"label": "Org Credential","name": "orgId","type": "orgLookup","helpText": "If changed, the metadata grid will reload with the metadata items of the selected Org Credential."}],"showGrid": true,"editGrid": true,"reloadGridData": true,"showCommitMessage": true,"helpText": "When deleting components, a table appears with a list of User Story Commits with status \'Complete\'. Select the commits you would like to undo and click Undo Commits. When the operation is finished, the status of the selected User Story Commits will be updated to \'Commit Undone\'.","helpLink": "https://docs.copado.com/git-operations/destructive-changes","pages": "GitSnapshotCommit,UserStoryCommit","endpoint": "commit","showAdvancedSection":true,"possibleRunningJob":",GitDeletion,{!snapshotId},true"},{"operationType": "FullProfilePermissionSets","operationLabel": "Full Profiles & Permission Sets","showGrid": true,"gridMetadataTypes": "Profile,PermissionSet","showCommitMessage": true,"helpText": "","helpLink": "https://docs.copado.com/git-operations/commit-full-profiles-and-permission-sets","pages": "GitSnapshotCommit,UserStoryCommit","endpoint": "commit","showAdvancedSection":true,"possibleRunningJob":""},{"operationType": "VlocityDependencies","operationLabel": "","showGrid": false,"gridMetadataTypes": "","showCommitMessage": false,"helpText": "","helpLink": "","pages": "UserStoryCommit","endpoint": "","showAdvancedSection":false,"possibleRunningJob": ",MetadataDependenciesJob,{!userStoryId},true"},{"operationType": "GitCommit","operationLabel": "","showGrid": false,"gridMetadataTypes": "","showCommitMessage": false,"helpText": "Git Commit help","helpLink": "","pages": "UserStoryCommit","endpoint": "","showAdvancedSection":false,"possibleRunningJob": ",GitCommit,{!snapshotId},true"}]';
            MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', mockResponse, null);
            Test.setMock(HttpCalloutMock.class, fakeResponse);
            GitCommit_MainPageController controller = new GitCommit_MainPageController();
            System.assertEquals(0, controller.pageMessagesMap.size());
            System.assertNotEquals(null, controller.pageMessagesMap);
            System.assertEquals(4, controller.operationsMap.size());
            System.assertEquals(1, controller.snapshotList.size());
            System.assertEquals(tu.item('User_Story__c', 0).Id, controller.userStory.Id);

            GitCommit_HeaderController headerController = new GitCommit_HeaderController();
            headerController.pageController = controller;
            User_Story__c us = [SELECT Name, User_Story_Title__c FROM User_Story__c WHERE Id = :tu.item('User_Story__c', 0).Id];
            String msg = headerController.commitMessage;
            String expectedMsg = us.Name + ': ' + us.User_Story_Title__c;
            System.assertEquals(expectedMsg, msg);
            List<SelectOption> options = headerController.availableOperationList;
            System.assertEquals(4, options.size());

            GitCommit_GridController gridController = new GitCommit_GridController();
            gridController.pageController = controller;
            String opName = gridController.operationName;
            System.assertEquals('', opName);
            Boolean startPoller = gridController.startActionPoller;
            System.assertEquals(false, startPoller);
            Boolean showRefreshPromtButton = gridController.showRefreshCachePromtButton;
            System.assertEquals(false, showRefreshPromtButton);
            Boolean refreshSucceeded = gridController.isRefreshCacheSucceeded;
            System.assertEquals(false, refreshSucceeded);

            pReference.getParameters().put('operation', 'refreshCache');
            gridController.initPoller();
            System.assertEquals('refreshCache', gridController.operationName);
            System.assertEquals(true, gridController.startActionPoller);
            System.assertEquals(1, gridController.componentMessagesMap.size());
            System.assertEquals(1, gridController.getComponentMessageSize());
            for (String severity : gridController.componentMessagesMap.keySet()) {
                System.assertEquals('info', severity);
                for (Object obj : gridController.componentMessagesMap.get(severity)) {
                    System.assertEquals(Label.Initializing, obj);
                }
            }

            gridController.pollerHandler();
            System.assertEquals(false, gridController.isRefreshCacheSucceeded);
            System.assertEquals(1, gridController.componentMessagesMap.size());
            System.assertEquals(0, gridController.copadoNotificationList.size());
            System.assertEquals(null, gridController.copadoNotificationId);

            // Create 1 copado notification
            tu.insertSObjects(
                'Copado_Notification__c',
                1,
                new Map<String, Object>{
                    'Type__c' => 'MetadataRetriever',
                    'status__c' => 'Starting',
                    'isSuccess__c' => false,
                    'isFinished__c' => false,
                    'Name' => 'PROGRESS_STATUS_COPADO',
                    'ParentId__c' => tu.item('Org__c', 0).Id
                }
            );

            gridController.pollerHandler();
            System.assertEquals(false, gridController.isRefreshCacheSucceeded);
            System.assertEquals(2, gridController.getComponentMessageSize());
            System.assertEquals(1, gridController.copadoNotificationList.size());
            System.assertEquals(tu.item('Copado_Notification__c', 0).Id, gridController.copadoNotificationId);

            Copado_Notification__c cn = (Copado_Notification__c) tu.item('Copado_Notification__c', 0);
            cn.isFinished__c = true;
            cn.isSuccess__c = false;
            cn.status__c = 'done';
            update cn;
            gridController.pollerHandler();
            System.assertEquals(false, gridController.isRefreshCacheSucceeded);
            System.assertEquals(true, gridController.showRefreshCachePromtButton);
            System.assertEquals(2, gridController.componentMessagesMap.size());
            System.assertEquals(3, gridController.getComponentMessageSize());

            gridController.clearMessagesMap();
            System.assertEquals(0, gridController.componentMessagesMap.size());
            System.assertEquals(0, gridController.copadoNotificationList.size());
            System.assertEquals('', gridController.copadoNotificationId);
            System.assertEquals(false, gridController.showCloseVlocityPromtButton);
            System.assertEquals(false, gridController.showRefreshCachePromtButton);
            System.assertEquals(false, gridController.isVlocitySucceeded);
            System.assertEquals(false, gridController.startActionPoller);
            Test.stopTest();
        }
    }

    /**
     * Open the new git commit page from user story, vlocity get dependencies
     */
    @IsTest
    private static void gitCommitPageUSVlocityDependencies() {
        User u = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(u.Username), true, true, true, true, true);

        System.runAs(u) {
            // Create current sprint record
            tu.insertSObject(
                'Sprint__c',
                new Map<String, Object>{ 'Name' => 'Sprint 2', 'Start_Date__c' => Date.today().addDays(-8), 'End_Date__c' => Date.today().addDays(8) }
            );

            // Create environments record
            tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'Dev1', 'org_id__c' => 'SFDC_OrgId' });
            tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'Dev2', 'org_id__c' => 'SFDC_OrgId2' });
            tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'Int', 'org_id__c' => 'SFDC_OrgId3' });
            tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'UAT', 'org_id__c' => 'SFDC_OrgId4' });
            tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'Prod', 'org_id__c' => 'SFDC_OrgId5' });
            insert new List<SObject>{
                tu.item('Environment__c', 0),
                tu.item('Environment__c', 1),
                tu.item('Environment__c', 2),
                tu.item('Environment__c', 3),
                tu.item('Environment__c', 4)
            };

            // Create org credentials record
            tu.createSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'OrgDev1',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 0).Id
                }
            );
            tu.createSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'OrgDev2',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId2',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 1).Id
                }
            );
            tu.createSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'OrgInt',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId3',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Default_Credential__c' => true,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 2).Id
                }
            );
            tu.createSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'OrgUAT',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId4',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 3).Id
                }
            );
            tu.createSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'OrgProd',
                    'Org_Type__c' => 'Production',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId5',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Test_Frequency__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 4).Id
                }
            );
            insert new List<SObject>{ tu.item('Org__c', 0), tu.item('Org__c', 1), tu.item('Org__c', 2), tu.item('Org__c', 3), tu.item('Org__c', 4) };

            // Create 1 git repository
            tu.insertSObjects('Git_Repository__c', 1, new Map<String, Object>{ 'Name' => 'test', 'URI__c' => 'http://www.test.uri' });

            // Create deployment flow record
            tu.insertSObject(
                'Deployment_Flow__c',
                new Map<String, Object>{ 'Name' => 'Deployment Flow', 'Active__c' => true, 'Git_Repository__c' => tu.item('Git_Repository__c', 0).Id }
            );

            // Create deployment flow steps record
            tu.createSObject(
                'Deployment_Flow_Step__c',
                new Map<String, Object>{
                    'Source_Environment__c' => tu.item('Environment__c', 0).Id,
                    'Destination_Environment__c' => tu.item('Environment__c', 2).Id,
                    'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id
                }
            );
            tu.createSObject(
                'Deployment_Flow_Step__c',
                new Map<String, Object>{
                    'Source_Environment__c' => tu.item('Environment__c', 1).Id,
                    'Destination_Environment__c' => tu.item('Environment__c', 2).Id,
                    'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id
                }
            );
            tu.createSObject(
                'Deployment_Flow_Step__c',
                new Map<String, Object>{
                    'Source_Environment__c' => tu.item('Environment__c', 2).Id,
                    'Destination_Environment__c' => tu.item('Environment__c', 3).Id,
                    'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id
                }
            );
            tu.createSObject(
                'Deployment_Flow_Step__c',
                new Map<String, Object>{
                    'Source_Environment__c' => tu.item('Environment__c', 3).Id,
                    'Destination_Environment__c' => tu.item('Environment__c', 4).Id,
                    'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id
                }
            );
            insert new List<SObject>{
                tu.item('Deployment_Flow_Step__c', 0),
                tu.item('Deployment_Flow_Step__c', 1),
                tu.item('Deployment_Flow_Step__c', 2),
                tu.item('Deployment_Flow_Step__c', 3)
            };

            // Create project record
            tu.insertSObject(
                'Project__c',
                new Map<String, Object>{
                    'Name' => 'My project',
                    'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id,
                    'Index_Metadata__c' => false
                }
            );

            // Create 3 user story to fill sobjectlist
            tu.insertSObjects(
                'User_Story__c',
                3,
                new Map<String, Object>{
                    'User_Story_Title__c' => 'us-0000000',
                    'Status__c' => 'Approved',
                    'Sprint__c' => tu.item('Sprint__c', 0).Id,
                    'Project__c' => tu.item('Project__c', 0).Id,
                    'Environment__c' => tu.item('Environment__c', 0).Id,
                    'Org_Credential__c' => tu.item('Org__c', 0).Id
                }
            );

            // Create 1 git backup
            tu.insertSObjects(
                'Git_Backup__c',
                1,
                new Map<String, Object>{
                    'Name' => 'backupname',
                    'Branch__c' => 'branchName',
                    'Frequency__c' => null,
                    'Git_Repository__c' => tu.item('Git_Repository__c', 0).Id,
                    'Org__c' => tu.item('Org__c', 0).Id
                }
            );

            // Create vlocity feature
            tu.insertSObjects('Feature__c', 1, new Map<String, Object>{ 'Name' => 'Vlocity', 'Enabled__c' => true });

            Test.startTest();
            PageReference pReference = Page.GitCommitMain;
            pReference.getParameters().put('userStoryId', tu.item('User_Story__c', 0).Id);
            pReference.getParameters().put('variant', 'userstorycommit');
            Test.setCurrentPage(pReference);

            String mockResponse = '[{"operationType": "RecommitFiles","operationLabel": "Recommit Files","showGrid": true,"showUserStorySelections": true,"showCommitMessage": true,"operationFormElements": [{"label": "Re-Create Feature Branch","name": "recreateFeatureBranch","value": "","type": "checkbox","helpText": "If checked, the existing feature branch will be deleted and the selected components in the grid will be committed in a new feature branch. Previous commits will not be present in the new feature branch. WARNING: Profiles and Permission Sets committed as full in this User Story will be recommitted as in the Commit Files operation. If you want them to be recommitted as full, you need to commit them again using the Full Profiles & Permission Sets git operation."}],"helpText": "When recommitting files, the metadata grid appears with the existing user story selections. You can uncheck the selected components and also select new ones.","helpLink": "https://docs.copado.com/git-operations/recommit-files","pages": "UserStoryCommit","endpoint": "commit","showAdvancedSection":true,"possibleRunningJob":""},{"operationType": "GitDeletion","operationLabel": "Destructive Changes","operationButtonLabel": "Commit Destructive Changes","attachmentName": "Git Deletion","operationFormElements": [{"label": "Org Credential","name": "orgId","type": "orgLookup","helpText": "If changed, the metadata grid will reload with the metadata items of the selected Org Credential."}],"showGrid": true,"editGrid": true,"reloadGridData": true,"showCommitMessage": true,"helpText": "When deleting components, a table appears with a list of User Story Commits with status \'Complete\'. Select the commits you would like to undo and click Undo Commits. When the operation is finished, the status of the selected User Story Commits will be updated to \'Commit Undone\'.","helpLink": "https://docs.copado.com/git-operations/destructive-changes","pages": "GitSnapshotCommit,UserStoryCommit","endpoint": "commit","showAdvancedSection":true,"possibleRunningJob":",GitDeletion,{!snapshotId},true"},{"operationType": "FullProfilePermissionSets","operationLabel": "Full Profiles & Permission Sets","showGrid": true,"gridMetadataTypes": "Profile,PermissionSet","showCommitMessage": true,"helpText": "","helpLink": "https://docs.copado.com/git-operations/commit-full-profiles-and-permission-sets","pages": "GitSnapshotCommit,UserStoryCommit","endpoint": "commit","showAdvancedSection":true,"possibleRunningJob":""},{"operationType": "VlocityDependencies","operationLabel": "","showGrid": false,"gridMetadataTypes": "","showCommitMessage": false,"helpText": "","helpLink": "","pages": "UserStoryCommit","endpoint": "","showAdvancedSection":false,"possibleRunningJob": ",MetadataDependenciesJob,{!userStoryId},true"},{"operationType": "GitCommit","operationLabel": "","showGrid": false,"gridMetadataTypes": "","showCommitMessage": false,"helpText": "Git Commit help","helpLink": "","pages": "UserStoryCommit","endpoint": "","showAdvancedSection":false,"possibleRunningJob": ",GitCommit,{!snapshotId},true"}]';
            MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', mockResponse, null);
            Test.setMock(HttpCalloutMock.class, fakeResponse);
            GitCommit_MainPageController controller = new GitCommit_MainPageController();
            System.assertEquals(0, controller.pageMessagesMap.size());
            System.assertNotEquals(null, controller.pageMessagesMap);
            System.assertEquals(4, controller.operationsMap.size());
            System.assertEquals(1, controller.snapshotList.size());
            System.assertEquals(tu.item('User_Story__c', 0).Id, controller.userStory.Id);
            System.assertEquals(true, controller.showVlocity);

            GitCommit_HeaderController headerController = new GitCommit_HeaderController();
            headerController.pageController = controller;
            User_Story__c us = [SELECT Name, User_Story_Title__c FROM User_Story__c WHERE Id = :tu.item('User_Story__c', 0).Id];
            String msg = headerController.commitMessage;
            String expectedMsg = us.Name + ': ' + us.User_Story_Title__c;
            System.assertEquals(expectedMsg, msg);
            List<SelectOption> options = headerController.availableOperationList;
            System.assertEquals(4, options.size());

            GitCommit_GridController gridController = new GitCommit_GridController();
            gridController.pageController = controller;
            String opName = gridController.operationName;
            System.assertEquals('', opName);
            Boolean startPoller = gridController.startActionPoller;
            System.assertEquals(false, startPoller);
            Boolean showVlocityPromtButton = gridController.showCloseVlocityPromtButton;
            System.assertEquals(false, showVlocityPromtButton);
            Boolean vlocitySucceeded = gridController.isVlocitySucceeded;
            System.assertEquals(false, vlocitySucceeded);

            pReference.getParameters().put('operation', 'vlocity');
            gridController.initPoller();
            System.assertEquals('vlocity', gridController.operationName);
            System.assertEquals(true, gridController.startActionPoller);
            System.assertEquals(1, gridController.componentMessagesMap.size());
            System.assertEquals(1, gridController.getComponentMessageSize());
            for (String severity : gridController.componentMessagesMap.keySet()) {
                System.assertEquals('info', severity);
                for (Object obj : gridController.componentMessagesMap.get(severity)) {
                    System.assertEquals(Label.Initializing, obj);
                }
            }

            gridController.pollerHandler();
            System.assertEquals(false, gridController.isRefreshCacheSucceeded);
            System.assertEquals(1, gridController.componentMessagesMap.size());
            System.assertEquals(0, gridController.copadoNotificationList.size());
            System.assertEquals(null, gridController.copadoNotificationId);

            // Create 1 copado notification
            tu.insertSObjects(
                'Copado_Notification__c',
                1,
                new Map<String, Object>{
                    'Type__c' => 'MetadataDependenciesJob',
                    'status__c' => 'Starting',
                    'isSuccess__c' => false,
                    'isFinished__c' => false,
                    'Name' => 'MetadataDependenciesJob ' + tu.item('User_Story__c', 0).Id,
                    'ParentId__c' => tu.item('User_Story__c', 0).Id
                }
            );

            gridController.pollerHandler();
            System.assertEquals(false, gridController.isVlocitySucceeded);
            System.assertEquals(2, gridController.getComponentMessageSize());
            System.assertEquals(1, gridController.copadoNotificationList.size());
            System.assertEquals(tu.item('Copado_Notification__c', 0).Id, gridController.copadoNotificationId);

            Copado_Notification__c cn = (Copado_Notification__c) tu.item('Copado_Notification__c', 0);
            cn.isFinished__c = true;
            cn.isSuccess__c = true;
            cn.status__c = 'done';
            update cn;
            gridController.pollerHandler();
            System.assertEquals(true, gridController.isVlocitySucceeded);

            gridController.clearMessagesMap();
            System.assertEquals(0, gridController.componentMessagesMap.size());
            System.assertEquals(0, gridController.copadoNotificationList.size());
            System.assertEquals('', gridController.copadoNotificationId);
            System.assertEquals(false, gridController.showCloseVlocityPromtButton);
            System.assertEquals(false, gridController.showRefreshCachePromtButton);
            System.assertEquals(false, gridController.isVlocitySucceeded);
            System.assertEquals(false, gridController.startActionPoller);
            Test.stopTest();
        }
    }

    /**
     * Open the new git commit page from user story, destructive changes
     */
    @IsTest
    private static void gitCommitPageUSDestructiveChanges() {
        User u = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(u.Username), true, true, true, true, true);
        Personal_Settings__c settings = new Personal_Settings__c(Disable_Re_Create_Feature_Branch_in_US__c = true, SetupOwnerId = u.Id);
        upsert settings;
        System.runAs(u) {
            // Create current sprint record
            tu.insertSObject(
                'Sprint__c',
                new Map<String, Object>{ 'Name' => 'Sprint 2', 'Start_Date__c' => Date.today().addDays(-8), 'End_Date__c' => Date.today().addDays(8) }
            );

            // Create environments record
            tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'Dev1', 'org_id__c' => 'SFDC_OrgId' });
            tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'Dev2', 'org_id__c' => 'SFDC_OrgId2' });
            tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'Int', 'org_id__c' => 'SFDC_OrgId3' });
            tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'UAT', 'org_id__c' => 'SFDC_OrgId4' });
            tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'Prod', 'org_id__c' => 'SFDC_OrgId5' });
            insert new List<SObject>{
                tu.item('Environment__c', 0),
                tu.item('Environment__c', 1),
                tu.item('Environment__c', 2),
                tu.item('Environment__c', 3),
                tu.item('Environment__c', 4)
            };

            // Create org credentials record
            tu.createSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'OrgDev1',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 0).Id
                }
            );
            tu.createSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'OrgDev2',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId2',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 1).Id
                }
            );
            tu.createSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'OrgInt',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId3',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Default_Credential__c' => true,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 2).Id
                }
            );
            tu.createSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'OrgUAT',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId4',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 3).Id
                }
            );
            tu.createSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'OrgProd',
                    'Org_Type__c' => 'Production',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId5',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Test_Frequency__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 4).Id
                }
            );
            insert new List<SObject>{ tu.item('Org__c', 0), tu.item('Org__c', 1), tu.item('Org__c', 2), tu.item('Org__c', 3), tu.item('Org__c', 4) };

            // Create 1 git repository
            tu.insertSObjects('Git_Repository__c', 1, new Map<String, Object>{ 'Name' => 'test', 'URI__c' => 'http://www.test.uri' });

            // Create deployment flow record
            tu.insertSObject(
                'Deployment_Flow__c',
                new Map<String, Object>{ 'Name' => 'Deployment Flow', 'Active__c' => true, 'Git_Repository__c' => tu.item('Git_Repository__c', 0).Id }
            );

            // Create deployment flow steps record
            tu.createSObject(
                'Deployment_Flow_Step__c',
                new Map<String, Object>{
                    'Source_Environment__c' => tu.item('Environment__c', 0).Id,
                    'Destination_Environment__c' => tu.item('Environment__c', 2).Id,
                    'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id
                }
            );
            tu.createSObject(
                'Deployment_Flow_Step__c',
                new Map<String, Object>{
                    'Source_Environment__c' => tu.item('Environment__c', 1).Id,
                    'Destination_Environment__c' => tu.item('Environment__c', 2).Id,
                    'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id
                }
            );
            tu.createSObject(
                'Deployment_Flow_Step__c',
                new Map<String, Object>{
                    'Source_Environment__c' => tu.item('Environment__c', 2).Id,
                    'Destination_Environment__c' => tu.item('Environment__c', 3).Id,
                    'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id
                }
            );
            tu.createSObject(
                'Deployment_Flow_Step__c',
                new Map<String, Object>{
                    'Source_Environment__c' => tu.item('Environment__c', 3).Id,
                    'Destination_Environment__c' => tu.item('Environment__c', 4).Id,
                    'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id
                }
            );
            insert new List<SObject>{
                tu.item('Deployment_Flow_Step__c', 0),
                tu.item('Deployment_Flow_Step__c', 1),
                tu.item('Deployment_Flow_Step__c', 2),
                tu.item('Deployment_Flow_Step__c', 3)
            };

            // Create project record
            tu.insertSObject(
                'Project__c',
                new Map<String, Object>{
                    'Name' => 'My project',
                    'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id,
                    'Index_Metadata__c' => false
                }
            );

            // Create 3 user story to fill sobjectlist
            tu.insertSObjects(
                'User_Story__c',
                3,
                new Map<String, Object>{
                    'User_Story_Title__c' => 'us-0000000',
                    'Status__c' => 'Approved',
                    'Sprint__c' => tu.item('Sprint__c', 0).Id,
                    'Project__c' => tu.item('Project__c', 0).Id,
                    'Environment__c' => tu.item('Environment__c', 0).Id,
                    'Org_Credential__c' => tu.item('Org__c', 0).Id
                }
            );

            // Create 1 git backup
            tu.insertSObjects(
                'Git_Backup__c',
                1,
                new Map<String, Object>{
                    'Name' => 'backupname',
                    'Branch__c' => 'branchName',
                    'Frequency__c' => null,
                    'Git_Repository__c' => tu.item('Git_Repository__c', 0).Id,
                    'Org__c' => tu.item('Org__c', 0).Id
                }
            );

            Test.startTest();
            PageReference pReference = Page.GitCommitMain;
            pReference.getParameters().put('userStoryId', tu.item('User_Story__c', 0).Id);
            pReference.getParameters().put('variant', 'userstorycommit');
            Test.setCurrentPage(pReference);

            String mockResponse = '[{"operationType": "RecommitFiles","operationLabel": "Recommit Files","showGrid": true,"showUserStorySelections": true,"showCommitMessage": true,"operationFormElements": [{"label": "Re-Create Feature Branch","name": "recreateFeatureBranch","value": "","type": "checkbox","helpText": "If checked, the existing feature branch will be deleted and the selected components in the grid will be committed in a new feature branch. Previous commits will not be present in the new feature branch. WARNING: Profiles and Permission Sets committed as full in this User Story will be recommitted as in the Commit Files operation. If you want them to be recommitted as full, you need to commit them again using the Full Profiles & Permission Sets git operation."}],"helpText": "When recommitting files, the metadata grid appears with the existing user story selections. You can uncheck the selected components and also select new ones.","helpLink": "https://docs.copado.com/git-operations/recommit-files","pages": "UserStoryCommit","endpoint": "commit","showAdvancedSection":true,"possibleRunningJob":""},{"operationType": "GitDeletion","operationLabel": "Destructive Changes","operationButtonLabel": "Commit Destructive Changes","attachmentName": "Git Deletion","operationFormElements": [{"label": "Org Credential","name": "orgId","type": "orgLookup","helpText": "If changed, the metadata grid will reload with the metadata items of the selected Org Credential."}],"showGrid": true,"editGrid": true,"reloadGridData": true,"showCommitMessage": true,"helpText": "When deleting components, a table appears with a list of User Story Commits with status \'Complete\'. Select the commits you would like to undo and click Undo Commits. When the operation is finished, the status of the selected User Story Commits will be updated to \'Commit Undone\'.","helpLink": "https://docs.copado.com/git-operations/destructive-changes","pages": "GitSnapshotCommit,UserStoryCommit","endpoint": "commit","showAdvancedSection":true,"possibleRunningJob":",GitDeletion,{!snapshotId},true"},{"operationType": "FullProfilePermissionSets","operationLabel": "Full Profiles & Permission Sets","showGrid": true,"gridMetadataTypes": "Profile,PermissionSet","showCommitMessage": true,"helpText": "","helpLink": "https://docs.copado.com/git-operations/commit-full-profiles-and-permission-sets","pages": "GitSnapshotCommit,UserStoryCommit","endpoint": "commit","showAdvancedSection":true,"possibleRunningJob":""},{"operationType": "VlocityDependencies","operationLabel": "","showGrid": false,"gridMetadataTypes": "","showCommitMessage": false,"helpText": "","helpLink": "","pages": "UserStoryCommit","endpoint": "","showAdvancedSection":false,"possibleRunningJob": ",MetadataDependenciesJob,{!userStoryId},true"},{"operationType": "GitCommit","operationLabel": "","showGrid": false,"gridMetadataTypes": "","showCommitMessage": false,"helpText": "Git Commit help","helpLink": "","pages": "UserStoryCommit","endpoint": "","showAdvancedSection":false,"possibleRunningJob": ",GitCommit,{!snapshotId},true"}]';
            MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', mockResponse, null);
            Test.setMock(HttpCalloutMock.class, fakeResponse);
            GitCommit_MainPageController controller = new GitCommit_MainPageController();
            System.assertEquals(0, controller.pageMessagesMap.size());
            System.assertNotEquals(null, controller.pageMessagesMap);
            System.assertEquals(4, controller.operationsMap.size());
            System.assertEquals(1, controller.snapshotList.size());
            System.assertEquals(tu.item('User_Story__c', 0).Id, controller.userStory.Id);

            GitCommit_HeaderController headerController = new GitCommit_HeaderController();
            headerController.pageController = controller;
            User_Story__c us = [SELECT Name, User_Story_Title__c FROM User_Story__c WHERE Id = :tu.item('User_Story__c', 0).Id];
            String msg = headerController.commitMessage;
            String expectedMsg = us.Name + ': ' + us.User_Story_Title__c;
            System.assertEquals(expectedMsg, msg);
            List<SelectOption> options = headerController.availableOperationList;
            System.assertEquals(4, options.size());

            GitCommit_GridController gridController = new GitCommit_GridController();
            gridController.pageController = controller;
            String opName = gridController.operationName;
            System.assertEquals('', opName);
            Boolean startPoller = gridController.startActionPoller;
            System.assertEquals(false, startPoller);
            Boolean showRefreshPromtButton = gridController.showRefreshCachePromtButton;
            System.assertEquals(false, showRefreshPromtButton);
            Boolean refreshSucceeded = gridController.isRefreshCacheSucceeded;
            System.assertEquals(false, refreshSucceeded);

            GitCommit_OperationsController operationController = new GitCommit_OperationsController();
            String expectedStr = operationController.updateAuxObject();
            System.assertEquals('', expectedStr);
            Boolean disableRecreateBranch = operationController.disableRecreateBranch;
            System.assert(disableRecreateBranch, 'Disable Re-Create Feature Branch in US under personal settings should be true');
            operationController.pageController = controller;
            AuxiliaryObject__c auxObj = operationController.auxObj;
            System.assertEquals(tu.item('Org__c', 0).Id, auxObj.Org_Credential__c);
            auxObj.Org_Credential__c = tu.item('Org__c', 1).Id;
            Test.stopTest();
        }
    }

    /**
     * Open the new git commit page from user story, advanced section and branch update
     */
    @IsTest
    private static void gitCommitPageUSAdvanced() {
        User u = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(u.Username), true, true, true, true, true);

        System.runAs(u) {
            // Create current sprint record
            tu.insertSObject(
                'Sprint__c',
                new Map<String, Object>{ 'Name' => 'Sprint 2', 'Start_Date__c' => Date.today().addDays(-8), 'End_Date__c' => Date.today().addDays(8) }
            );

            // Create environments record
            tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'Dev1', 'org_id__c' => 'SFDC_OrgId' });
            tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'Dev2', 'org_id__c' => 'SFDC_OrgId2' });
            tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'Int', 'org_id__c' => 'SFDC_OrgId3' });
            tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'UAT', 'org_id__c' => 'SFDC_OrgId4' });
            tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'Prod', 'org_id__c' => 'SFDC_OrgId5' });
            insert new List<SObject>{
                tu.item('Environment__c', 0),
                tu.item('Environment__c', 1),
                tu.item('Environment__c', 2),
                tu.item('Environment__c', 3),
                tu.item('Environment__c', 4)
            };

            // Create org credentials record
            tu.createSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'OrgDev1',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 0).Id
                }
            );
            tu.createSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'OrgDev2',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId2',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 1).Id
                }
            );
            tu.createSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'OrgInt',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId3',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Default_Credential__c' => true,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 2).Id
                }
            );
            tu.createSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'OrgUAT',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId4',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 3).Id
                }
            );
            tu.createSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'OrgProd',
                    'Org_Type__c' => 'Production',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId5',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Test_Frequency__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 4).Id
                }
            );
            insert new List<SObject>{ tu.item('Org__c', 0), tu.item('Org__c', 1), tu.item('Org__c', 2), tu.item('Org__c', 3), tu.item('Org__c', 4) };

            // Create 1 git repository
            tu.insertSObjects('Git_Repository__c', 1, new Map<String, Object>{ 'Name' => 'test', 'URI__c' => 'http://www.test.uri' });

            // Create deployment flow record
            tu.insertSObject(
                'Deployment_Flow__c',
                new Map<String, Object>{ 'Name' => 'Deployment Flow', 'Active__c' => true, 'Git_Repository__c' => tu.item('Git_Repository__c', 0).Id }
            );

            // Create deployment flow steps record
            tu.createSObject(
                'Deployment_Flow_Step__c',
                new Map<String, Object>{
                    'Source_Environment__c' => tu.item('Environment__c', 0).Id,
                    'Destination_Environment__c' => tu.item('Environment__c', 2).Id,
                    'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id
                }
            );
            tu.createSObject(
                'Deployment_Flow_Step__c',
                new Map<String, Object>{
                    'Source_Environment__c' => tu.item('Environment__c', 1).Id,
                    'Destination_Environment__c' => tu.item('Environment__c', 2).Id,
                    'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id
                }
            );
            tu.createSObject(
                'Deployment_Flow_Step__c',
                new Map<String, Object>{
                    'Source_Environment__c' => tu.item('Environment__c', 2).Id,
                    'Destination_Environment__c' => tu.item('Environment__c', 3).Id,
                    'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id
                }
            );
            tu.createSObject(
                'Deployment_Flow_Step__c',
                new Map<String, Object>{
                    'Source_Environment__c' => tu.item('Environment__c', 3).Id,
                    'Destination_Environment__c' => tu.item('Environment__c', 4).Id,
                    'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id
                }
            );
            insert new List<SObject>{
                tu.item('Deployment_Flow_Step__c', 0),
                tu.item('Deployment_Flow_Step__c', 1),
                tu.item('Deployment_Flow_Step__c', 2),
                tu.item('Deployment_Flow_Step__c', 3)
            };

            // Create project record
            tu.insertSObject(
                'Project__c',
                new Map<String, Object>{
                    'Name' => 'My project',
                    'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id,
                    'Index_Metadata__c' => false
                }
            );

            // Create 3 user story to fill sobjectlist
            tu.insertSObjects(
                'User_Story__c',
                3,
                new Map<String, Object>{
                    'User_Story_Title__c' => 'us-0000000',
                    'Status__c' => 'Approved',
                    'Sprint__c' => tu.item('Sprint__c', 0).Id,
                    'Project__c' => tu.item('Project__c', 0).Id,
                    'Environment__c' => tu.item('Environment__c', 0).Id,
                    'Org_Credential__c' => tu.item('Org__c', 0).Id
                }
            );

            // Create 1 git backup
            tu.insertSObjects(
                'Git_Backup__c',
                1,
                new Map<String, Object>{
                    'Name' => 'backupname',
                    'Branch__c' => 'branchName',
                    'Frequency__c' => null,
                    'Git_Repository__c' => tu.item('Git_Repository__c', 0).Id,
                    'Org__c' => tu.item('Org__c', 0).Id
                }
            );

            Test.startTest();
            PageReference pReference = Page.GitCommitMain;
            pReference.getParameters().put('userStoryId', tu.item('User_Story__c', 0).Id);
            pReference.getParameters().put('variant', 'userstorycommit');
            Test.setCurrentPage(pReference);

            String mockResponse = '[{"operationType": "RecommitFiles","operationLabel": "Recommit Files","showGrid": true,"showUserStorySelections": true,"showCommitMessage": true,"operationFormElements": [{"label": "Re-Create Feature Branch","name": "recreateFeatureBranch","value": "","type": "checkbox","helpText": "If checked, the existing feature branch will be deleted and the selected components in the grid will be committed in a new feature branch. Previous commits will not be present in the new feature branch. WARNING: Profiles and Permission Sets committed as full in this User Story will be recommitted as in the Commit Files operation. If you want them to be recommitted as full, you need to commit them again using the Full Profiles & Permission Sets git operation."}],"helpText": "When recommitting files, the metadata grid appears with the existing user story selections. You can uncheck the selected components and also select new ones.","helpLink": "https://docs.copado.com/git-operations/recommit-files","pages": "UserStoryCommit","endpoint": "commit","showAdvancedSection":true,"possibleRunningJob":""},{"operationType": "GitDeletion","operationLabel": "Destructive Changes","operationButtonLabel": "Commit Destructive Changes","attachmentName": "Git Deletion","operationFormElements": [{"label": "Org Credential","name": "orgId","type": "orgLookup","helpText": "If changed, the metadata grid will reload with the metadata items of the selected Org Credential."}],"showGrid": true,"editGrid": true,"reloadGridData": true,"showCommitMessage": true,"helpText": "When deleting components, a table appears with a list of User Story Commits with status \'Complete\'. Select the commits you would like to undo and click Undo Commits. When the operation is finished, the status of the selected User Story Commits will be updated to \'Commit Undone\'.","helpLink": "https://docs.copado.com/git-operations/destructive-changes","pages": "GitSnapshotCommit,UserStoryCommit","endpoint": "commit","showAdvancedSection":true,"possibleRunningJob":",GitDeletion,{!snapshotId},true"},{"operationType": "FullProfilePermissionSets","operationLabel": "Full Profiles & Permission Sets","showGrid": true,"gridMetadataTypes": "Profile,PermissionSet","showCommitMessage": true,"helpText": "","helpLink": "https://docs.copado.com/git-operations/commit-full-profiles-and-permission-sets","pages": "GitSnapshotCommit,UserStoryCommit","endpoint": "commit","showAdvancedSection":true,"possibleRunningJob":""},{"operationType": "VlocityDependencies","operationLabel": "","showGrid": false,"gridMetadataTypes": "","showCommitMessage": false,"helpText": "","helpLink": "","pages": "UserStoryCommit","endpoint": "","showAdvancedSection":false,"possibleRunningJob": ",MetadataDependenciesJob,{!userStoryId},true"},{"operationType": "GitCommit","operationLabel": "","showGrid": false,"gridMetadataTypes": "","showCommitMessage": false,"helpText": "Git Commit help","helpLink": "","pages": "UserStoryCommit","endpoint": "","showAdvancedSection":false,"possibleRunningJob": ",GitCommit,{!snapshotId},true"}]';
            MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', mockResponse, null);
            Test.setMock(HttpCalloutMock.class, fakeResponse);
            GitCommit_MainPageController controller = new GitCommit_MainPageController();

            System.assertEquals(0, controller.pageMessagesMap.size());
            System.assertNotEquals(null, controller.pageMessagesMap);
            System.assertEquals(4, controller.operationsMap.size());
            System.assertEquals(1, controller.snapshotList.size());
            System.assertEquals(tu.item('User_Story__c', 0).Id, controller.userStory.Id);

            GitCommit_HeaderController headerController = new GitCommit_HeaderController();
            headerController.pageController = controller;
            User_Story__c us = [SELECT Id, Name, User_Story_Title__c FROM User_Story__c WHERE Id = :tu.item('User_Story__c', 0).Id];
            String msg = headerController.commitMessage;
            List<SelectOption> options = headerController.availableOperationList;

            // Assertions
            String expectedMsg = us.Name + ': ' + us.User_Story_Title__c;
            Set<String> assertOptionValues = new Set<String>{
                'Commit Files',
                'Recommit Files',
                'Destructive Changes',
                'Full Profiles & Permission Sets'
            };
            Set<String> optionValues = new Set<String>();
            for (SelectOption optionsSel : options) {
                optionValues.add(optionsSel.getValue());
            }
            System.assertEquals(4, options.size());
            System.assertEquals(expectedMsg, msg);
            System.assertEquals(assertOptionValues, optionValues);
            //

            GitCommit_GridController gridController = new GitCommit_GridController();
            gridController.pageController = controller;
            String opName = gridController.operationName;
            System.assertEquals('', opName);
            Boolean startPoller = gridController.startActionPoller;
            System.assertEquals(false, startPoller);
            Boolean showRefreshPromtButton = gridController.showRefreshCachePromtButton;
            System.assertEquals(false, showRefreshPromtButton);
            Boolean refreshSucceeded = gridController.isRefreshCacheSucceeded;
            System.assertEquals(false, refreshSucceeded);

            // Click on "Advance" button.
            String baseBranch = 'dev1';
            GitCommit_AdvancedController advancedController = new GitCommit_AdvancedController();
            advancedController.pageController = controller;
            pReference.getParameters().put('branchName', baseBranch);
            advancedController.updateUserStoryBaseBranch();

            String assertBaseBranch = [SELECT Id, Base_Branch__c FROM User_Story__c WHERE Id = :us.Id].Base_Branch__c;
            System.assertEquals(baseBranch, assertBaseBranch);

            Test.stopTest();
        }
    }

    /**
     * Open the new git commit page from snapshot, commit changes
     */
    @IsTest
    private static void gitCommitPageSnapshotCommit() {
        User u = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(u.Username), true, true, true, true, true);

        System.runAs(u) {
            // Create current sprint record
            tu.insertSObject(
                'Sprint__c',
                new Map<String, Object>{ 'Name' => 'Sprint 2', 'Start_Date__c' => Date.today().addDays(-8), 'End_Date__c' => Date.today().addDays(8) }
            );

            // Create environments record
            tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'Dev1', 'org_id__c' => 'SFDC_OrgId' });
            tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'Dev2', 'org_id__c' => 'SFDC_OrgId2' });
            tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'Int', 'org_id__c' => 'SFDC_OrgId3' });
            tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'UAT', 'org_id__c' => 'SFDC_OrgId4' });
            tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'Prod', 'org_id__c' => 'SFDC_OrgId5' });
            insert new List<SObject>{
                tu.item('Environment__c', 0),
                tu.item('Environment__c', 1),
                tu.item('Environment__c', 2),
                tu.item('Environment__c', 3),
                tu.item('Environment__c', 4)
            };

            // Create org credentials record
            tu.createSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'OrgDev1',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 0).Id
                }
            );
            tu.createSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'OrgDev2',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId2',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 1).Id
                }
            );
            tu.createSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'OrgInt',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId3',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Default_Credential__c' => true,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 2).Id
                }
            );
            tu.createSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'OrgUAT',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId4',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 3).Id
                }
            );
            tu.createSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'OrgProd',
                    'Org_Type__c' => 'Production',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId5',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Test_Frequency__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 4).Id
                }
            );
            insert new List<SObject>{ tu.item('Org__c', 0), tu.item('Org__c', 1), tu.item('Org__c', 2), tu.item('Org__c', 3), tu.item('Org__c', 4) };

            // Create 1 git repository
            tu.insertSObjects('Git_Repository__c', 1, new Map<String, Object>{ 'Name' => 'test', 'URI__c' => 'http://www.test.uri' });

            // Create deployment flow record
            tu.insertSObject(
                'Deployment_Flow__c',
                new Map<String, Object>{ 'Name' => 'Deployment Flow', 'Active__c' => true, 'Git_Repository__c' => tu.item('Git_Repository__c', 0).Id }
            );

            // Create deployment flow steps record
            tu.createSObject(
                'Deployment_Flow_Step__c',
                new Map<String, Object>{
                    'Source_Environment__c' => tu.item('Environment__c', 0).Id,
                    'Destination_Environment__c' => tu.item('Environment__c', 2).Id,
                    'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id
                }
            );
            tu.createSObject(
                'Deployment_Flow_Step__c',
                new Map<String, Object>{
                    'Source_Environment__c' => tu.item('Environment__c', 1).Id,
                    'Destination_Environment__c' => tu.item('Environment__c', 2).Id,
                    'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id
                }
            );
            tu.createSObject(
                'Deployment_Flow_Step__c',
                new Map<String, Object>{
                    'Source_Environment__c' => tu.item('Environment__c', 2).Id,
                    'Destination_Environment__c' => tu.item('Environment__c', 3).Id,
                    'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id
                }
            );
            tu.createSObject(
                'Deployment_Flow_Step__c',
                new Map<String, Object>{
                    'Source_Environment__c' => tu.item('Environment__c', 3).Id,
                    'Destination_Environment__c' => tu.item('Environment__c', 4).Id,
                    'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id
                }
            );
            insert new List<SObject>{
                tu.item('Deployment_Flow_Step__c', 0),
                tu.item('Deployment_Flow_Step__c', 1),
                tu.item('Deployment_Flow_Step__c', 2),
                tu.item('Deployment_Flow_Step__c', 3)
            };

            // Create 1 git backup
            tu.insertSObjects(
                'Git_Backup__c',
                1,
                new Map<String, Object>{
                    'Name' => 'backupname',
                    'Branch__c' => 'branchName',
                    'Frequency__c' => null,
                    'Git_Repository__c' => tu.item('Git_Repository__c', 0).Id,
                    'Org__c' => tu.item('Org__c', 0).Id
                }
            );

            Test.startTest();
            PageReference pReference = Page.GitCommitMain;
            pReference.getParameters().put('snapshotId', tu.item('Git_Backup__c', 0).Id);
            pReference.getParameters().put('variant', 'GitSnapshotCommit');
            Test.setCurrentPage(pReference);

            String mockResponse = '[{"operationType": "GitDeletion","operationLabel": "Destructive Changes","operationButtonLabel": "Commit Destructive Changes","attachmentName": "Git Deletion","operationFormElements": [{"label": "Org Credential","name": "orgId","type": "orgLookup","helpText": "If changed, the metadata grid will reload with the metadata items of the selected Org Credential."}],"showGrid": true,"editGrid": true,"reloadGridData": true,"showCommitMessage": true,"helpText": "When deleting components, a table appears with a list of User Story Commits with status \'Complete\'. Select the commits you would like to undo and click Undo Commits. When the operation is finished, the status of the selected User Story Commits will be updated to \'Commit Undone\'.","helpLink": "https://docs.copado.com/git-operations/destructive-changes","pages": "GitSnapshotCommit,UserStoryCommit","endpoint": "commit","showAdvancedSection":true,"possibleRunningJob":",GitDeletion,{!snapshotId},true"},{"operationType": "FullProfilePermissionSets","operationLabel": "Full Profiles & Permission Sets","showGrid": true,"gridMetadataTypes": "Profile,PermissionSet","showCommitMessage": true,"helpText": "","helpLink": "https://docs.copado.com/git-operations/commit-full-profiles-and-permission-sets","pages": "GitSnapshotCommit,UserStoryCommit","endpoint": "commit","showAdvancedSection":true,"possibleRunningJob":""},{"operationType": "VlocityDependencies","operationLabel": "","showGrid": false,"gridMetadataTypes": "","showCommitMessage": false,"helpText": "","helpLink": "","pages": "UserStoryCommit","endpoint": "","showAdvancedSection":false,"possibleRunningJob": ",MetadataDependenciesJob,{!userStoryId},true"},{"operationType": "GitCommit","operationLabel": "","showGrid": false,"gridMetadataTypes": "","showCommitMessage": false,"helpText": "Git Commit help","helpLink": "","pages": "UserStoryCommit","endpoint": "","showAdvancedSection":false,"possibleRunningJob": ",GitCommit,{!snapshotId},true"}]';
            MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', mockResponse, null);
            Test.setMock(HttpCalloutMock.class, fakeResponse);
            GitCommit_MainPageController controller = new GitCommit_MainPageController();
            System.assertEquals(0, controller.pageMessagesMap.size());
            System.assertNotEquals(null, controller.pageMessagesMap);
            System.assertEquals(3, controller.operationsMap.size());
            System.assertEquals(1, controller.snapshotList.size());
            System.assertEquals(tu.item('Git_Backup__c', 0).Id, controller.snapshot.Id);

            GitCommit_HeaderController headerController = new GitCommit_HeaderController();
            headerController.pageController = controller;
            String msg = headerController.commitMessage;
            System.assertEquals('', msg);
            List<SelectOption> options = headerController.availableOperationList;
            System.assertEquals(3, options.size());
            headerController.commitMessage = 'test';

            headerController.deleteMetadataIndex();
            String commitId = GitCommit_HeaderController.createGitOrgCommit(
                'test',
                tu.item('Org__c', 0).Id,
                tu.item('Git_Backup__c', 0).Id,
                'Commit Files'
            );
            System.assertNotEquals(null, commitId);

            pReference.getParameters().put('commitId', commitId);
            PageReference redirectedPage = headerController.goToWaitingForPage();

            PageReference waitingForPage = Page.SnapshotWaitingFor;
            waitingForPage.getParameters().put('id', tu.item('Git_Backup__c', 0).Id);
            waitingForPage.getParameters().put('type', 'co_commitChanges');
            waitingForPage.getParameters().put('ep', headerController.pageController.operationItem.endpoint);
            waitingForPage.getParameters().put('cType', headerController.pageController.operationItem.operationLabel);
            waitingForPage.getParameters().put('cId', commitId);
            System.assertEquals(waitingForPage.getUrl(), redirectedPage.getUrl());

            Test.stopTest();
        }
    }

    /**
     * Open the new git commit page from snapshot, cancel commit
     */
    @IsTest
    private static void gitCommitPageSnapshotCommitCancel() {
        User u = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(u.Username), true, true, true, true, true);

        System.runAs(u) {
            // Create current sprint record
            tu.insertSObject(
                'Sprint__c',
                new Map<String, Object>{ 'Name' => 'Sprint 2', 'Start_Date__c' => Date.today().addDays(-8), 'End_Date__c' => Date.today().addDays(8) }
            );

            // Create environments record
            tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'Dev1', 'org_id__c' => 'SFDC_OrgId' });
            tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'Dev2', 'org_id__c' => 'SFDC_OrgId2' });
            tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'Int', 'org_id__c' => 'SFDC_OrgId3' });
            tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'UAT', 'org_id__c' => 'SFDC_OrgId4' });
            tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'Prod', 'org_id__c' => 'SFDC_OrgId5' });
            insert new List<SObject>{
                tu.item('Environment__c', 0),
                tu.item('Environment__c', 1),
                tu.item('Environment__c', 2),
                tu.item('Environment__c', 3),
                tu.item('Environment__c', 4)
            };

            // Create org credentials record
            tu.createSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'OrgDev1',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 0).Id
                }
            );
            tu.createSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'OrgDev2',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId2',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 1).Id
                }
            );
            tu.createSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'OrgInt',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId3',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Default_Credential__c' => true,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 2).Id
                }
            );
            tu.createSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'OrgUAT',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId4',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 3).Id
                }
            );
            tu.createSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'OrgProd',
                    'Org_Type__c' => 'Production',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId5',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Test_Frequency__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 4).Id
                }
            );
            insert new List<SObject>{ tu.item('Org__c', 0), tu.item('Org__c', 1), tu.item('Org__c', 2), tu.item('Org__c', 3), tu.item('Org__c', 4) };

            // Create 1 git repository
            tu.insertSObjects('Git_Repository__c', 1, new Map<String, Object>{ 'Name' => 'test', 'URI__c' => 'http://www.test.uri' });

            // Create deployment flow record
            tu.insertSObject(
                'Deployment_Flow__c',
                new Map<String, Object>{ 'Name' => 'Deployment Flow', 'Active__c' => true, 'Git_Repository__c' => tu.item('Git_Repository__c', 0).Id }
            );

            // Create deployment flow steps record
            tu.createSObject(
                'Deployment_Flow_Step__c',
                new Map<String, Object>{
                    'Source_Environment__c' => tu.item('Environment__c', 0).Id,
                    'Destination_Environment__c' => tu.item('Environment__c', 2).Id,
                    'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id
                }
            );
            tu.createSObject(
                'Deployment_Flow_Step__c',
                new Map<String, Object>{
                    'Source_Environment__c' => tu.item('Environment__c', 1).Id,
                    'Destination_Environment__c' => tu.item('Environment__c', 2).Id,
                    'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id
                }
            );
            tu.createSObject(
                'Deployment_Flow_Step__c',
                new Map<String, Object>{
                    'Source_Environment__c' => tu.item('Environment__c', 2).Id,
                    'Destination_Environment__c' => tu.item('Environment__c', 3).Id,
                    'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id
                }
            );
            tu.createSObject(
                'Deployment_Flow_Step__c',
                new Map<String, Object>{
                    'Source_Environment__c' => tu.item('Environment__c', 3).Id,
                    'Destination_Environment__c' => tu.item('Environment__c', 4).Id,
                    'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id
                }
            );
            insert new List<SObject>{
                tu.item('Deployment_Flow_Step__c', 0),
                tu.item('Deployment_Flow_Step__c', 1),
                tu.item('Deployment_Flow_Step__c', 2),
                tu.item('Deployment_Flow_Step__c', 3)
            };

            // Create 1 git backup
            tu.insertSObjects(
                'Git_Backup__c',
                1,
                new Map<String, Object>{
                    'Name' => 'backupname',
                    'Branch__c' => 'branchName',
                    'Frequency__c' => null,
                    'Git_Repository__c' => tu.item('Git_Repository__c', 0).Id,
                    'Org__c' => tu.item('Org__c', 0).Id
                }
            );

            Test.startTest();
            PageReference pReference = Page.GitCommitMain;
            pReference.getParameters().put('snapshotId', tu.item('Git_Backup__c', 0).Id);
            pReference.getParameters().put('variant', 'GitSnapshotCommit');
            Test.setCurrentPage(pReference);

            String mockResponse = '[{"operationType": "GitDeletion","operationLabel": "Destructive Changes","operationButtonLabel": "Commit Destructive Changes","attachmentName": "Git Deletion","operationFormElements": [{"label": "Org Credential","name": "orgId","type": "orgLookup","helpText": "If changed, the metadata grid will reload with the metadata items of the selected Org Credential."}],"showGrid": true,"editGrid": true,"reloadGridData": true,"showCommitMessage": true,"helpText": "When deleting components, a table appears with a list of User Story Commits with status \'Complete\'. Select the commits you would like to undo and click Undo Commits. When the operation is finished, the status of the selected User Story Commits will be updated to \'Commit Undone\'.","helpLink": "https://docs.copado.com/git-operations/destructive-changes","pages": "GitSnapshotCommit,UserStoryCommit","endpoint": "commit","showAdvancedSection":true,"possibleRunningJob":",GitDeletion,{!snapshotId},true"},{"operationType": "FullProfilePermissionSets","operationLabel": "Full Profiles & Permission Sets","showGrid": true,"gridMetadataTypes": "Profile,PermissionSet","showCommitMessage": true,"helpText": "","helpLink": "https://docs.copado.com/git-operations/commit-full-profiles-and-permission-sets","pages": "GitSnapshotCommit,UserStoryCommit","endpoint": "commit","showAdvancedSection":true,"possibleRunningJob":""},{"operationType": "VlocityDependencies","operationLabel": "","showGrid": false,"gridMetadataTypes": "","showCommitMessage": false,"helpText": "","helpLink": "","pages": "UserStoryCommit","endpoint": "","showAdvancedSection":false,"possibleRunningJob": ",MetadataDependenciesJob,{!userStoryId},true"},{"operationType": "GitCommit","operationLabel": "","showGrid": false,"gridMetadataTypes": "","showCommitMessage": false,"helpText": "Git Commit help","helpLink": "","pages": "UserStoryCommit","endpoint": "","showAdvancedSection":false,"possibleRunningJob": ",GitCommit,{!snapshotId},true"}]';
            MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', mockResponse, null);
            Test.setMock(HttpCalloutMock.class, fakeResponse);
            GitCommit_MainPageController controller = new GitCommit_MainPageController();
            System.assertEquals(0, controller.pageMessagesMap.size());
            System.assertNotEquals(null, controller.pageMessagesMap);
            System.assertEquals(3, controller.operationsMap.size());
            System.assertEquals(1, controller.snapshotList.size());
            System.assertEquals(tu.item('Git_Backup__c', 0).Id, controller.snapshot.Id);

            GitCommit_HeaderController headerController = new GitCommit_HeaderController();
            headerController.pageController = controller;
            String msg = headerController.commitMessage;
            System.assertEquals('', msg);
            List<SelectOption> options = headerController.availableOperationList;
            System.assertEquals(3, options.size());
            controller.returnToRecord();
            Test.stopTest();
        }
    }

    /**
     * Open the new git commit page from dx, commit changes
     */
    @IsTest
    private static void gitCommitPageDXCommit() {
        User u = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(u.Username), true, true, true, true, true);

        System.runAs(u) {
            // Create current sprint record
            tu.insertSObject(
                'Sprint__c',
                new Map<String, Object>{ 'Name' => 'Sprint 2', 'Start_Date__c' => Date.today().addDays(-8), 'End_Date__c' => Date.today().addDays(8) }
            );

            // Create environments record
            tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'Dev1', 'org_id__c' => 'SFDC_OrgId' });
            tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'Dev2', 'org_id__c' => 'SFDC_OrgId2' });
            tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'Int', 'org_id__c' => 'SFDC_OrgId3' });
            tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'UAT', 'org_id__c' => 'SFDC_OrgId4' });
            tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'Prod', 'org_id__c' => 'SFDC_OrgId5' });
            insert new List<SObject>{
                tu.item('Environment__c', 0),
                tu.item('Environment__c', 1),
                tu.item('Environment__c', 2),
                tu.item('Environment__c', 3),
                tu.item('Environment__c', 4)
            };

            // Create org credentials record
            tu.createSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'OrgDev1',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 0).Id
                }
            );
            tu.createSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'OrgDev2',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId2',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 1).Id
                }
            );
            tu.createSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'OrgInt',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId3',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Default_Credential__c' => true,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 2).Id
                }
            );
            tu.createSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'OrgUAT',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId4',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 3).Id
                }
            );
            tu.createSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'OrgProd',
                    'Org_Type__c' => 'Production',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId5',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Test_Frequency__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 4).Id
                }
            );
            insert new List<SObject>{ tu.item('Org__c', 0), tu.item('Org__c', 1), tu.item('Org__c', 2), tu.item('Org__c', 3), tu.item('Org__c', 4) };

            // Create 1 git repository
            tu.insertSObjects('Git_Repository__c', 1, new Map<String, Object>{ 'Name' => 'test', 'URI__c' => 'http://www.test.uri' });

            // Create deployment flow record
            tu.insertSObject(
                'Deployment_Flow__c',
                new Map<String, Object>{
                    'Name' => 'Deployment Flow',
                    'Active__c' => true,
                    'Git_Repository__c' => tu.item('Git_Repository__c', 0).Id,
                    'Enable_Copado_DX__c' => true
                }
            );

            // Create deployment flow steps record
            tu.createSObject(
                'Deployment_Flow_Step__c',
                new Map<String, Object>{
                    'Source_Environment__c' => tu.item('Environment__c', 0).Id,
                    'Destination_Environment__c' => tu.item('Environment__c', 2).Id,
                    'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id,
                    'Enable_as_Scratch_Org_Destination__c' => 'Default DX Target'
                }
            );
            tu.createSObject(
                'Deployment_Flow_Step__c',
                new Map<String, Object>{
                    'Source_Environment__c' => tu.item('Environment__c', 1).Id,
                    'Destination_Environment__c' => tu.item('Environment__c', 2).Id,
                    'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id
                }
            );
            tu.createSObject(
                'Deployment_Flow_Step__c',
                new Map<String, Object>{
                    'Source_Environment__c' => tu.item('Environment__c', 2).Id,
                    'Destination_Environment__c' => tu.item('Environment__c', 3).Id,
                    'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id
                }
            );
            tu.createSObject(
                'Deployment_Flow_Step__c',
                new Map<String, Object>{
                    'Source_Environment__c' => tu.item('Environment__c', 3).Id,
                    'Destination_Environment__c' => tu.item('Environment__c', 4).Id,
                    'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id
                }
            );
            insert new List<SObject>{
                tu.item('Deployment_Flow_Step__c', 0),
                tu.item('Deployment_Flow_Step__c', 1),
                tu.item('Deployment_Flow_Step__c', 2),
                tu.item('Deployment_Flow_Step__c', 3)
            };

            // Create project record
            tu.insertSObject(
                'Project__c',
                new Map<String, Object>{
                    'Name' => 'My project',
                    'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id,
                    'Index_Metadata__c' => false
                }
            );

            // Create 3 user story to fill sobjectlist
            tu.insertSObjects(
                'User_Story__c',
                3,
                new Map<String, Object>{
                    'User_Story_Title__c' => 'us-0000000',
                    'Status__c' => 'Approved',
                    'Sprint__c' => tu.item('Sprint__c', 0).Id,
                    'Project__c' => tu.item('Project__c', 0).Id,
                    'Environment__c' => tu.item('Environment__c', 0).Id,
                    'Org_Credential__c' => tu.item('Org__c', 0).Id
                }
            );

            // Create 1 git backup
            tu.insertSObjects(
                'Git_Backup__c',
                1,
                new Map<String, Object>{
                    'Name' => 'backupname',
                    'Branch__c' => 'branchName',
                    'Frequency__c' => null,
                    'Git_Repository__c' => tu.item('Git_Repository__c', 0).Id,
                    'Org__c' => tu.item('Org__c', 0).Id
                }
            );

            Test.startTest();
            PageReference pReference = Page.GitCommitMain;
            pReference.getParameters().put('userStoryId', tu.item('User_Story__c', 0).Id);
            pReference.getParameters().put('variant', 'dxCommit');
            Test.setCurrentPage(pReference);

            String mockResponse = '[{"operationType": "RecommitFiles","operationLabel": "Recommit Files","showGrid": true,"showUserStorySelections": true,"showCommitMessage": true,"operationFormElements": [{"label": "Re-Create Feature Branch","name": "recreateFeatureBranch","value": "","type": "checkbox","helpText": "If checked, the existing feature branch will be deleted and the selected components in the grid will be committed in a new feature branch. Previous commits will not be present in the new feature branch. WARNING: Profiles and Permission Sets committed as full in this User Story will be recommitted as in the Commit Files operation. If you want them to be recommitted as full, you need to commit them again using the Full Profiles & Permission Sets git operation."}],"helpText": "When recommitting files, the metadata grid appears with the existing user story selections. You can uncheck the selected components and also select new ones.","helpLink": "https://docs.copado.com/git-operations/recommit-files","pages": "UserStoryCommit","endpoint": "commit","showAdvancedSection":true,"possibleRunningJob":""},{"operationType": "GitDeletion","operationLabel": "Destructive Changes","operationButtonLabel": "Commit Destructive Changes","attachmentName": "Git Deletion","operationFormElements": [{"label": "Org Credential","name": "orgId","type": "orgLookup","helpText": "If changed, the metadata grid will reload with the metadata items of the selected Org Credential."}],"showGrid": true,"editGrid": true,"reloadGridData": true,"showCommitMessage": true,"helpText": "When deleting components, a table appears with a list of User Story Commits with status \'Complete\'. Select the commits you would like to undo and click Undo Commits. When the operation is finished, the status of the selected User Story Commits will be updated to \'Commit Undone\'.","helpLink": "https://docs.copado.com/git-operations/destructive-changes","pages": "GitSnapshotCommit,UserStoryCommit","endpoint": "commit","showAdvancedSection":true,"possibleRunningJob":",GitDeletion,{!snapshotId},true"},{"operationType": "FullProfilePermissionSets","operationLabel": "Full Profiles & Permission Sets","showGrid": true,"gridMetadataTypes": "Profile,PermissionSet","showCommitMessage": true,"helpText": "","helpLink": "https://docs.copado.com/git-operations/commit-full-profiles-and-permission-sets","pages": "GitSnapshotCommit,UserStoryCommit","endpoint": "commit","showAdvancedSection":true,"possibleRunningJob":""},{"operationType": "VlocityDependencies","operationLabel": "","showGrid": false,"gridMetadataTypes": "","showCommitMessage": false,"helpText": "","helpLink": "","pages": "UserStoryCommit","endpoint": "","showAdvancedSection":false,"possibleRunningJob": ",MetadataDependenciesJob,{!userStoryId},true"},{"operationType": "GitCommit","operationLabel": "","showGrid": false,"gridMetadataTypes": "","showCommitMessage": false,"helpText": "Git Commit help","helpLink": "","pages": "UserStoryCommit","endpoint": "","showAdvancedSection":false,"possibleRunningJob": ",GitCommit,{!snapshotId},true"}]';
            MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', mockResponse, null);
            Test.setMock(HttpCalloutMock.class, fakeResponse);
            GitCommit_MainPageController controller = new GitCommit_MainPageController();
            System.assertEquals(0, controller.pageMessagesMap.size());
            System.assertNotEquals(null, controller.pageMessagesMap);
            System.assertEquals(4, controller.operationsMap.size());
            System.assertEquals(1, controller.snapshotList.size());
            System.assertEquals(tu.item('User_Story__c', 0).Id, controller.userStory.Id);

            GitCommit_GridController gridController = new GitCommit_GridController();
            gridController.pageController = controller;
            String artifactId = gridController.artifactsParentOrgId;
            System.assertNotEquals(null, artifactId);

            GitCommit_HeaderController headerController = new GitCommit_HeaderController();
            headerController.pageController = controller;
            User_Story__c us = [SELECT Name, User_Story_Title__c FROM User_Story__c WHERE Id = :tu.item('User_Story__c', 0).Id];
            String msg = headerController.commitMessage;
            String expectedMsg = us.Name + ': ' + us.User_Story_Title__c;
            System.assertEquals(expectedMsg, msg);
            List<SelectOption> options = headerController.availableOperationList;
            System.assertEquals(4, options.size());

            headerController.deleteMetadataIndex();
            String commitId = GitCommit_HeaderController.createGitOrgCommit(
                'test',
                tu.item('Org__c', 0).Id,
                tu.item('Git_Backup__c', 0).Id,
                'Commit Files'
            );
            System.assertNotEquals(null, commitId);

            pReference.getParameters().put('commitId', commitId);
            PageReference redirectedPage = headerController.goToWaitingForPage();

            PageReference waitingForPage = Page.UserStoryPageWaitingFor;
            waitingForPage.getParameters().put('id', tu.item('User_Story__c', 0).Id);
            waitingForPage.getParameters().put('type', 'co_commitChanges');
            waitingForPage.getParameters().put('ep', headerController.pageController.operationItem.endpoint);
            waitingForPage.getParameters().put('sId', tu.item('Git_Backup__c', 0).Id);
            waitingForPage.getParameters().put('cType', headerController.pageController.operationItem.operationLabel);
            waitingForPage.getParameters().put('cId', commitId);
            System.assertEquals(waitingForPage.getUrl(), redirectedPage.getUrl());

            Test.stopTest();
        }
    }

    /**
     * Open the new git commit page from dx, cancel commit
     */
    @IsTest
    private static void gitCommitPageDXCommitCancel() {
        User u = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(u.Username), true, true, true, true, true);

        System.runAs(u) {
            // Create current sprint record
            tu.insertSObject(
                'Sprint__c',
                new Map<String, Object>{ 'Name' => 'Sprint 2', 'Start_Date__c' => Date.today().addDays(-8), 'End_Date__c' => Date.today().addDays(8) }
            );

            // Create environments record
            tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'Dev1', 'org_id__c' => 'SFDC_OrgId' });
            tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'Dev2', 'org_id__c' => 'SFDC_OrgId2' });
            tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'Int', 'org_id__c' => 'SFDC_OrgId3' });
            tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'UAT', 'org_id__c' => 'SFDC_OrgId4' });
            tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'Prod', 'org_id__c' => 'SFDC_OrgId5' });
            insert new List<SObject>{
                tu.item('Environment__c', 0),
                tu.item('Environment__c', 1),
                tu.item('Environment__c', 2),
                tu.item('Environment__c', 3),
                tu.item('Environment__c', 4)
            };

            // Create org credentials record
            tu.createSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'OrgDev1',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 0).Id
                }
            );
            tu.createSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'OrgDev2',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId2',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 1).Id
                }
            );
            tu.createSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'OrgInt',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId3',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Default_Credential__c' => true,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 2).Id
                }
            );
            tu.createSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'OrgUAT',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId4',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 3).Id
                }
            );
            tu.createSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'OrgProd',
                    'Org_Type__c' => 'Production',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId5',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Test_Frequency__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 4).Id
                }
            );
            insert new List<SObject>{ tu.item('Org__c', 0), tu.item('Org__c', 1), tu.item('Org__c', 2), tu.item('Org__c', 3), tu.item('Org__c', 4) };

            // Create 1 git repository
            tu.insertSObjects('Git_Repository__c', 1, new Map<String, Object>{ 'Name' => 'test', 'URI__c' => 'http://www.test.uri' });

            // Create deployment flow record
            tu.insertSObject(
                'Deployment_Flow__c',
                new Map<String, Object>{
                    'Name' => 'Deployment Flow',
                    'Active__c' => true,
                    'Git_Repository__c' => tu.item('Git_Repository__c', 0).Id,
                    'Enable_Copado_DX__c' => true
                }
            );

            // Create deployment flow steps record
            tu.createSObject(
                'Deployment_Flow_Step__c',
                new Map<String, Object>{
                    'Source_Environment__c' => tu.item('Environment__c', 0).Id,
                    'Destination_Environment__c' => tu.item('Environment__c', 2).Id,
                    'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id,
                    'Enable_as_Scratch_Org_Destination__c' => 'Default DX Target'
                }
            );
            tu.createSObject(
                'Deployment_Flow_Step__c',
                new Map<String, Object>{
                    'Source_Environment__c' => tu.item('Environment__c', 1).Id,
                    'Destination_Environment__c' => tu.item('Environment__c', 2).Id,
                    'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id
                }
            );
            tu.createSObject(
                'Deployment_Flow_Step__c',
                new Map<String, Object>{
                    'Source_Environment__c' => tu.item('Environment__c', 2).Id,
                    'Destination_Environment__c' => tu.item('Environment__c', 3).Id,
                    'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id
                }
            );
            tu.createSObject(
                'Deployment_Flow_Step__c',
                new Map<String, Object>{
                    'Source_Environment__c' => tu.item('Environment__c', 3).Id,
                    'Destination_Environment__c' => tu.item('Environment__c', 4).Id,
                    'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id
                }
            );
            insert new List<SObject>{
                tu.item('Deployment_Flow_Step__c', 0),
                tu.item('Deployment_Flow_Step__c', 1),
                tu.item('Deployment_Flow_Step__c', 2),
                tu.item('Deployment_Flow_Step__c', 3)
            };

            // Create project record
            tu.insertSObject(
                'Project__c',
                new Map<String, Object>{
                    'Name' => 'My project',
                    'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id,
                    'Index_Metadata__c' => false
                }
            );

            // Create 3 user story to fill sobjectlist
            tu.insertSObjects(
                'User_Story__c',
                3,
                new Map<String, Object>{
                    'User_Story_Title__c' => 'us-0000000',
                    'Status__c' => 'Approved',
                    'Sprint__c' => tu.item('Sprint__c', 0).Id,
                    'Project__c' => tu.item('Project__c', 0).Id,
                    'Environment__c' => tu.item('Environment__c', 0).Id,
                    'Org_Credential__c' => tu.item('Org__c', 0).Id
                }
            );

            // Create 1 git backup
            tu.insertSObjects(
                'Git_Backup__c',
                1,
                new Map<String, Object>{
                    'Name' => 'backupname',
                    'Branch__c' => 'branchName',
                    'Frequency__c' => null,
                    'Git_Repository__c' => tu.item('Git_Repository__c', 0).Id,
                    'Org__c' => tu.item('Org__c', 0).Id
                }
            );

            Test.startTest();
            PageReference pReference = Page.GitCommitMain;
            pReference.getParameters().put('userStoryId', tu.item('User_Story__c', 0).Id);
            pReference.getParameters().put('variant', 'dxCommit');
            Test.setCurrentPage(pReference);

            String mockResponse = '[{"operationType": "RecommitFiles","operationLabel": "Recommit Files","showGrid": true,"showUserStorySelections": true,"showCommitMessage": true,"operationFormElements": [{"label": "Re-Create Feature Branch","name": "recreateFeatureBranch","value": "","type": "checkbox","helpText": "If checked, the existing feature branch will be deleted and the selected components in the grid will be committed in a new feature branch. Previous commits will not be present in the new feature branch. WARNING: Profiles and Permission Sets committed as full in this User Story will be recommitted as in the Commit Files operation. If you want them to be recommitted as full, you need to commit them again using the Full Profiles & Permission Sets git operation."}],"helpText": "When recommitting files, the metadata grid appears with the existing user story selections. You can uncheck the selected components and also select new ones.","helpLink": "https://docs.copado.com/git-operations/recommit-files","pages": "UserStoryCommit","endpoint": "commit","showAdvancedSection":true,"possibleRunningJob":""},{"operationType": "GitDeletion","operationLabel": "Destructive Changes","operationButtonLabel": "Commit Destructive Changes","attachmentName": "Git Deletion","operationFormElements": [{"label": "Org Credential","name": "orgId","type": "orgLookup","helpText": "If changed, the metadata grid will reload with the metadata items of the selected Org Credential."}],"showGrid": true,"editGrid": true,"reloadGridData": true,"showCommitMessage": true,"helpText": "When deleting components, a table appears with a list of User Story Commits with status \'Complete\'. Select the commits you would like to undo and click Undo Commits. When the operation is finished, the status of the selected User Story Commits will be updated to \'Commit Undone\'.","helpLink": "https://docs.copado.com/git-operations/destructive-changes","pages": "GitSnapshotCommit,UserStoryCommit","endpoint": "commit","showAdvancedSection":true,"possibleRunningJob":",GitDeletion,{!snapshotId},true"},{"operationType": "FullProfilePermissionSets","operationLabel": "Full Profiles & Permission Sets","showGrid": true,"gridMetadataTypes": "Profile,PermissionSet","showCommitMessage": true,"helpText": "","helpLink": "https://docs.copado.com/git-operations/commit-full-profiles-and-permission-sets","pages": "GitSnapshotCommit,UserStoryCommit","endpoint": "commit","showAdvancedSection":true,"possibleRunningJob":""},{"operationType": "VlocityDependencies","operationLabel": "","showGrid": false,"gridMetadataTypes": "","showCommitMessage": false,"helpText": "","helpLink": "","pages": "UserStoryCommit","endpoint": "","showAdvancedSection":false,"possibleRunningJob": ",MetadataDependenciesJob,{!userStoryId},true"},{"operationType": "GitCommit","operationLabel": "","showGrid": false,"gridMetadataTypes": "","showCommitMessage": false,"helpText": "Git Commit help","helpLink": "","pages": "UserStoryCommit","endpoint": "","showAdvancedSection":false,"possibleRunningJob": ",GitCommit,{!snapshotId},true"}]';
            MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', mockResponse, null);
            Test.setMock(HttpCalloutMock.class, fakeResponse);
            GitCommit_MainPageController controller = new GitCommit_MainPageController();
            System.assertEquals(0, controller.pageMessagesMap.size());
            System.assertNotEquals(null, controller.pageMessagesMap);
            System.assertEquals(4, controller.operationsMap.size());
            System.assertEquals(1, controller.snapshotList.size());
            System.assertEquals(tu.item('User_Story__c', 0).Id, controller.userStory.Id);

            GitCommit_GridController gridController = new GitCommit_GridController();
            gridController.pageController = controller;
            String artifactId = gridController.artifactsParentOrgId;
            System.assertNotEquals(null, artifactId);

            GitCommit_HeaderController headerController = new GitCommit_HeaderController();
            headerController.pageController = controller;
            User_Story__c us = [SELECT Name, User_Story_Title__c FROM User_Story__c WHERE Id = :tu.item('User_Story__c', 0).Id];
            String msg = headerController.commitMessage;
            String expectedMsg = us.Name + ': ' + us.User_Story_Title__c;
            System.assertEquals(expectedMsg, msg);
            List<SelectOption> options = headerController.availableOperationList;
            System.assertEquals(4, options.size());
            controller.returnToRecord();

            Test.stopTest();
        }
    }

    /**
     * Open the new git commit page from dx, no branch, job fails
     */
    @IsTest
    private static void gitCommitPageDXNoBranchFailJob() {
        User u = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(u.Username), true, true, true, true, true);

        System.runAs(u) {
            // Create current sprint record
            tu.insertSObject(
                'Sprint__c',
                new Map<String, Object>{ 'Name' => 'Sprint 2', 'Start_Date__c' => Date.today().addDays(-8), 'End_Date__c' => Date.today().addDays(8) }
            );

            // Create environments record
            tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'Dev1', 'org_id__c' => 'SFDC_OrgId' });
            tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'Dev2', 'org_id__c' => 'SFDC_OrgId2' });
            tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'Int', 'org_id__c' => 'SFDC_OrgId3' });
            tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'UAT', 'org_id__c' => 'SFDC_OrgId4' });
            tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'Prod', 'org_id__c' => 'SFDC_OrgId5' });
            insert new List<SObject>{
                tu.item('Environment__c', 0),
                tu.item('Environment__c', 1),
                tu.item('Environment__c', 2),
                tu.item('Environment__c', 3),
                tu.item('Environment__c', 4)
            };

            // Create org credentials record
            tu.createSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'OrgDev1',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 0).Id
                }
            );
            tu.createSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'OrgDev2',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId2',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 1).Id
                }
            );
            tu.createSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'OrgInt',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId3',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Default_Credential__c' => true,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 2).Id
                }
            );
            tu.createSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'OrgUAT',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId4',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 3).Id
                }
            );
            tu.createSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'OrgProd',
                    'Org_Type__c' => 'Production',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId5',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Test_Frequency__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 4).Id
                }
            );
            insert new List<SObject>{ tu.item('Org__c', 0), tu.item('Org__c', 1), tu.item('Org__c', 2), tu.item('Org__c', 3), tu.item('Org__c', 4) };

            // Create 1 git repository
            tu.insertSObjects('Git_Repository__c', 1, new Map<String, Object>{ 'Name' => 'test', 'URI__c' => 'http://www.test.uri' });

            // Create deployment flow record
            tu.insertSObject(
                'Deployment_Flow__c',
                new Map<String, Object>{
                    'Name' => 'Deployment Flow',
                    'Active__c' => true,
                    'Git_Repository__c' => tu.item('Git_Repository__c', 0).Id,
                    'Enable_Copado_DX__c' => true
                }
            );

            // Create deployment flow steps record
            tu.createSObject(
                'Deployment_Flow_Step__c',
                new Map<String, Object>{
                    'Source_Environment__c' => tu.item('Environment__c', 0).Id,
                    'Destination_Environment__c' => tu.item('Environment__c', 2).Id,
                    'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id,
                    'Enable_as_Scratch_Org_Destination__c' => 'Default DX Target'
                }
            );
            tu.createSObject(
                'Deployment_Flow_Step__c',
                new Map<String, Object>{
                    'Source_Environment__c' => tu.item('Environment__c', 1).Id,
                    'Destination_Environment__c' => tu.item('Environment__c', 2).Id,
                    'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id
                }
            );
            tu.createSObject(
                'Deployment_Flow_Step__c',
                new Map<String, Object>{
                    'Source_Environment__c' => tu.item('Environment__c', 2).Id,
                    'Destination_Environment__c' => tu.item('Environment__c', 3).Id,
                    'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id
                }
            );
            tu.createSObject(
                'Deployment_Flow_Step__c',
                new Map<String, Object>{
                    'Source_Environment__c' => tu.item('Environment__c', 3).Id,
                    'Destination_Environment__c' => tu.item('Environment__c', 4).Id,
                    'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id
                }
            );
            insert new List<SObject>{
                tu.item('Deployment_Flow_Step__c', 0),
                tu.item('Deployment_Flow_Step__c', 1),
                tu.item('Deployment_Flow_Step__c', 2),
                tu.item('Deployment_Flow_Step__c', 3)
            };

            // Create project record
            tu.insertSObject(
                'Project__c',
                new Map<String, Object>{
                    'Name' => 'My project',
                    'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id,
                    'Index_Metadata__c' => false
                }
            );

            // Create 3 user story to fill sobjectlist
            tu.insertSObjects(
                'User_Story__c',
                3,
                new Map<String, Object>{
                    'User_Story_Title__c' => 'us-0000000',
                    'Status__c' => 'Approved',
                    'Sprint__c' => tu.item('Sprint__c', 0).Id,
                    'Project__c' => tu.item('Project__c', 0).Id,
                    'Environment__c' => tu.item('Environment__c', 0).Id,
                    'Org_Credential__c' => tu.item('Org__c', 0).Id
                }
            );

            // Create attachment for metadatasources
            tu.insertSObjects(
                'Attachment',
                3,
                new Map<String, Object>{
                    'Name' => DXLabel.METADATA_SOURCES,
                    'ParentId' => tu.item('Org__c', 0).Id,
                    'Body' => Blob.valueOf(
                        '{"selectedArtifactIDs":["a1K1n000005ZwwNEAS"],"repositoryId":"","metadataSourceType":"artifact","metadataSource":"a1K1n000005ZwwNEAS","isPatch":false,"projectBranchCreated":true}'
                    )
                }
            );

            Test.startTest();
            PageReference pReference = Page.GitCommitMain;
            pReference.getParameters().put('userStoryId', tu.item('User_Story__c', 0).Id);
            pReference.getParameters().put('variant', 'dxCommit');
            Test.setCurrentPage(pReference);

            String mockResponse = '[{"operationType": "RecommitFiles","operationLabel": "Recommit Files","showGrid": true,"showUserStorySelections": true,"showCommitMessage": true,"operationFormElements": [{"label": "Re-Create Feature Branch","name": "recreateFeatureBranch","value": "","type": "checkbox","helpText": "If checked, the existing feature branch will be deleted and the selected components in the grid will be committed in a new feature branch. Previous commits will not be present in the new feature branch. WARNING: Profiles and Permission Sets committed as full in this User Story will be recommitted as in the Commit Files operation. If you want them to be recommitted as full, you need to commit them again using the Full Profiles & Permission Sets git operation."}],"helpText": "When recommitting files, the metadata grid appears with the existing user story selections. You can uncheck the selected components and also select new ones.","helpLink": "https://docs.copado.com/git-operations/recommit-files","pages": "UserStoryCommit","endpoint": "commit","showAdvancedSection":true,"possibleRunningJob":""},{"operationType": "GitDeletion","operationLabel": "Destructive Changes","operationButtonLabel": "Commit Destructive Changes","attachmentName": "Git Deletion","operationFormElements": [{"label": "Org Credential","name": "orgId","type": "orgLookup","helpText": "If changed, the metadata grid will reload with the metadata items of the selected Org Credential."}],"showGrid": true,"editGrid": true,"reloadGridData": true,"showCommitMessage": true,"helpText": "When deleting components, a table appears with a list of User Story Commits with status \'Complete\'. Select the commits you would like to undo and click Undo Commits. When the operation is finished, the status of the selected User Story Commits will be updated to \'Commit Undone\'.","helpLink": "https://docs.copado.com/git-operations/destructive-changes","pages": "GitSnapshotCommit,UserStoryCommit","endpoint": "commit","showAdvancedSection":true,"possibleRunningJob":",GitDeletion,{!snapshotId},true"},{"operationType": "FullProfilePermissionSets","operationLabel": "Full Profiles & Permission Sets","showGrid": true,"gridMetadataTypes": "Profile,PermissionSet","showCommitMessage": true,"helpText": "","helpLink": "https://docs.copado.com/git-operations/commit-full-profiles-and-permission-sets","pages": "GitSnapshotCommit,UserStoryCommit","endpoint": "commit","showAdvancedSection":true,"possibleRunningJob":""},{"operationType": "VlocityDependencies","operationLabel": "","showGrid": false,"gridMetadataTypes": "","showCommitMessage": false,"helpText": "","helpLink": "","pages": "UserStoryCommit","endpoint": "","showAdvancedSection":false,"possibleRunningJob": ",MetadataDependenciesJob,{!userStoryId},true"},{"operationType": "GitCommit","operationLabel": "","showGrid": false,"gridMetadataTypes": "","showCommitMessage": false,"helpText": "Git Commit help","helpLink": "","pages": "UserStoryCommit","endpoint": "","showAdvancedSection":false,"possibleRunningJob": ",GitCommit,{!snapshotId},true"}]';
            MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', mockResponse, null);
            Test.setMock(HttpCalloutMock.class, fakeResponse);
            GitCommit_MainPageController controller = new GitCommit_MainPageController();
            System.assertEquals(0, controller.pageMessagesMap.size());
            System.assertNotEquals(null, controller.pageMessagesMap);
            System.assertEquals(4, controller.operationsMap.size());
            System.assertEquals(0, controller.snapshotList.size());
            System.assertEquals(tu.item('User_Story__c', 0).Id, controller.userStory.Id);
            System.assertEquals(true, controller.showCreateDXBranchPrompt);

            GitCommit_IntermediaryController intermediaryController = new GitCommit_IntermediaryController();
            intermediaryController.pageController = controller;
            Boolean dxJobStarted = intermediaryController.dxBranchJobStarted;
            System.assertEquals(false, dxJobStarted);
            Map<String, Set<Object>> componentMessagesMap = intermediaryController.componentMessagesMap;
            System.assertEquals(0, componentMessagesMap.size());

            intermediaryController.createDXBranch();
            Integer messageCount = intermediaryController.getComponentMessageSize();
            System.assertEquals(1, messageCount);
            for (String severity : intermediaryController.componentMessagesMap.keySet()) {
                System.assertEquals('error', severity);
                for (Object obj : intermediaryController.componentMessagesMap.get(severity)) {
                    System.assertEquals('Malformed JSON: Expected \'{\' at the beginning of object', obj);
                }
            }

            Test.stopTest();
        }
    }

    /**
     * Open the new git commit page from dx, no branch, notification returned success
     */
    @IsTest
    private static void gitCommitPageDXNoBranchNotificationSuccess() {
        User u = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(u.Username), true, true, true, true, true);

        System.runAs(u) {
            // Create current sprint record
            tu.insertSObject(
                'Sprint__c',
                new Map<String, Object>{ 'Name' => 'Sprint 2', 'Start_Date__c' => Date.today().addDays(-8), 'End_Date__c' => Date.today().addDays(8) }
            );

            // Create environments record
            tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'Dev1', 'org_id__c' => 'SFDC_OrgId' });
            tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'Dev2', 'org_id__c' => 'SFDC_OrgId2' });
            tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'Int', 'org_id__c' => 'SFDC_OrgId3' });
            tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'UAT', 'org_id__c' => 'SFDC_OrgId4' });
            tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'Prod', 'org_id__c' => 'SFDC_OrgId5' });
            insert new List<SObject>{
                tu.item('Environment__c', 0),
                tu.item('Environment__c', 1),
                tu.item('Environment__c', 2),
                tu.item('Environment__c', 3),
                tu.item('Environment__c', 4)
            };

            // Create org credentials record
            tu.createSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'OrgDev1',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 0).Id
                }
            );
            tu.createSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'OrgDev2',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId2',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 1).Id
                }
            );
            tu.createSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'OrgInt',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId3',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Default_Credential__c' => true,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 2).Id
                }
            );
            tu.createSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'OrgUAT',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId4',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 3).Id
                }
            );
            tu.createSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'OrgProd',
                    'Org_Type__c' => 'Production',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId5',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Test_Frequency__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 4).Id
                }
            );
            insert new List<SObject>{ tu.item('Org__c', 0), tu.item('Org__c', 1), tu.item('Org__c', 2), tu.item('Org__c', 3), tu.item('Org__c', 4) };

            // Create 1 git repository
            tu.insertSObjects('Git_Repository__c', 1, new Map<String, Object>{ 'Name' => 'test', 'URI__c' => 'http://www.test.uri' });

            // Create deployment flow record
            tu.insertSObject(
                'Deployment_Flow__c',
                new Map<String, Object>{
                    'Name' => 'Deployment Flow',
                    'Active__c' => true,
                    'Git_Repository__c' => tu.item('Git_Repository__c', 0).Id,
                    'Enable_Copado_DX__c' => true
                }
            );

            // Create deployment flow steps record
            tu.createSObject(
                'Deployment_Flow_Step__c',
                new Map<String, Object>{
                    'Source_Environment__c' => tu.item('Environment__c', 0).Id,
                    'Destination_Environment__c' => tu.item('Environment__c', 2).Id,
                    'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id,
                    'Enable_as_Scratch_Org_Destination__c' => 'Default DX Target'
                }
            );
            tu.createSObject(
                'Deployment_Flow_Step__c',
                new Map<String, Object>{
                    'Source_Environment__c' => tu.item('Environment__c', 1).Id,
                    'Destination_Environment__c' => tu.item('Environment__c', 2).Id,
                    'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id
                }
            );
            tu.createSObject(
                'Deployment_Flow_Step__c',
                new Map<String, Object>{
                    'Source_Environment__c' => tu.item('Environment__c', 2).Id,
                    'Destination_Environment__c' => tu.item('Environment__c', 3).Id,
                    'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id
                }
            );
            tu.createSObject(
                'Deployment_Flow_Step__c',
                new Map<String, Object>{
                    'Source_Environment__c' => tu.item('Environment__c', 3).Id,
                    'Destination_Environment__c' => tu.item('Environment__c', 4).Id,
                    'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id
                }
            );
            insert new List<SObject>{
                tu.item('Deployment_Flow_Step__c', 0),
                tu.item('Deployment_Flow_Step__c', 1),
                tu.item('Deployment_Flow_Step__c', 2),
                tu.item('Deployment_Flow_Step__c', 3)
            };

            // Create project record
            tu.insertSObject(
                'Project__c',
                new Map<String, Object>{
                    'Name' => 'My project',
                    'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id,
                    'Index_Metadata__c' => false
                }
            );

            // Create 3 user story to fill sobjectlist
            tu.insertSObjects(
                'User_Story__c',
                3,
                new Map<String, Object>{
                    'User_Story_Title__c' => 'us-0000000',
                    'Status__c' => 'Approved',
                    'Sprint__c' => tu.item('Sprint__c', 0).Id,
                    'Project__c' => tu.item('Project__c', 0).Id,
                    'Environment__c' => tu.item('Environment__c', 0).Id,
                    'Org_Credential__c' => tu.item('Org__c', 0).Id
                }
            );

            // Create attachment for metadatasources
            tu.insertSObjects(
                'Attachment',
                3,
                new Map<String, Object>{
                    'Name' => DXLabel.METADATA_SOURCES,
                    'ParentId' => tu.item('Org__c', 0).Id,
                    'Body' => Blob.valueOf(
                        '{"selectedArtifactIDs":["a1K1n000005ZwwNEAS"],"repositoryId":"","metadataSourceType":"artifact","metadataSource":"a1K1n000005ZwwNEAS","isPatch":false,"projectBranchCreated":true}'
                    )
                }
            );

            Test.startTest();
            PageReference pReference = Page.GitCommitMain;
            pReference.getParameters().put('userStoryId', tu.item('User_Story__c', 0).Id);
            pReference.getParameters().put('variant', 'dxCommit');
            Test.setCurrentPage(pReference);

            String mockResponse = '[{"operationType": "RecommitFiles","operationLabel": "Recommit Files","showGrid": true,"showUserStorySelections": true,"showCommitMessage": true,"operationFormElements": [{"label": "Re-Create Feature Branch","name": "recreateFeatureBranch","value": "","type": "checkbox","helpText": "If checked, the existing feature branch will be deleted and the selected components in the grid will be committed in a new feature branch. Previous commits will not be present in the new feature branch. WARNING: Profiles and Permission Sets committed as full in this User Story will be recommitted as in the Commit Files operation. If you want them to be recommitted as full, you need to commit them again using the Full Profiles & Permission Sets git operation."}],"helpText": "When recommitting files, the metadata grid appears with the existing user story selections. You can uncheck the selected components and also select new ones.","helpLink": "https://docs.copado.com/git-operations/recommit-files","pages": "UserStoryCommit","endpoint": "commit","showAdvancedSection":true,"possibleRunningJob":""},{"operationType": "GitDeletion","operationLabel": "Destructive Changes","operationButtonLabel": "Commit Destructive Changes","attachmentName": "Git Deletion","operationFormElements": [{"label": "Org Credential","name": "orgId","type": "orgLookup","helpText": "If changed, the metadata grid will reload with the metadata items of the selected Org Credential."}],"showGrid": true,"editGrid": true,"reloadGridData": true,"showCommitMessage": true,"helpText": "When deleting components, a table appears with a list of User Story Commits with status \'Complete\'. Select the commits you would like to undo and click Undo Commits. When the operation is finished, the status of the selected User Story Commits will be updated to \'Commit Undone\'.","helpLink": "https://docs.copado.com/git-operations/destructive-changes","pages": "GitSnapshotCommit,UserStoryCommit","endpoint": "commit","showAdvancedSection":true,"possibleRunningJob":",GitDeletion,{!snapshotId},true"},{"operationType": "FullProfilePermissionSets","operationLabel": "Full Profiles & Permission Sets","showGrid": true,"gridMetadataTypes": "Profile,PermissionSet","showCommitMessage": true,"helpText": "","helpLink": "https://docs.copado.com/git-operations/commit-full-profiles-and-permission-sets","pages": "GitSnapshotCommit,UserStoryCommit","endpoint": "commit","showAdvancedSection":true,"possibleRunningJob":""},{"operationType": "VlocityDependencies","operationLabel": "","showGrid": false,"gridMetadataTypes": "","showCommitMessage": false,"helpText": "","helpLink": "","pages": "UserStoryCommit","endpoint": "","showAdvancedSection":false,"possibleRunningJob": ",MetadataDependenciesJob,{!userStoryId},true"},{"operationType": "GitCommit","operationLabel": "","showGrid": false,"gridMetadataTypes": "","showCommitMessage": false,"helpText": "Git Commit help","helpLink": "","pages": "UserStoryCommit","endpoint": "","showAdvancedSection":false,"possibleRunningJob": ",GitCommit,{!snapshotId},true"}]';
            MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', mockResponse, null);
            Test.setMock(HttpCalloutMock.class, fakeResponse);
            GitCommit_MainPageController controller = new GitCommit_MainPageController();
            System.assertEquals(0, controller.pageMessagesMap.size());
            System.assertNotEquals(null, controller.pageMessagesMap);
            System.assertEquals(4, controller.operationsMap.size());
            System.assertEquals(0, controller.snapshotList.size());
            System.assertEquals(tu.item('User_Story__c', 0).Id, controller.userStory.Id);
            System.assertEquals(true, controller.showCreateDXBranchPrompt);

            GitCommit_IntermediaryController intermediaryController = new GitCommit_IntermediaryController();
            intermediaryController.pageController = controller;
            Boolean dxJobStarted = intermediaryController.dxBranchJobStarted;
            System.assertEquals(false, dxJobStarted);
            Map<String, Set<Object>> componentMessagesMap = intermediaryController.componentMessagesMap;
            System.assertEquals(0, componentMessagesMap.size());

            fakeResponse = new MockHttpResponseGenerator(
                200,
                'Complete',
                '{"copadoJobId":"1458f75f-1c4f-4116-a92f-607fb3fb4bbc","ok":"Job has started!","status":"initializing"}',
                null
            );
            Test.setMock(HttpCalloutMock.class, fakeResponse);
            intermediaryController.createDXBranch();
            Integer messageCount = intermediaryController.getComponentMessageSize();
            System.assertEquals(1, messageCount);
            for (String severity : intermediaryController.componentMessagesMap.keySet()) {
                System.assertEquals('info', severity);
                for (Object obj : intermediaryController.componentMessagesMap.get(severity)) {
                    System.assertEquals(Label.Initializing, obj);
                }
            }

            PageReference redirectedPage = intermediaryController.pollerHandler();
            System.assertEquals(1, intermediaryController.componentMessagesMap.size());
            System.assertEquals(1, intermediaryController.copadoNotificationList.size());
            System.assertEquals(2, intermediaryController.getComponentMessageSize());
            System.assertNotEquals(null, intermediaryController.copadoNotificationId);
            System.assertEquals(null, redirectedPage);

            Copado_Notification__c cn = [SELECT status__c, isSuccess__c, isFinished__c FROM Copado_Notification__c LIMIT 1];
            cn.isFinished__c = true;
            cn.isSuccess__c = true;
            update cn;

            redirectedPage = intermediaryController.pollerHandler();
            System.assertEquals(1, intermediaryController.componentMessagesMap.size());
            System.assertEquals(1, intermediaryController.copadoNotificationList.size());
            System.assertEquals(2, intermediaryController.getComponentMessageSize());
            System.assertNotEquals(null, intermediaryController.copadoNotificationId);

            PageReference expectedPage = Page.GitCommitMain;
            expectedPage.getParameters().put('userStoryId', tu.item('User_Story__c', 0).Id);
            expectedPage.getParameters().put('variant', 'dxCommit');
            System.assertEquals(expectedPage.getUrl(), redirectedPage.getUrl());

            Test.stopTest();
        }
    }

    /**
     * Open the new git commit page from dx, no branch, notification returned warning
     */
    @IsTest
    private static void gitCommitPageDXNoBranchNotificationWarning() {
        User u = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(u.Username), true, true, true, true, true);

        System.runAs(u) {
            // Create current sprint record
            tu.insertSObject(
                'Sprint__c',
                new Map<String, Object>{ 'Name' => 'Sprint 2', 'Start_Date__c' => Date.today().addDays(-8), 'End_Date__c' => Date.today().addDays(8) }
            );

            // Create environments record
            tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'Dev1', 'org_id__c' => 'SFDC_OrgId' });
            tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'Dev2', 'org_id__c' => 'SFDC_OrgId2' });
            tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'Int', 'org_id__c' => 'SFDC_OrgId3' });
            tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'UAT', 'org_id__c' => 'SFDC_OrgId4' });
            tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'Prod', 'org_id__c' => 'SFDC_OrgId5' });
            insert new List<SObject>{
                tu.item('Environment__c', 0),
                tu.item('Environment__c', 1),
                tu.item('Environment__c', 2),
                tu.item('Environment__c', 3),
                tu.item('Environment__c', 4)
            };

            // Create org credentials record
            tu.createSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'OrgDev1',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 0).Id
                }
            );
            tu.createSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'OrgDev2',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId2',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 1).Id
                }
            );
            tu.createSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'OrgInt',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId3',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Default_Credential__c' => true,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 2).Id
                }
            );
            tu.createSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'OrgUAT',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId4',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 3).Id
                }
            );
            tu.createSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'OrgProd',
                    'Org_Type__c' => 'Production',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId5',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Test_Frequency__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 4).Id
                }
            );
            insert new List<SObject>{ tu.item('Org__c', 0), tu.item('Org__c', 1), tu.item('Org__c', 2), tu.item('Org__c', 3), tu.item('Org__c', 4) };

            // Create 1 git repository
            tu.insertSObjects('Git_Repository__c', 1, new Map<String, Object>{ 'Name' => 'test', 'URI__c' => 'http://www.test.uri' });

            // Create deployment flow record
            tu.insertSObject(
                'Deployment_Flow__c',
                new Map<String, Object>{
                    'Name' => 'Deployment Flow',
                    'Active__c' => true,
                    'Git_Repository__c' => tu.item('Git_Repository__c', 0).Id,
                    'Enable_Copado_DX__c' => true
                }
            );

            // Create deployment flow steps record
            tu.createSObject(
                'Deployment_Flow_Step__c',
                new Map<String, Object>{
                    'Source_Environment__c' => tu.item('Environment__c', 0).Id,
                    'Destination_Environment__c' => tu.item('Environment__c', 2).Id,
                    'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id,
                    'Enable_as_Scratch_Org_Destination__c' => 'Default DX Target'
                }
            );
            tu.createSObject(
                'Deployment_Flow_Step__c',
                new Map<String, Object>{
                    'Source_Environment__c' => tu.item('Environment__c', 1).Id,
                    'Destination_Environment__c' => tu.item('Environment__c', 2).Id,
                    'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id
                }
            );
            tu.createSObject(
                'Deployment_Flow_Step__c',
                new Map<String, Object>{
                    'Source_Environment__c' => tu.item('Environment__c', 2).Id,
                    'Destination_Environment__c' => tu.item('Environment__c', 3).Id,
                    'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id
                }
            );
            tu.createSObject(
                'Deployment_Flow_Step__c',
                new Map<String, Object>{
                    'Source_Environment__c' => tu.item('Environment__c', 3).Id,
                    'Destination_Environment__c' => tu.item('Environment__c', 4).Id,
                    'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id
                }
            );
            insert new List<SObject>{
                tu.item('Deployment_Flow_Step__c', 0),
                tu.item('Deployment_Flow_Step__c', 1),
                tu.item('Deployment_Flow_Step__c', 2),
                tu.item('Deployment_Flow_Step__c', 3)
            };

            // Create project record
            tu.insertSObject(
                'Project__c',
                new Map<String, Object>{
                    'Name' => 'My project',
                    'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id,
                    'Index_Metadata__c' => false
                }
            );

            // Create 3 user story to fill sobjectlist
            tu.insertSObjects(
                'User_Story__c',
                3,
                new Map<String, Object>{
                    'User_Story_Title__c' => 'us-0000000',
                    'Status__c' => 'Approved',
                    'Sprint__c' => tu.item('Sprint__c', 0).Id,
                    'Project__c' => tu.item('Project__c', 0).Id,
                    'Environment__c' => tu.item('Environment__c', 0).Id,
                    'Org_Credential__c' => tu.item('Org__c', 0).Id
                }
            );

            // Create attachment for metadatasources
            tu.insertSObjects(
                'Attachment',
                3,
                new Map<String, Object>{
                    'Name' => DXLabel.METADATA_SOURCES,
                    'ParentId' => tu.item('Org__c', 0).Id,
                    'Body' => Blob.valueOf(
                        '{"selectedArtifactIDs":["a1K1n000005ZwwNEAS"],"repositoryId":"","metadataSourceType":"artifact","metadataSource":"a1K1n000005ZwwNEAS","isPatch":false,"projectBranchCreated":true}'
                    )
                }
            );

            Test.startTest();
            PageReference pReference = Page.GitCommitMain;
            pReference.getParameters().put('userStoryId', tu.item('User_Story__c', 0).Id);
            pReference.getParameters().put('variant', 'dxCommit');
            Test.setCurrentPage(pReference);

            String mockResponse = '[{"operationType": "RecommitFiles","operationLabel": "Recommit Files","showGrid": true,"showUserStorySelections": true,"showCommitMessage": true,"operationFormElements": [{"label": "Re-Create Feature Branch","name": "recreateFeatureBranch","value": "","type": "checkbox","helpText": "If checked, the existing feature branch will be deleted and the selected components in the grid will be committed in a new feature branch. Previous commits will not be present in the new feature branch. WARNING: Profiles and Permission Sets committed as full in this User Story will be recommitted as in the Commit Files operation. If you want them to be recommitted as full, you need to commit them again using the Full Profiles & Permission Sets git operation."}],"helpText": "When recommitting files, the metadata grid appears with the existing user story selections. You can uncheck the selected components and also select new ones.","helpLink": "https://docs.copado.com/git-operations/recommit-files","pages": "UserStoryCommit","endpoint": "commit","showAdvancedSection":true,"possibleRunningJob":""},{"operationType": "GitDeletion","operationLabel": "Destructive Changes","operationButtonLabel": "Commit Destructive Changes","attachmentName": "Git Deletion","operationFormElements": [{"label": "Org Credential","name": "orgId","type": "orgLookup","helpText": "If changed, the metadata grid will reload with the metadata items of the selected Org Credential."}],"showGrid": true,"editGrid": true,"reloadGridData": true,"showCommitMessage": true,"helpText": "When deleting components, a table appears with a list of User Story Commits with status \'Complete\'. Select the commits you would like to undo and click Undo Commits. When the operation is finished, the status of the selected User Story Commits will be updated to \'Commit Undone\'.","helpLink": "https://docs.copado.com/git-operations/destructive-changes","pages": "GitSnapshotCommit,UserStoryCommit","endpoint": "commit","showAdvancedSection":true,"possibleRunningJob":",GitDeletion,{!snapshotId},true"},{"operationType": "FullProfilePermissionSets","operationLabel": "Full Profiles & Permission Sets","showGrid": true,"gridMetadataTypes": "Profile,PermissionSet","showCommitMessage": true,"helpText": "","helpLink": "https://docs.copado.com/git-operations/commit-full-profiles-and-permission-sets","pages": "GitSnapshotCommit,UserStoryCommit","endpoint": "commit","showAdvancedSection":true,"possibleRunningJob":""},{"operationType": "VlocityDependencies","operationLabel": "","showGrid": false,"gridMetadataTypes": "","showCommitMessage": false,"helpText": "","helpLink": "","pages": "UserStoryCommit","endpoint": "","showAdvancedSection":false,"possibleRunningJob": ",MetadataDependenciesJob,{!userStoryId},true"},{"operationType": "GitCommit","operationLabel": "","showGrid": false,"gridMetadataTypes": "","showCommitMessage": false,"helpText": "Git Commit help","helpLink": "","pages": "UserStoryCommit","endpoint": "","showAdvancedSection":false,"possibleRunningJob": ",GitCommit,{!snapshotId},true"}]';
            MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', mockResponse, null);
            Test.setMock(HttpCalloutMock.class, fakeResponse);
            GitCommit_MainPageController controller = new GitCommit_MainPageController();
            System.assertEquals(0, controller.pageMessagesMap.size());
            System.assertNotEquals(null, controller.pageMessagesMap);
            System.assertEquals(4, controller.operationsMap.size());
            System.assertEquals(0, controller.snapshotList.size());
            System.assertEquals(tu.item('User_Story__c', 0).Id, controller.userStory.Id);
            System.assertEquals(true, controller.showCreateDXBranchPrompt);

            GitCommit_IntermediaryController intermediaryController = new GitCommit_IntermediaryController();
            intermediaryController.pageController = controller;
            Boolean dxJobStarted = intermediaryController.dxBranchJobStarted;
            System.assertEquals(false, dxJobStarted);
            Map<String, Set<Object>> componentMessagesMap = intermediaryController.componentMessagesMap;
            System.assertEquals(0, componentMessagesMap.size());

            fakeResponse = new MockHttpResponseGenerator(
                200,
                'Complete',
                '{"copadoJobId":"1458f75f-1c4f-4116-a92f-607fb3fb4bbc","ok":"Job has started!","status":"initializing"}',
                null
            );
            Test.setMock(HttpCalloutMock.class, fakeResponse);
            intermediaryController.createDXBranch();
            Integer messageCount = intermediaryController.getComponentMessageSize();
            System.assertEquals(1, messageCount);
            for (String severity : intermediaryController.componentMessagesMap.keySet()) {
                System.assertEquals('info', severity);
                for (Object obj : intermediaryController.componentMessagesMap.get(severity)) {
                    System.assertEquals(Label.Initializing, obj);
                }
            }

            PageReference redirectedPage = intermediaryController.pollerHandler();
            System.assertEquals(1, intermediaryController.componentMessagesMap.size());
            System.assertEquals(1, intermediaryController.copadoNotificationList.size());
            System.assertEquals(2, intermediaryController.getComponentMessageSize());
            System.assertNotEquals(null, intermediaryController.copadoNotificationId);
            System.assertEquals(null, redirectedPage);

            Copado_Notification__c cn = [SELECT status__c, isSuccess__c, isFinished__c, Message__c FROM Copado_Notification__c LIMIT 1];
            cn.Message__c = 'warning warning';
            cn.isFinished__c = true;
            cn.isSuccess__c = false;
            update cn;

            redirectedPage = intermediaryController.pollerHandler();
            System.assertEquals(2, intermediaryController.componentMessagesMap.size());
            System.assertEquals(1, intermediaryController.copadoNotificationList.size());
            System.assertEquals(3, intermediaryController.getComponentMessageSize());
            System.assertNotEquals(null, intermediaryController.copadoNotificationId);
            System.assertEquals(null, redirectedPage);

            intermediaryController.goBackToUserStory();
            Test.stopTest();
        }
    }

    /**
     * Gitcommit_maincontroller is empty, to cover one line added this method. If we add something in controller, method will be covered in this test method
     */
    @IsTest
    private static void mainControllerTest() {
        User u = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(u.Username), true, true, true, true, true);

        System.runAs(u) {
            // Create current sprint record
            tu.insertSObject(
                'Sprint__c',
                new Map<String, Object>{ 'Name' => 'Sprint 2', 'Start_Date__c' => Date.today().addDays(-8), 'End_Date__c' => Date.today().addDays(8) }
            );

            // Create environments record
            tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'Dev1', 'org_id__c' => 'SFDC_OrgId' });
            tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'Dev2', 'org_id__c' => 'SFDC_OrgId2' });
            tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'Int', 'org_id__c' => 'SFDC_OrgId3' });
            tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'UAT', 'org_id__c' => 'SFDC_OrgId4' });
            tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'Prod', 'org_id__c' => 'SFDC_OrgId5' });
            insert new List<SObject>{
                tu.item('Environment__c', 0),
                tu.item('Environment__c', 1),
                tu.item('Environment__c', 2),
                tu.item('Environment__c', 3),
                tu.item('Environment__c', 4)
            };

            // Create org credentials record
            tu.createSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'OrgDev1',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 0).Id
                }
            );
            tu.createSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'OrgDev2',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId2',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 1).Id
                }
            );
            tu.createSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'OrgInt',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId3',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Default_Credential__c' => true,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 2).Id
                }
            );
            tu.createSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'OrgUAT',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId4',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 3).Id
                }
            );
            tu.createSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'OrgProd',
                    'Org_Type__c' => 'Production',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId5',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Test_Frequency__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 4).Id
                }
            );
            insert new List<SObject>{ tu.item('Org__c', 0), tu.item('Org__c', 1), tu.item('Org__c', 2), tu.item('Org__c', 3), tu.item('Org__c', 4) };

            // Create 1 git repository
            tu.insertSObjects('Git_Repository__c', 1, new Map<String, Object>{ 'Name' => 'test', 'URI__c' => 'http://www.test.uri' });

            // Create deployment flow record
            tu.insertSObject(
                'Deployment_Flow__c',
                new Map<String, Object>{
                    'Name' => 'Deployment Flow',
                    'Active__c' => true,
                    'Git_Repository__c' => tu.item('Git_Repository__c', 0).Id,
                    'Enable_Copado_DX__c' => true
                }
            );

            // Create deployment flow steps record
            tu.createSObject(
                'Deployment_Flow_Step__c',
                new Map<String, Object>{
                    'Source_Environment__c' => tu.item('Environment__c', 0).Id,
                    'Destination_Environment__c' => tu.item('Environment__c', 2).Id,
                    'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id,
                    'Enable_as_Scratch_Org_Destination__c' => 'Default DX Target'
                }
            );
            tu.createSObject(
                'Deployment_Flow_Step__c',
                new Map<String, Object>{
                    'Source_Environment__c' => tu.item('Environment__c', 1).Id,
                    'Destination_Environment__c' => tu.item('Environment__c', 2).Id,
                    'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id
                }
            );
            tu.createSObject(
                'Deployment_Flow_Step__c',
                new Map<String, Object>{
                    'Source_Environment__c' => tu.item('Environment__c', 2).Id,
                    'Destination_Environment__c' => tu.item('Environment__c', 3).Id,
                    'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id
                }
            );
            tu.createSObject(
                'Deployment_Flow_Step__c',
                new Map<String, Object>{
                    'Source_Environment__c' => tu.item('Environment__c', 3).Id,
                    'Destination_Environment__c' => tu.item('Environment__c', 4).Id,
                    'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id
                }
            );
            insert new List<SObject>{
                tu.item('Deployment_Flow_Step__c', 0),
                tu.item('Deployment_Flow_Step__c', 1),
                tu.item('Deployment_Flow_Step__c', 2),
                tu.item('Deployment_Flow_Step__c', 3)
            };

            // Create project record
            tu.insertSObject(
                'Project__c',
                new Map<String, Object>{
                    'Name' => 'My project',
                    'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id,
                    'Index_Metadata__c' => false
                }
            );

            // Create 3 user story to fill sobjectlist
            tu.insertSObjects(
                'User_Story__c',
                3,
                new Map<String, Object>{
                    'User_Story_Title__c' => 'us-0000000',
                    'Status__c' => 'Approved',
                    'Sprint__c' => tu.item('Sprint__c', 0).Id,
                    'Project__c' => tu.item('Project__c', 0).Id,
                    'Environment__c' => tu.item('Environment__c', 0).Id,
                    'Org_Credential__c' => tu.item('Org__c', 0).Id
                }
            );

            // Create attachment for metadatasources
            tu.insertSObjects(
                'Attachment',
                3,
                new Map<String, Object>{
                    'Name' => DXLabel.METADATA_SOURCES,
                    'ParentId' => tu.item('Org__c', 0).Id,
                    'Body' => Blob.valueOf(
                        '{"selectedArtifactIDs":["a1K1n000005ZwwNEAS"],"repositoryId":"","metadataSourceType":"artifact","metadataSource":"a1K1n000005ZwwNEAS","isPatch":false,"projectBranchCreated":true}'
                    )
                }
            );

            Test.startTest();
            PageReference pReference = Page.GitCommitMain;
            pReference.getParameters().put('userStoryId', tu.item('User_Story__c', 0).Id);
            pReference.getParameters().put('variant', 'dxCommit');
            Test.setCurrentPage(pReference);

            String mockResponse = '[{"operationType": "RecommitFiles","operationLabel": "Recommit Files","showGrid": true,"showUserStorySelections": true,"showCommitMessage": true,"operationFormElements": [{"label": "Re-Create Feature Branch","name": "recreateFeatureBranch","value": "","type": "checkbox","helpText": "If checked, the existing feature branch will be deleted and the selected components in the grid will be committed in a new feature branch. Previous commits will not be present in the new feature branch. WARNING: Profiles and Permission Sets committed as full in this User Story will be recommitted as in the Commit Files operation. If you want them to be recommitted as full, you need to commit them again using the Full Profiles & Permission Sets git operation."}],"helpText": "When recommitting files, the metadata grid appears with the existing user story selections. You can uncheck the selected components and also select new ones.","helpLink": "https://docs.copado.com/git-operations/recommit-files","pages": "UserStoryCommit","endpoint": "commit","showAdvancedSection":true,"possibleRunningJob":""},{"operationType": "GitDeletion","operationLabel": "Destructive Changes","operationButtonLabel": "Commit Destructive Changes","attachmentName": "Git Deletion","operationFormElements": [{"label": "Org Credential","name": "orgId","type": "orgLookup","helpText": "If changed, the metadata grid will reload with the metadata items of the selected Org Credential."}],"showGrid": true,"editGrid": true,"reloadGridData": true,"showCommitMessage": true,"helpText": "When deleting components, a table appears with a list of User Story Commits with status \'Complete\'. Select the commits you would like to undo and click Undo Commits. When the operation is finished, the status of the selected User Story Commits will be updated to \'Commit Undone\'.","helpLink": "https://docs.copado.com/git-operations/destructive-changes","pages": "GitSnapshotCommit,UserStoryCommit","endpoint": "commit","showAdvancedSection":true,"possibleRunningJob":",GitDeletion,{!snapshotId},true"},{"operationType": "FullProfilePermissionSets","operationLabel": "Full Profiles & Permission Sets","showGrid": true,"gridMetadataTypes": "Profile,PermissionSet","showCommitMessage": true,"helpText": "","helpLink": "https://docs.copado.com/git-operations/commit-full-profiles-and-permission-sets","pages": "GitSnapshotCommit,UserStoryCommit","endpoint": "commit","showAdvancedSection":true,"possibleRunningJob":""},{"operationType": "VlocityDependencies","operationLabel": "","showGrid": false,"gridMetadataTypes": "","showCommitMessage": false,"helpText": "","helpLink": "","pages": "UserStoryCommit","endpoint": "","showAdvancedSection":false,"possibleRunningJob": ",MetadataDependenciesJob,{!userStoryId},true"},{"operationType": "GitCommit","operationLabel": "","showGrid": false,"gridMetadataTypes": "","showCommitMessage": false,"helpText": "Git Commit help","helpLink": "","pages": "UserStoryCommit","endpoint": "","showAdvancedSection":false,"possibleRunningJob": ",GitCommit,{!snapshotId},true"}]';
            MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', mockResponse, null);
            Test.setMock(HttpCalloutMock.class, fakeResponse);
            GitCommit_MainPageController controller = new GitCommit_MainPageController();
            System.assertEquals(0, controller.pageMessagesMap.size());
            System.assertNotEquals(null, controller.pageMessagesMap);
            System.assertEquals(4, controller.operationsMap.size());
            System.assertEquals(0, controller.snapshotList.size());
            System.assertEquals(tu.item('User_Story__c', 0).Id, controller.userStory.Id);
            System.assertEquals(true, controller.showCreateDXBranchPrompt);

            GitCommit_MainController mainController = new GitCommit_MainController();
            mainController.pageController = controller;
            System.assertEquals(0, mainController.getPageMessageSize());
            Test.stopTest();
        }
    }
}