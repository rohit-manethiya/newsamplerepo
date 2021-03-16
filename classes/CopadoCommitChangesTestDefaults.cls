@IsTest
public class CopadoCommitChangesTestDefaults {
    
    public class PipelineDefaults extends AbstractTestData {
        public ITestDefaults setFieldDefaults() {
            Map<Schema.SObjectField, Object> defaults = new Map<Schema.SObjectField, Object> {
                Deployment_Flow__c.Name => 'MyPipeline',
                Deployment_Flow__c.Active__c => true,
                Deployment_Flow__c.Main_Branch__c => 'master'
            };
            testDataFieldDefaultsByObject.put(Deployment_Flow__c.SObjectType, defaults);
            return this;
        }
    }
}