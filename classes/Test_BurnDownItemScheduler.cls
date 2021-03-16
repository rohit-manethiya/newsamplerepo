/**
 * Created by ferhatozsavran on 5/31/18.
 */

@IsTest
public with sharing class Test_BurnDownItemScheduler {

    @testSetup static void setupData() {
        TestUtilities.enableLicenses(2, 2, 2, 2, 2);
    }

    @IsTest
    static void burndownItemTest() {

        TestUtilities tu = new TestUtilities();

        // Create user to assign as developer to the user stories
        tu.insertSObject('User', new Map<String,Object>{
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

        TestUtilities.assignLicense(String.valueOf(tu.item('User',0).get('Username')), true, true, true, true, true);

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
                'Developer__c' => tu.item('User',0).Id
        });

        // Create previous sprint record
        tu.insertSObject('Sprint__c', new Map<String,Object>{
                'Name' => 'Sprint 1',
                'Start_Date__c' => Date.today().addDays(-16),
                'End_Date__c' => Date.today().addDays(-9)
        });

        // Create 8 burndownitem  for sprint
        tu.insertSObjects('Burndown_Item__c', 8, new Map<String,Object>{
                'Sprint__c' => tu.item('Sprint__c',1).Id,
                'Date__c' => Date.today().addDays(-9),
                'Expected_Story_Point__c' => 100,
                'Total_Story_Point__c' => 90
        });

        // Create 77 user story to previous sprint
        tu.insertSObjects('User_Story__c', 77, new Map<String,Object>{
                'User_Story_Title__c' => 'us-0000000',
                'Status__c' => 'Completed',
                'Sprint__c' => tu.item('Sprint__c',1).Id,
                'Story_Points_SFDC__c' => 3
        });

        System.runAs((User)tu.item('User',0)) {
            Test.startTest();
            String hour = String.valueOf(Datetime.now().hour());
            Integer minutes = (Datetime.now().minute() + 5) >= 60 ? (Datetime.now().minute() + 5) - 60 : Datetime.now().minute() + 5;
            String min = String.valueOf(minutes);
            String ss = String.valueOf(Datetime.now().second());

            //parse to cron expression
            String nextFireTime = ss + ' ' + min + ' ' + hour + ' * * ?';

            BurnDownItemScheduler s = new BurnDownItemScheduler();
            System.schedule('Burndown Item Job Started At' + String.valueOf(Datetime.now()), nextFireTime, s);
            Test.stopTest();
        }
    }

    @IsTest
    static void burndownItemExistingBurndDownTest() {

        TestUtilities tu = new TestUtilities();

        // Create user to assign as developer to the user stories
        tu.insertSObject('User', new Map<String,Object>{
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

        TestUtilities.assignLicense(String.valueOf(tu.item('User',0).get('Username')), true, true, true, true, true);

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
                'Developer__c' => tu.item('User',0).Id
        });

        // Create previous sprint record
        tu.insertSObject('Sprint__c', new Map<String,Object>{
                'Name' => 'Sprint 1',
                'Start_Date__c' => Date.today().addDays(-8),
                'End_Date__c' => Date.today().addDays(8)
        });

        // Create 8 burndownitem  for sprint
        tu.insertSObjects('Burndown_Item__c', 8, new Map<String,Object>{
                'Sprint__c' => tu.item('Sprint__c',1).Id,
                'Date__c' => Date.today().addDays(-8),
                'Expected_Story_Point__c' => 100,
                'Total_Story_Point__c' => 90
        });

        // Create 77 user story to previous sprint
        tu.insertSObjects('User_Story__c', 77, new Map<String,Object>{
                'User_Story_Title__c' => 'us-0000000',
                'Status__c' => 'Completed',
                'Sprint__c' => tu.item('Sprint__c',1).Id,
                'Story_Points_SFDC__c' => 3
        });

        System.runAs((User)tu.item('User',0)) {
            Test.startTest();
            String hour = String.valueOf(Datetime.now().hour());
            Integer minutes = (Datetime.now().minute() + 5) >= 60 ? (Datetime.now().minute() + 5) - 60 : Datetime.now().minute() + 5;
            String min = String.valueOf(minutes);
            String ss = String.valueOf(Datetime.now().second());

            //parse to cron expression
            String nextFireTime = ss + ' ' + min + ' ' + hour + ' * * ?';

            BurnDownItemScheduler s = new BurnDownItemScheduler();
            System.schedule('Burndown Item Job Started At' + String.valueOf(Datetime.now()), nextFireTime, s);
            Test.stopTest();
        }
    }

    @IsTest
    static void runBurnDownDirectly() {

        TestUtilities tu = new TestUtilities();

        // Create user to assign as developer to the user stories
        tu.insertSObject('User', new Map<String,Object>{
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

        TestUtilities.assignLicense(String.valueOf(tu.item('User',0).get('Username')), true, true, true, true, true);

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
                'Developer__c' => tu.item('User',0).Id
        });

        // Create previous sprint record
        tu.insertSObject('Sprint__c', new Map<String,Object>{
                'Name' => 'Sprint 1',
                'Start_Date__c' => Date.today().addDays(-8),
                'End_Date__c' => Date.today().addDays(8)
        });

        // Create 8 burndownitem  for sprint
        tu.insertSObjects('Burndown_Item__c', 8, new Map<String,Object>{
                'Sprint__c' => tu.item('Sprint__c',1).Id,
                'Date__c' => Date.today().addDays(-8),
                'Expected_Story_Point__c' => 100,
                'Total_Story_Point__c' => 90
        });

        // Create 77 user story to previous sprint
        tu.insertSObjects('User_Story__c', 77, new Map<String,Object>{
                'User_Story_Title__c' => 'us-0000000',
                'Status__c' => 'Completed',
                'Sprint__c' => tu.item('Sprint__c',1).Id,
                'Story_Points_SFDC__c' => 3
        });

        System.runAs((User)tu.item('User',0)) {
            Test.startTest();
            String hour = String.valueOf(Datetime.now().hour());
            Integer minutes = (Datetime.now().minute() + 5) >= 60 ? (Datetime.now().minute() + 5) - 60 : Datetime.now().minute() + 5;
            String min = String.valueOf(minutes);
            String ss = String.valueOf(Datetime.now().second());

            //parse to cron expression
            String nextFireTime = ss + ' ' + min + ' ' + hour + ' * * ?';
            BurnDownItemScheduler.scheduleIt('Burndown Item Job Started At', nextFireTime);
            Test.stopTest();
        }
    }
}