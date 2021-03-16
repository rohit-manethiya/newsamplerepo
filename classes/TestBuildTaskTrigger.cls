@isTest
private class TestBuildTaskTrigger {
    @testSetup
    static void setupData() {
        TestUtilities.setTestSettingsEE();
        TestUtilities.insertAdminUsers(new List<String>{'copado-test-1@test.org', 'copado-test-2@test.org'});
    }
    static testMethod void test_LatestCIUpdates(){
        Continuous_Integration__c ci1 = new Continuous_Integration__c(Name='My CI 1', Active__c=true, Status__c='Draft');
        Continuous_Integration__c ci2 = new Continuous_Integration__c(Name='My CI 2', Active__c=true, Status__c='Draft');
        List<Continuous_Integration__c> cis = new List<Continuous_Integration__c>();
        cis.add(ci1);
        cis.add(ci2);
        insert cis;

        List<Build_Task__c> bts = new List<Build_Task__c>();
        bts.add(new Build_Task__c(Continuous_Integration__c=ci1.Id, Duration__c=1, Status__c='Pending'));
        bts.add(new Build_Task__c(Continuous_Integration__c=ci2.Id, Duration__c=2, Status__c='Pending'));
        insert bts;
        system.assertEquals(1,[select Last_Build_Task_Duration__c from Continuous_Integration__c where id =:ci1.id].Last_Build_Task_Duration__c);
        system.assertEquals(2,[select Last_Build_Task_Duration__c from Continuous_Integration__c where id =:ci2.id].Last_Build_Task_Duration__c);
        system.assertEquals('Pending',[select Status__c from Continuous_Integration__c where id =:ci1.id].Status__c);
        system.assertEquals('Pending',[select Status__c from Continuous_Integration__c where id =:ci2.id].Status__c);

        //set start time
        for(Build_Task__c bt:bts)bt.Status__c='In Progress';
        update bts;
        system.assertNotEquals(null,[select Start_Time__c from Build_Task__c where id=:bts[0].Id].Start_Time__c);
        system.assertNotEquals(null,[select Start_Time__c from Build_Task__c where id=:bts[1].Id].Start_Time__c);
        //set duration
        for(Build_Task__c bt:bts)bt.Status__c='Success';
        update bts;
        system.assertNotEquals(null,[select Duration__c from Build_Task__c where id=:bts[0].Id].Duration__c);
        system.assertNotEquals(null,[select Duration__c from Build_Task__c where id=:bts[1].Id].Duration__c);

        bts = new List<Build_Task__c>();
        bts.add(new Build_Task__c(Continuous_Integration__c=ci1.Id, Duration__c=10, Status__c='Failed'));
        bts.add(new Build_Task__c(Continuous_Integration__c=ci2.Id, Duration__c=20, Status__c='Success'));
        insert bts;

        system.assertEquals(10,[select Last_Build_Task_Duration__c from Continuous_Integration__c where id =:ci1.id].Last_Build_Task_Duration__c);
        system.assertEquals(20,[select Last_Build_Task_Duration__c from Continuous_Integration__c where id =:ci2.id].Last_Build_Task_Duration__c);
        system.assertEquals('Failed',[select Status__c from Continuous_Integration__c where id =:ci1.id].Status__c);
        system.assertEquals('Success',[select Status__c from Continuous_Integration__c where id =:ci2.id].Status__c);
    }
    static testMethod void test_prepareDataLogic_OnBuildFailure(){
        List<User> users = [select Id, UserType, Email from User where isActive=true and username like 'copado-test%' limit 2];
        Continuous_Integration__c ci1 = new Continuous_Integration__c(OwnerId=users[0].Id, Name='My CI', Active__c=true, Status__c='Draft');
        Continuous_Integration__c ci2 = new Continuous_Integration__c(OwnerId=users[1].Id, Name='My CI', Active__c=true, Status__c='Draft');
        List<Continuous_Integration__c> cis = new List<Continuous_Integration__c>();
        cis.add(ci1);
        cis.add(ci2);
        insert cis;

        List<Continuous_Integration_Permission__c> cips = [select Id, User__c, Email_Notification__c from Continuous_Integration_Permission__c where Continuous_Integration__c=:cis[0].Id or Continuous_Integration__c=:cis[1].Id];
        system.assertEquals(2, cips.size());
        for(Continuous_Integration_Permission__c c : cips){
            if(c.User__c==cis[0].OwnerId){
                c.Email_Notification__c='On Build Failure; On Build Success; On Deploy Failure; On Deploy Success';
            }
        }
        update cips;
        cips = [select Id, User__c, Email_Notification__c from Continuous_Integration_Permission__c where Continuous_Integration__c=:cis[0].Id or Continuous_Integration__c=:cis[1].Id];
        system.assertEquals(2, cips.size());
        Build_Task__c bt1 = new Build_Task__c(Continuous_Integration__c=cis[0].Id, Type__c='Validate', Status__c='Pending');
        Build_Task__c bt2 = new Build_Task__c(Continuous_Integration__c=cis[1].Id, Type__c='Deploy', Status__c='Pending');
        List<Build_Task__c> bts = new List<Build_Task__c>();
        bts.add(bt1);
        bts.add(bt2);
        insert bts;
        //List<SObject> os = new List<SObject>();
        //os.add(bt1);
        //os.add(bt2);

        Test.startTest();
        //BuildTaskTriggerHelper.prepareData(os);
        bts[0].Status__c='Failed';
        bts[1].Status__c='Pending';
        update bts;
        Test.stopTest();
        system.assertEquals(2, BuildTaskTriggerHelper.userMap.keySet().size());
        system.debug('@@@ Emails: '+BuildTaskTriggerHelper.emails);
        system.assertEquals(1, BuildTaskTriggerHelper.emails.size());
        // the above assertion comes back with 2, but we are expecting one.
    }
    static testMethod void test_queue_1(){
        BuildTaskTriggerHandler.skipSendingEmails = true;
        Deployment__c pre = new Deployment__c(Name='pre');
        insert pre;
        Continuous_Integration__c ci1 = new Continuous_Integration__c(Name='Test Queue', Active__c=true, Status__c='Draft', Pre_Deployment_Jobs__c=pre.Id);
        Continuous_Integration__c ci2 = new Continuous_Integration__c(Name='Test Queue 2', Active__c=true, Status__c='Draft', Post_Success_Deployment_Jobs__c=pre.Id);
        Continuous_Integration__c ci3 = new Continuous_Integration__c(Name='Test Queue 3', Active__c=true, Status__c='Draft');
        List<Continuous_Integration__c> cis = new List<Continuous_Integration__c>();
        cis.add(ci1);
        cis.add(ci2);
        cis.add(ci3);
        insert cis;
        Set<Id> ciIds = new Set<Id>();
        for(Continuous_Integration__c ci:cis)ciIds.add(ci.Id);
        Build_Task__c bt1 = new Build_Task__c(Continuous_Integration__c=cis[0].Id, Type__c='Validate', Status__c='Receiving');
        Build_Task__c bt2 = new Build_Task__c(Continuous_Integration__c=cis[1].Id, Type__c='Deploy', Status__c='Receiving');
        Build_Task__c bt3 = new Build_Task__c(Continuous_Integration__c=cis[2].Id, Type__c='Deploy', Status__c='Receiving');
        Build_Task__c bt4 = new Build_Task__c(Continuous_Integration__c=cis[0].Id, Type__c='Validate', Status__c='Receiving');
        Build_Task__c bt5 = new Build_Task__c(Continuous_Integration__c=cis[1].Id, Type__c='Deploy', Status__c='Receiving');
        List<Build_Task__c> bts = new List<Build_Task__c>();
        bts.add(bt1);
        bts.add(bt2);
        bts.add(bt3);
        bts.add(bt4);
        bts.add(bt5);
        insert bts;
        Test.startTest();
        //C1 bt1 and bt4 will be queued (only bt1 will be called out)
        bt1.Status__c='Queued';
        bt4.Status__c='Queued';
        //C2 bt2 and bt5 will be one queued but the other In Progress (no callouts since there 1 one already In Progress)
        bt2.Status__c='In Progress';
        bt5.Status__c='Queued';
        //C3 bt3 is a basic ci no pre/post jobs (no callouts)
        bt3.Status__c='In Progress';
        update bts;
        system.Assert(BuildTaskTriggerHelper.calloutIds.contains(bt1.Id));
        system.assertEquals(1,BuildTaskTriggerHelper.calloutIds.size());
        Test.stopTest();
    }

