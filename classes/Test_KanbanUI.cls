@IsTest
public with sharing class Test_KanbanUI {
    private static String namespace = Settings.ns;

    @TestSetup
    static void setupData() {
        List<User> userList = TestDataFactory.createUsers();
        TestUtilities.enableLicenses(2, 2, 2, 2, 2, 2);
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Copado_User'];
        insert new PermissionSetAssignment(AssigneeId = userList[0].Id, PermissionSetId = ps.Id);
    }

    // testing kanban for user story object with sprint field as a column. Edit the kanban record
    @IsTest
    static void userStorySprintKanbanUI() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true, true);

        String soqlQuery =
            'SELECT Id,OwnerId,Name,CreatedDate,' +
            namespace +
            'Apex_Code_Coverage__c,' +
            namespace +
            'Developer__c,' +
            namespace +
            'Environment__c,' +
            namespace +
            'Priority__c,' +
            namespace +
            'Sprint__c,' +
            namespace +
            'Status__c,' +
            namespace +
            'Total_Story_Points__c,' +
            namespace +
            'User_Story_Title__c,' +
            namespace +
            'Progress_Status__c,' +
            namespace +
            'Progress__c,' +
            namespace +
            'Sprint__r.Name,' +
            namespace +
            'Story_Points_SFDC__c FROM ' +
            namespace +
            'user_story__c WHERE Name LIKE \'us-%\' ORDER BY CreatedDate ASC NULLS LAST LIMIT 150';

        String jsonSetting =
            '{"queryWrapper":{"wholeSoql":"' +
            soqlQuery +
            '",' +
            '"viewName":"User Story",' +
            '"userImageField":"' +
            namespace +
            'Developer__c",' +
            '"summarizeByList":[{"order":1,"operatorName":"Average","fieldName":"' +
            namespace +
            'Apex_Code_Coverage__c"},{"order":2,"operatorName":"Sum","fieldName":"' +
            namespace +
            'Total_Story_Points__c"},{"order":3,"operatorName":"Min","fieldName":"' +
            namespace +
            'Progress__c"},{"order":4,"operatorName":"Max","fieldName":"' +
            namespace +
            'Story_Points_SFDC__c"}],' +
            '"sobjectTypeName":"' +
            namespace +
            'user_story__c",' +
            '"selectedFooterFields":["' +
            namespace +
            'Progress_Status__c"],' +
            '"selectedFields":["Id","OwnerId","Name","CreatedDate","' +
            namespace +
            'Apex_Code_Coverage__c","' +
            namespace +
            'Developer__c","' +
            namespace +
            'Environment__c","' +
            namespace +
            'Priority__c","' +
            namespace +
            'Sprint__c","' +
            namespace +
            'Status__c","' +
            namespace +
            'Total_Story_Points__c","' +
            namespace +
            'User_Story_Title__c","' +
            namespace +
            'Progress_Status__c","' +
            namespace +
            'Progress__c","' +
            namespace +
            'Sprint__r.Name","' +
            namespace +
            'Story_Points_SFDC__c"],' +
            '"queryLimit":"150",' +
            '"orderedIn":"ASC",' +
            '"orderByList":["CreatedDate"],' +
            '"nullValues":"NULLS LAST",' +
            '"kanbanDescription":"This kanban is created to check status of the user stories which are not promoted yet. It will only show first 150 records.",' +
            '"headerField":"' +
            namespace +
            'User_Story_Title__c",' +
            '"filterLogic":"",' +
            '"fieldToReadUpdate":"' +
            namespace +
            'Sprint__c",' +
            '"enableFilterLogic":false,' +
            '"criteriaList":[{"order":1,"operatorSet":null,"operator":"s","input":"us-","fieldType":"STRING","fieldName":"Name","dateTimeInput":null,"dateInput":null}],' +
            '"colorField":"' +
            namespace +
            'Developer__c"},' +
            '"queryJson":""}';

        // Create kanban record to use it in the page
        // Note: user_story__c.Sprint__c is referece type. Only reference conditions will be covered
        Kanban_Board__c kanbanBoardRecord = new Kanban_Board__c();
        kanbanBoardRecord.Name = 'User Story Kanban';
        kanbanBoardRecord.SOQL_Query__c = soqlQuery;
        kanbanBoardRecord.Field_to_read_update__c = namespace + 'user_story__c.' + namespace + 'Sprint__c';
        kanbanBoardRecord.Description__c = 'This kanban is created to check status of the user stories which are not promoted yet. It will only show first 150 records.';
        kanbanBoardRecord.Columns_SOQL__c = '';
        kanbanBoardRecord.JSON_Settings__c = jsonSetting;
        insert kanbanBoardRecord;

        // Create Sprint to populate on user stories
        Sprint__c sprint = new Sprint__c();
        sprint.Name = 'Sprint 1';
        sprint.Status__c = 'In Progress';
        insert sprint;

        // Create 200 user story to fill sobjectlist
        List<User_Story__c> userStoryList = new List<User_Story__c>();
        for (integer i = 0; i < 200; i++) {
            User_Story__c userStory = new User_Story__c();
            userStory.User_Story_Title__c = 'us-000000' + i;
            userStory.Sprint__c = sprint.Id;

            userStoryList.add(userStory);
        }
        insert userStoryList;

        System.runAs(sysUser) {
            // Use the PageReference Apex class to instantiate a page
            PageReference pageRef = Page.KanbanBoardView;
            Test.setCurrentPage(pageRef);
            ApexPages.StandardController sc = new ApexPages.StandardController(kanbanBoardRecord);
            KanbanBoard controller = new KanbanBoard(sc);

            // Checking the list size. 150 user stories should be in the list
            System.assertEquals(150, controller.cardDetailsMap.size());

            controller.getKanbanViews();

            // Checking the list size of kanban views. 1 record should be in the list. Only default one.
            System.assertEquals(1, controller.getKanbanViews().size());

            // Editing the kanban view
            ApexPages.currentPage().getParameters().put('kanbanView', 'Edit');
            controller.kanbanViewsActions();
            QueryEditorController componentController = new QueryEditorController();
            componentController.compMode = 'Edit';
            componentController.qEditor = controller.qEditor;

            componentController.objectNameValidation();

            // Checking the criteria list before adding new line item
            System.assertEquals(1, componentController.qEditor.queryWrapper.criteriaList.size());
            componentController.addNewCriteria();
            componentController.addNewCriteria();
            System.assertEquals(3, componentController.qEditor.queryWrapper.criteriaList.size());
            componentController.removeCriteria();
            System.assertEquals(2, componentController.qEditor.queryWrapper.criteriaList.size());

            // Populate possible options. Actual value should be 3. (none,asc,desc) for Ordered In. Populate possible options at Null Values. Actual value should be 3 (none,nulls first,nulls last) for null values
            componentController.getAllFieldsAPINameMultiSelect();
            componentController.getAllFieldsAPIName();
            componentController.getUserLookupFieldsAPIName();
            componentController.getAllFieldsAPINameOrderBy();
            componentController.getAllFieldsAPINameReadUpdate();
            componentController.getAllFieldsAPINameForHeader();
            componentController.getOrderedInOptions();
            componentController.getSummarizeByOpeartor();
            componentController.getSummarizeByFields();
            System.assertEquals(3, componentController.getOrderedInOptions().size());
            componentController.getNullValuesOptions();
            System.assertEquals(3, componentController.getNullValuesOptions().size());

            // Select the 'Promote Change' field for second criteria and populate possible operator for it. We have to define 'cro' parameter to 2. Checking the list size, it should be 3 with values (none, equal, not equal).Select the 'equal' as a operator and assign 'false' value for the second criteria. Click to Validate button, the query will be updated
            ApexPages.currentPage().getParameters().put('cro', '2');
            componentController.qEditor.queryWrapper.criteriaList[1].fieldName = namespace + 'Promote_Change__c';
            componentController.getFieldOperators();
            System.assertEquals(3, componentController.qEditor.queryWrapper.criteriaList[1].operatorSet.size());
            componentController.qEditor.queryWrapper.criteriaList[1].operator = 'e';
            componentController.qEditor.queryWrapper.criteriaList[1].input = 'false';
            componentController.queryMaker();
            controller.applyChanges();

            controller.updateJsonToHideColum();
        }
    }

    // testing kanban for user story object with status field as a column
    @IsTest
    static void userStoryStatusKanbanUI() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true, true);

        String soqlQuery =
            'SELECT OwnerId,Name,RecordTypeId,Id,' +
            namespace +
            'Developer__c,' +
            namespace +
            'Project__c,' +
            namespace +
            'Sprint__c,' +
            namespace +
            'User_Story_Title__c,' +
            namespace +
            'Status__c,' +
            namespace +
            'Progress_Status__c,' +
            namespace +
            'Progress__c,' +
            namespace +
            'Story_Points_SFDC__c,' +
            namespace +
            'Total_Story_Points__c FROM ' +
            namespace +
            'user_story__c WHERE ' +
            namespace +
            'User_Story_Title__c LIKE \'us-000%\' AND (' +
            namespace +
            'Promote_Change__c = false OR ' +
            namespace +
            'Apex_Tests_Passed__c = false) ORDER BY ' +
            namespace +
            'Developer__c DESC NULLS LAST LIMIT 75';

        String jsonSetting =
            '{"queryWrapper":{"wholeSoql":"' +
            soqlQuery +
            '",' +
            '"viewName":"User Stories - 29.05.2018",' +
            '"userImageField":"' +
            namespace +
            'Developer__c",' +
            '"summarizeByList":[{"order":1,"operatorName":"Min","fieldName":"' +
            namespace +
            'Story_Points_SFDC__c"},{"order":2,"operatorName":"Max","fieldName":"' +
            namespace +
            'Story_Points_SFDC__c"},{"order":3,"operatorName":"Average","fieldName":"' +
            namespace +
            'Progress__c"},{"order":4,"operatorName":"Sum","fieldName":"' +
            namespace +
            'Total_Story_Points__c"}],' +
            '"sobjectTypeName":"' +
            namespace +
            'user_story__c",' +
            '"selectedFooterFields":["' +
            namespace +
            'Progress_Status__c","' +
            namespace +
            'Progress__c"],' +
            '"selectedFields":["Id","OwnerId","Name","RecordTypeId","' +
            namespace +
            'Developer__c","' +
            namespace +
            'Project__c","' +
            namespace +
            'Sprint__c","' +
            namespace +
            'User_Story_Title__c","' +
            namespace +
            'Progress_Status__c","' +
            namespace +
            'Status__c","' +
            namespace +
            'Progress__c","' +
            namespace +
            'Story_Points_SFDC__c","' +
            namespace +
            'Total_Story_Points__c"],' +
            '"queryLimit":"75",' +
            '"orderedIn":"DESC",' +
            '"orderByList":["' +
            namespace +
            'Developer__c"],' +
            '"nullValues":"NULLS LAST",' +
            '"kanbanDescription":"This board is created to check progress of the developer by status. It will only show 75 user stories.",' +
            '"headerField":"' +
            namespace +
            'User_Story_Title__c",' +
            '"filterLogic":"1 AND (2 OR 3)",' +
            '"fieldToReadUpdate":"' +
            namespace +
            'Status__c",' +
            '"enableFilterLogic":true,' +
            '"criteriaList":[{"order":1,"operatorSet":null,"operator":"s","input":"US-000","fieldType":"STRING","fieldName":"Name","dateTimeInput":null,"dateInput":null},{"order":2,"operatorSet":null,"operator":"e","input":"false","fieldType":"BOOLEAN","fieldName":"' +
            namespace +
            'Promote_Change__c","dateTimeInput":null,"dateInput":null},{"order":3,"operatorSet":null,"operator":"e","input":"false","fieldType":"BOOLEAN","fieldName":"' +
            namespace +
            'Apex_Tests_Passed__c","dateTimeInput":null,"dateInput":null}],' +
            '"colorField":"' +
            namespace +
            'Developer__c"},' +
            '"queryJson":""}';

        // Create kanban record to use it in the page
        // Note: user_story__c.Status__c is picklist type. Only picklist conditions will be covered
        Kanban_Board__c kanbanBoardRecord = new Kanban_Board__c();
        kanbanBoardRecord.Name = 'User Stories - 29.05.2018';
        kanbanBoardRecord.SOQL_Query__c = soqlQuery;
        kanbanBoardRecord.Field_to_read_update__c = namespace + 'user_story__c.' + namespace + 'Status__c';
        kanbanBoardRecord.Description__c = 'This board is created to check progress of the developer by status. It will only show 75 user stories.';
        kanbanBoardRecord.Columns_SOQL__c = '';
        kanbanBoardRecord.JSON_Settings__c = jsonSetting;
        insert kanbanBoardRecord;

        // Create 50 user story with status in progress
        // Create 50 user story with status ready for testing
        // Create 50 user story with status approved
        List<User_Story__c> userStoryList = new List<User_Story__c>();
        for (integer i = 0; i < 150; i++) {
            User_Story__c userStory = new User_Story__c();
            userStory.User_Story_Title__c = 'us-000000' + i;
            userStory.Promote_Change__c = false;
            userStory.Apex_Tests_Passed__c = false;
            userStory.Progress__c = 50;
            userStory.Developer__c = sysUser.Id;
            userStory.Status__c = i < 50 ? 'In Progress' : i >= 50 && i < 100 ? 'Ready for testing' : 'Approved';

            userStoryList.add(userStory);
        }
        insert userStoryList;

        System.runAs(sysUser) {
            // Use the PageReference Apex class to instantiate a page
            PageReference pageRef = Page.KanbanBoardView;
            Test.setCurrentPage(pageRef);
            ApexPages.StandardController sc = new ApexPages.StandardController(kanbanBoardRecord);
            KanbanBoard controller = new KanbanBoard(sc);
            System.assertNotEquals(0, controller.colorValueMap.size(), 'Check colorValueMap population logic in KanbanBoard class inside constructor!');
            System.assertNotEquals(0, controller.profileImageMap.size(), 'Check profileImageMap population logic in KanbanBoard class inside constructor!');
            System.assertNotEquals(0, controller.footerFieldList.size(), 'Check footerFieldList population logic in KanbanBoard class inside constructor!');

            // Checking the list size. 75 user stories should be in the list
            System.assertEquals(75, controller.cardDetailsMap.size());

            // Checking the list size of kanban views. 1 record should be in the list. Only default one
            controller.getKanbanViews();
            System.assertEquals(1, controller.getKanbanViews().size());

            // Editing the kanban view
            ApexPages.currentPage().getParameters().put('kanbanView', 'Edit');
            controller.kanbanViewsActions();
            QueryEditorController componentController = new QueryEditorController();
            componentController.compMode = 'Edit';
            componentController.qEditor = controller.qEditor;

            // Checking the criteria list before adding new line item
            System.assertEquals(4, componentController.qEditor.queryWrapper.summarizeByList.size());
            componentController.addNewSummarizeBy();
            System.assertEquals(5, componentController.qEditor.queryWrapper.summarizeByList.size());
            componentController.removeSummarizeBy();
            System.assertEquals(4, componentController.qEditor.queryWrapper.summarizeByList.size());

            // Validate existing query
            componentController.queryMaker();

            controller.changeView();
        }
    }

    // testing kanban for user story object with status field as a column. It has sub view. Edit sub view and delete it
    @IsTest
    static void userStoryStatusSubKanbanUI() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true, true);

        String soqlQuery =
            'SELECT Id,OwnerId,Name,CreatedDate,' +
            namespace +
            'Developer__c,' +
            namespace +
            'User_Story_Title__c,' +
            namespace +
            'Environment__c,' +
            namespace +
            'Sprint__c,' +
            namespace +
            'Status__c,' +
            namespace +
            'Sprint__r.Name FROM ' +
            namespace +
            'user_story__c WHERE ' +
            namespace +
            'User_Story_Title__c LIKE \'us-%\' ORDER BY CreatedDate ASC NULLS LAST LIMIT 150';

        String jsonSetting =
            '{"queryWrapper":{"wholeSoql":"' +
            soqlQuery +
            '",' +
            '"viewName":"User Story",' +
            '"sobjectTypeName":"' +
            namespace +
            'user_story__c",' +
            '"selectedFields":["Id","OwnerId","Name","CreatedDate","' +
            namespace +
            'Developer__c","' +
            namespace +
            'Environment__c","' +
            namespace +
            'Sprint__c","' +
            namespace +
            'Status__c","' +
            namespace +
            'Sprint__r.Name"],' +
            '"queryLimit":"150",' +
            '"orderedIn":"ASC",' +
            '"orderByList":["CreatedDate"],' +
            '"nullValues":"NULLS LAST",' +
            '"kanbanDescription":"This kanban is created to check status of the user stories which are not promoted yet. It will only show first 150 records.",' +
            '"filterLogic":"",' +
            '"fieldToReadUpdate":"' +
            namespace +
            'Sprint__c",' +
            '"enableFilterLogic":false,' +
            '"criteriaList":[{"order":1,"operatorSet":null,"operator":"s","input":"us-","fieldType":"STRING","fieldName":"Name","dateTimeInput":null,"dateInput":null}]}' +
            '"queryJson":""}';

        // Create kanban record to use it in the page
        // Note: user_story__c.Status__c is picklist type. Only picklist conditions will be covered
        Kanban_Board__c kanbanBoardRecord = new Kanban_Board__c();
        kanbanBoardRecord.Name = 'User Story Kanban';
        kanbanBoardRecord.SOQL_Query__c = soqlQuery;
        kanbanBoardRecord.Field_to_read_update__c = namespace + 'user_story__c.' + namespace + 'Status__c';
        kanbanBoardRecord.Description__c = 'This kanban is created to check status of the user stories which are not promoted yet. It will only show first 150 records.';
        kanbanBoardRecord.Columns_SOQL__c = '';
        kanbanBoardRecord.JSON_Settings__c = jsonSetting;
        insert kanbanBoardRecord;

        String soqlQueryView =
            'SELECT Id,OwnerId,Name,IsDeleted,' +
            namespace +
            'Status__c,' +
            namespace +
            'User_Story_Title__c,' +
            namespace +
            'Developer__c FROM ' +
            namespace +
            'user_story__c WHERE Name LIKE \'us-%\' ORDER BY CreatedDate ASC NULLS LAST LIMIT 140';

        String jsonSettingView =
            '{"queryWrapper":{"wholeSoql":"' +
            soqlQueryView +
            '",' +
            '"viewName":"new test 1",' +
            '"userImageField":"' +
            namespace +
            'Developer__c",' +
            '"sobjectTypeName":"' +
            namespace +
            'User_Story__c",' +
            '"selectedFields":["Id","OwnerId","Name","IsDeleted","' +
            namespace +
            'Status__c","' +
            namespace +
            'User_Story_Title__c","' +
            namespace +
            'Developer__c"],' +
            '"queryLimit":"140",' +
            '"orderedIn":"ASC",' +
            '"orderByList":["CreatedDate"],' +
            '"nullValues":"NULLS LAST",' +
            '"kanbanDescription":"test 1",' +
            '"headerField":"' +
            namespace +
            'User_Story_Title__c",' +
            '"filterLogic":"",' +
            '"fieldToReadUpdate":"' +
            namespace +
            'Status__c",' +
            '"enableFilterLogic":false,' +
            '"criteriaList":[{"order":1,"operatorSet":null,"operator":"s","input":"us-","fieldType":"STRING","fieldName":"Name","dateTimeInput":null,"dateInput":null},{"order":2,"operatorSet":null,"operator":"--None--","input":"","fieldType":"STRING","fieldName":"--None--","dateTimeInput":null,"dateInput":null},{"order":3,"operatorSet":null,"operator":"--None--","input":"","fieldType":"STRING","fieldName":"--None--","dateTimeInput":null,"dateInput":null}]},' +
            '"queryJson":""}';

        // Create kanban view record to use it in the page
        // Note: user_story__c.Status__c is picklist type. Only picklist conditions will be covered
        Kanban_Board_View__c kanbanBoardView = new Kanban_Board_View__c();
        kanbanBoardView.Kanban_Board__c = kanbanBoardRecord.Id;
        kanbanBoardView.SOQL_Json__c = jsonSettingView;
        kanbanBoardView.Name = 'Kanban Board View Test';
        insert kanbanBoardView;

        // Create 50 user story with status in progress
        // Create 50 user story with status ready for testing
        // Create 30 user story with status approved
        List<User_Story__c> userStoryList = new List<User_Story__c>();
        for (integer i = 0; i < 130; i++) {
            User_Story__c userStory = new User_Story__c();
            userStory.User_Story_Title__c = 'us-000000' + i;
            userStory.Promote_Change__c = false;
            userStory.Apex_Tests_Passed__c = false;
            userStory.Status__c = i < 50 ? 'In Progress' : i >= 50 && i < 100 ? 'Ready for testing' : 'Approved';

            userStoryList.add(userStory);
        }
        insert userStoryList;

        System.runAs(sysUser) {
            // Use the PageReference Apex class to instantiate a page
            PageReference pageRef = Page.KanbanBoardView;
            Test.setCurrentPage(pageRef);
            pageRef.getParameters().put('kbViewId', kanbanBoardView.Id);
            ApexPages.StandardController sc = new ApexPages.StandardController(kanbanBoardRecord);
            KanbanBoard controller = new KanbanBoard(sc);

            // Checking the list size. 130 user stories should be in the list
            System.assertEquals(130, controller.cardDetailsMap.size());

            controller.updateJsonToHideColum();

            // Checking the list size of kanban views. 2 records should be in the list. Default one and related kanban board view
            controller.getKanbanViews();
            System.assertEquals(2, controller.getKanbanViews().size());

            // Editing the kanban board view
            ApexPages.currentPage().getParameters().put('kanbanView', 'Edit');
            controller.kanbanViewsActions();

            // Instantiate and construct the controller class of component.
            QueryEditorController componentController = new QueryEditorController();
            componentController.compMode = 'Edit';
            componentController.qEditor = controller.qEditor;

            // Checking the criteria list before deleting last item, delete it and add new item
            System.assertEquals(3, componentController.qEditor.queryWrapper.criteriaList.size());
            componentController.removeCriteria();
            System.assertEquals(2, componentController.qEditor.queryWrapper.criteriaList.size());
            componentController.addNewCriteria();
            System.assertEquals(3, componentController.qEditor.queryWrapper.criteriaList.size());

            // Populate possible options. Actual value should be 3. (none,asc,desc) for Ordered In. Populate possible options at Null Values. Actual value should be 3 (none,nulls first,nulls last) for null values
            componentController.getAllFieldsAPINameMultiSelect();
            componentController.getAllFieldsAPIName();
            componentController.getUserLookupFieldsAPIName();
            componentController.getAllFieldsAPINameOrderBy();
            componentController.getAllFieldsAPINameReadUpdate();
            componentController.getAllFieldsAPINameForHeader();
            componentController.getOrderedInOptions();
            componentController.getSummarizeByOpeartor();
            componentController.getSummarizeByFields();
            System.assertEquals(3, componentController.getOrderedInOptions().size());
            componentController.getNullValuesOptions();
            System.assertEquals(3, componentController.getNullValuesOptions().size());

            // Select the 'Promote Change' field for second criteria and populate possible operator for it. We have to define 'cro' parameter to 2. Checking the list size, it should be 3 with values (none, equal, not equal)
            ApexPages.currentPage().getParameters().put('cro', '2');
            componentController.qEditor.queryWrapper.criteriaList[1].fieldName = namespace + 'Promote_Change__c';
            componentController.getFieldOperators();
            System.assertEquals(3, componentController.qEditor.queryWrapper.criteriaList[1].operatorSet.size());

            // Click to Validate button, (expecting a colon, found 'us') will appear. Select the 'equal' as a operator and assign 'false' value for the second criteria.
            componentController.qEditor.queryWrapper.criteriaList[1].operator = 's';
            componentController.qEditor.queryWrapper.criteriaList[1].input = 'us-';
            componentController.queryMaker();
            componentController.qEditor.queryWrapper.criteriaList[1].operator = 'e';
            componentController.qEditor.queryWrapper.criteriaList[1].input = 'false';
            componentController.queryMaker();

            // Enable filter logic area. Checking if the value is true. Define filterlogic and click to validate button again
            componentController.toggleLogic();
            System.assertEquals(true, componentController.qEditor.queryWrapper.enableFilterLogic);
            componentController.qEditor.queryWrapper.filterLogic = '1 OR 2';
            componentController.queryMaker();
            controller.applyChanges();

            // Try to change view to the default and delete kanban board view
            controller.changeView();
            controller.selectedKanbanView = kanbanBoardView.Id;
            controller.deleteView();
        }
    }

    // testing the create new sub kanban board view
    @IsTest
    static void newSubUserStoryKanbanUI() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true, true);

        String soqlQuery =
            'SELECT Id,OwnerId,Name,CreatedDate,' +
            namespace +
            'Apex_Code_Coverage__c,' +
            namespace +
            'Developer__c,' +
            namespace +
            'Environment__c,' +
            namespace +
            'Priority__c,' +
            namespace +
            'Sprint__c,' +
            namespace +
            'Status__c,' +
            namespace +
            'Total_Story_Points__c,' +
            namespace +
            'User_Story_Title__c,' +
            namespace +
            'Progress_Status__c,' +
            namespace +
            'Progress__c,' +
            namespace +
            'Sprint__r.Name,' +
            namespace +
            'Story_Points_SFDC__c FROM ' +
            namespace +
            'user_story__c WHERE Name LIKE \'us-%\' ORDER BY CreatedDate ASC NULLS LAST LIMIT 150';

        String jsonSetting =
            '{"queryWrapper":{"wholeSoql":"' +
            soqlQuery +
            '",' +
            '"viewName":"User Story",' +
            '"userImageField":"' +
            namespace +
            'Developer__c",' +
            '"summarizeByList":[{"order":1,"operatorName":"Average","fieldName":"' +
            namespace +
            'Apex_Code_Coverage__c"},{"order":2,"operatorName":"Sum","fieldName":"' +
            namespace +
            'Total_Story_Points__c"},{"order":3,"operatorName":"Min","fieldName":"' +
            namespace +
            'Progress__c"},{"order":4,"operatorName":"Max","fieldName":"' +
            namespace +
            'Story_Points_SFDC__c"}],' +
            '"sobjectTypeName":"' +
            namespace +
            'user_story__c",' +
            '"selectedFooterFields":["' +
            namespace +
            'Progress_Status__c"],' +
            '"selectedFields":["Id","OwnerId","Name","CreatedDate","' +
            namespace +
            'Apex_Code_Coverage__c","' +
            namespace +
            'Developer__c","' +
            namespace +
            'Environment__c","' +
            namespace +
            'Priority__c","' +
            namespace +
            'Sprint__c","' +
            namespace +
            'Status__c","' +
            namespace +
            'Total_Story_Points__c","' +
            namespace +
            'User_Story_Title__c","' +
            namespace +
            'Progress_Status__c","' +
            namespace +
            'Progress__c","' +
            namespace +
            'Sprint__r.Name","' +
            namespace +
            'Story_Points_SFDC__c"],' +
            '"queryLimit":"150",' +
            '"orderedIn":"ASC",' +
            '"orderByList":["CreatedDate"],' +
            '"nullValues":"NULLS LAST",' +
            '"kanbanDescription":"This kanban is created to check status of the user stories which are not promoted yet. It will only show first 150 records.",' +
            '"headerField":"' +
            namespace +
            'User_Story_Title__c",' +
            '"filterLogic":"",' +
            '"fieldToReadUpdate":"' +
            namespace +
            'Sprint__c",' +
            '"enableFilterLogic":false,' +
            '"criteriaList":[{"order":1,"operatorSet":null,"operator":"s","input":"us-","fieldType":"STRING","fieldName":"Name","dateTimeInput":null,"dateInput":null}],' +
            '"colorField":"' +
            namespace +
            'Developer__c"},' +
            '"queryJson":""}';

        // Create kanban record to use it in the page
        // Note: user_story__c.Sprint__c is referece type. Only reference conditions will be covered
        Kanban_Board__c kanbanBoardRecord = new Kanban_Board__c();
        kanbanBoardRecord.Name = 'User Story Kanban';
        kanbanBoardRecord.SOQL_Query__c = soqlQuery;
        kanbanBoardRecord.Field_to_read_update__c = namespace + 'user_story__c.' + namespace + 'Sprint__c';
        kanbanBoardRecord.Description__c = 'This kanban is created to check status of the user stories which are not promoted yet. It will only show first 150 records.';
        kanbanBoardRecord.Columns_SOQL__c = '';
        kanbanBoardRecord.JSON_Settings__c = jsonSetting;
        insert kanbanBoardRecord;

        // Create Sprint to populate on user stories
        Sprint__c sprint = new Sprint__c();
        sprint.Name = 'Sprint 1';
        sprint.Status__c = 'In Progress';
        insert sprint;

        // Create 200 user story to fill sobjectlist
        List<User_Story__c> userStoryList = new List<User_Story__c>();
        for (integer i = 0; i < 200; i++) {
            User_Story__c userStory = new User_Story__c();
            userStory.User_Story_Title__c = 'us-000000' + i;
            userStory.Sprint__c = sprint.Id;
            userStory.Developer__c = sysUser.Id;

            userStoryList.add(userStory);
        }
        insert userStoryList;

        System.runAs(sysUser) {
            // Use the PageReference Apex class to instantiate a page
            PageReference pageRef = Page.KanbanBoardView;
            Test.setCurrentPage(pageRef);
            ApexPages.StandardController sc = new ApexPages.StandardController(kanbanBoardRecord);
            KanbanBoard controller = new KanbanBoard(sc);

            // Checking the list size. 150 user stories should be in the list
            System.assertEquals(150, controller.cardDetailsMap.size());

            // Creating new view
            ApexPages.currentPage().getParameters().put('kanbanView', 'NewView');
            controller.kanbanViewsActions();

            // Instantiate and construct the controller class of component.
            QueryEditorController componentController = new QueryEditorController();
            componentController.compMode = 'NewView';
            componentController.qEditor = controller.qEditor;

            // Checking the criteria list and it should be 3
            System.assertEquals(3, componentController.qEditor.queryWrapper.criteriaList.size());

            // Populate possible options. Actual value should be 3. (none,asc,desc) for Ordered In. Populate possible options at Null Values. Actual value should be 3 (none,nulls first,nulls last) for null values
            componentController.getAllFieldsAPINameMultiSelect();
            componentController.getAllFieldsAPIName();
            componentController.getUserLookupFieldsAPIName();
            componentController.getAllFieldsAPINameOrderBy();
            componentController.getAllFieldsAPINameForHeader();
            componentController.getOrderedInOptions();
            componentController.getSummarizeByOpeartor();
            componentController.getSummarizeByFields();
            System.assertEquals(3, componentController.getOrderedInOptions().size());
            componentController.getNullValuesOptions();
            System.assertEquals(3, componentController.getNullValuesOptions().size());
            componentController.getAllFieldsAPINameReadUpdate();
            componentController.qEditor.queryWrapper.fieldToReadUpdate = '--None--';

            // Fill name and description for kanban
            componentController.qEditor.queryWrapper.viewName = 'New kanban board view for existing kanban';
            componentController.qEditor.queryWrapper.kanbanDescription = 'New kanban board view for existing kanban description';

            // Select the fields you want to show in the kanban board body
            componentController.qEditor.queryWrapper.selectedFields = new List<String>{ 'IsDeleted' };

            // Select the 'User Story Title' field for first criteria and populate possible operator for it. We have to define 'cro' parameter to 0. Checking the list size, it should be 6 with values (none, equal, not equal, starts with, contains, does not contain)
            ApexPages.currentPage().getParameters().put('cro', '1');
            componentController.qEditor.queryWrapper.criteriaList[0].fieldName = namespace + 'User_Story_Title__c';
            componentController.getFieldOperators();
            System.assertEquals(6, componentController.qEditor.queryWrapper.criteriaList[0].operatorSet.size());
            componentController.qEditor.queryWrapper.criteriaList[0].operator = 's';
            componentController.qEditor.queryWrapper.criteriaList[0].input = 'us-';

            // Click to Validate button, the query will be return with error, (Field to Read/Update is not selected). Select the field to Read/Update and validate again
            componentController.queryMaker();

            componentController.qEditor.queryWrapper.fieldToReadUpdate = namespace + 'Status__c';
            componentController.qEditor.queryWrapper.headerField = namespace + 'User_Story_Title__c';
            componentController.qEditor.queryWrapper.userImageField = namespace + 'Developer__c';
            componentController.qEditor.queryWrapper.colorField = namespace + 'Developer__c';
            componentController.qEditor.queryWrapper.selectedFooterFields = new List<String>{
                namespace + 'Progress_Status__c',
                namespace + 'Progress__c'
            };
            componentController.queryMaker();

            controller.saveAsNew();
        }
    }

    // testing the updating record with remote action
    @IsTest
    static void updateRecordUserStoryKanbanUI() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true, true);

        String soqlQuery =
            'SELECT Id,OwnerId,Name,CreatedDate,' +
            namespace +
            'Developer__c,' +
            namespace +
            'User_Story_Title__c,' +
            namespace +
            'Environment__c,' +
            namespace +
            'Sprint__c,' +
            namespace +
            'Status__c,' +
            namespace +
            'Sprint__r.Name FROM ' +
            namespace +
            'user_story__c WHERE ' +
            namespace +
            'User_Story_Title__c LIKE \'us-%\' ORDER BY CreatedDate ASC NULLS LAST LIMIT 150';

        String jsonSetting =
            '{"queryWrapper":{"wholeSoql":"' +
            soqlQuery +
            '",' +
            '"viewName":"User Story",' +
            '"sobjectTypeName":"' +
            namespace +
            'user_story__c",' +
            '"selectedFields":["Id","OwnerId","Name","CreatedDate","' +
            namespace +
            'Developer__c","' +
            namespace +
            'Environment__c","' +
            namespace +
            'Sprint__c","' +
            namespace +
            'Status__c","' +
            namespace +
            'Sprint__r.Name"],' +
            '"queryLimit":"150",' +
            '"orderedIn":"ASC",' +
            '"orderByList":["CreatedDate"],' +
            '"nullValues":"NULLS LAST",' +
            '"kanbanDescription":"This kanban is created to check status of the user stories which are not promoted yet. It will only show first 150 records.",' +
            '"filterLogic":"",' +
            '"fieldToReadUpdate":"' +
            namespace +
            'Sprint__c",' +
            '"enableFilterLogic":false,' +
            '"criteriaList":[{"order":1,"operatorSet":null,"operator":"s","input":"us-","fieldType":"STRING","fieldName":"Name","dateTimeInput":null,"dateInput":null}],' +
            '"queryJson":""}';

        // Create kanban record to use it in the page
        // Note: user_story__c.Status__c is picklist type. Only picklist conditions will be covered
        Kanban_Board__c kanbanBoardRecord = new Kanban_Board__c();
        kanbanBoardRecord.Name = 'User Story Kanban';
        kanbanBoardRecord.SOQL_Query__c = soqlQuery;
        kanbanBoardRecord.Field_to_read_update__c = namespace + 'user_story__c.' + namespace + 'Status__c';
        kanbanBoardRecord.Description__c = 'This kanban is created to check status of the user stories which are not promoted yet. It will only show first 150 records.';
        kanbanBoardRecord.Columns_SOQL__c = '';
        kanbanBoardRecord.JSON_Settings__c = jsonSetting;
        insert kanbanBoardRecord;

        String soqlQueryView =
            'SELECT Id,OwnerId,Name,IsDeleted,' +
            namespace +
            'Status__c,' +
            namespace +
            'User_Story_Title__c,' +
            namespace +
            'Developer__c FROM ' +
            namespace +
            'user_story__c WHERE Name LIKE \'us-%\' ORDER BY CreatedDate ASC NULLS LAST LIMIT 140';

        String jsonSettingView =
            '{"queryWrapper":{"wholeSoql":"' +
            soqlQueryView +
            '",' +
            '"viewName":"new test 1",' +
            '"userImageField":"' +
            namespace +
            'Developer__c",' +
            '"sobjectTypeName":"' +
            namespace +
            'User_Story__c",' +
            '"selectedFields":["Id","OwnerId","Name","IsDeleted","' +
            namespace +
            'Status__c","' +
            namespace +
            'User_Story_Title__c","' +
            namespace +
            'Developer__c"],' +
            '"queryLimit":"140",' +
            '"orderedIn":"ASC",' +
            '"orderByList":["CreatedDate"],' +
            '"nullValues":"NULLS LAST",' +
            '"kanbanDescription":"test 1",' +
            '"headerField":"' +
            namespace +
            'User_Story_Title__c",' +
            '"filterLogic":"",' +
            '"fieldToReadUpdate":"' +
            namespace +
            'Status__c",' +
            '"enableFilterLogic":false,' +
            '"criteriaList":[{"order":1,"operatorSet":null,"operator":"s","input":"us-","fieldType":"STRING","fieldName":"Name","dateTimeInput":null,"dateInput":null},{"order":2,"operatorSet":null,"operator":"--None--","input":"","fieldType":"STRING","fieldName":"--None--","dateTimeInput":null,"dateInput":null},{"order":3,"operatorSet":null,"operator":"--None--","input":"","fieldType":"STRING","fieldName":"--None--","dateTimeInput":null,"dateInput":null}]},' +
            '"queryJson":""}';

        // Create kanban view record to use it in the page
        // Note: user_story__c.Status__c is picklist type. Only picklist conditions will be covered
        Kanban_Board_View__c kanbanBoardView = new Kanban_Board_View__c();
        kanbanBoardView.Kanban_Board__c = kanbanBoardRecord.Id;
        kanbanBoardView.SOQL_Json__c = jsonSettingView;
        kanbanBoardView.Name = 'Kanban Board View Test';
        insert kanbanBoardView;

        // Create 50 user story with status in progress
        // Create 50 user story with status ready for testing
        // Create 30 user story with status approved
        List<User_Story__c> userStoryList = new List<User_Story__c>();
        for (integer i = 0; i < 130; i++) {
            User_Story__c userStory = new User_Story__c();
            userStory.User_Story_Title__c = 'us-000000' + i;
            userStory.Status__c = i < 50 ? 'In Progress' : i >= 50 && i < 100 ? 'Ready for testing' : 'Approved';

            userStoryList.add(userStory);
        }
        insert userStoryList;

        System.runAs(sysUser) {
            // Use the PageReference Apex class to instantiate a page
            PageReference pageRef = Page.KanbanBoardView;
            Test.setCurrentPage(pageRef);
            pageRef.getParameters().put('kbViewId', kanbanBoardView.Id);
            ApexPages.StandardController sc = new ApexPages.StandardController(kanbanBoardRecord);
            KanbanBoard controller = new KanbanBoard(sc);

            // Checking the list size. 130 user stories should be in the list
            System.assertEquals(130, controller.cardDetailsMap.size());

            System.assertEquals('Ready for testing', userStoryList[65].Status__c);
            System.assertEquals(30, [SELECT COUNT() FROM User_Story__c WHERE Status__c = 'Approved']);
            User_Story__c uStory = userStoryList[65];
            KanbanBoard.updateRecordsPicklistValue(uStory.Id, 'Approved', namespace + 'Status__c', 'Name');
            System.assertEquals(31, [SELECT COUNT() FROM User_Story__c WHERE Status__c = 'Approved']);
        }
    }

    // testing the updating record with remote action
    @IsTest
    static void updateRecordUserStoryKanbanUIForEnvironment() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true, true);

        String soqlQuery =
            'SELECT Id,OwnerId,Name,CreatedDate,' +
            namespace +
            'Developer__c,' +
            namespace +
            'User_Story_Title__c,' +
            namespace +
            'Environment__c,' +
            namespace +
            'Sprint__c,' +
            namespace +
            'Status__c,' +
            namespace +
            'Sprint__r.Name FROM ' +
            namespace +
            'user_story__c WHERE ' +
            namespace +
            'User_Story_Title__c LIKE \'us-%\' ORDER BY CreatedDate ASC NULLS LAST LIMIT 150';

        String jsonSetting =
            '{"queryWrapper":{"wholeSoql":"' +
            soqlQuery +
            '",' +
            '"viewName":"User Story",' +
            '"sobjectTypeName":"' +
            namespace +
            'user_story__c",' +
            '"selectedFields":["Id","OwnerId","Name","CreatedDate","' +
            namespace +
            'Developer__c","' +
            namespace +
            'Environment__c","' +
            namespace +
            'Sprint__c","' +
            namespace +
            'Status__c","' +
            namespace +
            'Sprint__r.Name"],' +
            '"queryLimit":"150",' +
            '"orderedIn":"ASC",' +
            '"orderByList":["CreatedDate"],' +
            '"nullValues":"NULLS LAST",' +
            '"kanbanDescription":"This kanban is created to check status of the user stories which are not promoted yet. It will only show first 150 records.",' +
            '"filterLogic":"",' +
            '"fieldToReadUpdate":"' +
            namespace +
            'Sprint__c",' +
            '"enableFilterLogic":false,' +
            '"criteriaList":[{"order":1,"operatorSet":null,"operator":"s","input":"us-","fieldType":"STRING","fieldName":"Name","dateTimeInput":null,"dateInput":null}],' +
            '"queryJson":""}';

        // Create kanban record to use it in the page
        // Note: user_story__c.Status__c is picklist type. Only picklist conditions will be covered
        Kanban_Board__c kanbanBoardRecord = new Kanban_Board__c();
        kanbanBoardRecord.Name = 'User Story Kanban';
        kanbanBoardRecord.SOQL_Query__c = soqlQuery;
        kanbanBoardRecord.Field_to_read_update__c = namespace + 'user_story__c.' + namespace + 'Environment__c';
        kanbanBoardRecord.Description__c = 'This kanban is created to check status of the user stories which are not promoted yet. It will only show first 150 records.';
        kanbanBoardRecord.Columns_SOQL__c = '';
        kanbanBoardRecord.JSON_Settings__c = jsonSetting;
        insert kanbanBoardRecord;

        String soqlQueryView =
            'SELECT Id,OwnerId,Name,IsDeleted,' +
            namespace +
            'Status__c,' +
            namespace +
            'User_Story_Title__c,' +
            namespace +
            'Environment__c,' +
            namespace +
            'Developer__c FROM ' +
            namespace +
            'user_story__c WHERE Name LIKE \'us-%\' ORDER BY CreatedDate ASC NULLS LAST LIMIT 140';

        String jsonSettingView =
            '{"queryWrapper":{"wholeSoql":"' +
            soqlQueryView +
            '",' +
            '"viewName":"new test 1",' +
            '"userImageField":"' +
            namespace +
            'Developer__c",' +
            '"sobjectTypeName":"' +
            namespace +
            'User_Story__c",' +
            '"selectedFields":["Id","OwnerId","Name","IsDeleted","' +
            namespace +
            'Status__c","' +
            namespace +
            'User_Story_Title__c","' +
            namespace +
            'Environment__c","' +
            namespace +
            'Developer__c"],' +
            '"queryLimit":"140",' +
            '"orderedIn":"ASC",' +
            '"orderByList":["CreatedDate"],' +
            '"nullValues":"NULLS LAST",' +
            '"kanbanDescription":"test 1",' +
            '"headerField":"' +
            namespace +
            'User_Story_Title__c",' +
            '"filterLogic":"",' +
            '"fieldToReadUpdate":"' +
            namespace +
            'Status__c",' +
            '"enableFilterLogic":false,' +
            '"criteriaList":[{"order":1,"operatorSet":null,"operator":"s","input":"us-","fieldType":"STRING","fieldName":"Name","dateTimeInput":null,"dateInput":null},{"order":2,"operatorSet":null,"operator":"--None--","input":"","fieldType":"STRING","fieldName":"--None--","dateTimeInput":null,"dateInput":null},{"order":3,"operatorSet":null,"operator":"--None--","input":"","fieldType":"STRING","fieldName":"--None--","dateTimeInput":null,"dateInput":null}]},' +
            '"queryJson":""}';

        // Create kanban view record to use it in the page
        // Note: user_story__c.Environment__c is reference type. Only reference conditions will be covered
        Kanban_Board_View__c kanbanBoardView = new Kanban_Board_View__c();
        kanbanBoardView.Kanban_Board__c = kanbanBoardRecord.Id;
        kanbanBoardView.SOQL_Json__c = jsonSettingView;
        kanbanBoardView.Name = 'Kanban Board View Test';
        insert kanbanBoardView;

        Environment__c env1 = new Environment__c(Name = 'Dev1 Environment', Type__c = 'Sandbox');
        Environment__c env2 = new Environment__c(Name = 'Dev2 Environment', Type__c = 'Sandbox');
        insert new List<Environment__c>{ env1, env2 };

        List<User_Story__c> userStoryList = new List<User_Story__c>();
        for (integer i = 0; i < 130; i++) {
            User_Story__c userStory = new User_Story__c();
            userStory.Environment__c = env1.Id;
            userStoryList.add(userStory);
        }
        insert userStoryList;

        System.runAs(sysUser) {
            // Use the PageReference Apex class to instantiate a page
            PageReference pageRef = Page.KanbanBoardView;
            Test.setCurrentPage(pageRef);
            pageRef.getParameters().put('kbViewId', kanbanBoardView.Id);
            ApexPages.StandardController sc = new ApexPages.StandardController(kanbanBoardRecord);
            KanbanBoard controller = new KanbanBoard(sc);

            // Checking the list size. 130 user stories should be in the list
            System.assertEquals(130, controller.cardDetailsMap.size());

            System.assertEquals(env1.Id, userStoryList[65].Environment__c);
            System.assertEquals(130, [SELECT COUNT() FROM User_Story__c WHERE Environment__c = :env1.Id]);
            User_Story__c uStory = userStoryList[65];
            KanbanBoard.updateRecordsPicklistValue(uStory.Id, 'Dev2 Environment', namespace + 'Environment__c', 'Name');
            System.assertEquals(129, [SELECT COUNT() FROM User_Story__c WHERE Environment__c = :env1.Id]);
        }
    }

    // testing the create new kanban board view
    @IsTest
    static void newUserStoryKanbanUI() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true, true);

        // Create Sprint to populate on user stories
        Sprint__c sprint = new Sprint__c();
        sprint.Name = 'Sprint 1';
        sprint.Status__c = 'In Progress';
        insert sprint;

        // Create 200 user story to fill sobjectlist
        List<User_Story__c> userStoryList = new List<User_Story__c>();
        for (integer i = 0; i < 200; i++) {
            User_Story__c userStory = new User_Story__c();
            userStory.User_Story_Title__c = 'us-000000' + i;
            userStory.Sprint__c = sprint.Id;
            userStory.Developer__c = sysUser.Id;

            userStoryList.add(userStory);
        }
        insert userStoryList;

        System.runAs(sysUser) {
            // Use the PageReference Apex class to instantiate a page
            PageReference pageRef = Page.KanbanBoardEdit;
            Test.setCurrentPage(pageRef);
            ApexPages.StandardController sc = new ApexPages.StandardController(new Kanban_Board__c());
            KanbanBoardEditController controller = new KanbanBoardEditController(sc);

            controller.objectNameValidation();
            ApexPages.Message[] pageMessages = ApexPages.getMessages();
            System.assertEquals(1, pageMessages.size());

            controller.qEditor.queryWrapper.sobjectTypeName = namespace + 'User_Story__c';
            controller.objectNameValidation();
            pageMessages = ApexPages.getMessages();

            controller.createKanban();
            pageMessages = ApexPages.getMessages();

            // Instantiate and construct the controller class of component.
            QueryEditorController componentController = new QueryEditorController();
            componentController.compMode = 'NewView';
            componentController.qEditor = controller.qEditor;

            // Checking the criteria list and it should be 3
            System.assertEquals(3, componentController.qEditor.queryWrapper.criteriaList.size());

            // Populate possible options. Actual value should be 3. (none,asc,desc) for Ordered In. Populate possible options at Null Values. Actual value should be 3 (none,nulls first,nulls last) for null values
            componentController.getAllFieldsAPINameMultiSelect();
            componentController.getAllFieldsAPIName();
            componentController.getUserLookupFieldsAPIName();
            componentController.getAllFieldsAPINameOrderBy();
            componentController.getAllFieldsAPINameForHeader();
            componentController.getOrderedInOptions();
            componentController.getSummarizeByOpeartor();
            componentController.getSummarizeByFields();
            System.assertEquals(3, componentController.getOrderedInOptions().size());
            componentController.getNullValuesOptions();
            System.assertEquals(3, componentController.getNullValuesOptions().size());
            componentController.getAllFieldsAPINameReadUpdate();
            componentController.qEditor.queryWrapper.fieldToReadUpdate = '--None--';

            // Fill name and description for kanban
            componentController.qEditor.queryWrapper.viewName = 'New kanban board view for existing kanban';
            componentController.qEditor.queryWrapper.kanbanDescription = 'New kanban board view for existing kanban description';

            controller.createKanban();

            // Select the fields you want to show in the kanban board body
            componentController.qEditor.queryWrapper.selectedFields = new List<String>{ 'IsDeleted' };

            // Select the 'User Story Title' field for first criteria and populate possible operator for it. We have to define 'cro' parameter to 0. Checking the list size, it should be 6 with values (none, equal, not equal, starts with, contains, does not contain)
            ApexPages.currentPage().getParameters().put('cro', '1');
            componentController.qEditor.queryWrapper.criteriaList[0].fieldName = namespace + 'User_Story_Title__c';
            componentController.getFieldOperators();
            System.assertEquals(6, componentController.qEditor.queryWrapper.criteriaList[0].operatorSet.size());
            componentController.qEditor.queryWrapper.criteriaList[0].operator = 's';
            componentController.qEditor.queryWrapper.criteriaList[0].input = 'us-';

            // Click to Validate button, the query will be return with error, (Field to Read/Update is not selected). Select the field to Read/Update and validate again
            componentController.queryMaker();

            componentController.qEditor.queryWrapper.fieldToReadUpdate = namespace + 'Status__c';
            componentController.qEditor.queryWrapper.headerField = namespace + 'User_Story_Title__c';
            componentController.qEditor.queryWrapper.colorField = namespace + 'Developer__c';
            componentController.qEditor.queryWrapper.selectedFooterFields = new List<String>{
                namespace + 'Progress_Status__c',
                namespace + 'Progress__c'
            };
            componentController.queryMaker();

            controller.createKanban();
        }
    }
}