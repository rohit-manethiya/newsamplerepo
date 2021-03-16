public class EnvironmentalVariableTriggerHelpler {

    public static Map<String, Boolean> existingEnvironmentalVariablesMap { get; set; }
    public static Map<String, Boolean> updatingEnvironmentalVariablesMap { get; set; }

    public static void prepareData() {
        Set<String> environmentSet = new Set<String>();
        existingEnvironmentalVariablesMap = new Map<String, Boolean>();
        updatingEnvironmentalVariablesMap = new Map<String, Boolean>();
        for(SObject so : Trigger.new) {
            Environmental_Variable__c envVar = (Environmental_Variable__c) so;
            environmentSet.add(envVar.Environment__c);
        }

        for(Environmental_Variable__c ev : [SELECT Name, Environment__c, Value__c FROM Environmental_Variable__c WHERE Environment__c != NULL AND Environment__c = :environmentSet]) {
            existingEnvironmentalVariablesMap.put(ev.Name + ev.Environment__c, true);
            existingEnvironmentalVariablesMap.put(ev.Value__c + ev.Environment__c, true);
        }
    }

    public static void checkForDuplicates(Environmental_Variable__c ev) {
        if(existingEnvironmentalVariablesMap.containsKey(ev.Name + ev.Environment__c) || existingEnvironmentalVariablesMap.containsKey(ev.Value__c + ev.Environment__c)) {
            ev.addError(Label.DUPLICATED_ENVIRONMENTAL_VARIABLE);
        }
    }

    public static void checkForDuplicatesUpdate(Environmental_Variable__c ev) {
        if(updatingEnvironmentalVariablesMap.containsKey(ev.Value__c + ev.Environment__c)) {
            ev.addError(Label.DUPLICATED_ENVIRONMENTAL_VARIABLE);
        } else {
            updatingEnvironmentalVariablesMap.put(ev.Value__c + ev.Environment__c, true);
        }
    }
}