public without sharing class OrgTriggerHelper {
	private static boolean sched = false;
	private static String[] idsToRemoveAttach = new String[]{};
    private static Map<String, Environment__c> environmentMap;
	public static List<Environment__c> environments;

    public static void prepareData(List<SObject> records){
        environments = new List<Environment__c>();
        environmentMap = new Map<String, Environment__c>();
        Set<String> orgIds = new Set<String>();
        // NR: unneeded. Java oauth part will handle clashing.
        //Map<String,Integer> unique_ids = new Map<String,Integer>();
        
        for(SObject so : records){
            Org__c o = (Org__c)so;
            String tmp = extractOrgId((String)o.SFDC_Org_ID__c);
            if(tmp!=null)orgIds.add(tmp);
            // prevent unique sfdc org id field to clash when adding multiple org credentials for the same org
            // NR: unneeded. Java oauth part will handle clashing.
            //if(isValidCopadoSFDC_Org_Id(o.SFDC_Org_ID__c))unique_ids.put(getBaseSFDC_Org_Id(o.SFDC_Org_ID__c),0);
        }
        Set<Id> eids = new Set<Id>();
        for(Environment__c e : [select Id, Name, Org_ID__c from Environment__c where Org_ID__c IN :orgIds]){
            environmentMap.put(e.Org_ID__c, e);
            eids.add(e.Id);
        }
        for(SObject so : records){
            Org__c neworg = (Org__c)so;
            String sfdcorgId = extractOrgId((String)neworg.SFDC_Org_ID__c);
			Environment__c e = environmentMap.get(sfdcorgId);
            if(!environmentMap.containsKey(sfdcorgId)){

                e = new Environment__c();
                e.Name = neworg.Name;
                e.Type__c = neworg.Org_Type__c;
                e.Org_ID__c = sfdcorgId;
                environments.add(e);
            }        
        }
        Utilities.Secure_DML(environments, Utilities.DML_Action.UPS, schema.Sobjecttype.Environment__c);
        
        for(Environment__c e : [select Id, Name, Org_ID__c from Environment__c where Org_ID__c IN :orgIds]){
            environmentMap.put(e.Org_ID__c, e);
            eids.add(e.Id);
        }
        
        /* NR: unneeded. Java oauth part will handle clashing.

        //query if exist already a clashing org credential
        if(Trigger.new !=null) {
            for(Org__c o:[select Id, SFDC_Org_ID__c from Org__c where SFDC_Org_ID__c!='' and (not (id in :Trigger.newMap.keyset()))]){
                if( isValidCopadoSFDC_Org_Id(o.SFDC_Org_ID__c) && unique_ids.containsKey(getBaseSFDC_Org_Id(o.SFDC_Org_ID__c))){
                    Integer current = unique_ids.get(getBaseSFDC_Org_Id(o.SFDC_Org_ID__c));
                    unique_ids.put(getBaseSFDC_Org_Id(o.SFDC_Org_ID__c), current+1);   
                }
            }
            //set the SFDC_Org_Id with an un-clashing one
            for(SObject so:Trigger.new){
                Org__c o = (Org__c)so;
                //this will only add a copy number when there is a clash and it doen't have a copy number already. 
                if(isValidCopadoSFDC_Org_Id(o.SFDC_Org_ID__c) && unique_ids.get(o.SFDC_Org_ID__c)>0){
                    o.SFDC_Org_ID__c += '_'+ unique_ids.get(o.SFDC_Org_ID__c);
                }
            }
        }
		*/
    }
	public static Boolean isScheduled(Org__c o){
		if(o.Test_Frequency__c!=null && o.Test_Frequency__c!='None' && o.Validated_Date__c!=null){
			sched = true;
			return true;
		}
		return false;
	}
	public static void checkApexTest(Org__c o){
		if(isScheduled(o) && !FeatureHelper.isFeatureEnabled('Apex Test')){
			o.Test_Frequency__c = 'None';
		}
	}
	public static void enforceScheduler(){
		if(sched)BatchHelper.enforceScheduler();
	}
	public static void isMetadataChanged(Org__c o, Org__c old){
		if(old.Metadata_Types__c != o.Metadata_Types__c){
			idsToRemoveAttach.add(o.id);
		}
	}
	public static void deleteMetadataAttachments(){
        Utilities.Secure_DML([SELECT Id FROM Attachment where ParentId = :idsToRemoveAttach and Name ='MetaData'], Utilities.DML_Action.DEL, schema.Sobjecttype.Attachment);
	}
    public static void setOrgEnvironment(Org__c neworg){
        String newId = extractOrgId(neworg.SFDC_Org_ID__c);
        //boolean isValidated = (neworg.Validated_Date__c!=null)?true:false;
        System.debug('**** set org environament for SFDC_Org_ID__c: ' + neworg.SFDC_Org_ID__c);
        System.debug('**** set org environament for newId: ' + newId);
        System.debug('**** env map: ' + environmentMap);
        if(newId != null){
            neworg.environment__c = environmentMap.get(newId).Id;
        }
    }
    private static String extractOrgId(String s){
        if(s==null)return null;
        if(s.length() >= 37 && s.contains('_'))return s.split('_')[0];
        if(s.length() == 18 && s.startsWith('00D'))return s;
        return null;
    }
    private static boolean isValidCopadoSFDC_Org_Id(String oid){
        return String.isNotBlank(oid) && oid.length()>=37;
    }
    private static String getBaseSFDC_Org_Id(String oid){
        if(!isValidCopadoSFDC_Org_Id(oid))return oid;
        return oid.substring(0, 37);
    }
}