@IsTest
public with sharing class TestSprintVirtualWall {

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
        tu.insertSObject('User', new Map<String,Object>{
                'ProfileId' => [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
                'LastName' => 'LastName',
                'Email' => 'test2@test2.com',
                'Username' => 'puser000@amamama.com' + System.currentTimeMillis(),
                'CompanyName' => 'TEST',
                'Title' => 'title',
                'Alias' => 'alias',
                'TimeZoneSidKey' => 'America/Los_Angeles',
                'EmailEncodingKey' => 'UTF-8',
                'LanguageLocaleKey' => 'en_US',
                'LocaleSidKey' => 'en_US'
        });
        TestUtilities.enableLicenses(2, 2, 2, 2, 2);
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Copado_User'];
        insert new PermissionSetAssignment(AssigneeId = tu.item('User', 0).Id, PermissionSetId = ps.Id);
    }

	@IsTest static void sprintWallActualVelocityZero() {
        // Create user to assign as developer to the user stories
        User u = [SELECT Id,Name,LastName,Email,Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(u.Username), true, true, true, true, true);

		// Create current sprint record
		tu.insertSObject('Sprint__c', new Map<String,Object>{
				'Name' => 'Sprint 2',
				'Start_Date__c' => Date.today().addDays(-8),
				'End_Date__c' => Date.today().addDays(8)
		});

        List<SObject> insertSObjects = new List<SObject>();
        // Create 248 user story to fill sobjectlist
        insertSObjects.addAll(tu.createSObjects('User_Story__c', 248, new Map<String,Object>{
                'User_Story_Title__c' => 'us-0000000',
                'Status__c' => 'Approved',
                'Sprint__c' => tu.item('Sprint__c',0).get('Id'),
                'Story_Points_SFDC__c' => 2,
                'Developer__c' => u.Id
        }));

		// Create previous sprint record
        tu.insertSObject('Sprint__c', new Map<String,Object>{
				'Name' => 'Sprint 1',
				'Start_Date__c' => Date.today().addDays(-16),
				'End_Date__c' => Date.today().addDays(-8)
		});

        // Create 77 user story to previous sprint
        insertSObjects.addAll(tu.createSObjects('User_Story__c', 77, new Map<String,Object>{
                'User_Story_Title__c' => 'us-0000000',
                'Status__c' => 'In Progress',
                'Sprint__c' => tu.item('Sprint__c',1).get('Id'),
                'Story_Points_SFDC__c' => 3
        }));

		// Create next sprint record
        tu.insertSObject('Sprint__c', new Map<String,Object>{
				'Name' => 'Sprint 3',
				'Start_Date__c' => Date.today().addDays(8),
				'End_Date__c' => Date.today().addDays(16)
		});

        // Create 17 user story to next sprint
        insertSObjects.addAll(tu.createSObjects('User_Story__c', 17, new Map<String,Object>{
                'User_Story_Title__c' => 'us-0000000',
                'Status__c' => 'Completed',
                'Sprint__c' => tu.item('Sprint__c',2).get('Id'),
                'Story_Points_SFDC__c' => 4
        }));

        insert insertSObjects;

        System.runAs(u) {
            Test.startTest();
            Test.setCurrentPage(Page.SprintVirtualWall);
            ApexPages.StandardController sc = new ApexPages.StandardController(tu.item('Sprint__c', 0));
            SprintVirtualWall controller = new SprintVirtualWall(sc);

            // Check if the user story wrapper list size 200. Normally it has 248 us but limit is 200.
            System.assertEquals(controller.usWrapperList.size(), 200);

            // Pagination setup and check the expected values
            Boolean nextDisabled = controller.getDisableNext();
            System.assertEquals(nextDisabled, false);
            Boolean previousDisabled = controller.getDisablePrevious();
            System.assertEquals(previousDisabled, true);
            Integer pageNumber = controller.getPageNumber();
            System.assertEquals(pageNumber, 1);
            Integer totalPageNumber = controller.getTotalPages();
            System.assertEquals(totalPageNumber, 2);

            // Sprint setup and check the expected values
            String nextSprint = controller.getNextSprint();
            System.assertEquals(nextSprint, tu.item('Sprint__c', 2).get('Id'));
            String previousSprint = controller.getPreviousSprint();
            System.assertEquals(previousSprint, tu.item('Sprint__c', 1).get('Id'));

            // Velocity setup and check the expected values
            controller.getDaysLeftString();
            Map<String, Decimal> velocityMap = controller.getCalculatedVelocities();
            System.assertEquals(velocityMap.get('actual'), 0);
            System.assertEquals(velocityMap.get('planned'), 496);

            // Chatter setup and validation
            Boolean chatterEnabled = controller.getIsChatterEnabled();

            // Pagination process
            controller.next();
            controller.previous();
            controller.end();
            controller.beginning();

            // Filter values setup and apply filter
            ApexPages.currentPage().getParameters().put('pRenderer', 'usWithFilter');
            controller.pageRendererAssignment();
            controller.pickListValuesWrapperList[0].isSelected = true;
            controller.usDevWrapperList[0].isSelected = true;
            controller.rtValuesWrapperList[0].isSelected = true;
            controller.applyFilter();
            System.assertEquals(controller.usWrapperList.size(), 0); // Check if the user story wrapper list size 0. Selected filters should return empty list.
            controller.refreshTable();
            controller.pickListValuesWrapperList[0].isSelected = false;
            controller.usDevWrapperList[0].isSelected = false;
            controller.rtValuesWrapperList[0].isSelected = false;
            controller.applyFilter();
            System.assertEquals(controller.usWrapperList.size(), 200); // Check if the user story wrapper list size 200. Normally it has 248 us but limit is 200.

            // User story operations
            ApexPages.currentPage().getParameters().put('usId', String.valueOf(tu.item('User_Story__c', 2).get('Id')));
            controller.moveUsToNextSprint();
            ApexPages.currentPage().getParameters().put('usId', String.valueOf(tu.item('User_Story__c', 23).get('Id')));
            controller.removeSprintFromUs();
            System.assertEquals(controller.usWrapperList.size(), 200); // Check if the user story wrapper list size 200. Normally it has 246 us but limit is 200.


            // User Story Edit
            ApexPages.currentPage().getParameters().put('usId', String.valueOf(tu.item('User_Story__c', 5).get('Id')));
            ApexPages.currentPage().getParameters().put('mode', 'edit');
            controller.prepareUserStory();
            System.assertEquals(controller.us.Id, String.valueOf(tu.item('User_Story__c', 5).get('Id')));
            controller.userStoryUpdateOperation();

            // User Story Mass Update
            controller.usWrapperList[1].isSelected = true;
            controller.usWrapperList[12].isSelected = true;
            controller.usWrapperList[44].isSelected = true;
            controller.usWrapperList[77].isSelected = true;
            ApexPages.currentPage().getParameters().put('mode', 'massupdate');
            controller.prepareUserStory();
            controller.us.Developer__c = u.Id;
            controller.userStoryUpdateOperation();
            Test.stopTest();

            // New User Story
            ApexPages.currentPage().getParameters().put('mode', 'new');
            controller.prepareUserStory();
            controller.userStoryCreateOperation();
        }
	}

    @IsTest static void sprintWallActualVelocityNotZero() {
        // Create user to assign as developer to the user stories
        User u = [SELECT Id,Name,LastName,Email,Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(u.Username), true, true, true, true, true);

        // Create current sprint record
        tu.insertSObject('Sprint__c', new Map<String,Object>{
                'Name' => 'Sprint 2',
                'Start_Date__c' => Date.today().addDays(-8),
                'End_Date__c' => Date.today().addDays(8)
        });

        // Create 248 user story to fill sobjectlist
        tu.insertSObjects('User_Story__c', 248, new Map<String,Object>{
                'User_Story_Title__c' => 'us-0000000',
                'Status__c' => 'Approved',
                'Sprint__c' => tu.item('Sprint__c',0).get('Id'),
                'Story_Points_SFDC__c' => 2
        });

        // Create previous sprint record
        tu.insertSObject('Sprint__c', new Map<String,Object>{
                'Name' => 'Sprint 1',
                'Start_Date__c' => Date.today().addDays(-16),
                'End_Date__c' => Date.today().addDays(-8)
        });

        // Create attachment for sprint record to show burndown chart
        tu.insertSObject('Attachment', new Map<String,Object>{
                'Name' => 'BurnDownItem',
                'Body' => Blob.valueOf('[{"idealValue":47388.00,"dates":"2018-05-28","actualValue":42450.00},{"idealValue":23694.00,"dates":"2018-05-29","actualValue":32645.00},{"idealValue":0.00,"dates":"2018-05-30","actualValue":8476.00}]'),
                'ParentId' => tu.item('Sprint__c',1).get('Id')
        });

        // Create 77 user story to previous sprint
        tu.insertSObjects('User_Story__c', 77, new Map<String,Object>{
                'User_Story_Title__c' => 'us-0000000',
                'Status__c' => 'In Progress',
                'Sprint__c' => tu.item('Sprint__c',1).get('Id'),
                'Story_Points_SFDC__c' => 3
        });

        // Create next sprint record
        tu.insertSObject('Sprint__c', new Map<String,Object>{
                'Name' => 'Sprint 3',
                'Start_Date__c' => Date.today().addDays(8),
                'End_Date__c' => Date.today().addDays(16)
        });

        // Create 17 user story to next sprint
        tu.insertSObjects('User_Story__c', 17, new Map<String,Object>{
                'User_Story_Title__c' => 'us-0000000',
                'Status__c' => 'Completed',
                'Sprint__c' => tu.item('Sprint__c',2).get('Id'),
                'Story_Points_SFDC__c' => 4,
                'Developer__c' => u.Id
        });

        // Create 1 user story task to user story 340
        tu.insertSObjects('User_Story_Task__c', 17, new Map<String,Object>{
                'Status__c' => 'In Progress',
                'Subject__c' => 'Test',
                'Hours_Remaining__c' => 2,
                'User_Story__c' => tu.item('User_Story__c',340).get('Id')
        });

        // Create 8 burndownitem  for sprint
        tu.insertSObjects('Burndown_Item__c', 8, new Map<String,Object>{
                'Sprint__c' => tu.item('Sprint__c',2).get('Id'),
                'Date__c' => Date.today().addDays(8),
                'Expected_Story_Point__c' => 100,
                'Total_Story_Point__c' => 90
        });

        System.runAs(u) {
            Test.startTest();
            Test.setCurrentPage(Page.SprintVirtualWall);
            ApexPages.StandardController sc = new ApexPages.StandardController(tu.item('Sprint__c', 2));
            SprintVirtualWall controller = new SprintVirtualWall(sc);

            // Check if the user story wrapper list size 17.
            System.assertEquals(controller.usWrapperList.size(), 17);

            // Pagination setup and check the expected values
            Boolean nextDisabled = controller.getDisableNext();
            System.assertEquals(nextDisabled, true);
            Boolean previousDisabled = controller.getDisablePrevious();
            System.assertEquals(previousDisabled, true);
            Integer pageNumber = controller.getPageNumber();
            System.assertEquals(pageNumber, 1);
            Integer totalPageNumber = controller.getTotalPages();
            System.assertEquals(totalPageNumber, 1);

            // Sprint setup and check the expected values
            String nextSprint = controller.getNextSprint();
            System.assertEquals(nextSprint, '');
            String previousSprint = controller.getPreviousSprint();
            System.assertEquals(previousSprint, tu.item('Sprint__c', 0).get('Id'));

            // Velocity setup and check the expected values
            String daysLeft = controller.getDaysLeftString();
            System.assertEquals(daysLeft, 'NOT STARTED');
            Map<String, Decimal> velocityMap = controller.getCalculatedVelocities();
            System.assertEquals(velocityMap.get('actual'), 68);
            System.assertEquals(velocityMap.get('planned'), 68);

            // Sprint operations (Next sprint, Previous sprint)
            ApexPages.currentPage().getParameters().put('sprMode', 'previous');
            controller.goToStandardRecordView();
            ApexPages.currentPage().getParameters().put('sprMode', '');
            controller.goToStandardRecordView();

            // User story task operations
            ApexPages.currentPage().getParameters().put('pSwitcher', 'snippet');
            controller.pageSwithcerAssignment();
            ApexPages.currentPage().getParameters().put('usId', String.valueOf(tu.item('User_Story__c', 340).get('Id')));
            controller.prepareUserStoryTask();
            controller.userStoryTaskOperation();

            System.assertEquals('Not Started', controller.usTask.Status__c);

            // Edit user story task
            ApexPages.currentPage().getParameters().put('usId', String.valueOf(tu.item('User_Story__c', 340).get('Id')));
            ApexPages.currentPage().getParameters().put('usTaskId', String.valueOf(tu.item('User_Story_Task__c', 0).get('Id')));
            controller.prepareUserStoryTask();
            controller.userStoryTaskOperation();

            SprintVirtualWall.updateRecordsPicklistValue(String.valueOf(tu.item('User_Story_Task__c', 0).get('Id')), 'Completed');

            // Delete user story task
            String usTaskId = ApexPages.currentPage().getParameters().get('usTaskId');
            controller.userStoryTaskDeletion();

            // Check the burndown item chart
            controller.getData();
            Test.stopTest();
        }
    }

    @IsTest static void sprintWallBurnDownForClosedSprint() {
        // Create user to assign as developer to the user stories
        User u = [SELECT Id,Name,LastName,Email,Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(u.Username), true, true, true, true, true);

        // Create current sprint record
        tu.insertSObject('Sprint__c', new Map<String,Object>{
                'Name' => 'Sprint 2',
                'Start_Date__c' => Date.today().addDays(-8),
                'End_Date__c' => Date.today().addDays(8)
        });

        // Create 248 user story to fill sobjectlist
        tu.insertSObjects('User_Story__c', 248, new Map<String,Object>{
                'User_Story_Title__c' => 'us-0000000',
                'Status__c' => 'Approved',
                'Sprint__c' => tu.item('Sprint__c',0).get('Id'),
                'Story_Points_SFDC__c' => 2
        });

        // Create previous sprint record
        tu.insertSObject('Sprint__c', new Map<String,Object>{
                'Name' => 'Sprint 1',
                'Start_Date__c' => Date.today().addDays(-16),
                'End_Date__c' => Date.today().addDays(-8)
        });

        // Create attachment for sprint record to show burndown chart
        tu.insertSObject('Attachment', new Map<String,Object>{
                'Name' => 'BurnDownItems',
                'Body' => Blob.valueOf('[{"idealValue":47388.00,"dates":"2018-05-28","actualValue":42450.00},{"idealValue":23694.00,"dates":"2018-05-29","actualValue":32645.00},{"idealValue":0.00,"dates":"2018-05-30","actualValue":8476.00}]'),
                'ParentId' => tu.item('Sprint__c',1).get('Id')
        });

        // Create 77 user story to previous sprint
        tu.insertSObjects('User_Story__c', 77, new Map<String,Object>{
                'User_Story_Title__c' => 'us-0000000',
                'Status__c' => 'In Progress',
                'Sprint__c' => tu.item('Sprint__c',1).get('Id'),
                'Story_Points_SFDC__c' => 3
        });

        System.runAs(u) {
            Test.startTest();
            Test.setCurrentPage(Page.SprintVirtualWall);
            ApexPages.StandardController sc = new ApexPages.StandardController(tu.item('Sprint__c', 1));
            SprintVirtualWall controller = new SprintVirtualWall(sc);

            // Check if the user story wrapper list size 77.
            System.assertEquals(controller.usWrapperList.size(), 77);

            // Check the burndown item chart
            controller.getData();
            Test.stopTest();
        }
    }

    @IsTest static void sprintWallMassUpdate() {
        // Create user to assign as developer to the user stories
        User u = [SELECT Id,Name,LastName,Email,Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        User u1 = [SELECT Id,Name,LastName,Email,Username FROM User WHERE Email = 'test2@test2.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(u.Username), true, true, true, true, true);

        // Create current sprint record
        tu.insertSObject('Sprint__c', new Map<String,Object>{
                'Name' => 'Sprint 2',
                'Start_Date__c' => Date.today().addDays(-8),
                'End_Date__c' => Date.today().addDays(8)
        });

        // Create 248 user story to fill sobjectlist
        tu.insertSObjects('User_Story__c', 248, new Map<String,Object>{
                'User_Story_Title__c' => 'us-0000000',
                'Status__c' => 'Approved',
                'Sprint__c' => tu.item('Sprint__c',0).Id,
                'Story_Points_SFDC__c' => 2,
                'Developer__c' => u.Id
        });

        // Create previous sprint record
        tu.insertSObject('Sprint__c', new Map<String,Object>{
                'Name' => 'Sprint 1',
                'Start_Date__c' => Date.today().addDays(-16),
                'End_Date__c' => Date.today().addDays(-8)
        });

        // Create 77 user story to previous sprint
        tu.insertSObjects('User_Story__c', 77, new Map<String,Object>{
                'User_Story_Title__c' => 'us-0000000',
                'Status__c' => 'In Progress',
                'Sprint__c' => tu.item('Sprint__c',1).Id,
                'Story_Points_SFDC__c' => 3
        });

        // Create next sprint record
        tu.insertSObject('Sprint__c', new Map<String,Object>{
                'Name' => 'Sprint 3',
                'Start_Date__c' => Date.today().addDays(8),
                'End_Date__c' => Date.today().addDays(16)
        });

        // Create 17 user story to next sprint
        tu.insertSObjects('User_Story__c', 17, new Map<String,Object>{
                'User_Story_Title__c' => 'us-0000000',
                'Status__c' => 'Completed',
                'Sprint__c' => tu.item('Sprint__c',2).Id,
                'Story_Points_SFDC__c' => 4
        });

        System.runAs(u) {
            Test.startTest();
            Test.setCurrentPage(Page.SprintVirtualWall);
            ApexPages.StandardController sc = new ApexPages.StandardController(tu.item('Sprint__c', 0));
            SprintVirtualWall controller = new SprintVirtualWall(sc);

            // Check if the user story wrapper list size 200. Normally it has 248 us but limit is 200.
            System.assertEquals(controller.usWrapperList.size(), 200);

            // User Story Mass Update
            for(Integer i=0; i<200; i++){
                controller.usWrapperList[i].isSelected = true;
            }
            ApexPages.currentPage().getParameters().put('mode', 'massupdate');
            controller.prepareUserStory();
            System.assertEquals(controller.usWrapperList[55].userStory.Developer__c, String.valueOf(u.Id));
            controller.us.Developer__c = u1.Id;
            controller.userStoryUpdateOperation();
            System.assertEquals(controller.usWrapperList[55].userStory.Developer__c, String.valueOf(u1.Id));
            Test.stopTest();
        }
    }

    @IsTest static void completeSprintSplitAndMove() {
        // Create user to assign as developer to the user stories
        User u = [SELECT Id,Name,LastName,Email,Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(u.Username), true, true, true, true, true);

        // Create current sprint record
        tu.insertSObject('Sprint__c', new Map<String,Object>{
                'Name' => 'Sprint 2',
                'Start_Date__c' => Date.today().addDays(-8),
                'End_Date__c' => Date.today().addDays(8)
        });

        // Create 8 user story to fill sobjectlist
        tu.insertSObjects('User_Story__c', 8, new Map<String,Object>{
                'User_Story_Title__c' => 'us-0000000',
                'Status__c' => 'In Progress',
                'Sprint__c' => tu.item('Sprint__c',0).Id,
                'Story_Points_SFDC__c' => 2,
                'Developer__c' => u.Id
        });

        // Create 8 user story to fill sobjectlist
        tu.insertSObjects('User_Story__c', 8, new Map<String,Object>{
                'User_Story_Title__c' => 'us-0000000',
                'Status__c' => 'In Progress',
                'Sprint__c' => tu.item('Sprint__c',0).Id,
                'Story_Points_SFDC__c' => 2,
                'Developer__c' => u.Id,
                'Progress__c' => 60
        });

        // Create 18 user story to fill sobjectlist
        tu.insertSObjects('User_Story__c', 18, new Map<String,Object>{
                'User_Story_Title__c' => 'us-0000000',
                'Status__c' => 'Completed',
                'Sprint__c' => tu.item('Sprint__c',0).Id,
                'Story_Points_SFDC__c' => 2,
                'Developer__c' => u.Id
        });

        // Create next sprint record
        tu.insertSObject('Sprint__c', new Map<String,Object>{
                'Name' => 'Sprint 3',
                'Start_Date__c' => Date.today().addDays(8),
                'End_Date__c' => Date.today().addDays(16)
        });

        // Create 17 user story to next sprint
        tu.insertSObjects('User_Story__c', 17, new Map<String,Object>{
                'User_Story_Title__c' => 'us-0000000',
                'Status__c' => 'Completed',
                'Sprint__c' => tu.item('Sprint__c',1).Id,
                'Story_Points_SFDC__c' => 4
        });

        System.runAs(u) {
            Test.startTest();
            Test.setCurrentPage(Page.SprintVirtualWall);
            ApexPages.StandardController sc = new ApexPages.StandardController(tu.item('Sprint__c', 0));
            SprintVirtualWall controller = new SprintVirtualWall(sc);

            // Check if the user story wrapper list size 26.
            System.assertEquals(controller.usWrapperList.size(), 34);

            // Populate modal values
            Integer completedUs = controller.getCompletedUsNumber();
            System.assertEquals(18, completedUs);
            Integer inCompletedUs = controller.getInCompletedUsNumber();
            System.assertEquals(16, inCompletedUs);
            List<SelectOption> optList = controller.getSprintCompleteOptions();
            System.assertEquals(optList.size(), 3);

            // complete sprint and check the number based on status
            controller.selectedSprintCompleteOption = 'splitmove';
            controller.completeSprint();
            Integer newCompletedUs = controller.getCompletedUsNumber();
            System.assertEquals(26, newCompletedUs);

            Test.stopTest();
        }
    }

    @IsTest static void completeSprintBacklog() {
        // Create user to assign as developer to the user stories
        User u = [SELECT Id,Name,LastName,Email,Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(u.Username), true, true, true, true, true);

        // Create current sprint record
        tu.insertSObject('Sprint__c', new Map<String,Object>{
                'Name' => 'Sprint 2',
                'Start_Date__c' => Date.today().addDays(-8),
                'End_Date__c' => Date.today().addDays(8)
        });

        // Create 8 user story to fill sobjectlist
        tu.insertSObjects('User_Story__c', 8, new Map<String,Object>{
                'User_Story_Title__c' => 'us-0000000',
                'Status__c' => 'In Progress',
                'Sprint__c' => tu.item('Sprint__c',0).Id,
                'Story_Points_SFDC__c' => 2,
                'Developer__c' => u.Id
        });

        // Create 18 user story to fill sobjectlist
        tu.insertSObjects('User_Story__c', 18, new Map<String,Object>{
                'User_Story_Title__c' => 'us-0000000',
                'Status__c' => 'Completed',
                'Sprint__c' => tu.item('Sprint__c',0).Id,
                'Story_Points_SFDC__c' => 2,
                'Developer__c' => u.Id
        });

        System.runAs(u) {
            Test.startTest();
            Test.setCurrentPage(Page.SprintVirtualWall);
            ApexPages.StandardController sc = new ApexPages.StandardController(tu.item('Sprint__c', 0));
            SprintVirtualWall controller = new SprintVirtualWall(sc);

            // Check if the user story wrapper list size 26.
            System.assertEquals(controller.usWrapperList.size(), 26);

            // Populate modal values
            Integer completedUs = controller.getCompletedUsNumber();
            System.assertEquals(completedUs, 18);
            Integer inCompletedUs = controller.getInCompletedUsNumber();
            System.assertEquals(inCompletedUs, 8);
            List<SelectOption> optList = controller.getSprintCompleteOptions();
            System.assertEquals(optList.size(), 1);

            // complete sprint and check the number based on status
            controller.selectedSprintCompleteOption = 'backlog';
            controller.completeSprint();
            Integer newCompletedUs = controller.getCompletedUsNumber();
            System.assertEquals(newCompletedUs, 18);

            Test.stopTest();
        }
    }

    @IsTest static void completeSprintNextSprint() {
        // Create user to assign as developer to the user stories
        User u = [SELECT Id,Name,LastName,Email,Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(u.Username), true, true, true, true, true);

        // Create current sprint record
        tu.insertSObject('Sprint__c', new Map<String,Object>{
                'Name' => 'Sprint 2',
                'Start_Date__c' => Date.today().addDays(-8),
                'End_Date__c' => Date.today().addDays(8)
        });

        // Create 8 user story to fill sobjectlist
        tu.insertSObjects('User_Story__c', 8, new Map<String,Object>{
                'User_Story_Title__c' => 'us-0000000',
                'Status__c' => 'In Progress',
                'Sprint__c' => tu.item('Sprint__c',0).Id,
                'Story_Points_SFDC__c' => 2,
                'Developer__c' => u.Id
        });

        // Create 18 user story to fill sobjectlist
        tu.insertSObjects('User_Story__c', 18, new Map<String,Object>{
                'User_Story_Title__c' => 'us-0000000',
                'Status__c' => 'Completed',
                'Sprint__c' => tu.item('Sprint__c',0).Id,
                'Story_Points_SFDC__c' => 2,
                'Developer__c' => u.Id
        });

        // Create next sprint record
        tu.insertSObject('Sprint__c', new Map<String,Object>{
                'Name' => 'Sprint 3',
                'Start_Date__c' => Date.today().addDays(8),
                'End_Date__c' => Date.today().addDays(16)
        });

        // Create 17 user story to next sprint
        tu.insertSObjects('User_Story__c', 17, new Map<String,Object>{
                'User_Story_Title__c' => 'us-0000000',
                'Status__c' => 'Completed',
                'Sprint__c' => tu.item('Sprint__c',1).Id,
                'Story_Points_SFDC__c' => 4
        });

        System.runAs(u) {
            Test.startTest();
            Test.setCurrentPage(Page.SprintVirtualWall);
            ApexPages.StandardController sc = new ApexPages.StandardController(tu.item('Sprint__c', 0));
            SprintVirtualWall controller = new SprintVirtualWall(sc);

            // Check if the user story wrapper list size 26.
            System.assertEquals(controller.usWrapperList.size(), 26);

            // Populate modal values
            Integer completedUs = controller.getCompletedUsNumber();
            System.assertEquals(completedUs, 18);
            Integer inCompletedUs = controller.getInCompletedUsNumber();
            System.assertEquals(inCompletedUs, 8);
            List<SelectOption> optList = controller.getSprintCompleteOptions();
            System.assertEquals(optList.size(), 3);

            // complete sprint and check the number based on status
            controller.selectedSprintCompleteOption = 'nextsprint';
            controller.completeSprint();
            Integer newCompletedUs = controller.getCompletedUsNumber();
            System.assertEquals(newCompletedUs, 18);

            Test.stopTest();
        }
    }

    @IsTest static void sprintWallKanbanBoard() {
        // Create user to assign as developer to the user stories
        User u = [SELECT Id,Name,LastName,Email,Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(u.Username), true, true, true, true, true);

        // Create current sprint record
        tu.insertSObject('Sprint__c', new Map<String,Object>{
                'Name' => 'Sprint 2',
                'Start_Date__c' => Date.today().addDays(-8),
                'End_Date__c' => Date.today().addDays(8)
        });

        // Create 8 user story to fill sobjectlist
        tu.insertSObjects('User_Story__c', 8, new Map<String,Object>{
                'User_Story_Title__c' => 'us-0000000',
                'Status__c' => 'Approved',
                'Sprint__c' => tu.item('Sprint__c',0).Id,
                'Story_Points_SFDC__c' => 2,
                'Developer__c' => u.Id
        });

        System.runAs(u) {
            Test.startTest();
            Test.setCurrentPage(Page.SprintVirtualWall);
            ApexPages.StandardController sc = new ApexPages.StandardController(tu.item('Sprint__c', 0));
            SprintVirtualWall controller = new SprintVirtualWall(sc);

            // Check if the user story wrapper list size 8.
            System.assertEquals(controller.usWrapperList.size(), 8);

            controller.kanbanBoardOperations();
            Test.stopTest();
        }
    }

    @IsTest static void sprintWallOrder() {
        // Create user to assign as developer to the user stories
        User u = [SELECT Id,Name,LastName,Email,Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(u.Username), true, true, true, true, true);

        // Create current sprint record
        tu.insertSObject('Sprint__c', new Map<String,Object>{
                'Name' => 'Sprint 2',
                'Start_Date__c' => Date.today().addDays(-8),
                'End_Date__c' => Date.today().addDays(8)
        });

        // Create 8 user story to fill sobjectlist
        tu.insertSObjects('User_Story__c', 8, new Map<String,Object>{
                'User_Story_Title__c' => 'us-0000000',
                'Status__c' => 'Approved',
                'Sprint__c' => tu.item('Sprint__c',0).Id,
                'Story_Points_SFDC__c' => 2,
                'Developer__c' => u.Id
        });

        System.runAs(u) {
            Test.startTest();
            Test.setCurrentPage(Page.SprintVirtualWall);
            ApexPages.StandardController sc = new ApexPages.StandardController(tu.item('Sprint__c', 0));
            SprintVirtualWall controller = new SprintVirtualWall(sc);

            // Check if the user story wrapper list size 8.
            System.assertEquals(controller.usWrapperList.size(), 8);

            ApexPages.currentPage().getParameters().put('newUSOrder', '[2,3,4,1]');
            ApexPages.currentPage().getParameters().put('oldUSOrder', '[1,2,3,4]');
            controller.updateUSOrder();
            Test.stopTest();
        }
    }
}