@IsTest
private class Test_GitCommitMainNegative {

    static TestUtilities tu = new TestUtilities();

    @TestSetup static void setupData() {
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

        tu.insertSObject('User', new Map<String, Object>{
                'ProfileId' => [SELECT Id FROM Profile WHERE Name = 'Standard User'].Id,
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
        });

        TestUtilities.enableLicenses(2, 2, 2, 2, 2);
        FeatureManagement.setPackageIntegerValue('CBM_Branches', 2);
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Copado_User'];
        insert new PermissionSetAssignment(AssigneeId = tu.item('User', 0).Id, PermissionSetId = ps.Id);
    }

    /**
     * Open the new git commit page from user story without Copado licenses assigned to the user
     */
    @IsTest static void gitCommitPageUSWithoutCopadoLicense() {
        User u = [SELECT Id,Name,LastName,Email,Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(u.Username), false, false, false, false, false);

        System.runAs(u) {
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
                    'Validated_Date__c' => System.now(),
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
                    'Default_Credential__c' => true,
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

            // Create 3 user story to fill sobjectlist
            tu.insertSObjects('User_Story__c', 3, new Map<String, Object>{
                    'User_Story_Title__c' => 'us-0000000',
                    'Status__c' => 'Approved',
                    'Sprint__c' => tu.item('Sprint__c', 0).Id,
                    'Story_Points_SFDC__c' => 2,
                    'Project__c' => tu.item('Project__c', 0).Id,
                    'Environment__c' => tu.item('Environment__c', 0).Id,
                    'Org_Credential__c' => tu.item('Org__c', 0).Id,
                    'Metadata_Types_in_Selection__c' => 'ApexClass'
            });

            Test.startTest();
            PageReference pReference = Page.GitCommitMain;
            pReference.getParameters().put('userStoryId', tu.item('User_Story__c', 0).Id);
            Test.setCurrentPage(pReference);

            GitCommit_MainPageController controller = new GitCommit_MainPageController();
            System.assertEquals(1, controller.pageMessagesMap.size());

            for(String severity : controller.pageMessagesMap.keySet()) {
                System.assertEquals('warning', severity);
                System.assertEquals(1, controller.pageMessagesMap.get(severity).size());
                for(Object obj : controller.pageMessagesMap.get(severity)) {
                    System.assertEquals(Label.CCM_License_Restriction, obj);
                }
            }

            Test.stopTest();
        }
    }