    static testMethod void test_queue_2(){
        BuildTaskTriggerHandler.skipSendingEmails = true;
        Deployment__c pre = new Deployment__c(Name='pre');
        insert pre;
        Continuous_Integration__c ci1 = new Continuous_Integration__c(Name='Test Queue', Active__c=true, Status__c='Draft', Pre_Deployment_Jobs__c=pre.Id);
        Continuous_Integration__c ci2 = new Continuous_Integration__c(Name='Test Queue 2', Active__c=true, Status__c='Draft', Post_Success_Deployment_Jobs__c=pre.Id);
        Continuous_Integration__c ci3 = new Continuous_Integration__c(Name='Test Queue 3', Active__c=true, Status__c='Draft');
        List<Continuous_Integration__c> cis = new List<Continuous_Integration__c>();
        cis.add(ci1);
        cis.add(ci2);
        cis.add(ci3);
        insert cis;
        Set<Id> ciIds = new Set<Id>();
        for(Continuous_Integration__c ci:cis)ciIds.add(ci.Id);
        Build_Task__c bt1 = new Build_Task__c(Continuous_Integration__c=cis[0].Id, Type__c='Validate', Status__c='Receiving');
        Build_Task__c bt2 = new Build_Task__c(Continuous_Integration__c=cis[1].Id, Type__c='Deploy', Status__c='Receiving');
        Build_Task__c bt3 = new Build_Task__c(Continuous_Integration__c=cis[2].Id, Type__c='Deploy', Status__c='Receiving');
        Build_Task__c bt4 = new Build_Task__c(Continuous_Integration__c=cis[0].Id, Type__c='Validate', Status__c='Receiving');
        Build_Task__c bt5 = new Build_Task__c(Continuous_Integration__c=cis[1].Id, Type__c='Deploy', Status__c='Receiving');
        List<Build_Task__c> bts = new List<Build_Task__c>();
        bts.add(bt1);
        bts.add(bt2);
        bts.add(bt3);
        bts.add(bt4);
        bts.add(bt5);
        insert bts;
        Test.startTest();
        //C1 bt1 now In Progress and bt4 stays queued (no callouts)
        bt1.Status__c='In Progress';
        bt4.Status__c='Queued';
        //C2 bt2 now is Success bt5 must be called out
        bt2.Status__c='Success';
        bt5.Status__c='Queued';
        //C3 bt3 is a basic ci no pre/post jobs (no callouts)
        bt3.Status__c='Success';
        update bts;
        system.Assert(BuildTaskTriggerHelper.calloutIds.contains(bt5.Id));
        system.assertEquals(1,BuildTaskTriggerHelper.calloutIds.size());
        Test.stopTest();
    }

