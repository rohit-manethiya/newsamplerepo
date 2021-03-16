@isTest
private class TestCopadoSmartHelpController {
    private static final User RUNNING_USER;

    static {
        RUNNING_USER = createRunningUser();
    }

    @TestSetup
    static void setupData() {
        TestUtilities.enableLicenses(2, 2, 2, 2, 2, 2);
        assignUserPermissions(RUNNING_USER.Id);
    }

    @IsTest
    private static void setHelpList() {
        assignAllLicenses();

        System.runAs(RUNNING_USER) {
            CopadoSmartHelpController controller = getPageController('GitCommitMain', '');

            Test.startTest();
            controller.setHelpList();
            Test.stopTest();

            Integer expectedCount = getSmartHelpTips('Triggering_Action__c = \'Always Show\' AND Base_Page__c = \'' + controller.vfPageName + '\'')
                .size();
            Integer actualCount = controller.helpList.size();

            System.assertEquals(
                expectedCount,
                actualCount,
                'The matching criteria for retrieving Copado Smart Help tips (only active records) for the current page' +
                ' & tip type is not working as expected.'
            );
        }
    }

    @IsTest
    private static void setTypeList() {
        assignAllLicenses();

        System.runAs(RUNNING_USER) {
            CopadoSmartHelpController controller = getPageController('GitCommitMain', 'CustomField');

            Test.startTest();
            controller.setTypeList();
            Test.stopTest();

            Integer expectedCount = getSmartHelpTips(
                    'Triggering_Action__c != \'Always Show\' AND Triggering_Value__c = \'' +
                    controller.tipType +
                    '\' AND Base_Page__c = \'' +
                    controller.vfPageName +
                    '\''
                )
                .size();
            Integer actualCount = controller.helpList.size();

            System.assertEquals(
                expectedCount,
                actualCount,
                'The matching criteria for retrieving Copado Smart Help tips (only active records) for the current page' +
                ' & tip type is not working as expected.'
            );
        }
    }

    @IsTest
    private static void removeTip() {
        assignAllLicenses();

        System.runAs(RUNNING_USER) {
            CopadoSmartHelpController controller = getPageController('GitCommitMain', 'CustomField');
            controller.setTypeList();
            Integer initialCount = controller.helpList.size();
            controller.tipKey = 'Profile_Permission_Set_FLS';

            Test.startTest();
            controller.removeTip();
            Test.stopTest();

            Integer expectedCount = initialCount - 1;
            Integer actualCount = controller.helpList.size();

            System.assertEquals(expectedCount, actualCount, 'Failed to remove the Profile_Permission_Set_FLS tip from the list.');
        }
    }

    @IsTest
    private static void getCopadoSmartHelps() {
        assignAllLicenses();

        System.runAs(RUNNING_USER) {
            CopadoSmartHelpController controller = getPageController('GitCommitMain', 'ApexClass');

            Test.startTest();
            controller.setTypeList();
            Test.stopTest();

            Integer expectedCount = getSmartHelpTips(
                    'Triggering_Value__c = \'' +
                    controller.tipType +
                    '\' AND Base_Page__c = \'' +
                    controller.vfPageName +
                    '\''
                )
                .size();
            Integer actualCount = controller.helpList.size();

            System.assertEquals(
                expectedCount,
                actualCount,
                'The matching criteria for retrieving Copado Smart Help tips (only active records) for the current page' +
                ' & tip type is not working as expected.'
            );
        }
    }

    private static User createRunningUser() {
        List<User> users = TestDataFactory.createUsers();
        users[0].Show_Copado_Tips__c = true;
        update users;
        return users[0];
    }

    private static void assignUserPermissions(Id userId) {
        PermissionSet permissionSet = [SELECT Id FROM PermissionSet WHERE Name = 'Copado_User'];
        List<PermissionSetAssignment> assignments = [
            SELECT Id
            FROM PermissionSetAssignment
            WHERE PermissionSetId = :permissionSet.Id AND AssigneeId = :userId
        ];
        if (assignments.isEmpty()) {
            insert new PermissionSetAssignment(AssigneeId = userId, PermissionSetId = permissionSet.Id);
        }
    }

    private static void assignAllLicenses() {
        TestUtilities.assignLicense(UserInfo.getUserName(), true, true, true, true, true, true);
    }

    private static CopadoSmartHelpController getPageController(String vfPageName, String tipType) {
        CopadoSmartHelpController controller = new CopadoSmartHelpController();
        controller.vfPageName = vfPageName;
        controller.tipType = tipType;
        return controller;
    }

    private static List<Copado_Smart_Help__mdt> getSmartHelpTips(String queryFilter) {
        String query = 'SELECT Id FROM Copado_Smart_Help__mdt WHERE Active__c = TRUE';
        if (String.isNotBlank(queryFilter)) {
            query += ' AND ' + queryFilter;
        }
        return Database.query(query);
    }
}