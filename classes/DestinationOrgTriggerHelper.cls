public without sharing class DestinationOrgTriggerHelper {
    private static Map<String, Org__c> orgMap = new Map<String, Org__c>();
    private static List<Deployment_History__c> history = new List<Deployment_History__c>();
    public static void prepareData() {
        if (Trigger.new != null) {
            for (SObject so : Trigger.new) {
                Destination_Org__c d = (Destination_Org__c) so;
                if (d.To_Org__c != null)
                    orgMap.put(d.To_Org__c, null);
            }
        }
        if (Trigger.old != null) {
            for (SObject so : Trigger.old) {
                Destination_Org__c d = (Destination_Org__c) so;
                if (d.To_Org__c != null)
                    orgMap.put(d.To_Org__c, null);
            }
        }
        for (Org__c org : [SELECT Id, Name, Environment__r.Org_ID__c FROM Org__c WHERE Id IN :orgMap.keySet()]) {
            orgMap.put(org.id, org);
        }
    }
    public static void addHistory(Destination_Org__c d, String event) {
        Deployment_History__c h = new Deployment_History__c(
            Deployment_Id__c = d.Deployment__c,
            Deployment__c = d.Deployment__c,
            Date__c = System.now(),
            Event__c = event,
            Object__c = 'Destination Org',
            User__c = UserInfo.getUserId(),
            Field__c = 'Destination Org'
        );
        if (event == 'Created')
            h.New_Value__c = d.To_Org__c;
        if (event == 'Deleted')
            h.Old_Value__c = d.To_Org__c;
        if (String.isNotBlank(h.New_Value__c) && orgMap.containsKey(h.New_Value__c))
            h.New_Value__c = orgMap.get(h.New_Value__c).Name + ' (' + orgMap.get(h.New_Value__c).Environment__r.Org_ID__c + ')';
        if (String.isNotBlank(h.Old_Value__c) && orgMap.containsKey(h.Old_Value__c))
            h.Old_Value__c = orgMap.get(h.Old_Value__c).Name + ' (' + orgMap.get(h.Old_Value__c).Environment__r.Org_ID__c + ')';
        history.add(h);
    }
    public static void insertHistory() {
        insert history;
        history.clear();
    }
}