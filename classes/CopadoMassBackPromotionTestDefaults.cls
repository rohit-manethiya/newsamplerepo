public with sharing class CopadoMassBackPromotionTestDefaults {
    public with sharing class PromotedUserStoryDefaults extends AbstractTestData {
        public ITestDefaults setFieldDefaults() {
            Map<Schema.SObjectField, Object> defaults = new Map<Schema.SObjectField, Object>{
                Promoted_User_Story__c.Name => 'MyPromotedUSerStory'
            };
            testDataFieldDefaultsByObject.put(Promoted_User_Story__c.SObjectType, defaults);
            return this;
        }
    }

    public with sharing class PromotionDefaults extends AbstractTestData {
        public ITestDefaults setFieldDefaults() {
            Map<Schema.SObjectField, Object> defaults = new Map<Schema.SObjectField, Object> {
            };
            testDataFieldDefaultsByObject.put(Promotion__c.SObjectType, defaults);
            return this;
        }
    }
}