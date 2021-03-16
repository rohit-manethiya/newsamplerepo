/**
 * @author Ümit Can Uçkan
 * @version 2.0
 * @date 12/07/18
 * @testClass: WorkManagerTest
 * @description: Controller for WorkManager Page
 */

global with sharing class WorkManager {
    public static final String backlogWhereClause = 'Status__c != \'Backburner\'  AND Status__c != \'Cancelled\' AND Status__c != \'Rejected\' AND Sprint__c = null ';
    //to be able to run the final state of panels and save it back
    public static User currentUser {
        get {
            if (null == currentUser && Schema.sObjectType.User.isQueryable() && Schema.sObjectType.User.isAccessible()) {
                currentUser = [SELECT Work_Manager_Panels__c FROM User WHERE Id = :UserInfo.getUserId()];
            }
            return currentUser;
        }
        private set;
    }
    //workManagerPanel var to be able to us on UI side
    public String workManagerPanel {
        get {
            if (String.isBlank(workManagerPanel)) {
                workManagerPanel = currentUser.Work_Manager_Panels__c;
            }
            return workManagerPanel;
        }
        set;
    }
    //used on state save to be able to correct datas before saving them
    public static Map<String, TableWrapper> wholeTablesMap {
        get {
            if (null == wholeTablesMap) {
                wholeTablesMap = new Map<String, TableWrapper>();
            }
            return wholeTablesMap;
        }
        set;
    }
    //deserialized final states list
    public static List<UserStates> initialStates {
        get {
            initialStates = String.isNotBlank(currentUser.Work_Manager_Panels__c)
                ? (List<UserStates>) Json.deserialize('[' + currentUser.Work_Manager_Panels__c + ']', List<UserStates>.class)
                : new List<UserStates>();
            return initialStates;
        }
        set;
    }
    //namespace to use both on page and controller sides
    public static String ns {
        get {
            if (String.isBlank(ns)) {
                ns = Settings.ns;
            }
            return ns;
        }
        set;
    }
    //will render current look up selection for input field to add new panel
    public String currentFieldApiSelection {
        get {
            if (String.isBlank(currentFieldApiSelection)) {
                currentFieldApiSelection = ns + 'Sprint__c';
            }
            return currentFieldApiSelection;
        }
        set;
    }
    //used for adding new tables to the panel
    public User_Story__c inputUs {
        get {
            if (null == inputUs) {
                inputUs = new User_Story__c();
            }
            return inputUs;
        }
        set;
    }
    //used for adding new tables to the panel
    public List<User_Story__c> inputUsList {
        get {
            if (null == inputUsList) {
                inputUsList = new List<User_Story__c>();
            }
            return inputUsList;
        }
        set;
    }
    private Sprint__c cSprint;
    public Id cSprintId {
        get {
            if (null == cSprintId && Schema.sObjectType.Sprint__c.isQueryable() && Schema.sObjectType.Sprint__c.isAccessible()) {
                List<Sprint__c> cSprintList = new List<Sprint__c>(
                    [
                        SELECT Id, Name, Team__c, End_Date__c
                        FROM Sprint__c
                        WHERE Start_Date__c <= :System.today() AND End_Date__c >= :System.today()
                        ORDER BY Team__c NULLS LAST
                        LIMIT 1
                    ]
                );
                if (cSprintList.size() > 0) {
                    cSprint = cSprintList[0];
                    cSprintId = cSprint.Id;
                }
            }
            return cSprintId;
        }
        set;
    }
    public Id nSprintId {
        get {
            if (null == cSprintId && null != cSprint && Schema.sObjectType.Sprint__c.isQueryable() && Schema.sObjectType.Sprint__c.isAccessible()) {
                List<Sprint__c> nSprintList = new List<Sprint__c>(
                    [
                        SELECT Id, Name, Team__c
                        FROM Sprint__c
                        WHERE Start_Date__c >= :cSprint.End_Date__c AND Id != :cSprint.Id
                        ORDER BY Team__c NULLS LAST
                        LIMIT 1
                    ]
                );
                if (nSprintList.size() > 0) {
                    nSprintId = nSprintList[0].Id;
                }
            }
            return nSprintId;
        }
        set;
    }
    //picklist on the top left of the page to change current config
    public List<SelectOption> availablePanelStates {
        get {
            availablePanelStates = new List<SelectOption>();
            String updatedWmp;
            if (Schema.sObjectType.User.isQueryable() && Schema.sObjectType.User.isAccessible()) {
                updatedWmp = [SELECT Work_Manager_Panels__c FROM User WHERE Id = :UserInfo.getUserId()].Work_Manager_Panels__c;
            }
            if (String.isNotBlank(updatedWmp)) {
                UserStates castedPanels = (UserStates) Json.deserialize(updatedWmp, UserStates.class);
                for (PanelData dp : castedPanels.panelData) {
                    availablePanelStates.add(new SelectOption(dp.pName, dp.pName));
                }
                selectedState = castedPanels.lastState;
            } else {
                selectedState = 'default';
                availablePanelStates.add(new SelectOption(selectedState, selectedState));
            }
            return availablePanelStates;
        }
        set;
    }
    public String selectedState { get; set; }
    //look up and status fields to filter new table
    public List<SelectOption> usRelations {
        get {
            if (null == usRelations) {
                usRelations = new List<SelectOption>();
                List<Schema.FieldSetMember> fSM = SObjectType.User_Story__c.FieldSets.Work_Manager_Relations.getFields();
                for (Schema.FieldSetMember fS : fSM) {
                    if (String.valueOf(fS.getType()) == 'REFERENCE') {
                        usRelations.add(new SelectOption(fS.getFieldPath(), fS.getLabel()));
                    }
                }
                usRelations.sort();
                //Add Status Option
                usRelations.add(new SelectOption(Settings.ns + 'Status__c', 'Status'));
            }
            return usRelations;
        }
        set;
    }
    //in use on returnType method
    public static Map<String, Schema.SObjectField> sObjectFieldMap {
        get {
            if (null == sObjectFieldMap) {
                sObjectFieldMap = Schema.SObjectType.User_Story__c.fields.getMap();
            }
            return sObjectFieldMap;
        }
        set;
    }
    /**
     *
     * @param selectedState
     * @param initPanelDataParam
     *
     * @description updates current user's workManagerPanel field with current panel(s) and table(s)
     *
     * @return updated JSON
     */
    public static String updateUserRecord(String selectedState, List<PanelData> initPanelDataParam) {
        UserStates json2save = new UserStates(selectedState, initPanelDataParam);
        String strJson2save = JSON.serialize(json2save);

        if (Schema.sObjectType.User.fields.Work_Manager_Panels__c.isUpdateable()) {
            currentUser.Work_Manager_Panels__c = strJson2save;
        }
        Utilities.Secure_DML(currentUser, Utilities.DML_Action.UPD, schema.Sobjecttype.User);

        return strJson2save;
    }
    /**
     *
     * @param rIds
     * @param statusName
     * @description updates backlog or backburner records with current order on the page
     */
    @RemoteAction
    global static void saveStatusOrders(List<String> rIds, String statusName) {
        List<Sobject> usList = new List<Sobject>();
        if (Schema.sObjectType.User_Story__c.isQueryable() && Schema.sObjectType.User_Story__c.isAccessible()) {
            usList = [SELECT id, Backburner_Rank__c, Backlog_Rank__c FROM User_Story__c WHERE id IN :rIds];
        }

        String field2put = (statusName.toLowerCase() == 'backlog' ? 'Backlog_Rank__c' : 'Backburner_Rank__c');
        String field2clear = (statusName.toLowerCase() != 'backlog' ? 'Backlog_Rank__c' : 'Backburner_Rank__c');
        if (
            Schema.sObjectType.User_Story__c.fields.Backburner_Rank__c.isUpdateable() &&
            Schema.sObjectType.User_Story__c.fields.Backlog_Rank__c.isUpdateable()
        ) {
            for (SObject sobj : usList) {
                sobj.put(field2put, rIds.indexOf((string) sobj.get('id')) + 1);
                sobj.put(field2clear, null);
            }
        }
        Utilities.Secure_DML(usList, Utilities.DML_Action.UPD, schema.Sobjecttype.User_Story__c);
    }
    /**
     *
     * @param rid
     * @param qObject
     * @param clause
     * @description updates the given record after drag and drop performed
     */
    @RemoteAction
    global static void saveNewClause(String rid, String qObject, String clause) {
        SObject us = null;
        if (Schema.sObjectType.User_Story__c.isQueryable() && Schema.sObjectType.User_Story__c.isAccessible()) {
            Id recordId = rid;
            us = Database.query('SELECT Id,' + qObject + ' FROM User_Story__c WHERE Id = :recordId');
        }
        if (Schema.sObjectType.User_Story__c.fields.getMap().get(qObject).getDescribe().isUpdateable()) {
            us.put(qObject, clause);
        }
        Utilities.Secure_DML(us, Utilities.DML_Action.UPD, schema.Sobjecttype.User_Story__c);
    }
    /**
     *
     * @param selectedState
     *
     * @description returns desired panel after config selectlist has changed
     * @return selectedPanelData as object
     */
    @RemoteAction
    global static PanelData changeConfig(String selectedState) {
        List<PanelData> initPanelData = initialStates[0].panelData;
        PanelData pd2sendOnChange;
        for (Integer i = 0; i < initPanelData.size(); i++) {
            if (initPanelData[i].pName == selectedState) {
                pd2sendOnChange = initPanelData[i];
                break;
            }
        }
        updateUserRecord(selectedState, initPanelData);
        return pd2sendOnChange;
    }

    /**
     * @deprecated
     *
     * @param selectedState
     * @param occupiedState
     * @param AdditionalQuery
     * @param dmlType
     *
     * @return
     */
    global static PanelPlusJson addConfig(String selectedState, String occupiedState, String AdditionalQuery, String dmlType) {
        return null;
    }
    /**
     *
     * @param selectedState
     * @param occupiedState
     * @param AdditionalQuery
     * @param dmlType
     * @param panelRowCount
     * @description generates new panel and it's panels
     * @return newly created panel with all details
     */
    @RemoteAction
    public static PanelPlusJson addConfig(String selectedState, String occupiedState, String AdditionalQuery, String dmlType, String panelRowCount) {
        System.debug('dmlType==> ' + dmlType);
        List<PanelData> initPanelData = initialStates[0].panelData;
        PanelData newPanel;
        for (Integer i = 0; i < initPanelData.size(); i++) {
            if (dmlType == 'create' && initPanelData[i].pName == occupiedState) {
                newPanel = new PanelData(selectedState, initPanelData[i].pWrappers, AdditionalQuery, panelRowCount);
                initPanelData.add(newPanel);
            } else if (dmlType == 'update' && initPanelData[i].pName == occupiedState) {
                newPanel = new PanelData(selectedState, initPanelData[i].pWrappers, AdditionalQuery, panelRowCount);
                initPanelData.add(newPanel);
                initPanelData.remove(i);
            }
        }
        String fJson = updateUserRecord(selectedState, initPanelData);
        return new PanelPlusJson(fJson, newPanel);
    }
    /**
     *
     * @param selectedState
     * @description removes desired panel
     *
     * @return next panel Data
     */
    @RemoteAction
    global static PanelData removeConfig(String selectedState) {
        List<PanelData> initPanelData = initialStates[0].panelData;
        String nextState;
        if (initPanelData.size() > 1) {
            for (Integer i = 0; i < initPanelData.size(); i++) {
                if (initPanelData[i].pName == selectedState) {
                    initPanelData.remove(i);
                }
            }
            nextState = initPanelData[0].pName;
            updateUserRecord(nextState, initPanelData);
        } else {
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.WARNING, Label.You_Need_to_Select_Config));
        }

        return initPanelData[0];
    }
    /**
     *
     * @param objListFromPage
     * @param put2wholeMap
     * @param selectedState
     * @param currentTableOrder
     *
     * @description updates workManager field on user with current values
     * @return JSON with all data
     */
    @RemoteAction
    global static String saveCurrentTables(String objListFromPage, String put2wholeMap, String selectedState, List<String> currentTableOrder) {
        List<String> tableOrderList = currentTableOrder;
        List<PWrapper> orderedList = new List<PWrapper>();
        for (Integer orderSize = 0; orderSize < tableOrderList.size(); orderSize++) {
            orderedList.add(new PWrapper());
        }
        for (TableWrapper tw : (List<TableWrapper>) Json.deserialize(put2wholeMap, List<TableWrapper>.class)) {
            wholeTablesMap.put(
                tw.headerClause,
                new TableWrapper(
                    tw.usList,
                    tw.tableHeader,
                    tw.clause,
                    tw.fType,
                    tw.headerClause,
                    tw.qObject,
                    tw.whereClause,
                    tw.additionalQuery,
                    tw.min,
                    tw.max,
                    tw.panelRowCount,
                    tw.sortOrder
                )
            );
        }
        String AdditionalQuery = '';
        String panelRowCount = '';
        for (PWrapper pw : (List<PWrapper>) Json.deserialize(objListFromPage, List<PWrapper>.class)) {
            orderedList[tableOrderList.indexOf(wholeTablesMap.get(pw.pId).tableHeader)] = pw;
            if (wholeTablesMap.containsKey(pw.pId)) {
                AdditionalQuery = wholeTablesMap.get(pw.pId).additionalQuery;
                panelRowCount = wholeTablesMap.get(pw.pId).panelRowCount;
            }
            pw.pType = wholeTablesMap.get(pw.pId).qObject;
            pw.pId = wholeTablesMap.get(pw.pId).clause;
        }
        List<PanelData> initPanelData = initialStates.size() > 0 ? initialStates[0].panelData : new List<PanelData>();
        PanelData currentPanelData = new PanelData(selectedState, new Set<PWrapper>(orderedList), AdditionalQuery, panelRowCount);
        for (Integer i = 0; i < initPanelData.size(); i++) {
            if (initPanelData[i].pName == currentPanelData.pName) {
                initPanelData.remove(i);
                break;
            }
        }
        initPanelData.add(currentPanelData);
        return updateUserRecord(selectedState, initPanelData);
    }
    /**
     * @deprecated
     *
     * @param tableHeader
     * @param whereClause
     * @param additionalQuery
     *
     * @return
     */
    @RemoteAction
    global static TableWrapper usList(String tableHeader, String whereClause, String additionalQuery) {
        return null;
    }
    /**
     *
     * @param tableHeader
     * @param whereClause
     * @param additionalQuery
     * @param min
     * @param max
     * @param panelRowCount
     * @param sortOrder
     * @description generates tables for given criterias and headers
     * @return newly generated table
     */
    @RemoteAction
    public static TableWrapper prepareUsList(
        String tableHeader,
        String whereClause,
        String additionalQuery,
        String min,
        String max,
        String panelRowCount,
        String sortOrder
    ) {
        String fType = tableHeader.split(':')[0];
        String clause, qObject;
        if (tableHeader.split(':')[1].substring(0, 1) == ' ') {
            clause = tableHeader.split(':')[1].substring(1);
        } else {
            clause = tableHeader.split(':')[1];
        }

        panelRowCount = String.isBlank(panelRowCount) ? '200' : panelRowCount;

        sortOrder = String.isBlank(sortOrder) ? '' : sortOrder;

        if (tableHeader.contains('changeOnBackend') && tableHeader.contains(':')) {
            tableHeader = tableHeader.split(':')[0].replace('__c', '').replace('_', '') + ': ' + returnNameofCurrentRecord(tableHeader.split(':')[1]);
        }
        qObject = whereClause.split(' ')[0];
        String headerClause = tableHeader.split(':')[1].substring(1);
        UserStoryWrapper[] usArray = new List<UserStoryWrapper>{};
        List<User_Story__c> tempList = new List<User_Story__c>();

        //System.debug('whereClause==> '+whereClause);
        String wholeQuery = 'SELECT ' + availableColumns + ' FROM User_Story__c ';
        wholeQuery += (String.isBlank(whereClause)
            ? ''
            : (' WHERE ' +
                (whereClause != 'Status__c = \'Backlog\'' ? whereClause : backlogWhereClause) +
                (String.isBlank(additionalQuery)
                    ? ''
                    : (additionalQuery.length() > 0 && (!additionalQuery.replace(' ', '').startsWithIgnoreCase('orderby')) ? ' AND ' : '') +
                        additionalQuery)));
        wholeQuery += (sortOrder.contains('order by') ? sortOrder : ' order by Backlog_Rank__c,Backburner_Rank__c,name desc');
        wholeQuery += ' NULLS LAST LIMIT ' + panelRowCount;
        System.debug('wholeQuery==> ' + wholeQuery);

        if (Schema.sObjectType.User_Story__c.isQueryable() && Schema.sObjectType.User_Story__c.isAccessible()) {
            tempList = Database.query(wholeQuery);
        }
        for (User_Story__c us : tempList) {
            usArray.add(new UserStoryWrapper(us));
        }
        return new TableWrapper(
            usArray,
            tableHeader,
            clause,
            fType,
            headerClause,
            qObject,
            whereClause,
            additionalQuery,
            min,
            max,
            panelRowCount,
            sortOrder
        );
    }

    /**
     * @description Clear auxUS when user picks another lookup
     *
     * @return null
     */
    public PageReference clearInputUs() {
        inputUs = new User_Story__c();
        return null;
    }
    //returns available columns from field set to the page
    public static string availableColumns {
        get {
            set<String> toJoin = new Set<String>();
            if (String.isBlank(availableColumns)) {
                availableColumns = '';
                List<Schema.FieldSetMember> fSM = SObjectType.User_Story__c.FieldSets.Work_Manager_Columns.getFields();
                for (Schema.FieldSetMember fS : fSM) {
                    if (returnType(fS.getFieldPath()) == 'REFERENCE') {
                        toJoin.add(fS.getFieldPath().toLowerCase().replace('__c', '__r.name'));
                    }
                    toJoin.add(fS.getFieldPath().toLowerCase());
                }
                toJoin.add('name');
                toJoin.add('id');
                availableColumns = String.join(new List<String>(toJoin), ',');
                //System.debug('availableColumns==> '+availableColumns);
            }
            return availableColumns;
        }
        set;
    }
    /**
     *
     * @param fieldApi
     * @description returns field type of given api
     * @return type
     */
    public static String returnType(string fieldApi) {
        Schema.SObjectField field = sObjectFieldMap.get(fieldApi);
        Schema.DisplayType FldType = field.getDescribe().getType();
        system.debug('FldType==> ' + FldType);
        return String.valueOf(FldType);
    }
    /**
     *
     * @param id
     *
     * @description converts 15 digit id to 18
     * @return Id type id
     */
    public static Id idConverter(String id) {
        id = id.replace(' ', '');
        if (id.length() == 18) {
            return (Id) id;
        }

        String suffix = '';
        for (Integer i = 0; i < 3; i++) {
            Integer flags = 0;
            for (Integer j = 0; j < 5; j++) {
                String c = id.substring(i * 5 + j, i * 5 + j + 1);
                if ((c.compareTo('A') >= 0) && (c.compareTo('Z') <= 0)) {
                    flags += 1 << j;
                }
            }
            suffix = suffix + 'ABCDEFGHIJKLMNOPQRSTUVWXYZ012345'.substring(flags, flags + 1);
        }
        return (Id) (id + suffix);
    }
    /**
     *
     * @param cId
     * @description return record name of the given id
     * @return name of the record from the Id
     */
    public static String returnNameofCurrentRecord(string cId) {
        id sId = idConverter(cId);
        System.debug('sId==> ' + sId);
        String sobjectType = sId.getSObjectType().getDescribe().getName();
        Sobject sobj = null;
        if (sId.getSObjectType().getDescribe().isQueryable()) {
            sobj = Database.query('SELECT Id, Name FROM ' + sobjectType + ' WHERE Id=:sId LIMIT 1');
        }
        return (String) sobj.get('Name');
    }
    public PageReference reInitList() {
        inputUsList.clear();
        usCloneList.clear();
        return null;
    }
    public PageReference showInputUs() {
        //System.debug('inputUsList=1=> '+inputUsList);
        //System.debug('usCloneList=1=> '+usCloneList);
        Integer currentIndex = Integer.valueOf(ApexPages.currentPage().getParameters().get('cIndex'));
        //System.debug('currentIndex==> '+currentIndex);
        Integer counterL = 0;
        for (SObject usItem : usCloneList) {
            if (counterL != currentIndex) {
                User_Story__c tempUs = (User_Story__c) usItem;
                if (null != tempUs.get(tempUs.User_Story_Title__c)) {
                    inputUsList.set(counterL, (User_Story__c) usCloneList.get(counterL));
                    counterL++;
                }
            }
        }
        return null;
    }
    public List<SObject> usCloneList {
        get {
            if (null == usCloneList) {
                usCloneList = new List<User_Story__c>();
            }
            return usCloneList;
        }
        set;
    }
    public PageReference EditCriterias() {
        String additionalQueryLocal = ApexPages.currentPage().getParameters().get('aQuery');
        System.debug('additionalQueryLocal==> ' + additionalQueryLocal);
        List<String> criterias = additionalQueryLocal.replace(')', '').replace('(', '').split(' and | or | AND | OR | And | Or ');
        System.debug('criterias==> ' + criterias);
        if (additionalQueryLocal.replace(' ', '').length() > 0) {
            inputUsList.clear();
            for (String s : criterias) {
                String s0 = s.split('=')[0].deleteWhitespace(), s1 = s.split('=')[1];
                System.debug('s==> ' + s);
                sObject sobj = new User_Story__c();
                sobj.put(ns + 'User_Story_Title__c', s0.replace('null', ''));
                sobj.put(s0, s1.replace('\'', ''));
                inputUsList.add((User_Story__c) sobj);
            }
        }
        return null;
    }
    public PageReference addLine() {
        inputUsList.add(new User_Story__c(User_Story_Title__c = ns + 'Sprint__c'));
        usCloneList.clear();
        for (SObject usItem : inputUsList) {
            User_Story__c tempUs = (User_Story__c) usItem;
            sObject sobj = new User_Story__c();
            sobj.put((String) usItem.get('User_Story_Title__c'), (String) tempUs.get(tempUs.User_Story_Title__c));
            sobj.put('User_Story_Title__c', tempUs.User_Story_Title__c);
            usCloneList.add(sobj);
        }
        return null;
    }
    public PageReference removeLine() {
        Integer rIndex = Integer.valueOf(ApexPages.currentPage().getParameters().get('rIndex'));
        System.debug('rIndex==> ' + rIndex);
        inputUsList.remove(rIndex);
        return null;
    }
    //table wrapper used in handlebarJs
    global with sharing class TableWrapper {
        public String whereClause { get; set; }
        public String qObject { get; set; }
        public String headerClause { get; set; }
        public String fType { get; set; }
        public String clause { get; set; }
        public String tableHeader { get; set; }
        public List<UserStoryWrapper> usList { get; set; }
        public String additionalQuery { get; set; }
        public String min { get; set; }
        public String max { get; set; }
        public String panelRowCount { get; set; }
        public String sortOrder { get; set; }
        public TableWrapper(
            List<UserStoryWrapper> usList,
            String tableHeader,
            String clause,
            String fType,
            String headerClause,
            String qObject,
            String whereClause,
            String additionalQuery,
            String min,
            String max,
            String panelRowCount,
            String sortOrder
        ) {
            this.usList = usList;
            this.tableHeader = tableHeader;
            this.clause = clause;
            this.fType = fType;
            this.headerClause = headerClause;
            this.qObject = qObject;
            this.whereClause = whereClause;
            this.additionalQuery = additionalQuery;
            this.min = min;
            this.max = max;
            this.panelRowCount = panelRowCount;
            this.sortOrder = sortOrder.replace('null', '');
        }
    }
    //nested by tableWrapper -level 2 of tableWrapper-
    global with sharing class UserStoryWrapper {
        public Boolean isSelected { get; set; }
        public User_Story__c usItem { get; set; }
        public UserStoryWrapper(User_Story__c usItem) {
            this.usItem = usItem;
            this.isSelected = false;
        }
    }
    //whole panels and final state info
    global with sharing class UserStates {
        public String lastState { get; set; }
        public List<PanelData> panelData { get; set; }
        public UserStates(String lastState, List<PanelData> panelData) {
            this.panelData = panelData;
            this.lastState = lastState;
        }
    }
    //panel(config) wrapper -level 2 of userStates-
    global with sharing class PanelData {
        public String pName { get; set; }
        public String additionalQuery { get; set; }
        public Set<pWrapper> pWrappers { get; set; }
        public String panelRowCount { get; set; }
        public PanelData(String pName, Set<pWrapper> pWrapper, String additionalQuery, String panelRowCount) {
            this.pName = pName;
            this.pWrappers = pWrapper;
            this.additionalQuery = additionalQuery;
            this.panelRowCount = panelRowCount;
        }
    }

    global with sharing class PanelPlusJson {
        public String jsonWmp { get; set; }
        public PanelData pData { get; set; }
        public PanelPlusJson(String jsonWmp, PanelData pData) {
            this.jsonWmp = jsonWmp;
            this.pData = pData;
        }
    }
    //tables wrapper -level 2 PanelData-
    global with sharing class PWrapper {
        public String pId { get; set; }
        public String pType { get; set; }
        public List<String> columns { get; set; }
        public String min { get; set; }
        public String max { get; set; }
        public String sortOrder { get; set; }
        public PWrapper(String pId, String pType, List<String> columns, String min, String max, String sortOrder) {
            this.pId = pId;
            this.pType = pType;
            this.columns = columns;
            this.max = max.replace('null', '');
            this.min = min.replace('null', '');
            this.sortOrder = sortOrder;
        }
        public PWrapper() {
        }
    }
}