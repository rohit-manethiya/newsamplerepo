@IsTest
public with sharing class CopadoPromotionTestDefaults {
    public with sharing class UserStoryDefaults extends AbstractTestData {
        public ITestDefaults setFieldDefaults() {
            Id userStoryRecordTypeId = Schema.SObjectType.User_Story__c.getRecordTypeInfosByDeveloperName().get('User_Story').getRecordTypeId();
            Map<Schema.SObjectField, Object> defaults = new Map<Schema.SObjectField, Object> {
                User_Story__c.RecordTypeId => userStoryRecordTypeId,
                User_Story__c.User_Story_Title__c => 'My new User Story',
                User_Story__c.Promote_Change__c => true
            };
            testDataFieldDefaultsByObject.put(User_Story__c.SObjectType, defaults);
            return this;
        }
    }
  
  	public class PromotionDefaults extends AbstractTestData {
        public ITestDefaults setFieldDefaults() {
            Map<Schema.SObjectField, Object> defaults = new Map<Schema.SObjectField, Object> {
            };
            testDataFieldDefaultsByObject.put(Promotion__c.SObjectType, defaults);
            return this;
        }
    }

    public class PromotedUserStoryDefaults extends AbstractTestData {
        public ITestDefaults setFieldDefaults() {
            Map<Schema.SObjectField, Object> defaults = new Map<Schema.SObjectField, Object> {
            };
            testDataFieldDefaultsByObject.put(Promoted_User_Story__c.SObjectType, defaults);
            return this;
        }
    }
}