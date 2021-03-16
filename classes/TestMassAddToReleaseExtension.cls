@IsTest
private class TestMassAddToReleaseExtension {
    private static final String STANDARD_USER = 'test_user@myorg.com';
    @TestSetup
    static void makeData() {
        TestUtilities.enableLicenses(2, 2, 2, 2, 2, 30);
        ITestDefaults userCreation = new CopadoSetupTestDefaults.UserDefaults().createRunAsUsers().executeDML();

        User standardUser = userCreation.getRunAsUsers().get('Standard')[0];
        System.runAs(standardUser) {
            TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, true, true, true, true);
            ITestDefaults releaseDefaults = new CopadoUserStoryTestDefaults.ReleaseDefaults()
                .setFieldDefaults()
                .includeDefaults(CopadoUserStoryTestDefaults.SprintDefaults.class)
                .includeDefaults(CopadoUserStoryTestDefaults.ProjectDefaults.class)
                .includeDefaults(CopadoUserStoryTestDefaults.UserStoryDefaults.class)
                .setSObjectRelation(
                    Release__c.SObjectType,
                    Project__c.SObjectType,
                    new Map<Schema.SObjectField, Integer>{ Release__c.Project__c => 1 }
                )
                .setSObjectRelation(
                    User_Story__c.SObjectType,
                    Project__c.SObjectType,
                    new Map<Schema.SObjectField, Integer>{ User_Story__c.Project__c => 1 }
                )
                .setSObjectRelation(
                    User_Story__c.SObjectType,
                    Sprint__c.SObjectType,
                    new Map<Schema.SObjectField, Integer>{ User_Story__c.Sprint__c => 3 }
                )
                .setSObjectRelation(
                    Sprint__c.SObjectType,
                    Project__c.SObjectType,
                    new Map<Schema.SObjectField, Integer>{ Sprint__c.Project__c => 5 }
                )
                .setDataSize(Project__c.SObjectType, 1)
                .setDataSize(User_Story__c.SObjectType, 8)
                .setDataSize(Release__c.SObjectType, 1)
                .setDataSize(Sprint__c.SObjectType, 2)
                .generateDefaults()
                .executeDML();
        }
    }

    @IsTest
    static void massAddToReleaseBySprint() {
        User standardUser = [SELECT Username FROM User WHERE Username = :STANDARD_USER LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, false, false, false, false);
        System.runAs(standardUser) {
            Release__c testRelease = [SELECT Id, Name, Project__c FROM Release__c WHERE Name = 'MyNextRelease 0'];
            Map<Id,Sprint__c> assertSprintsById = new Map<Id,Sprint__c>([SELECT Id, Name FROM Sprint__c]);
            String sprint1Name = 'Sprint 0';
            String sprint2Name = 'Sprint 1';

            Test.startTest();
            PageReference massAddToReleasePage = Page.MassAddToRelease;
            massAddToReleasePage.getParameters().put('id',testRelease.id);
            Test.setCurrentPage(massAddToReleasePage);
            
            MassAddToReleaseExtension massAddToReleaseController = new MassAddToReleaseExtension(new ApexPages.StandardController(testRelease));
            
            List<MassAddToReleaseExtension.sprintWrapper> testSprints = massAddToReleaseController.wrapSprints(massAddToReleaseController.sprints);
            System.assertEquals(2, testSprints.size(), 'Number of Sprints is not correct');
            Integer assertSprint1Counter = 0;
            Integer assertSprint2Counter = 0;
            for(MassAddToReleaseExtension.sprintWrapper sprintsItem : testSprints){
                if(sprintsItem.sprint.Name == sprint1Name) {
                    assertSprint1Counter = sprintsItem.usWrapper.size();
                }
                if(sprintsItem.sprint.Name == sprint2Name) {
                    assertSprint2Counter = sprintsItem.usWrapper.size();
                }
            }
            System.assertEquals(3, assertSprint1Counter, 'Number of user stories in Sprint 1 is not correct');
            System.assertEquals(5, assertSprint2Counter, 'Number of user stories in Sprint 2 is not correct');
            
            // try to update (none selected) and expect error
            massAddToReleaseController.massAdd_BySprint();
            System.assert(ApexPages.getMessages()[0].getDetail().contains('You must select at least 1 User Story to add to the Release'), 'Message is not correct');
            Set<Id> assertUserStoriesSelected = new Set<Id>();
            
            // now we select 2 user stories (1 from each sprint) and add them to the release            
            for(MassAddToReleaseExtension.sprintWrapper sprintWrapperItem : massAddToReleaseController.wrappedSprints){	
                for(MassAddToReleaseExtension.userStoryWrapper userStoryItem : sprintWrapperItem.usWrapper){
                    if(sprintWrapperItem.sprint.Name == sprint1Name){
                        userStoryItem.selected = true;
                        assertUserStoriesSelected.add(userStoryItem.userStory.Id);
                        break;
                    }
                    if(sprintWrapperItem.sprint.Name == sprint2Name){
                        userStoryItem.selected = true;
                        assertUserStoriesSelected.add(userStoryItem.userStory.Id);
                        break;
                    }
                }
            }
            massAddToReleaseController.massAdd_BySprint();
            System.assert(ApexPages.getMessages()[1].getDetail().contains('Your selected User Stories have been added to the Release'), 'Message is not correct');
            
            Integer assertFinalUserStoriesSelected = 0;
            for(MassAddToReleaseExtension.sprintWrapper sprintWrapperItem : massAddToReleaseController.wrappedSprints){	
                for(MassAddToReleaseExtension.userStoryWrapper userStoryItem : sprintWrapperItem.usWrapper){
                    if(sprintWrapperItem.selected) {
                        assertFinalUserStoriesSelected++;
                    }
                }
            }
            System.assertEquals(0, assertFinalUserStoriesSelected, 'Selected User Stories has to be 0');

            Map<Id,User_Story__c> userStoriesInReleaseById = new Map<Id,User_Story__c>([SELECT Id, Name FROM User_Story__c WHERE Sprint__c = :assertSprintsById.keySet() AND Release__c = :testRelease.Id]);
            System.assertEquals(2, userStoriesInReleaseById.size(), 'Number of user stories in release is not correct');
            System.assert(assertUserStoriesSelected.equals(userStoriesInReleaseById.keySet()), 'Lists have not the same values');

            Test.stopTest();
        }
    }
}