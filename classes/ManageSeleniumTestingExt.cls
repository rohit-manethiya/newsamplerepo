/**
 *  @author     Umit Can Uckan
 *  @date       11/03/19
 *  @purpose    managing Selenium Test Suites via User Story/Deployment Flow with a button on view layouts
 */
public with sharing class ManageSeleniumTestingExt {
    public String userStoryId {
        get {
            if (String.isBlank(userStoryId)) {
                userStoryId = ApexPages.currentPage().getParameters().get('usId');
            }
            return userStoryId;
        }
        set;
    }

    public String flowId {
        get {
            if (String.isBlank(flowId)) {
                flowId = ApexPages.currentPage().getParameters().get('flowId');
            }
            return flowId;
        }
        set;
    }

    public List<List<Selenium_Test_Group__c>> stGroup4RelatedList {
        get {
            stGroup4RelatedList = new List<List<Selenium_Test_Group__c>>();
            if (String.isNotBlank(userStoryId)) {
                Set<Id> stGroupIds = new Set<Id>();
                if (Schema.SObjectType.User_Story_Selenium_Test__c.isQueryable() && Schema.SObjectType.User_Story_Selenium_Test__c.isAccessible()) {
                    for (User_Story_Selenium_Test__c ussTest : [
                        SELECT Id, User_Story__c, Selenium_Test_Group__c
                        FROM User_Story_Selenium_Test__c
                        WHERE User_Story__c = :userStoryId
                    ]) {
                        stGroupIds.add(ussTest.Selenium_Test_Group__c);
                    }
                } else {
                    UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.User_Story_Selenium_Test__c.label);
                }
                if (Schema.SObjectType.Selenium_Test_Group__c.isQueryable() && Schema.SObjectType.Selenium_Test_Group__c.isAccessible()) {
                    stGroup4RelatedList.add(
                        [
                            SELECT
                                Id,
                                Name,
                                Description__c,
                                Selenium_Settings__c,
                                Selenium_Settings__r.Name,
                                Environment__r.Name,
                                Environment__c,
                                Type__c
                            FROM Selenium_Test_Group__c
                            WHERE Id IN :stGroupIds
                        ]
                    );
                } else {
                    UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.Selenium_Test_Group__c.label);
                }
            } else {
                Set<Id> envIds = new Set<Id>();
                if (Schema.SObjectType.Deployment_Flow_Step__c.isQueryable() && Schema.SObjectType.Deployment_Flow_Step__c.isAccessible()) {
                    for (Deployment_Flow_Step__c dfs : [
                        SELECT Source_Environment__c, Destination_Environment__c
                        FROM Deployment_Flow_Step__c
                        WHERE Deployment_Flow_Step__c.Deployment_Flow__c = :flowId
                    ]) {
                        envIds.add(dfs.Source_Environment__c);
                        envIds.add(dfs.Destination_Environment__c);
                    }
                } else {
                    UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.Deployment_Flow_Step__c.label);
                }
                stGroup4RelatedList.add(new List<Selenium_Test_Group__c>());
                if (Schema.SObjectType.Selenium_Test_Group__c.isQueryable() && Schema.SObjectType.Selenium_Test_Group__c.isAccessible()) {
                    Integer counter = 0, index = 0;
                    for (Selenium_Test_Group__c stg : [
                        SELECT
                            (SELECT Id FROM User_Story_Selenium_Tests__r),
                            Id,
                            Name,
                            Description__c,
                            Selenium_Settings__c,
                            Selenium_Settings__r.Name,
                            Environment__r.Name,
                            Environment__c,
                            Type__c
                        FROM Selenium_Test_Group__c
                        WHERE Environment__c IN :envIds
                    ]) {
                        if (stg.User_Story_Selenium_Tests__r.size() == 0) {
                            if (counter == 1000) {
                                counter = 0;
                                index++;
                                stGroup4RelatedList.add(new List<Selenium_Test_Group__c>());
                            }
                            stGroup4RelatedList[index].add(stg);
                            counter++;
                        }
                    }
                } else {
                    UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.Selenium_Test_Group__c.label);
                }
            }
            System.debug('stGroup4RelatedList===> ' + stGroup4RelatedList.size());
            return stGroup4RelatedList;
        }
        set;
    }

    public Id depFlowId4Envs;
    public Map<String, Id> envMap {
        get {
            if (null == envMap) {
                envMap = new Map<String, Id>();
            }
            return envMap;
        }
        set;
    }
    public String envNamesString {
        get {
            return envNames.toString();
        }
    }
    public Set<String> envNames { get; set; }
    public User_Story__c userStory { get; set; }
    public Selenium_Test_Group__c mockGroup { get; set; }

    public List<SelectOption> allOrgs {
        get {
            if (null == allOrgs) {
                allOrgs = new List<SelectOption>();
            }
            return allOrgs;
        }
        set;
    }
    public List<SelectOption> selectedOrgs {
        get {
            if (null == selectedOrgs) {
                selectedOrgs = new List<SelectOption>();
            }
            return selectedOrgs;
        }
        set;
    }

    public List<SelectOption> allSuites {
        get {
            if (null == allSuites) {
                allSuites = new List<SelectOption>();
                if (Schema.SObjectType.Selenium_Test_Suite__c.isQueryable() && Schema.SObjectType.Selenium_Test_Suite__c.isAccessible()) {
                    for (Selenium_Test_Suite__c sts : [SELECT Id, Name FROM Selenium_Test_Suite__c ORDER BY Name]) {
                        allSuites.add(new SelectOption(sts.Id, sts.Name, false));
                    }
                } else {
                    UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.Selenium_Test_Suite__c.label);
                }
            }
            System.debug('allSuites===> ' + allSuites.size());
            return allSuites;
        }
        set;
    }
    public List<SelectOption> selectedSuites {
        get {
            if (null == selectedSuites) {
                selectedSuites = new List<SelectOption>();
            }
            return selectedSuites;
        }
        set;
    }

    public String title { get; set; }

    public class ApplicationException extends Exception {
    }

    /**
     *  defines the driven object for page and inits needed variables(title, environment list based on deployment flow)
     */
    public ManageSeleniumTestingExt() {
        if (!LicenseHelper.isCSTEnabled()) {
            throw new ApplicationException(Label.SELENIUM_NOT_ENABLED);
        }

        mockGroup = new Selenium_Test_Group__c();

        if (userStoryId != null) {
            if (Schema.SObjectType.User_Story__c.isQueryable() && Schema.SObjectType.User_Story__c.isAccessible()) {
                userStory = [
                    SELECT
                        Id,
                        Environment__c,
                        Project__c,
                        Project__r.Deployment_Flow__c,
                        Name,
                        User_Story_Title__c,
                        Release__c,
                        Release__r.Project__c,
                        Release__r.Project__r.Deployment_Flow__c,
                        Org_Credential__c,
                        Developer__c,
                        Status__c,
                        Progress__c
                    FROM User_Story__c
                    WHERE Id = :userStoryId
                ];
                depFlowId4Envs = userStory.Project__r.Deployment_Flow__c != null
                    ? userStory.Project__r.Deployment_Flow__c
                    : userStory.Release__r.Project__r.Deployment_Flow__c != null ? userStory.Release__r.Project__r.Deployment_Flow__c : null;
            } else {
                UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.User_Story__c.label);
            }
            title = Label.USER_STORY;
        } else {
            depFlowId4Envs = flowId;
            title = Label.REGRESSION;
        }
        if (Schema.SObjectType.Deployment_Flow_Step__c.isQueryable() && Schema.SObjectType.Deployment_Flow_Step__c.isAccessible()) {
            List<Deployment_Flow_Step__c> depFlowSteps = [
                SELECT Id, Name, Source_Environment__c, Source_Environment__r.Name, Destination_Environment__c, Destination_Environment__r.Name
                FROM Deployment_Flow_Step__c
                WHERE Deployment_Flow__c = :depFlowId4Envs
            ];
            for (Deployment_Flow_Step__c dfs : depFlowSteps) {
                envMap.put(dfs.Destination_Environment__r.Name, dfs.Destination_Environment__c);
                envMap.put(dfs.Source_Environment__r.Name, dfs.Source_Environment__c);
            }
            envNames = envMap.keySet();
            System.debug('envNames===> ' + envNames.size());
        } else {
            UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.Deployment_Flow_Step__c.label);
        }
    }

    /**
     *  Saves or updates current records on the panel
     */
    public void Save() {
        if (null == mockGroup.Selenium_Settings__c) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.SelectSeleniumSetting));
        } else if (String.isBlank(selectedEnv)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.SelectEnvironment));
        } else if (selectedOrgs.size() == 0) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.SelectOrgCredential));
        } else if (selectedSuites.size() == 0) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.SelectSeleniumTestSuite));
        } else {
            createSeleniumGroup_and_subRecords();
        }
    }
    /**
     * if edit, returns to page's initial state, if not, return to parameter Id
     *
     * @return
     */
    public PageReference back() {
        if (!isEdit) {
            if (String.isBlank(userStoryId)) {
                return new PageReference('/' + flowId);
            } else {
                return new PageReference('/' + userStoryId);
            }
        } else {
            clearPanel();
            return null;
        }
    }
    public boolean isEdit {
        get {
            if (null == isEdit) {
                isEdit = false;
            }
            return isEdit;
        }
        set;
    }
    /**
     * Delete the whole Selenium Group and sub records
     */
    public void deleteSeleniumGroup_and_subRecords() {
        try {
            String groupId = ApexPages.currentPage().getParameters().get('groupId');
            if (String.isNotBlank(userStoryId)) {
                if (Schema.SObjectType.User_Story_Selenium_Test__c.isQueryable() && Schema.SObjectType.User_Story_Selenium_Test__c.isAccessible()) {
                    Utilities.Secure_DML(
                        [SELECT Id FROM User_Story_Selenium_Test__c WHERE Selenium_Test_Group__c = :groupId],
                        Utilities.DML_Action.DEL,
                        schema.SObjectType.User_Story_Selenium_Test__c
                    );
                } else {
                    UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.User_Story_Selenium_Test__c.label);
                }
            }
            if (Schema.SObjectType.Selenium_Group_Test_Suite__c.isQueryable() && Schema.SObjectType.Selenium_Group_Test_Suite__c.isAccessible()) {
                Utilities.Secure_DML(
                    [SELECT Id FROM Selenium_Group_Test_Suite__c WHERE Selenium_Test_Group__c = :groupId],
                    Utilities.DML_Action.DEL,
                    schema.SObjectType.Selenium_Group_Test_Suite__c
                );
            } else {
                UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.Selenium_Group_Test_Suite__c.label);
            }
            if (
                Schema.SObjectType.Selenium_Group_Org_Credential__c.isQueryable() &&
                Schema.SObjectType.Selenium_Group_Org_Credential__c.isAccessible()
            ) {
                Utilities.Secure_DML(
                    [SELECT Id FROM Selenium_Group_Org_Credential__c WHERE Selenium_Test_Group__c = :groupId],
                    Utilities.DML_Action.DEL,
                    schema.SObjectType.Selenium_Group_Org_Credential__c
                );
            } else {
                UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.Selenium_Group_Org_Credential__c.label);
            }
            if (Schema.SObjectType.Selenium_Test_Run__c.isQueryable() && Schema.SObjectType.Selenium_Test_Run__c.isAccessible()) {
                Utilities.Secure_DML(
                    [SELECT Id FROM Selenium_Test_Run__c WHERE Selenium_Test_Group__c = :groupId],
                    Utilities.DML_Action.DEL,
                    schema.SObjectType.Selenium_Test_Run__c
                );
            } else {
                UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.Selenium_Test_Run__c.label);
            }
            if (Schema.SObjectType.Selenium_Test_Group__c.isQueryable() && Schema.SObjectType.Selenium_Test_Group__c.isAccessible()) {
                Utilities.Secure_DML(
                    [SELECT Id FROM Selenium_Test_Group__c WHERE Id = :groupId],
                    Utilities.DML_Action.DEL,
                    schema.SObjectType.Selenium_Test_Group__c
                );
            } else {
                UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.Selenium_Test_Group__c.label);
            }
            clearPanel();
        } catch (Exception ex) {
            System.debug('exception===> ' + ex);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
        }
    }
    private Map<String, Selenium_Group_Org_Credential__c> sgocEditMap {
        get {
            if (null == sgocEditMap) {
                sgocEditMap = new Map<String, Selenium_Group_Org_Credential__c>();
            }
            return sgocEditMap;
        }
        set;
    }
    private Map<String, Selenium_Group_Test_Suite__c> sgtsEditMap {
        get {
            if (null == sgtsEditMap) {
                sgtsEditMap = new Map<String, Selenium_Group_Test_Suite__c>();
            }
            return sgtsEditMap;
        }
        set;
    }
    private Map<String, List<Selenium_Test_Run__c>> strEditMap1 {
        get {
            if (null == strEditMap1) {
                strEditMap1 = new Map<String, List<Selenium_Test_Run__c>>();
            }
            return strEditMap1;
        }
        set;
    }
    private Map<String, List<Selenium_Test_Run__c>> strEditMap2 {
        get {
            if (null == strEditMap2) {
                strEditMap2 = new Map<String, List<Selenium_Test_Run__c>>();
            }
            return strEditMap2;
        }
        set;
    }
    /**
     * Clears panel lists
     */
    public void clearLists() {
        allOrgs.clear();
        selectedOrgs.clear();
        selectedSuites.clear();
    }
    /**
     * Zeroizes the whole page state
     */
    public void clearPanel() {
        mockGroup = new Selenium_Test_Group__c();
        clearLists();
        selectedEnv = '';
        isEdit = false;
        sgocEditMap = new Map<String, Selenium_Group_Org_Credential__c>();
        sgtsEditMap = new Map<String, Selenium_Group_Test_Suite__c>();
    }

    public String selectedEnv { get; set; }
    Id envId;
    public void populateSTG() {
        populateSTG(null);
    }
    /**
     *
     * Opens the multiselections panel for org and suites
     * @param envName Selected environment to bring available org credentials based on
     */
    public void populateSTG(String envName) {
        clearLists();
        selectedEnv = String.isNotBlank(envName) ? envName : ApexPages.currentPage().getParameters().get('selectedEnvironment');
        envId = envMap.get(selectedEnv);
        //Selenium_Test_Group__c
        if (Schema.SObjectType.Org__c.isQueryable() && Schema.SObjectType.Org__c.isAccessible()) {
            for (Org__c org : [SELECT Id, Name FROM Org__c WHERE Environment__c = :envId ORDER BY Name]) {
                allOrgs.add(new SelectOption(org.Id, org.Name, false));
            }
        } else {
            UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.Org__c.label);
        }
    }
    /**
     * assigns preselected already saved records for edit operation
     */
    public void editSeleniumGroup_and_subRecords() {
        try {
            isEdit = true;
            String groupId = ApexPages.currentPage().getParameters().get('groupId');
            if (Schema.SObjectType.Selenium_Test_Group__c.isQueryable() && Schema.SObjectType.Selenium_Test_Group__c.isAccessible()) {
                mockGroup = [
                    SELECT Id, Name, Description__c, Environment__c, Environment__r.Name, Type__c, Selenium_Settings__c, External_Id__c
                    FROM Selenium_Test_Group__c
                    WHERE Id = :groupId
                ];
            } else {
                UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.Selenium_Test_Group__c.label);
                return;
            }
            selectedEnv = mockGroup.Environment__r.Name;
            populateSTG(selectedEnv);

            List<Selenium_Test_Run__c> tempStrList;
            if (Schema.SObjectType.Selenium_Test_Run__c.isQueryable() && Schema.SObjectType.Selenium_Test_Run__c.isAccessible()) {
                for (Selenium_Test_Run__c str : [
                    SELECT Id, Name, Org_Credential__c, Org_Credential__r.Name, Selenium_Test_Suite__c, Selenium_Test_Suite__r.Name
                    FROM Selenium_Test_Run__c
                    WHERE Selenium_Test_Group__c = :groupId
                ]) {
                    if (strEditMap1.containsKey(str.Org_Credential__r.Name)) {
                        tempStrList = strEditMap1.get(str.Org_Credential__r.Name);
                    } else {
                        tempStrList = new List<Selenium_Test_Run__c>();
                    }
                    tempStrList.add(str);
                    strEditMap1.put(str.Org_Credential__r.Name, tempStrList);

                    if (strEditMap2.containsKey(str.Selenium_Test_Suite__r.Name)) {
                        tempStrList = strEditMap2.get(str.Selenium_Test_Suite__r.Name);
                    } else {
                        tempStrList = new List<Selenium_Test_Run__c>();
                    }
                    tempStrList.add(str);
                    strEditMap2.put(str.Selenium_Test_Suite__r.Name, tempStrList);
                }
            } else {
                UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.Selenium_Test_Run__c.label);
                return;
            }

            if (
                Schema.SObjectType.Selenium_Group_Org_Credential__c.isQueryable() &&
                Schema.SObjectType.Selenium_Group_Org_Credential__c.isAccessible()
            ) {
                for (Selenium_Group_Org_Credential__c sgoc : [
                    SELECT Id, Org_Credential__c, Org_Credential__r.Name
                    FROM Selenium_Group_Org_Credential__c
                    WHERE Selenium_Test_Group__c = :groupId
                ]) {
                    sgocEditMap.put(sgoc.Org_Credential__r.Name, sgoc);
                    selectedOrgs.add(new SelectOption(sgoc.Org_Credential__c, sgoc.Org_Credential__r.Name, false));
                }
            } else {
                UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.Selenium_Group_Org_Credential__c.label);
                return;
            }
            List<Integer> indexArray = new List<Integer>();
            for (Integer i = 0; i < allOrgs.size(); i++) {
                if (sgocEditMap.containsKey(allOrgs[i].getLabel())) {
                    indexArray.add(i);
                }
            }
            for (Integer i = indexArray.size() - 1; i >= 0; i--) {
                allOrgs.remove(indexArray[i]);
            }

            indexArray.clear();
            if (Schema.SObjectType.Selenium_Group_Test_Suite__c.isQueryable() && Schema.SObjectType.Selenium_Group_Test_Suite__c.isAccessible()) {
                for (Selenium_Group_Test_Suite__c sgts : [
                    SELECT Id, Selenium_Test_Suite__c, Selenium_Test_Suite__r.Name
                    FROM Selenium_Group_Test_Suite__c
                    WHERE Selenium_Test_Group__c = :groupId
                ]) {
                    sgtsEditMap.put(sgts.Selenium_Test_Suite__r.Name, sgts);
                    selectedSuites.add(new SelectOption(sgts.Selenium_Test_Suite__c, sgts.Selenium_Test_Suite__r.Name, false));
                }
            } else {
                UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.Selenium_Group_Test_Suite__c.label);
                return;
            }
            for (Integer i = 0; i < allSuites.size(); i++) {
                if (sgtsEditMap.containsKey(allSuites[i].getLabel())) {
                    indexArray.add(i);
                }
            }
            for (Integer i = indexArray.size() - 1; i >= 0; i--) {
                allSuites.remove(indexArray[i]);
            }
        } catch (Exception ex) {
            System.debug('exception===> ' + ex);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
        }
    }
    /**
     *  Upserts selected records and deleted removed records based on the maps populated on editSeleniumGroup_and_subRecords method
     */
    private void createSeleniumGroup_and_subRecords() {
        try {
            Set<Id> sgtsFlag = new Set<Id>();
            mockGroup.Name = String.isBlank(userStoryId)
                ? (Label.REGRESSION_TEST + ' - ' + selectedEnv).abbreviate(80)
                : (userStory.Name + ' - ' + selectedEnv).abbreviate(80);
            mockGroup.Environment__c = envId;
            mockGroup.Type__c = String.isBlank(userStoryId) ? Label.REGRESSION_TEST : Label.USER_STORY_TEST;
            mockGroup.Manage_Test_Runs_manually__c = false;
            if (String.isBlank(userStoryId)) {
                mockGroup.External_Id__c = envId;
            } else {
                mockGroup.External_Id__c = userStoryId + '_' + envId;
            }
            Utilities.Secure_DML(
                new List<Selenium_Test_Group__c>{ mockGroup },
                Utilities.DML_Action.UPS,
                schema.SObjectType.Selenium_Test_Group__c,
                Schema.SObjectType.Selenium_Test_Group__c.fields.External_Id__c
            );

            List<Selenium_Test_Run__c> str2Upsert = new List<Selenium_Test_Run__c>();
            List<Selenium_Group_Org_Credential__c> sgoc2Upsert = new List<Selenium_Group_Org_Credential__c>();
            List<Selenium_Group_Test_Suite__c> sgts2Upsert = new List<Selenium_Group_Test_Suite__c>();
            List<User_Story_Selenium_Test__c> usst2Upsert = new List<User_Story_Selenium_Test__c>();

            Set<Selenium_Test_Run__c> str2Delete = new Set<Selenium_Test_Run__c>();
            List<Selenium_Group_Org_Credential__c> sgoc2Delete = new List<Selenium_Group_Org_Credential__c>();
            List<Selenium_Group_Test_Suite__c> sgts2Delete = new List<Selenium_Group_Test_Suite__c>();

            for (SelectOption soOrg : allOrgs) {
                if (sgocEditMap.containsKey(soOrg.getLabel())) {
                    if (strEditMap1.containsKey(soOrg.getLabel())) {
                        str2Delete.addAll(strEditMap1.get(soOrg.getLabel()));
                    }
                    sgoc2Delete.add(sgocEditMap.get(soOrg.getLabel()));
                }
            }
            for (SelectOption soSuite : allSuites) {
                if (sgtsEditMap.containsKey(soSuite.getLabel())) {
                    if (strEditMap2.containsKey(soSuite.getLabel())) {
                        str2Delete.addAll(strEditMap2.get(soSuite.getLabel()));
                    }
                    sgts2Delete.add(sgtsEditMap.get(soSuite.getLabel()));
                }
            }
            for (SelectOption soOrg : selectedOrgs) {
                sgoc2Upsert.add(
                    new Selenium_Group_Org_Credential__c(
                        Selenium_Test_Group__c = mockGroup.Id,
                        Org_Credential__c = soOrg.getValue(),
                        External_Id__c = soOrg.getValue() + mockGroup.External_Id__c
                    )
                );
                for (SelectOption soSuite : selectedSuites) {
                    str2Upsert.add(
                        new Selenium_Test_Run__c(
                            Name = (soSuite.getLabel() + ' ' + selectedEnv).length() > 80
                                ? (soSuite.getLabel() + ' ' + selectedEnv).substring(0, 80)
                                : soSuite.getLabel() + ' ' + selectedEnv,
                            Org_Credential__c = soOrg.getValue(),
                            Selenium_Test_Suite__c = soSuite.getValue(),
                            Selenium_Settings__c = mockGroup.Selenium_Settings__c,
                            Selenium_Test_Group__c = mockGroup.Id,
                            External_ID__c = mockGroup.Id + '_' + soSuite.getValue() + '_' + soOrg.getValue()
                        )
                    );
                    //there is no need to create different records with for orgs, so checks if the suite has been already added
                    if (!sgtsFlag.contains(soSuite.getValue())) {
                        sgtsFlag.add(soSuite.getValue());
                        sgts2Upsert.add(
                            new Selenium_Group_Test_Suite__c(
                                Selenium_Test_Group__c = mockGroup.Id,
                                Selenium_Test_Suite__c = soSuite.getValue(),
                                External_Id__c = soSuite.getValue() + mockGroup.External_Id__c
                            )
                        );
                    }
                }
            }
            if (String.isNotBlank(userStoryId)) {
                usst2Upsert.add(
                    new User_Story_Selenium_Test__c(
                        User_Story__c = userStoryId,
                        Selenium_Test_Group__c = mockGroup.Id,
                        Name = (Label.FEATURE + ' ' + userStory.Name + ' - ' + mockGroup.Name).abbreviate(80),
                        External_Id__c = userStoryId + '_' + mockGroup.External_Id__c
                    )
                );
            }
            Utilities.Secure_DML(
                sgts2Upsert,
                Utilities.DML_Action.UPS,
                schema.SObjectType.Selenium_Group_Test_Suite__c,
                schema.SObjectType.Selenium_Group_Test_Suite__c.fields.External_Id__c
            );
            Utilities.Secure_DML(
                sgoc2Upsert,
                Utilities.DML_Action.UPS,
                schema.SObjectType.Selenium_Group_Org_Credential__c,
                schema.SObjectType.Selenium_Group_Org_Credential__c.fields.External_Id__c
            );
            Utilities.Secure_DML(
                usst2Upsert,
                Utilities.DML_Action.UPS,
                schema.SObjectType.User_Story_Selenium_Test__c,
                schema.SObjectType.User_Story_Selenium_Test__c.fields.External_Id__c
            );
            Utilities.Secure_DML(
                str2Upsert,
                Utilities.DML_Action.UPS,
                schema.SObjectType.Selenium_Test_Run__c,
                schema.SObjectType.Selenium_Test_Run__c.fields.External_ID__c
            );

            if (isEdit) {
                Set<Id> strSet2Delete = new Set<Id>();
                for (Selenium_Test_Run__c strItem : str2Delete) {
                    strSet2Delete.add(strItem.Id);
                }
                List<Selenium_Test_Run__c> list2Delete;
                if (Schema.SObjectType.Selenium_Test_Run__c.isQueryable() && Schema.SObjectType.Selenium_Test_Run__c.isAccessible()) {
                    list2Delete = [SELECT Id FROM Selenium_Test_Run__c WHERE Id IN :strSet2Delete];
                } else {
                    UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.Selenium_Test_Run__c.label);
                }
                if (!str2Delete.isEmpty()) {
                    Utilities.Secure_DML(list2Delete, Utilities.DML_Action.DEL, schema.SObjectType.Selenium_Test_Run__c);
                }
                if (!sgts2Delete.isEmpty()) {
                    Utilities.Secure_DML(sgts2Delete, Utilities.DML_Action.DEL, schema.SObjectType.Selenium_Group_Test_Suite__c);
                }
                if (!sgoc2Delete.isEmpty()) {
                    Utilities.Secure_DML(sgoc2Delete, Utilities.DML_Action.DEL, schema.SObjectType.Selenium_Group_Org_Credential__c);
                }
            }
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, Label.SELENIUM_GROUPS_UPDATED));
            clearPanel();
        } catch (Exception ex) {
            System.debug('exception===> ' + ex);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
        }
    }
}