    /**
     * Open the new git commit page from user story without permission set assigned to user
     * Testing without variant
     */
    @IsTest static void gitCommitPageUSWithoutPermissionSet() {
        User u = [SELECT Id,Name,LastName,Email,Username FROM User WHERE Email = 'test2@test2.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(u.Username), true, false, false, false, false);

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
                'Validated_Date__c' => System.now(),
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
                'Default_Credential__c' => true,
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

        // Create 3 user story to fill sobjectlist
        tu.insertSObjects('User_Story__c', 3, new Map<String, Object>{
                'User_Story_Title__c' => 'us-0000000',
                'Status__c' => 'Approved',
                'Sprint__c' => tu.item('Sprint__c', 0).Id,
                'Story_Points_SFDC__c' => 2,
                'Project__c' => tu.item('Project__c', 0).Id,
                'Environment__c' => tu.item('Environment__c', 0).Id,
                'Org_Credential__c' => tu.item('Org__c', 0).Id,
                'Metadata_Types_in_Selection__c' => 'ApexClass'
        });

        System.runAs(u) {
            Test.startTest();
            PageReference pReference = Page.GitCommitMain;
            pReference.getParameters().put('userStoryId', tu.item('User_Story__c', 0).Id);
            Test.setCurrentPage(pReference);

            GitCommit_MainPageController controller = new GitCommit_MainPageController();
            System.assertEquals(1, controller.pageMessagesMap.size());

            for(String severity : controller.pageMessagesMap.keySet()) {
                System.assertEquals('warning', severity);
                System.assertEquals(1, controller.pageMessagesMap.get(severity).size());
                for(Object obj : controller.pageMessagesMap.get(severity)) {
                    System.assertEquals(Label.MISSING_PERMISSIONS_CBM_FLOW, obj);
                }
            }

            Test.stopTest();
        }
    }

    /**
     * Open the new git commit page from user story, no snapshot
     */
    @IsTest static void gitCommitPageUSWithoutSnapshot() {
        User u = [SELECT Id,Name,LastName,Email,Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(u.Username), true, true, true, true, true);

        System.runAs(u) {
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
                    'Validated_Date__c' => System.now(),
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
                    'Default_Credential__c' => true,
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

            // Create 3 user story to fill sobjectlist
            tu.insertSObjects('User_Story__c', 3, new Map<String, Object>{
                    'User_Story_Title__c' => 'us-0000000',
                    'Status__c' => 'Approved',
                    'Sprint__c' => tu.item('Sprint__c', 0).Id,
                    'Story_Points_SFDC__c' => 2,
                    'Project__c' => tu.item('Project__c', 0).Id,
                    'Environment__c' => tu.item('Environment__c', 0).Id,
                    'Org_Credential__c' => tu.item('Org__c', 0).Id,
                    'Metadata_Types_in_Selection__c' => 'ApexClass'
            });

            Test.startTest();
            PageReference pReference = Page.GitCommitMain;
            pReference.getParameters().put('userStoryId', tu.item('User_Story__c', 0).Id);
            pReference.getParameters().put('variant', 'userstorycommit');
            Test.setCurrentPage(pReference);

            GitCommit_MainPageController controller = new GitCommit_MainPageController();
            System.assertEquals(1, controller.pageMessagesMap.size());

            for(String severity : controller.pageMessagesMap.keySet()) {
                System.assertEquals('error', severity);
                System.assertEquals(1, controller.pageMessagesMap.get(severity).size());
                for(Object obj : controller.pageMessagesMap.get(severity)) {
                    System.assertEquals(Label.USER_STORY_COMMIT_NO_SNAPSHOT_FOUND, obj);
                }
            }

            Test.stopTest();
        }
    }

    /**
     * Open the new git commit page from user story, flow is inactive
     */
    @IsTest static void gitCommitPageUSInactiveFlow() {
        User u = [SELECT Id,Name,LastName,Email,Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(u.Username), true, true, true, true, true);

        System.runAs(u) {
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
                    'Validated_Date__c' => System.now(),
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
                    'Default_Credential__c' => true,
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
                    'Active__c' => false
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

            // Create 3 user story to fill sobjectlist
            tu.insertSObjects('User_Story__c', 3, new Map<String, Object>{
                    'User_Story_Title__c' => 'us-0000000',
                    'Status__c' => 'Approved',
                    'Sprint__c' => tu.item('Sprint__c', 0).Id,
                    'Story_Points_SFDC__c' => 2,
                    'Project__c' => tu.item('Project__c', 0).Id,
                    'Environment__c' => tu.item('Environment__c', 0).Id,
                    'Org_Credential__c' => tu.item('Org__c', 0).Id,
                    'Metadata_Types_in_Selection__c' => 'ApexClass'
            });

            Test.startTest();
            PageReference pReference = Page.GitCommitMain;
            pReference.getParameters().put('userStoryId', tu.item('User_Story__c', 0).Id);
            pReference.getParameters().put('variant', 'userstorycommit');
            Test.setCurrentPage(pReference);

            GitCommit_MainPageController controller = new GitCommit_MainPageController();
            System.assertEquals(1, controller.pageMessagesMap.size());

            for(String severity : controller.pageMessagesMap.keySet()) {
                System.assertEquals('error', severity);
                System.assertEquals(1, controller.pageMessagesMap.get(severity).size());
                for(Object obj : controller.pageMessagesMap.get(severity)) {
                    System.assertEquals(Label.PROMOTION_FLOW_INACTIVE, obj);
                }
            }

            Test.stopTest();
        }
    }

    /**
     * Open the new git commit page from user story, blocked commit
     */
    @IsTest static void gitCommitPageUSBlockedCommit() {
        User u = [SELECT Id,Name,LastName,Email,Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(u.Username), true, true, true, true, true);

        System.runAs(u) {
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
                    'Validated_Date__c' => System.now(),
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
                    'Default_Credential__c' => true,
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
                    'Active__c' => true,
                    'Block_Commits__c' => true
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

            // Create 3 user story to fill sobjectlist
            tu.insertSObjects('User_Story__c', 3, new Map<String, Object>{
                    'User_Story_Title__c' => 'us-0000000',
                    'Status__c' => 'Approved',
                    'Sprint__c' => tu.item('Sprint__c', 0).Id,
                    'Story_Points_SFDC__c' => 2,
                    'Project__c' => tu.item('Project__c', 0).Id,
                    'Environment__c' => tu.item('Environment__c', 0).Id,
                    'Org_Credential__c' => tu.item('Org__c', 0).Id,
                    'Metadata_Types_in_Selection__c' => 'ApexClass'
            });

            Test.startTest();
            PageReference pReference = Page.GitCommitMain;
            pReference.getParameters().put('userStoryId', tu.item('User_Story__c', 0).Id);
            pReference.getParameters().put('variant', 'userstorycommit');
            Test.setCurrentPage(pReference);

            GitCommit_MainPageController controller = new GitCommit_MainPageController();
            System.assertEquals(1, controller.pageMessagesMap.size());

            for(String severity : controller.pageMessagesMap.keySet()) {
                System.assertEquals('error', severity);
                System.assertEquals(1, controller.pageMessagesMap.get(severity).size());
                for(Object obj : controller.pageMessagesMap.get(severity)) {
                    System.assertEquals(Label.DEPLOYMENT_FLOW_COMMITS_BLOCKED, obj);
                }
            }

            Test.stopTest();
        }
    }

    /**
     * Open the new git commit page from user story, Project and no Release.
     */
    @IsTest static void gitCommitPageUSProjectNoRelease() {
        User u = [SELECT Id,Name,LastName,Email,Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(u.Username), true, true, true, true, true);

        System.runAs(u) {
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
                    'Validated_Date__c' => System.now(),
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
                    'Default_Credential__c' => true,
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


            // Create 3 user story to fill sobjectlist
            tu.insertSObjects('User_Story__c', 3, new Map<String, Object>{
                    'User_Story_Title__c' => 'us-0000000',
                    'Status__c' => 'Approved',
                    'Sprint__c' => tu.item('Sprint__c', 0).Id,
                    'Story_Points_SFDC__c' => 2,
                    'Environment__c' => tu.item('Environment__c', 0).Id,
                    'Org_Credential__c' => tu.item('Org__c', 0).Id
            });

            Test.startTest();
            PageReference pReference = Page.GitCommitMain;
            pReference.getParameters().put('userStoryId', tu.item('User_Story__c', 0).Id);
            pReference.getParameters().put('variant', 'userstorycommit');
            Test.setCurrentPage(pReference);

            GitCommit_MainPageController controller = new GitCommit_MainPageController();
            System.assertEquals(1, controller.pageMessagesMap.size());

            for(String severity : controller.pageMessagesMap.keySet()) {
                System.assertEquals('error', severity);
                System.assertEquals(1, controller.pageMessagesMap.get(severity).size());
                for(Object obj : controller.pageMessagesMap.get(severity)) {
                    System.assertEquals(Label.PROMOTION_FLOW_INACTIVE, obj);
                }
            }

            Test.stopTest();
        }
    }

    /**
     * Open the new git commit page from user story, no environment
     */
    @IsTest static void gitCommitPageUSNoEnvironment() {
        User u = [SELECT Id,Name,LastName,Email,Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(u.Username), true, true, true, true, true);

        System.runAs(u) {
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
                    'Validated_Date__c' => System.now(),
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
                    'Default_Credential__c' => true,
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

            // Create 3 user story to fill sobjectlist
            tu.insertSObjects('User_Story__c', 3, new Map<String, Object>{
                    'User_Story_Title__c' => 'us-0000000',
                    'Status__c' => 'Approved',
                    'Sprint__c' => tu.item('Sprint__c', 0).Id,
                    'Story_Points_SFDC__c' => 2,
                    'Project__c' => tu.item('Project__c', 0).Id,
                    'Metadata_Types_in_Selection__c' => 'ApexClass'
            });

            Test.startTest();
            PageReference pReference = Page.GitCommitMain;
            pReference.getParameters().put('userStoryId', tu.item('User_Story__c', 0).Id);
            pReference.getParameters().put('variant', 'userstorycommit');
            Test.setCurrentPage(pReference);

            GitCommit_MainPageController controller = new GitCommit_MainPageController();
            System.assertEquals(1, controller.pageMessagesMap.size());

            for(String severity : controller.pageMessagesMap.keySet()) {
                System.assertEquals('error', severity);
                System.assertEquals(1, controller.pageMessagesMap.get(severity).size());
                for(Object obj : controller.pageMessagesMap.get(severity)) {
                    System.assertEquals(Label.USER_STORY_COMMIT_NO_ENVIRONMENT, obj);
                }
            }

            Test.stopTest();
        }
    }

    /**
     * Open the new git commit page from user story without variant is defined
     */
    @IsTest static void gitCommitPageUSWithoutVariant() {
        User u = [SELECT Id,Name,LastName,Email,Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(u.Username), true, true, true, true, true);

        System.runAs(u) {
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
                    'Validated_Date__c' => System.now(),
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
                    'Default_Credential__c' => true,
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

            // Create 3 user story to fill sobjectlist
            tu.insertSObjects('User_Story__c', 3, new Map<String, Object>{
                    'User_Story_Title__c' => 'us-0000000',
                    'Status__c' => 'Approved',
                    'Sprint__c' => tu.item('Sprint__c', 0).Id,
                    'Story_Points_SFDC__c' => 2,
                    'Project__c' => tu.item('Project__c', 0).Id,
                    'Environment__c' => tu.item('Environment__c', 0).Id,
                    'Org_Credential__c' => tu.item('Org__c', 0).Id,
                    'Metadata_Types_in_Selection__c' => 'ApexClass'
            });

            Test.startTest();
            PageReference pReference = Page.GitCommitMain;
            pReference.getParameters().put('userStoryId', tu.item('User_Story__c', 0).Id);
            Test.setCurrentPage(pReference);

            GitCommit_MainPageController controller = new GitCommit_MainPageController();
            System.assertEquals(1, controller.pageMessagesMap.size());

            for(String severity : controller.pageMessagesMap.keySet()) {
                System.assertEquals('error', severity);
                System.assertEquals(1, controller.pageMessagesMap.get(severity).size());
                for(Object obj : controller.pageMessagesMap.get(severity)) {
                    System.assertEquals('Variant is not defined', obj);
                }
            }

            Test.stopTest();
        }
    }

    /**
     * Open the new git commit page from user story with typo issue on variant
     */
    @IsTest static void gitCommitPageUSWithWrongVariant() {
        User u = [SELECT Id,Name,LastName,Email,Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(u.Username), true, true, true, true, true);

        System.runAs(u) {
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
                    'Validated_Date__c' => System.now(),
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
                    'Default_Credential__c' => true,
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

            // Create 3 user story to fill sobjectlist
            tu.insertSObjects('User_Story__c', 3, new Map<String, Object>{
                    'User_Story_Title__c' => 'us-0000000',
                    'Status__c' => 'Approved',
                    'Sprint__c' => tu.item('Sprint__c', 0).Id,
                    'Story_Points_SFDC__c' => 2,
                    'Project__c' => tu.item('Project__c', 0).Id,
                    'Environment__c' => tu.item('Environment__c', 0).Id,
                    'Org_Credential__c' => tu.item('Org__c', 0).Id,
                    'Metadata_Types_in_Selection__c' => 'ApexClass'
            });

            Test.startTest();
            PageReference pReference = Page.GitCommitMain;
            pReference.getParameters().put('userStoryId', tu.item('User_Story__c', 0).Id);
            pReference.getParameters().put('variant', 'userrstorycommit');
            Test.setCurrentPage(pReference);

            GitCommit_MainPageController controller = new GitCommit_MainPageController();
            System.assertEquals(1, controller.pageMessagesMap.size());

            for(String severity : controller.pageMessagesMap.keySet()) {
                System.assertEquals('error', severity);
                System.assertEquals(1, controller.pageMessagesMap.get(severity).size());
                for(Object obj : controller.pageMessagesMap.get(severity)) {
                    System.assertEquals('Unsupported service', obj);
                }
            }

            Test.stopTest();
        }
    }

    /**
     * Open the new git commit page from user story, connection problem
     */
    @IsTest static void gitCommitPageUSConnectionProblem() {
        User u = [SELECT Id,Name,LastName,Email,Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(u.Username), true, true, true, true, true);

        System.runAs(u) {
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
                    'Validated_Date__c' => System.now(),
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
                    'Default_Credential__c' => true,
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

            // Create 1 git repository
            tu.insertSObjects('Git_Repository__c', 1, new Map<String, Object>{
                    'Name' => 'test',
                    'URI__c' => 'http://www.test.uri'
            });

            // Create deployment flow record
            tu.insertSObject('Deployment_Flow__c', new Map<String, Object>{
                    'Name' => 'Deployment Flow',
                    'Active__c' => true,
                    'Git_Repository__c' => tu.item('Git_Repository__c', 0).Id
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

            // Create 3 user story to fill sobjectlist
            tu.insertSObjects('User_Story__c', 3, new Map<String, Object>{
                    'User_Story_Title__c' => 'us-0000000',
                    'Status__c' => 'Approved',
                    'Sprint__c' => tu.item('Sprint__c', 0).Id,
                    'Story_Points_SFDC__c' => 2,
                    'Project__c' => tu.item('Project__c', 0).Id,
                    'Environment__c' => tu.item('Environment__c', 0).Id,
                    'Org_Credential__c' => tu.item('Org__c', 0).Id,
                    'Metadata_Types_in_Selection__c' => 'ApexClass'
            });

            // Create 1 git backup
            tu.insertSObjects('Git_Backup__c', 1, new Map<String, Object>{
                    'Name' => 'backupname',
                    'Branch__c' => 'branchName',
                    'Frequency__c' => 'Daily',
                    'Git_Repository__c' => tu.item('Git_Repository__c', 0).Id,
                    'Org__c' => tu.item('Org__c', 0).Id
            });

            Test.startTest();
            PageReference pReference = Page.GitCommitMain;
            pReference.getParameters().put('userStoryId', tu.item('User_Story__c', 0).Id);
            pReference.getParameters().put('variant', 'userstorycommit');
            Test.setCurrentPage(pReference);

            GitCommit_MainPageController controller = new GitCommit_MainPageController();
            System.assertEquals(1, controller.pageMessagesMap.size());

            for(String severity : controller.pageMessagesMap.keySet()) {
                System.assertEquals('error', severity);
                System.assertEquals(1, controller.pageMessagesMap.get(severity).size());
                for(Object obj : controller.pageMessagesMap.get(severity)) {
                    System.assertEquals(Label.Connection_Problem, obj);
                }
            }

            Test.stopTest();
        }
    }

    /**
     * Open the new git commit page from user story with variant dxCommit, dx is not enabled
     */
    @IsTest static void gitCommitPageDXWithoutDxEnabled() {
        User u = [SELECT Id,Name,LastName,Email,Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(u.Username), true, true, true, true, true);

        System.runAs(u) {
            // Create current sprint record
            tu.insertSObject('Sprint__c', new Map<String, Object>{
                    'Name' => 'Sprint 2',
                    'Start_Date__c' => Date.today().addDays(-8),
                    'End_Date__c' => Date.today().addDays(8)
            });

            // Create environments record
            tu.createSObject('Environment__c', new Map<String, Object>{
                    'Name' => 'Dev1',
                    'Type__c' => 'Scratch Org',
                    'org_id__c' => 'SFDC_OrgId'
            });
            tu.createSObject('Environment__c', new Map<String, Object>{
                    'Name' => 'Dev2',
                    'Type__c' => 'Scratch Org',
                    'org_id__c' => 'SFDC_OrgId2'
            });
            tu.createSObject('Environment__c', new Map<String, Object>{
                    'Name' => 'Int',
                    'Type__c' => 'Scratch Org',
                    'org_id__c' => 'SFDC_OrgId3'
            });
            tu.createSObject('Environment__c', new Map<String, Object>{
                    'Name' => 'UAT',
                    'Type__c' => 'Scratch Org',
                    'org_id__c' => 'SFDC_OrgId4'
            });
            tu.createSObject('Environment__c', new Map<String, Object>{
                    'Name' => 'Prod',
                    'Type__c' => 'Scratch Org',
                    'org_id__c' => 'SFDC_OrgId5'
            });
            insert new List<SObject>{
                    tu.item('Environment__c', 0), tu.item('Environment__c', 1), tu.item('Environment__c', 2), tu.item('Environment__c', 3), tu.item('Environment__c', 4)
            };

            // Create org credentials record
            tu.createSObject('Org__c', new Map<String, Object>{
                    'Name' => 'OrgDev1',
                    'Org_Type__c' => 'Scratch Org',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 0).Id
            });
            tu.createSObject('Org__c', new Map<String, Object>{
                    'Name' => 'OrgDev2',
                    'Org_Type__c' => 'Scratch Org',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId2',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 1).Id
            });
            tu.createSObject('Org__c', new Map<String, Object>{
                    'Name' => 'OrgInt',
                    'Org_Type__c' => 'Scratch Org',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId3',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Default_Credential__c' => true,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 2).Id
            });
            tu.createSObject('Org__c', new Map<String, Object>{
                    'Name' => 'OrgUAT',
                    'Org_Type__c' => 'Scratch Org',
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

            // Create 3 user story to fill sobjectlist
            tu.insertSObjects('User_Story__c', 3, new Map<String, Object>{
                    'User_Story_Title__c' => 'us-0000000',
                    'Status__c' => 'Approved',
                    'Sprint__c' => tu.item('Sprint__c', 0).Id,
                    'Story_Points_SFDC__c' => 2,
                    'Project__c' => tu.item('Project__c', 0).Id,
                    'Environment__c' => tu.item('Environment__c', 0).Id,
                    'Org_Credential__c' => tu.item('Org__c', 0).Id,
                    'Metadata_Types_in_Selection__c' => 'ApexClass'
            });

            Test.startTest();
            PageReference pReference = Page.GitCommitMain;
            pReference.getParameters().put('userStoryId', tu.item('User_Story__c', 0).Id);
            pReference.getParameters().put('variant', 'dxcommit');
            Test.setCurrentPage(pReference);

            GitCommit_MainPageController controller = new GitCommit_MainPageController();
            System.assertEquals(1, controller.pageMessagesMap.size());

            for(String severity : controller.pageMessagesMap.keySet()) {
                System.assertEquals('error', severity);
                System.assertEquals(1, controller.pageMessagesMap.get(severity).size());
                for(Object obj : controller.pageMessagesMap.get(severity)) {
                    System.assertEquals(Label.DX_NOT_ENABLED_DF, obj);
                }
            }

            Test.stopTest();
        }
    }

    /**
     * Open the new git commit page from user story with variant dxCommit, flow not active
     */
    @IsTest static void gitCommitPageDXWithoutFlowNotActive() {
        User u = [SELECT Id,Name,LastName,Email,Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(u.Username), true, true, true, true, true);

        System.runAs(u) {
            // Create current sprint record
            tu.insertSObject('Sprint__c', new Map<String, Object>{
                    'Name' => 'Sprint 2',
                    'Start_Date__c' => Date.today().addDays(-8),
                    'End_Date__c' => Date.today().addDays(8)
            });

            // Create environments record
            tu.createSObject('Environment__c', new Map<String, Object>{
                    'Name' => 'Dev1',
                    'Type__c' => 'Scratch Org',
                    'org_id__c' => 'SFDC_OrgId'
            });
            tu.createSObject('Environment__c', new Map<String, Object>{
                    'Name' => 'Dev2',
                    'Type__c' => 'Scratch Org',
                    'org_id__c' => 'SFDC_OrgId2'
            });
            tu.createSObject('Environment__c', new Map<String, Object>{
                    'Name' => 'Int',
                    'Type__c' => 'Scratch Org',
                    'org_id__c' => 'SFDC_OrgId3'
            });
            tu.createSObject('Environment__c', new Map<String, Object>{
                    'Name' => 'UAT',
                    'Type__c' => 'Scratch Org',
                    'org_id__c' => 'SFDC_OrgId4'
            });
            tu.createSObject('Environment__c', new Map<String, Object>{
                    'Name' => 'Prod',
                    'Type__c' => 'Scratch Org',
                    'org_id__c' => 'SFDC_OrgId5'
            });
            insert new List<SObject>{
                    tu.item('Environment__c', 0), tu.item('Environment__c', 1), tu.item('Environment__c', 2), tu.item('Environment__c', 3), tu.item('Environment__c', 4)
            };

            // Create org credentials record
            tu.createSObject('Org__c', new Map<String, Object>{
                    'Name' => 'OrgDev1',
                    'Org_Type__c' => 'Scratch Org',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 0).Id
            });
            tu.createSObject('Org__c', new Map<String, Object>{
                    'Name' => 'OrgDev2',
                    'Org_Type__c' => 'Scratch Org',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId2',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 1).Id
            });
            tu.createSObject('Org__c', new Map<String, Object>{
                    'Name' => 'OrgInt',
                    'Org_Type__c' => 'Scratch Org',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId3',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Default_Credential__c' => true,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 2).Id
            });
            tu.createSObject('Org__c', new Map<String, Object>{
                    'Name' => 'OrgUAT',
                    'Org_Type__c' => 'Scratch Org',
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
                    'Active__c' => false
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

            // Create 3 user story to fill sobjectlist
            tu.insertSObjects('User_Story__c', 3, new Map<String, Object>{
                    'User_Story_Title__c' => 'us-0000000',
                    'Status__c' => 'Approved',
                    'Sprint__c' => tu.item('Sprint__c', 0).Id,
                    'Story_Points_SFDC__c' => 2,
                    'Project__c' => tu.item('Project__c', 0).Id,
                    'Environment__c' => tu.item('Environment__c', 0).Id,
                    'Org_Credential__c' => tu.item('Org__c', 0).Id,
                    'Metadata_Types_in_Selection__c' => 'ApexClass'
            });

            Test.startTest();
            PageReference pReference = Page.GitCommitMain;
            pReference.getParameters().put('userStoryId', tu.item('User_Story__c', 0).Id);
            pReference.getParameters().put('variant', 'dxcommit');
            Test.setCurrentPage(pReference);

            GitCommit_MainPageController controller = new GitCommit_MainPageController();
            System.assertEquals(1, controller.pageMessagesMap.size());

            for(String severity : controller.pageMessagesMap.keySet()) {
                System.assertEquals('error', severity);
                System.assertEquals(1, controller.pageMessagesMap.get(severity).size());
                for(Object obj : controller.pageMessagesMap.get(severity)) {
                    System.assertEquals(Label.PROMOTION_FLOW_INACTIVE, obj);
                }
            }

            Test.stopTest();
        }
    }

    /**
     * Open the new git commit page from user story with variant dxCommit, blocked commit
     */
    @IsTest static void gitCommitPageDXBlockedCommit() {
        User u = [SELECT Id,Name,LastName,Email,Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(u.Username), true, true, true, true, true);

        System.runAs(u) {
            // Create current sprint record
            tu.insertSObject('Sprint__c', new Map<String, Object>{
                    'Name' => 'Sprint 2',
                    'Start_Date__c' => Date.today().addDays(-8),
                    'End_Date__c' => Date.today().addDays(8)
            });

            // Create environments record
            tu.createSObject('Environment__c', new Map<String, Object>{
                    'Name' => 'Dev1',
                    'Type__c' => 'Scratch Org',
                    'org_id__c' => 'SFDC_OrgId'
            });
            tu.createSObject('Environment__c', new Map<String, Object>{
                    'Name' => 'Dev2',
                    'Type__c' => 'Scratch Org',
                    'org_id__c' => 'SFDC_OrgId2'
            });
            tu.createSObject('Environment__c', new Map<String, Object>{
                    'Name' => 'Int',
                    'Type__c' => 'Scratch Org',
                    'org_id__c' => 'SFDC_OrgId3'
            });
            tu.createSObject('Environment__c', new Map<String, Object>{
                    'Name' => 'UAT',
                    'Type__c' => 'Scratch Org',
                    'org_id__c' => 'SFDC_OrgId4'
            });
            tu.createSObject('Environment__c', new Map<String, Object>{
                    'Name' => 'Prod',
                    'Type__c' => 'Scratch Org',
                    'org_id__c' => 'SFDC_OrgId5'
            });
            insert new List<SObject>{
                    tu.item('Environment__c', 0), tu.item('Environment__c', 1), tu.item('Environment__c', 2), tu.item('Environment__c', 3), tu.item('Environment__c', 4)
            };

            // Create org credentials record
            tu.createSObject('Org__c', new Map<String, Object>{
                    'Name' => 'OrgDev1',
                    'Org_Type__c' => 'Scratch Org',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 0).Id
            });
            tu.createSObject('Org__c', new Map<String, Object>{
                    'Name' => 'OrgDev2',
                    'Org_Type__c' => 'Scratch Org',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId2',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 1).Id
            });
            tu.createSObject('Org__c', new Map<String, Object>{
                    'Name' => 'OrgInt',
                    'Org_Type__c' => 'Scratch Org',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId3',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Default_Credential__c' => true,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 2).Id
            });
            tu.createSObject('Org__c', new Map<String, Object>{
                    'Name' => 'OrgUAT',
                    'Org_Type__c' => 'Scratch Org',
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
                    'Active__c' => true,
                    'Block_Commits__c' => true
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

            // Create 3 user story to fill sobjectlist
            tu.insertSObjects('User_Story__c', 3, new Map<String, Object>{
                    'User_Story_Title__c' => 'us-0000000',
                    'Status__c' => 'Approved',
                    'Sprint__c' => tu.item('Sprint__c', 0).Id,
                    'Story_Points_SFDC__c' => 2,
                    'Project__c' => tu.item('Project__c', 0).Id,
                    'Environment__c' => tu.item('Environment__c', 0).Id,
                    'Org_Credential__c' => tu.item('Org__c', 0).Id,
                    'Metadata_Types_in_Selection__c' => 'ApexClass'
            });

            Test.startTest();
            PageReference pReference = Page.GitCommitMain;
            pReference.getParameters().put('userStoryId', tu.item('User_Story__c', 0).Id);
            pReference.getParameters().put('variant', 'dxcommit');
            Test.setCurrentPage(pReference);

            GitCommit_MainPageController controller = new GitCommit_MainPageController();
            System.assertEquals(1, controller.pageMessagesMap.size());

            for(String severity : controller.pageMessagesMap.keySet()) {
                System.assertEquals('error', severity);
                System.assertEquals(1, controller.pageMessagesMap.get(severity).size());
                for(Object obj : controller.pageMessagesMap.get(severity)) {
                    System.assertEquals(Label.DEPLOYMENT_FLOW_COMMITS_BLOCKED, obj);
                }
            }

            Test.stopTest();
        }
    }

    /**
     * Open the new git commit page from user story with variant dxCommit, dx has not default target
     */
    @IsTest static void gitCommitPageDXWithoutDefaultTarget() {
        User u = [SELECT Id,Name,LastName,Email,Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(u.Username), true, true, true, true, true);

        System.runAs(u) {
            // Create current sprint record
            tu.insertSObject('Sprint__c', new Map<String, Object>{
                    'Name' => 'Sprint 2',
                    'Start_Date__c' => Date.today().addDays(-8),
                    'End_Date__c' => Date.today().addDays(8)
            });

            // Create environments record
            tu.createSObject('Environment__c', new Map<String, Object>{
                    'Name' => 'Dev1',
                    'Type__c' => 'Scratch Org',
                    'org_id__c' => 'SFDC_OrgId'
            });
            tu.createSObject('Environment__c', new Map<String, Object>{
                    'Name' => 'Dev2',
                    'Type__c' => 'Scratch Org',
                    'org_id__c' => 'SFDC_OrgId2'
            });
            tu.createSObject('Environment__c', new Map<String, Object>{
                    'Name' => 'Int',
                    'Type__c' => 'Scratch Org',
                    'org_id__c' => 'SFDC_OrgId3'
            });
            tu.createSObject('Environment__c', new Map<String, Object>{
                    'Name' => 'UAT',
                    'Type__c' => 'Scratch Org',
                    'org_id__c' => 'SFDC_OrgId4'
            });
            tu.createSObject('Environment__c', new Map<String, Object>{
                    'Name' => 'Prod',
                    'Type__c' => 'Scratch Org',
                    'org_id__c' => 'SFDC_OrgId5'
            });
            insert new List<SObject>{
                    tu.item('Environment__c', 0), tu.item('Environment__c', 1), tu.item('Environment__c', 2), tu.item('Environment__c', 3), tu.item('Environment__c', 4)
            };

            // Create org credentials record
            tu.createSObject('Org__c', new Map<String, Object>{
                    'Name' => 'OrgDev1',
                    'Org_Type__c' => 'Scratch Org',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 0).Id
            });
            tu.createSObject('Org__c', new Map<String, Object>{
                    'Name' => 'OrgDev2',
                    'Org_Type__c' => 'Scratch Org',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId2',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 1).Id
            });
            tu.createSObject('Org__c', new Map<String, Object>{
                    'Name' => 'OrgInt',
                    'Org_Type__c' => 'Scratch Org',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId3',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Default_Credential__c' => true,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 2).Id
            });
            tu.createSObject('Org__c', new Map<String, Object>{
                    'Name' => 'OrgUAT',
                    'Org_Type__c' => 'Scratch Org',
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
                    'Active__c' => true,
                    'Enable_Copado_DX__c' => true
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

            // Create 3 user story to fill sobjectlist
            tu.insertSObjects('User_Story__c', 3, new Map<String, Object>{
                    'User_Story_Title__c' => 'us-0000000',
                    'Status__c' => 'Approved',
                    'Sprint__c' => tu.item('Sprint__c', 0).Id,
                    'Story_Points_SFDC__c' => 2,
                    'Project__c' => tu.item('Project__c', 0).Id,
                    'Environment__c' => tu.item('Environment__c', 0).Id,
                    'Org_Credential__c' => tu.item('Org__c', 0).Id,
                    'Metadata_Types_in_Selection__c' => 'ApexClass'
            });

            Test.startTest();
            PageReference pReference = Page.GitCommitMain;
            pReference.getParameters().put('userStoryId', tu.item('User_Story__c', 0).Id);
            pReference.getParameters().put('variant', 'dxcommit');
            Test.setCurrentPage(pReference);

            GitCommit_MainPageController controller = new GitCommit_MainPageController();
            System.assertEquals(1, controller.pageMessagesMap.size());

            for(String severity : controller.pageMessagesMap.keySet()) {
                System.assertEquals('error', severity);
                System.assertEquals(1, controller.pageMessagesMap.get(severity).size());
                for(Object obj : controller.pageMessagesMap.get(severity)) {
                    System.assertEquals(Label.DF_HAS_NO_DX_TARGET, obj);
                }
            }

            Test.stopTest();
        }
    }

    /**
     * Open the new git commit page from user story with variant dxCommit, no snapshot
     */
    @IsTest static void gitCommitPageDXWithoutSnapshot() {
        User u = [SELECT Id,Name,LastName,Email,Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(u.Username), true, true, true, true, true);

        System.runAs(u) {
            // Create current sprint record
            tu.insertSObject('Sprint__c', new Map<String, Object>{
                    'Name' => 'Sprint 2',
                    'Start_Date__c' => Date.today().addDays(-8),
                    'End_Date__c' => Date.today().addDays(8)
            });

            // Create environments record
            tu.createSObject('Environment__c', new Map<String, Object>{
                    'Name' => 'Dev1',
                    'Type__c' => 'Scratch Org',
                    'org_id__c' => 'SFDC_OrgId'
            });
            tu.createSObject('Environment__c', new Map<String, Object>{
                    'Name' => 'Dev2',
                    'Type__c' => 'Scratch Org',
                    'org_id__c' => 'SFDC_OrgId2'
            });
            tu.createSObject('Environment__c', new Map<String, Object>{
                    'Name' => 'Int',
                    'Type__c' => 'Scratch Org',
                    'org_id__c' => 'SFDC_OrgId3'
            });
            tu.createSObject('Environment__c', new Map<String, Object>{
                    'Name' => 'UAT',
                    'Type__c' => 'Scratch Org',
                    'org_id__c' => 'SFDC_OrgId4'
            });
            tu.createSObject('Environment__c', new Map<String, Object>{
                    'Name' => 'Prod',
                    'Type__c' => 'Scratch Org',
                    'org_id__c' => 'SFDC_OrgId5'
            });
            insert new List<SObject>{
                    tu.item('Environment__c', 0), tu.item('Environment__c', 1), tu.item('Environment__c', 2), tu.item('Environment__c', 3), tu.item('Environment__c', 4)
            };

            // Create org credentials record
            tu.createSObject('Org__c', new Map<String, Object>{
                    'Name' => 'OrgDev1',
                    'Org_Type__c' => 'Scratch Org',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 0).Id
            });
            tu.createSObject('Org__c', new Map<String, Object>{
                    'Name' => 'OrgDev2',
                    'Org_Type__c' => 'Scratch Org',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId2',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 1).Id
            });
            tu.createSObject('Org__c', new Map<String, Object>{
                    'Name' => 'OrgInt',
                    'Org_Type__c' => 'Scratch Org',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId3',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Default_Credential__c' => true,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 2).Id
            });
            tu.createSObject('Org__c', new Map<String, Object>{
                    'Name' => 'OrgUAT',
                    'Org_Type__c' => 'Scratch Org',
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
                    'Active__c' => true,
                    'Enable_Copado_DX__c' => true
            });

            // Create deployment flow steps record
            tu.createSObject('Deployment_Flow_Step__c', new Map<String, Object>{
                    'Source_Environment__c' => tu.item('Environment__c', 0).Id,
                    'Destination_Environment__c' => tu.item('Environment__c', 2).Id,
                    'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id,
                    'Enable_as_Scratch_Org_Destination__c' => 'Default DX Target'
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

            // Create 3 user story to fill sobjectlist
            tu.insertSObjects('User_Story__c', 3, new Map<String, Object>{
                    'User_Story_Title__c' => 'us-0000000',
                    'Status__c' => 'Approved',
                    'Sprint__c' => tu.item('Sprint__c', 0).Id,
                    'Story_Points_SFDC__c' => 2,
                    'Project__c' => tu.item('Project__c', 0).Id,
                    'Environment__c' => tu.item('Environment__c', 0).Id,
                    'Org_Credential__c' => tu.item('Org__c', 0).Id,
                    'Metadata_Types_in_Selection__c' => 'ApexClass'
            });

            Test.startTest();
            PageReference pReference = Page.GitCommitMain;
            pReference.getParameters().put('userStoryId', tu.item('User_Story__c', 0).Id);
            pReference.getParameters().put('variant', 'dxcommit');
            Test.setCurrentPage(pReference);

            GitCommit_MainPageController controller = new GitCommit_MainPageController();
            System.assertEquals(1, controller.pageMessagesMap.size());

            for(String severity : controller.pageMessagesMap.keySet()) {
                System.assertEquals('error', severity);
                System.assertEquals(1, controller.pageMessagesMap.get(severity).size());
                for(Object obj : controller.pageMessagesMap.get(severity)) {
                    System.assertEquals(Label.USER_STORY_COMMIT_NO_SNAPSHOT_FOUND, obj);
                }
            }

            Test.stopTest();
        }
    }

    /**
     * Open the new git commit page from user story with variant dxCommit, no snapshot, no metadata sources attachment
     */
    @IsTest static void gitCommitPageDXWithoutSnapshotAndAttachment() {
        User u = [SELECT Id,Name,LastName,Email,Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(u.Username), true, true, true, true, true);

        System.runAs(u) {
            // Create current sprint record
            tu.insertSObject('Sprint__c', new Map<String, Object>{
                    'Name' => 'Sprint 2',
                    'Start_Date__c' => Date.today().addDays(-8),
                    'End_Date__c' => Date.today().addDays(8)
            });

            // Create environments record
            tu.createSObject('Environment__c', new Map<String, Object>{
                    'Name' => 'Dev1',
                    'Type__c' => 'Scratch Org',
                    'org_id__c' => 'SFDC_OrgId'
            });
            tu.createSObject('Environment__c', new Map<String, Object>{
                    'Name' => 'Dev2',
                    'Type__c' => 'Scratch Org',
                    'org_id__c' => 'SFDC_OrgId2'
            });
            tu.createSObject('Environment__c', new Map<String, Object>{
                    'Name' => 'Int',
                    'Type__c' => 'Scratch Org',
                    'org_id__c' => 'SFDC_OrgId3'
            });
            tu.createSObject('Environment__c', new Map<String, Object>{
                    'Name' => 'UAT',
                    'Type__c' => 'Scratch Org',
                    'org_id__c' => 'SFDC_OrgId4'
            });
            tu.createSObject('Environment__c', new Map<String, Object>{
                    'Name' => 'Prod',
                    'Type__c' => 'Scratch Org',
                    'org_id__c' => 'SFDC_OrgId5'
            });
            insert new List<SObject>{
                    tu.item('Environment__c', 0), tu.item('Environment__c', 1), tu.item('Environment__c', 2), tu.item('Environment__c', 3), tu.item('Environment__c', 4)
            };

            // Create org credentials record
            tu.createSObject('Org__c', new Map<String, Object>{
                    'Name' => 'OrgDev1',
                    'Org_Type__c' => 'Scratch Org',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 0).Id
            });
            tu.createSObject('Org__c', new Map<String, Object>{
                    'Name' => 'OrgDev2',
                    'Org_Type__c' => 'Scratch Org',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId2',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 1).Id
            });
            tu.createSObject('Org__c', new Map<String, Object>{
                    'Name' => 'OrgInt',
                    'Org_Type__c' => 'Scratch Org',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId3',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Default_Credential__c' => true,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 2).Id
            });
            tu.createSObject('Org__c', new Map<String, Object>{
                    'Name' => 'OrgUAT',
                    'Org_Type__c' => 'Scratch Org',
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
                    'Active__c' => true,
                    'Enable_Copado_DX__c' => true
            });

            // Create deployment flow steps record
            tu.createSObject('Deployment_Flow_Step__c', new Map<String, Object>{
                    'Source_Environment__c' => tu.item('Environment__c', 0).Id,
                    'Destination_Environment__c' => tu.item('Environment__c', 2).Id,
                    'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id,
                    'Enable_as_Scratch_Org_Destination__c' => 'Default DX Target'
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

            // Create 3 user story to fill sobjectlist
            tu.insertSObjects('User_Story__c', 3, new Map<String, Object>{
                    'User_Story_Title__c' => 'us-0000000',
                    'Status__c' => 'Approved',
                    'Sprint__c' => tu.item('Sprint__c', 0).Id,
                    'Story_Points_SFDC__c' => 2,
                    'Project__c' => tu.item('Project__c', 0).Id,
                    'Environment__c' => tu.item('Environment__c', 0).Id,
                    'Org_Credential__c' => tu.item('Org__c', 0).Id,
                    'Metadata_Types_in_Selection__c' => 'ApexClass'
            });

            // Create attachment record
            tu.insertSObject('Attachment', new Map<String, Object>{
                    'Name' => DXLabel.METADATA_SOURCES,
                    'ParentId' => tu.item('Org__c', 0).Id,
                    'Body' => Blob.valueOf('{"isPatch":false,"projectBranchCreated":true}')
            });

            Test.startTest();
            PageReference pReference = Page.GitCommitMain;
            pReference.getParameters().put('userStoryId', tu.item('User_Story__c', 0).Id);
            pReference.getParameters().put('variant', 'dxcommit');
            Test.setCurrentPage(pReference);

            GitCommit_MainPageController controller = new GitCommit_MainPageController();
            System.assertEquals(1, controller.pageMessagesMap.size());

            for(String severity : controller.pageMessagesMap.keySet()) {
                System.assertEquals('error', severity);
                System.assertEquals(1, controller.pageMessagesMap.get(severity).size());
                for(Object obj : controller.pageMessagesMap.get(severity)) {
                    System.assertEquals(Label.USER_STORY_COMMIT_NO_SNAPSHOT_FOUND, obj);
                }
            }

            Test.stopTest();
        }
    }

    /**
     * Open the new git commit page from user story, operation parsing
     */
    @IsTest static void gitCommitPageUSOperationParsing() {
        User u = [SELECT Id,Name,LastName,Email,Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(u.Username), true, true, true, true, true);

        System.runAs(u) {
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
                    'Validated_Date__c' => System.now(),
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
                    'Default_Credential__c' => true,
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

            // Create 1 git repository
            tu.insertSObjects('Git_Repository__c', 1, new Map<String, Object>{
                    'Name' => 'test',
                    'URI__c' => 'http://www.test.uri'
            });

            // Create deployment flow record
            tu.insertSObject('Deployment_Flow__c', new Map<String, Object>{
                    'Name' => 'Deployment Flow',
                    'Active__c' => true,
                    'Git_Repository__c' => tu.item('Git_Repository__c', 0).Id
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

            // Create 3 user story to fill sobjectlist
            tu.insertSObjects('User_Story__c', 3, new Map<String, Object>{
                    'User_Story_Title__c' => 'us-0000000',
                    'Status__c' => 'Approved',
                    'Sprint__c' => tu.item('Sprint__c', 0).Id,
                    'Story_Points_SFDC__c' => 2,
                    'Project__c' => tu.item('Project__c', 0).Id,
                    'Environment__c' => tu.item('Environment__c', 0).Id,
                    'Org_Credential__c' => tu.item('Org__c', 0).Id,
                    'Metadata_Types_in_Selection__c' => 'ApexClass'
            });

            // Create 1 git backup
            tu.insertSObjects('Git_Backup__c', 1, new Map<String, Object>{
                    'Name' => 'backupname',
                    'Branch__c' => 'branchName',
                    'Frequency__c' => 'Daily',
                    'Git_Repository__c' => tu.item('Git_Repository__c', 0).Id,
                    'Org__c' => tu.item('Org__c', 0).Id
            });

            Test.startTest();
            PageReference pReference = Page.GitCommitMain;
            pReference.getParameters().put('userStoryId', tu.item('User_Story__c', 0).Id);
            pReference.getParameters().put('variant', 'userstorycommit');
            Test.setCurrentPage(pReference);

            String mockResponse = '{"Full Profiles & Permission Sets":{"tableSObject":null,"showUserStorySelections":null,"showTable":null,"showGrid":true,"showCommitMessage":true,"showAdvancedSection":true,"reloadGridData":null,"possibleRunningJob":"","pages":"GitSnapshotCommit,UserStoryCommit","operationType":"FullProfilePermissionSets","operationLabel":"Full Profiles & Permission Sets","operationFormElements":null,"operationButtonLabel":null,"helpText":"","helpLink":"https://docs.copado.com/git-operations/commit-full-profiles-and-permission-sets","gridMetadataTypes":"Profile,PermissionSet","endpoint":"commit","editGrid":null,"attachmentName":null},"Destructive Changes":{"tableSObject":null,"showUserStorySelections":null,"showTable":null,"showGrid":true,"showCommitMessage":true,"showAdvancedSection":true,"reloadGridData":true,"possibleRunningJob":",GitDeletion,{!snapshotId},true","pages":"GitSnapshotCommit,UserStoryCommit","operationType":"GitDeletion","operationLabel":"Destructive Changes","operationFormElements":[{"value":null,"type":"orgLookup","name":"orgId","label":"Org Credential","helpText":"If changed, the metadata grid will reload with the metadata items of the selected Org Credential.","boolValue":false}],"operationButtonLabel":"Commit Destructive Changes","helpText":"When deleting components, a table appears with a list of User Story Commits with status \'Complete\'. Select the commits you would like to undo and click Undo Commits. When the operation is finished, the status of the selected User Story Commits will be updated to \'Commit Undone\'.","helpLink":"https://docs.copado.com/git-operations/destructive-changes","gridMetadataTypes":null,"endpoint":"commit","editGrid":true,"attachmentName":"Git Deletion"},"Recommit Files":{"tableSObject":null,"showUserStorySelections":true,"showTable":null,"showGrid":true,"showCommitMessage":true,"showAdvancedSection":true,"reloadGridData":null,"possibleRunningJob":"","pages":"UserStoryCommit","operationType":"RecommitFiles","operationLabel":"Recommit Files","operationFormElements":[{"value":"","type":"checkbox","name":"recreateFeatureBranch","label":"Re-Create Feature Branch","helpText":"If checked, the existing feature branch will be deleted and the selected components in the grid will be committed in a new feature branch. Previous commits will not be present in the new feature branch. WARNING: Profiles and Permission Sets committed as full in this User Story will be recommitted as in the Commit Files operation. If you want them to be recommitted as full, you need to commit them again using the Full Profiles & Permission Sets git operation.","boolValue":false}],"operationButtonLabel":null,"helpText":"When recommitting files, the metadata grid appears with the existing user story selections. You can uncheck the selected components and also select new ones.","helpLink":"https://docs.copado.com/git-operations/recommit-files","gridMetadataTypes":null,"endpoint":"commit","editGrid":null,"attachmentName":null},"Commit Files":{"tableSObject":null,"showUserStorySelections":null,"showTable":null,"showGrid":true,"showCommitMessage":true,"showAdvancedSection":true,"reloadGridData":null,"possibleRunningJob":null,"pages":"GitSnapshotCommit,UserStoryCommit,DxCommit","operationType":"CommitFiles","operationLabel":"Commit Files","operationFormElements":null,"operationButtonLabel":null,"helpText":null,"helpLink":null,"gridMetadataTypes":null,"endpoint":"commit","editGrid":false,"attachmentName":null}}';
            MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', mockResponse, null);
            Test.setMock(HttpCalloutMock.class, fakeResponse);
            GitCommit_MainPageController controller = new GitCommit_MainPageController();
            System.assertEquals(1, controller.pageMessagesMap.size());

            for(String severity : controller.pageMessagesMap.keySet()) {
                System.assertEquals('error', severity);
                System.assertEquals(1, controller.pageMessagesMap.get(severity).size());
                for(Object obj : controller.pageMessagesMap.get(severity)) {
                    System.assertEquals(Label.Error_Parsing_Git_File, obj);
                }
            }

            Test.stopTest();
        }
    }

    /**
     * Open the new git commit page from user story with variant dxCommit, no environment
     */
    @IsTest static void gitCommitPageDXWithoutEnvironment() {
        User u = [SELECT Id,Name,LastName,Email,Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(u.Username), true, true, true, true, true);

        System.runAs(u) {
            // Create current sprint record
            tu.insertSObject('Sprint__c', new Map<String, Object>{
                    'Name' => 'Sprint 2',
                    'Start_Date__c' => Date.today().addDays(-8),
                    'End_Date__c' => Date.today().addDays(8)
            });

            // Create environments record
            tu.createSObject('Environment__c', new Map<String, Object>{
                    'Name' => 'Dev1',
                    'Type__c' => 'Scratch Org',
                    'org_id__c' => 'SFDC_OrgId'
            });
            tu.createSObject('Environment__c', new Map<String, Object>{
                    'Name' => 'Dev2',
                    'Type__c' => 'Scratch Org',
                    'org_id__c' => 'SFDC_OrgId2'
            });
            tu.createSObject('Environment__c', new Map<String, Object>{
                    'Name' => 'Int',
                    'Type__c' => 'Scratch Org',
                    'org_id__c' => 'SFDC_OrgId3'
            });
            tu.createSObject('Environment__c', new Map<String, Object>{
                    'Name' => 'UAT',
                    'Type__c' => 'Scratch Org',
                    'org_id__c' => 'SFDC_OrgId4'
            });
            tu.createSObject('Environment__c', new Map<String, Object>{
                    'Name' => 'Prod',
                    'Type__c' => 'Scratch Org',
                    'org_id__c' => 'SFDC_OrgId5'
            });
            insert new List<SObject>{
                    tu.item('Environment__c', 0), tu.item('Environment__c', 1), tu.item('Environment__c', 2), tu.item('Environment__c', 3), tu.item('Environment__c', 4)
            };

            // Create org credentials record
            tu.createSObject('Org__c', new Map<String, Object>{
                    'Name' => 'OrgDev1',
                    'Org_Type__c' => 'Scratch Org',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 0).Id
            });
            tu.createSObject('Org__c', new Map<String, Object>{
                    'Name' => 'OrgDev2',
                    'Org_Type__c' => 'Scratch Org',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId2',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 1).Id
            });
            tu.createSObject('Org__c', new Map<String, Object>{
                    'Name' => 'OrgInt',
                    'Org_Type__c' => 'Scratch Org',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId3',
                    'Token__c' => null,
                    'Username__c' => null,
                    'Default_Credential__c' => true,
                    'Validated_Date__c' => System.now(),
                    'Environment__c' => tu.item('Environment__c', 2).Id
            });
            tu.createSObject('Org__c', new Map<String, Object>{
                    'Name' => 'OrgUAT',
                    'Org_Type__c' => 'Scratch Org',
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
                    'Active__c' => false
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

            // Create 3 user story to fill sobjectlist
            tu.insertSObjects('User_Story__c', 3, new Map<String, Object>{
                    'User_Story_Title__c' => 'us-0000000',
                    'Status__c' => 'Approved',
                    'Sprint__c' => tu.item('Sprint__c', 0).Id,
                    'Story_Points_SFDC__c' => 2,
                    'Project__c' => tu.item('Project__c', 0).Id,
                    'Metadata_Types_in_Selection__c' => 'ApexClass'
            });

            Test.startTest();
            PageReference pReference = Page.GitCommitMain;
            pReference.getParameters().put('userStoryId', tu.item('User_Story__c', 0).Id);
            pReference.getParameters().put('variant', 'dxcommit');
            Test.setCurrentPage(pReference);

            GitCommit_MainPageController controller = new GitCommit_MainPageController();
            System.assertEquals(1, controller.pageMessagesMap.size());

            for(String severity : controller.pageMessagesMap.keySet()) {
                System.assertEquals('error', severity);
                System.assertEquals(1, controller.pageMessagesMap.get(severity).size());
                for(Object obj : controller.pageMessagesMap.get(severity)) {
                    System.assertEquals(Label.USER_STORY_COMMIT_NO_ENVIRONMENT, obj);
                }
            }

            Test.stopTest();
        }
    }
}