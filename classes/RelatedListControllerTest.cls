@IsTest
private with sharing class RelatedListControllerTest {
    @IsTest
    static void fetchRelatedListConfig() {
        Account acc = new Account(Name = 'test');
        insert acc;
        Contact cnt = new Contact(LastName = 'test', AccountId = acc.Id);
        insert cnt;

        RelatedListConfig config = RelatedListController.fetchRelatedListConfig(acc.Id, 'Contact', null);

        // If Contact does not have its own tab in the org it will be null so it can not be asserted
        // System.assertNotEquals(config.iconName, null, 'Contacts icon should not be null');
        System.assertEquals(config.childListName, 'Contacts', 'Child list name does not match');
        System.assertNotEquals(config.sobjectLabel, null, 'Object label should not be null');
        System.assertNotEquals(config.sobjectLabelPlural, null, 'Object plural label should not be null');
    }
}