    static testMethod void test_queue_3(){
        BuildTaskTriggerHandler.skipSendingEmails = true;
        Deployment__c pre = new Deployment__c(Name='pre');
        insert pre;
        Continuous_Integration__c ci1 = new Continuous_Integration__c(Name='Test Queue', Active__c=true, Status__c='Draft', Pre_Deployment_Jobs__c=pre.Id);
        Continuous_Integration__c ci2 = new Continuous_Integration__c(Name='Test Queue 2', Active__c=true, Status__c='Draft', Post_Success_Deployment_Jobs__c=pre.Id);
        Continuous_Integration__c ci3 = new Continuous_Integration__c(Name='Test Queue 3', Active__c=true, Status__c='Draft');
        List<Continuous_Integration__c> cis = new List<Continuous_Integration__c>();
        cis.add(ci1);
        cis.add(ci2);
        cis.add(ci3);
        insert cis;
        Set<Id> ciIds = new Set<Id>();
        for(Continuous_Integration__c ci:cis)ciIds.add(ci.Id);
        Build_Task__c bt1 = new Build_Task__c(Continuous_Integration__c=cis[0].Id, Type__c='Validate', Status__c='Receiving');
        Build_Task__c bt2 = new Build_Task__c(Continuous_Integration__c=cis[1].Id, Type__c='Deploy', Status__c='Receiving');
        Build_Task__c bt3 = new Build_Task__c(Continuous_Integration__c=cis[2].Id, Type__c='Deploy', Status__c='Receiving');
        Build_Task__c bt4 = new Build_Task__c(Continuous_Integration__c=cis[0].Id, Type__c='Validate', Status__c='Receiving');
        Build_Task__c bt5 = new Build_Task__c(Continuous_Integration__c=cis[1].Id, Type__c='Deploy', Status__c='Receiving');
        List<Build_Task__c> bts = new List<Build_Task__c>();
        bts.add(bt1);
        bts.add(bt2);
        bts.add(bt3);
        bts.add(bt4);
        bts.add(bt5);
        insert bts;
        Test.startTest();
        //C1 bt1 now Success and bt4 must be called out
        bt1.Status__c='Success';
        bt4.Status__c='Queued';
        //C2 bt5 now is In Progress (no callouts)
        bt2.Status__c='Success';
        bt5.Status__c='In Progress';
        update bts;
        system.Assert(BuildTaskTriggerHelper.calloutIds.contains(bt4.Id));
        system.assertEquals(1,BuildTaskTriggerHelper.calloutIds.size());
        Test.stopTest();
    }

