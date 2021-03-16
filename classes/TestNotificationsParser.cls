@isTest
public with sharing class TestNotificationsParser {
    static testMethod void test_NotifParser(){
        Copado_Notification__c c1 = new Copado_Notification__c();
        Copado_Notification__c c2 = new Copado_Notification__c();

        c1.Message__c = '';
        insert c1;
        c1 = [select id, isFinished__c, isSuccess__c, Status__c FROM Copado_Notification__c WHERE Id = :c1.id];
        System.assertEquals(null, c1.status__c);
        System.assertEquals(false, c1.isFinished__c);
        System.assertEquals(false, c1.isSuccess__c);

        c2.Message__c = '{"status": "terminated","isFinished":true,"isSuccess":false}';
        insert c2;
        c2 = [select id, isFinished__c, isSuccess__c, Status__c FROM Copado_Notification__c WHERE Id = :c2.id];
        System.assertEquals(true, c2.isFinished__c);
        System.assertEquals(false, c2.isSuccess__c);
        System.assertEquals('terminated', c2.Status__c);
    }
}