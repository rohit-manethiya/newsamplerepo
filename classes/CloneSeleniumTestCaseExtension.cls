public with sharing class CloneSeleniumTestCaseExtension {
    public final Selenium_Test_Case__c tc{get;set;}
    public Selenium_Test_Case__c clonedTC{get;set;}
    public CloneSeleniumTestCaseExtension(ApexPages.StandardController stdController) {
        tc = [SELECT id, name, Version__c FROM Selenium_Test_Case__c WHERE id = :stdController.getId()];
        clonedTC = tc.clone();
        // A new version must be created.
        Integer next = 1;
        try{
            System.debug('tc.Version__c='+tc.Version__c);
            next = Integer.valueOf(tc.Version__c.replace('v','')) + 1;
        }catch(Exception e) {
            System.debug('Error parsing the attachment name for the next version '+e);
            next = 2;
        }
        if(!Schema.SObjectType.Selenium_Test_Case__c.fields.Version__c.isCreateable() || !Schema.SObjectType.Selenium_Test_Case__c.fields.Previous_Version__c.isCreateable() || !Schema.SObjectType.Selenium_Test_Case__c.fields.Name.isCreateable()){
            return;
        }
        clonedTC.Version__c = ''+next;
        clonedTC.Previous_Version__c = tc.Id;
        clonedTC.Name = clonedTC.Name.replaceAll('-v[0-9]+$', '')+'-v'+clonedTC.Version__c;
    }

    public PageReference doClone(){
        Utilities.Secure_DML(clonedTC, Utilities.DML_Action.INS, schema.Sobjecttype.Selenium_Test_Case__c);

        Attachment[] sobs;
        List<Id> doneIds = new List<Id>();
        do {
            if(Schema.SObjectType.Attachment.isQueryable() && Schema.SObjectType.Attachment.isAccessible()){
                sobs = [SELECT Id, ParentId, Name, Description, Body, ContentType
                        FROM Attachment
                        WHERE ParentId = :tc.Id
                        AND Id NOT IN :doneIds
                        LIMIT 1
                ];
            }
            if (sobs.size() == 1) {
                Attachment sob = sobs[0];
                if( sob.Name == 'Copado.SeleniumTestCase.json' ) {
                    Map<String, Object> tc = (Map<String, Object>)JSON.deserializeUntyped(sob.Body.toString());
                    tc.put('name', (String)clonedTC.Name);
                    sob.Body = Blob.valueOf(JSON.serialize(tc));
                }
                Utilities.Secure_DML(new Attachment(
                        ParentId = clonedTC.Id,
                        Name = sob.Name,
                        Description = sob.Description,
                        Body = sob.Body,
                        ContentType = sob.ContentType
                        ), Utilities.DML_Action.INS, schema.Sobjecttype.Attachment);
                doneIds.add(sob.Id);
                System.debug('>>> loop heap=' + Limits.getHeapSize());
            }
        } while (sobs.size() == 1);


        return new PageReference('/'+clonedTC.Id);
    }
}