    static testMethod void test_queue_4(){
        BuildTaskTriggerHandler.skipSendingEmails = true;
        Deployment__c pre = new Deployment__c(Name='pre');
        insert pre;
        Continuous_Integration__c ci1 = new Continuous_Integration__c(Name='Test Queue', Active__c=true, Status__c='Draft', Pre_Deployment_Jobs__c=pre.Id);
        Continuous_Integration__c ci2 = new Continuous_Integration__c(Name='Test Queue 2', Active__c=true, Status__c='Draft', Post_Success_Deployment_Jobs__c=pre.Id);
        Continuous_Integration__c ci3 = new Continuous_Integration__c(Name='Test Queue 3', Active__c=true, Status__c='Draft');
        List<Continuous_Integration__c> cis = new List<Continuous_Integration__c>();
        cis.add(ci1);
        cis.add(ci2);
        cis.add(ci3);
        insert cis;
        Set<Id> ciIds = new Set<Id>();
        for(Continuous_Integration__c ci:cis)ciIds.add(ci.Id);
        Build_Task__c bt1 = new Build_Task__c(Continuous_Integration__c=cis[0].Id, Type__c='Validate', Status__c='Receiving');
        Build_Task__c bt2 = new Build_Task__c(Continuous_Integration__c=cis[1].Id, Type__c='Deploy', Status__c='Receiving');
        Build_Task__c bt3 = new Build_Task__c(Continuous_Integration__c=cis[2].Id, Type__c='Deploy', Status__c='Receiving');
        Build_Task__c bt4 = new Build_Task__c(Continuous_Integration__c=cis[0].Id, Type__c='Validate', Status__c='Receiving');
        Build_Task__c bt5 = new Build_Task__c(Continuous_Integration__c=cis[1].Id, Type__c='Deploy', Status__c='Receiving');
        List<Build_Task__c> bts = new List<Build_Task__c>();
        bts.add(bt1);
        bts.add(bt2);
        bts.add(bt3);
        bts.add(bt4);
        bts.add(bt5);
        insert bts;
        Test.startTest();
        //C1 bt4 now In Progress (no callouts)
        bt4.Status__c='In Progress';
        //C2 bt5 now is Failed (no callouts)
        bt2.Status__c='Success';
        bt5.Status__c='Failed';
        update bts;
        system.assertEquals(0,BuildTaskTriggerHelper.calloutIds.size());
        Test.stopTest();
    }

    static testMethod void test_queue_5(){
        BuildTaskTriggerHandler.skipSendingEmails = true;
        Deployment__c pre = new Deployment__c(Name='pre');
        insert pre;
        Continuous_Integration__c ci1 = new Continuous_Integration__c(Name='Test Queue', Active__c=true, Status__c='Draft', Pre_Deployment_Jobs__c=pre.Id);
        Continuous_Integration__c ci2 = new Continuous_Integration__c(Name='Test Queue 2', Active__c=true, Status__c='Draft', Post_Success_Deployment_Jobs__c=pre.Id);
        Continuous_Integration__c ci3 = new Continuous_Integration__c(Name='Test Queue 3', Active__c=true, Status__c='Draft');
        List<Continuous_Integration__c> cis = new List<Continuous_Integration__c>();
        cis.add(ci1);
        cis.add(ci2);
        cis.add(ci3);
        insert cis;
        Set<Id> ciIds = new Set<Id>();
        for(Continuous_Integration__c ci:cis)ciIds.add(ci.Id);
        Build_Task__c bt1 = new Build_Task__c(Continuous_Integration__c=cis[0].Id, Type__c='Validate', Status__c='Receiving');
        Build_Task__c bt2 = new Build_Task__c(Continuous_Integration__c=cis[1].Id, Type__c='Deploy', Status__c='Receiving');
        Build_Task__c bt3 = new Build_Task__c(Continuous_Integration__c=cis[2].Id, Type__c='Deploy', Status__c='Receiving');
        Build_Task__c bt4 = new Build_Task__c(Continuous_Integration__c=cis[0].Id, Type__c='Validate', Status__c='Receiving');
        Build_Task__c bt5 = new Build_Task__c(Continuous_Integration__c=cis[1].Id, Type__c='Deploy', Status__c='Receiving');
        List<Build_Task__c> bts = new List<Build_Task__c>();
        bts.add(bt1);
        bts.add(bt2);
        bts.add(bt3);
        bts.add(bt4);
        bts.add(bt5);
        insert bts;
        Test.startTest();
        //C1 bt4 now a Success (no callouts)
        bt4.Status__c='Success';
        update bts;
        system.assertEquals(0,BuildTaskTriggerHelper.calloutIds.size());
        Test.stopTest();
    }
}