@IsTest
private class TestUserStorySelectCommits {
    @testSetup
    static void setupData() {
        TestUtilities.enableLicenses(2, 2, 2, 2, 2);
    }

    @IsTest
    static void testBehavior() {
        testMethodUtilities.upsertOrgwideSettings();
        TestUtilities tu = new TestUtilities();
        // Create user to assign as developer to the user stories
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

        TestUtilities.assignLicense(String.valueOf(tu.item('User', 0).get('Username')), true, true, true, true, true);

        System.runAs((User) tu.item('User', 0)) {
            //Env
            tu.insertSObject('Environment__c', new Map<String, Object>{ 'Name' => 'Dev1 Environment', 'Type__c' => 'Sandbox' });

            //Org
            tu.insertSObject(
                'Org__c',
                new Map<String, Object>{
                    'Name' => 'OrgDev1',
                    'Org_Type__c' => 'Sandbox',
                    'SFDC_Org_ID__c' => 'SFDC_OrgId',
                    'Validated_Date__c' => system.now(),
                    'Environment__c' => tu.item('Environment__c', 0).Id
                }
            );

            //Repo
            tu.insertSObject('Git_Repository__c', new Map<String, Object>{ 'Name' => 'testRepo' });
            //Git Snapshot
            tu.insertSObject(
                'Git_Backup__c',
                new Map<String, Object>{
                    'Name' => 'testRepo',
                    'Git_Repository__c' => tu.item('Git_Repository__c', 0).Id,
                    'Org__c' => tu.item('Org__c', 0).Id,
                    'Branch__c' => 'dev1'
                }
            );

            //US
            tu.insertSObject(
                'User_Story__c',
                new Map<String, Object>{
                    'User_Story_Title__c' => 'us-0000000',
                    'Status__c' => 'Approved',
                    'Story_Points_SFDC__c' => 2,
                    'Developer__c' => tu.item('User', 0).Id,
                    'Org_Credential__c' => tu.item('Org__c', 0).Id
                }
            );

            //Snapshot Commit
            List<SObject> gitOrgCommits = tu.createSObjects(
                'Git_Org_Commit__c',
                200,
                new Map<String, Object>{
                    'Commit_Id__c' => 'a5sdfsdfsdfcb40b12ae6a599058ab408b3d63ae47be',
                    'Status__c' => 'Complete',
                    'Org__c' => tu.item('Org__c', 0).Id,
                    'Git_Operation__c' => 'Commit Files',
                    'Git_Backup__c' => tu.item('Git_Backup__c', 0).Id,
                    'Commit_Message__c' => 'c message'
                }
            );
            for (Integer i = 0; i <= gitOrgCommits.size() - 1; i++) {
                Git_Org_Commit__c g = (Git_Org_Commit__c) gitOrgCommits[i];
                g.Commit_Id__c = g.Commit_Id__c + String.valueOf(i);
            }
            insert gitOrgCommits;
        }

        Test.startTest();
        PageReference myVfPage = Page.UserStorySelectCommits;
        Test.setCurrentPage(myVfPage);
        System.runAs((User) tu.item('User', 0)) {
            // Put Id into the current page Parameters
            ApexPages.currentPage().getParameters().put('repoId', tu.item('Git_Repository__c', 0).Id);
            ApexPages.currentPage().getParameters().put('snapshotId', tu.item('Git_Backup__c', 0).Id);
            ApexPages.currentPage().getParameters().put('orgId', tu.item('Org__c', 0).Id);
            ApexPages.currentPage().getParameters().put('userStoryId', tu.item('User_Story__c', 0).Id);

            ApexPages.StandardController sc = new ApexPages.StandardController(tu.item('User_Story__c', 0));

            UserStorySelectCommits uSSC = new UserStorySelectCommits(sc);
            uSSC.next();
            uSSC.previous();
            for (UserStorySelectCommits.ACommit a : uSSC.commits) {
                a.sel = true;
            }
            uSSC.saveSelections();
            uSSC.cancel();
        }
        Test.stopTest();
        System.assert([SELECT COUNT() FROM User_Story_Commit__c] == 200);
    }
}