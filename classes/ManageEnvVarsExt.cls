public with sharing class ManageEnvVarsExt {

    public List<ManagedEnvVars> managedEnvVarsList { get; set; }
    public Boolean editing { get; set; }
    public String newEnvVarName { get; set; }
    public String deleteVarName { get; set; }
    private Id deploymentFlowId;
    public Map<String, String> envNameWithId = new Map<String, String>();
    private final String CONTINOUSINTEGRATION = ' - CI';
    private final String C_COLON = ': ';
    private final String C_DOT = '.';


    public ManageEnvVarsExt(ApexPages.StandardController std) {
        infoMessages();
        editing = false;
        deploymentFlowId = std.getId();
    }

    /**
     * This is used to show info messages on the page. They will appear at the first time you opened page
     */
    public void infoMessages() {
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, Label.ENV_VARS_VALUE_REQUIRED));
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, Label.ENV_VARS_UNIQUE_ENVIRONMENT));
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, Label.ENV_VARS_EASY_VALUES));
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, Label.ENV_VARS_GOOD_VALUES));
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, Label.ENV_VARS_COMMIT));
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, Label.ENV_VARS_DEPLOY));
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, Label.ENV_VARS_MORE + ' <a href="' + Label.ENV_VARS_DOCS + '">' + Label.ENV_VARS_DOCS + '</a>'));
    }

    /**
     * This is used to create environmental variable with empty values. (Just if you created continuous integration and included in your flow)
     * NOTE: it is called at page action
     */
    public void createMissingVars() {
        String repo;
        Set<String> branchNameSet = new Set<String>();
        if(Schema.SObjectType.Deployment_Flow_Step__c.isQueryable() && Schema.SObjectType.Deployment_Flow_Step__c.isAccessible()) {
            for(Deployment_Flow_Step__c dfs : [
                    SELECT Source_Environment__c, Destination_Environment__c, Source_Environment__r.Name, Destination_Environment__r.Name, Branch__c, Deployment_Flow__r.Git_Repository__c
                    FROM Deployment_Flow_Step__c
                    WHERE Deployment_Flow__c = :deploymentFlowId
            ]) {
                envNameWithId.put(dfs.Source_Environment__r.Name, dfs.Source_Environment__c);
                envNameWithId.put(dfs.Destination_Environment__r.Name, dfs.Destination_Environment__c);

                branchNameSet.add(dfs.Branch__c);
                repo = dfs.Deployment_Flow__r.Git_Repository__c;
            }
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Schema.SObjectType.Deployment_Flow_Step__c.getName() + C_COLON + Label.Insufficient_Access_Rights));
            return;
        }

        if(Schema.SObjectType.Continuous_Integration__c.isQueryable() && Schema.SObjectType.Continuous_Integration__c.isAccessible()) {
            for(Continuous_Integration__c ci : [
                    SELECT Destination_Org_Credential__r.Environment__c, Destination_Org_Credential__r.Environment__r.Name
                    FROM Continuous_Integration__c
                    WHERE Branch__c IN :branchNameSet AND Git_Repository__c = :repo
            ]) {
                String ciEnvironmentName = ci.Destination_Org_Credential__r.Environment__r.Name + CONTINOUSINTEGRATION;
                envNameWithId.put(ciEnvironmentName, ci.Destination_Org_Credential__r.Environment__c);
            }
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Schema.SObjectType.Continuous_Integration__c.getName() + C_COLON + Label.Insufficient_Access_Rights));
            return;
        }

        Boolean missingVariables = false;
        Map<String, Environmental_Variable__c> keyWithEV = new Map<String, Environmental_Variable__c>();

        Set<String> evName = new Set<String>();
        List<String> evNameList = new List<String>();

        if(Schema.SObjectType.Environmental_Variable__c.isQueryable() && Schema.SObjectType.Environmental_Variable__c.isAccessible()) {
            for(Environmental_Variable__c ev : [SELECT Environment__c, Id, Name, Value__c, Environment__r.Name FROM Environmental_Variable__c WHERE Environment__c IN :envNameWithId.values() ORDER BY Name]) {
                evName.add(ev.Name);
                String basicKey = ev.Name + C_DOT + ev.Environment__r.Name;
                String eVariableKeys = envNameWithId.containsKey(ev.Environment__r.Name) ? basicKey : basicKey + CONTINOUSINTEGRATION;
                keyWithEV.put(eVariableKeys, ev);
            }
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Schema.SObjectType.Environmental_Variable__c.getName() + C_COLON + Label.Insufficient_Access_Rights));
            return;
        }

        evNameList.addAll(evName);
        System.debug('*;evNameList' + evNameList);
        List<String> envName = getEnvNames();
        System.debug('*;envName' + envName);
        List<Environmental_Variable__c> environmentalVariableList = new List<Environmental_Variable__c>();
        for(Integer i = 0; i < evNameList.size(); i++) {
            for(Integer j = 1; j < envName.size(); j++) {
                if(keyWithEV.containsKey(evNameList[i] + C_DOT + envName[j])) {
                    environmentalVariableList.add(keyWithEV.get(evNameList[i] + C_DOT + envName[j]));
                } else {
                    missingVariables = true;
                    environmentalVariableList.add(new Environmental_Variable__c(Environment__c = envNameWithId.get(envName[j]), Name = evNameList[i]));
                }
            }
        }
        System.debug('**environmentalVariableList' + environmentalVariableList);
        System.debug('**environmentalVariableList' + environmentalVariableList.size());
        managedEnvVarsList = getEnvVars(environmentalVariableList);

        // If current customers are missing a variable the will be Warned
        if(missingVariables) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.ENV_VARS_MISSING_VALS));
        }
    }

    /**
     * This is used to fill wrapper class to show at the page
     * @param envVarList list of all environment variables that will be shown at page
     * @return
     */
    public List<ManagedEnvVars> getEnvVars(List<Environmental_Variable__c> envVarList) {
        List<ManagedEnvVars> managedEnvVarsList = new List<ManagedEnvVars>();

        Set<String> envNames = new Set<String>();
        String prevName = null;
        ManagedEnvVars mev = new ManagedEnvVars();
        mev.managedEnvVarList = new List<Environmental_Variable__c>();
        for(Environmental_Variable__c ev : envVarList) {
            if(prevName != ev.Name && prevName != null) {
                mev = new ManagedEnvVars();
                mev.managedEnvVarList = new List<Environmental_Variable__c>();
            }
            mev.meName = ev.Name;
            mev.managedEnvVarList.add(ev);
            prevName = ev.Name;
            if(!envNames.contains(ev.Name)) {
                managedEnvVarsList.add(mev);
                envNames.add(ev.Name);
            }

        }
        return managedEnvVarsList;
    }

    /**
     * This is used to return environment names for deployment flow
     * NOTE: Set<String> is sorted but when you add it to list sorting is changing thats why we added another sort afer adding all to the list
     * @return
     */
    public List<String> getEnvNames() {
        List<String> columnsNameList = new List<String>();
        columnsNameList.addAll(envNameWithId.keySet());
        columnsNameList.sort();
        columnsNameList.add(0, Label.NAME);
        return columnsNameList;
    }

    /**
     * This is used to create or update environmental variables records.
     * NOTE: If there is duplictate record, it will come from before trigger. Do not add extra duplicate code here. Thanks!!!!
     */
    public void save() {
        List<Environmental_Variable__c> environmentalVariablesList = new List<Environmental_Variable__c>();
        for(ManagedEnvVars mev : managedEnvVarsList) {
            environmentalVariablesList.addAll(mev.managedEnvVarList);
        }
        System.debug('environmentalVariablesList in save' + environmentalVariablesList);
        try {
            if(!environmentalVariablesList.isEmpty()) {
                Utilities.Secure_DML(environmentalVariablesList, Utilities.DML_Action.UPS, schema.SObjectType.Environmental_Variable__c);
                editing = false;
            }
        } catch(Exception e) {
            //Do not show FIELD_CUSTOM_VALIDATION_EXCEPTION messages
            if(!e.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, '' + e.getMessage()));
            }
        }
    }

    /**
     * This is used to change the render of page after clicking Edit button
     */
    public void editModeOn() {
        editing = true;
    }

    /**
     * This is used to change the render of page after clicking Cancel button
     */
    public void cancel() {
        editing = false;
    }

    /**
     * This is used to create new environmental variables record for each environment.
     */
    public void newVar() {
        List<Environmental_Variable__c> tmpEnvVarList = new List<Environmental_Variable__c>();
        List<String> envName = getEnvNames();

        for(Integer j = 1; j < envName.size(); j++) {
            Environmental_Variable__c ev = new Environmental_Variable__c();
            ev.Name = newEnvVarName;
            ev.Environment__c = envNameWithId.get(envName[j]);
            ev.Value__c = null;
            tmpEnvVarList.add(ev);
        }

        ManagedEnvVars mev = new ManagedEnvVars();
        mev.meName = newEnvVarName;
        mev.managedEnvVarList = new List<Environmental_Variable__c>(tmpEnvVarList);
        managedEnvVarsList.add(mev);
        editing = true;
    }

    /**
     * This is used to delete environmental variable from wrapper list. It need to delete record from existing list and database
     */
    public void doDelete() {
        Integer index = 0;
        for(ManagedEnvVars mEnvVars : managedEnvVarsList) {
            if(mEnvVars.meName == deleteVarName) {
                break;
            }
            index++;
        }
        managedEnvVarsList.remove(index);

        if(Schema.SObjectType.Environmental_Variable__c.isQueryable() && Schema.SObjectType.Environmental_Variable__c.isAccessible()) {
            Utilities.Secure_DML([SELECT Id FROM Environmental_Variable__c WHERE Name = :deleteVarName], Utilities.DML_Action.DEL, schema.SObjectType.Environmental_Variable__c);
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Schema.SObjectType.Environmental_Variable__c.getName() + C_COLON + Label.Insufficient_Access_Rights));
            return;
        }
        editing = false;
    }

    /**
     * wrapper class to hold environmental variables and present at visualforce page
     */
    public class ManagedEnvVars {
        public String meName { get; set; }
        public List<Environmental_Variable__c> managedEnvVarList { get; set; }
    }
}