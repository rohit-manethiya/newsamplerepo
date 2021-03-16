public with sharing class SprintVirtualWall {

    private final Sprint__c sprint;
    public User_Story__c us { get; set; }
    public User_Story_Task__c usTask { get; set; }

    @TestVisible private Integer offSetCounter = 0;  //keeps track of the offset
    @TestVisible private Integer listSize = 200; //sets the page size or number of rows

    private Set<String> sectionRendererSet = new Set<String>{
        'onlyUS', 'usWithFilter'
    };
    private Set<String> sectionSwitcherSet = new Set<String>{
        'list', 'snippet', 'drag'
    };

    public String sectionRenderer { get; set; } // Possible values are 'onlyUS', 'usWithFilter'
    public String sectionSwitcher { get; set; } // Possible values are 'list', 'snippet', 'drag'
    public String usModalMode { get; set; } // Possible values are 'new', 'edit', 'massupdate'
    public String namespace { get; set; }
    public String selectedSprintCompleteOption { get; set; }
    @TestVisible private String filterWhereConditions;
    private final String ONLYUS = 'onlyUS';
    private final String NONE = '--None--';
    private final String C_USID = 'usId';
    private final String C_ACTUAL = 'actual';
    private final String C_PLANNED = 'planned';
    private final String C_COMPLETED = 'Completed';
    private final String C_INPROGRESS = 'In Progress';
    private final String C_SPRCOMPLETE = 'Sprint_Complete';
    private final String C_USTASKID = 'usTaskId';
    private final String C_NEXTSPRINT = 'nextsprint';
    private final String BACKLOG = 'backlog';
    private final String C_BACKLOG = 'Backlog';
    private final String C_ID = 'Id';
    private final String C_EDIT = 'edit';
    private final String C_AND = ' AND ';

    public List<userStoryWrapper> usWrapperList { get; set; }
    public List<userStoryDeveloperWrapper> usDevWrapperList { get; set; } // keeps developer name of the user stories for filtering
    public List<userStoryStatusWrapper> pickListValuesWrapperList { get; set; } // keeps picklist values of status field of the user story object for filtering
    public List<userStoryRecordTypeWrapper> rtValuesWrapperList { get; set; } // keeps record type values for filtering

    private Map<String, Integer> userStoryFLS = null;

    private Integer totalListSizeCache;

    public Boolean isUsUpdateable { get; set; }
    public Boolean isUSCreateable { get; set; }
    public Boolean isUsTaskUpdateable { get; set; }
    public Boolean isUSTaskCreateable { get; set; }
    public Boolean isUSTaskDeletable { get; set; }
    public Boolean isKanbanCreateable { get; set; }


    public SprintVirtualWall(ApexPages.StandardController stdController) {
        if(!Test.isRunningTest()) {
            stdController.addFields(new List<String>(Schema.SObjectType.Sprint__c.fields.getMap().keySet()));
        }
        this.sprint = (Sprint__c) stdController.getRecord();

        namespace = Settings.ns;
        sectionRenderer = ONLYUS;
        sectionSwitcher = 'list';
        filterWhereConditions = '';

        isUsUpdateable = Schema.SObjectType.User_Story__c.isUpdateable();
        isUSCreateable = Schema.SObjectType.User_Story__c.isCreateable();
        isUsTaskUpdateable = Schema.SObjectType.User_Story_Task__c.isUpdateable();
        isUSTaskCreateable = Schema.SObjectType.User_Story_Task__c.isCreateable();
        isUSTaskDeletable = Schema.SObjectType.User_Story_Task__c.isDeletable();
        isKanbanCreateable = Schema.SObjectType.Kanban_Board__c.isCreateable();

        us = new User_Story__c();
        usTask = new User_Story_Task__c();

        getUserStories();
    }

    /**
     * To know how may records there are
     * @return
     */
    public Integer getTotalListSize() {
        return totalListSizeCache;
    }

    /**
     * user clicked beginning
     */
    public void beginning() {
        offSetCounter = 0;
        getUserStories();
    }

    /**
     * user clicked previous button
     */
    public void previous() {
        offSetCounter -= listSize;
        getUserStories();
    }

    /**
     * user clicked next button
     */
    public void next() {
        offSetCounter += listSize;
        getUserStories();
    }

    /**
     *  user clicked end
     */
    public void end() {
        Integer totalListSize = getTotalListSize();
        offSetCounter = totalListSize != 0 ? totalListSize - Math.mod(totalListSize, listSize) : 0;
        getUserStories();
    }

    /**
     * this will disable the previous and beginning buttons
     * @return
     */
    public Boolean getDisablePrevious() {
        return (offSetCounter > 0) ? false : true;
    }

    /**
     * this will disable the next and end buttons
     * @return
     */
    public Boolean getDisableNext() {
        return (offSetCounter + listSize < getTotalListSize()) ? false : true;
    }

    /**
     * this will return current page number
     * @return
     */
    public Integer getPageNumber() {
        return offSetCounter / listSize + 1;
    }

    /**
     * this will return total page number
     * @return
     */
    public Integer getTotalPages() {
        Integer totalListSize = getTotalListSize();
        return totalListSize != 0 ? (Math.mod(totalListSize, listSize) > 0) ? totalListSize / listSize + 1 : (totalListSize / listSize) : 1;
    }

    /**
     *
     */
    public void pageRendererAssignment() {
        sectionRenderer = ApexPages.currentPage().getParameters().get('pRenderer');
        if(!sectionRendererSet.contains(sectionRenderer)) {
            UIDesignHelper.genericWarningMessage(ApexPages.Severity.WARNING, Label.Incorrect_Parameter);
        }
        if(String.isNotBlank(sectionRenderer) && sectionRenderer == 'usWithFilter') {
            getUserStoryFilterValues();
        }
    }

    /**
     *
     */
    public void pageSwithcerAssignment() {
        sectionSwitcher = ApexPages.currentPage().getParameters().get('pSwitcher');
        if(!sectionSwitcherSet.contains(sectionSwitcher)) {
            UIDesignHelper.genericWarningMessage(ApexPages.Severity.WARNING, Label.Incorrect_Parameter);
        }
    }

    /**
     * this will return next sprint Id
     * @return
     */
    public String getNextSprint() {
        String nextSprintId = '';
        if(Schema.SObjectType.Sprint__c.isAccessible() && Schema.SObjectType.Sprint__c.isQueryable()) {
            List<Sprint__c> nextSprintList = [SELECT Id FROM Sprint__c WHERE Start_Date__c >= :sprint.End_Date__c AND Id != :sprint.Id AND Project__c = :sprint.Project__c ORDER BY Start_Date__c LIMIT 1];
            if(!nextSprintList.isEmpty()) {
                nextSprintId = nextSprintList[0].Id;
            }
        } else {
            UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.Sprint__c.getLabel());
            return nextSprintId;
        }
        return nextSprintId;
    }

    /**
     * this will return previous sprint Id
     * @return
     */
    public String getPreviousSprint() {
        String previousSprintId = '';
        if(Schema.SObjectType.Sprint__c.isAccessible() && Schema.SObjectType.Sprint__c.isQueryable()) {
            List<Sprint__c> prevSprintList = [SELECT Id FROM Sprint__c WHERE End_Date__c <= :sprint.Start_Date__c AND Id != :sprint.Id AND Project__c = :sprint.Project__c ORDER BY End_Date__c DESC LIMIT 1];
            if(!prevSprintList.isEmpty()) {
                previousSprintId = prevSprintList[0].Id;
            }
        } else {
            UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.Sprint__c.getLabel());
            return previousSprintId;
        }
        return previousSprintId;
    }

    /**
     * velocity calculation
     * @return
     */
    public Map<String, Decimal> getCalculatedVelocities() {
        Map<String, Decimal> calculatedVelocitiesMap = new Map<String, Decimal>();
        calculatedVelocitiesMap.put(C_ACTUAL, 0);
        calculatedVelocitiesMap.put(C_PLANNED, 0);
        if(String.isNotBlank(sprint.Id)) {
            Set<String> actualVelocityStatus = getCustomMetadataValues('Actual_Velocity_Statuses', C_COMPLETED);
            if(Schema.SObjectType.User_Story__c.isAccessible() && Schema.SObjectType.User_Story__c.isQueryable()) {
                for(User_Story__c us : [SELECT Story_Points_SFDC__c, Status__c FROM User_Story__c WHERE Sprint__c = :sprint.Id]) {
                    if(actualVelocityStatus.contains(us.Status__c)) {
                        Decimal currentValue = calculatedVelocitiesMap.get(C_ACTUAL);
                        Decimal newValue = us.Story_Points_SFDC__c != null ? us.Story_Points_SFDC__c : 0;
                        calculatedVelocitiesMap.put(C_ACTUAL, currentValue + newValue);
                    }
                    if(calculatedVelocitiesMap.containsKey(C_PLANNED)) {
                        Decimal currentValue = calculatedVelocitiesMap.get(C_PLANNED);
                        Decimal newValue = us.Story_Points_SFDC__c != null ? us.Story_Points_SFDC__c : 0;
                        calculatedVelocitiesMap.put(C_PLANNED, currentValue + newValue);
                    }
                }
            } else {
                UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.User_Story__c.getLabel());
                return calculatedVelocitiesMap;
            }
        }
        return calculatedVelocitiesMap;
    }

    /**
     * New ability to customize the calculation of actual velocity based on custom metadata 'Actual_Velocity_Statuses'. Default value is 'Completed'
     * New ability to customize the sprint complete 'Sprint_Complete'. default value is 'In Progress'
     * @param devName name of the custom metadata that you want to perform
     * @param defaultValue default value for the action
     * @return
     */
    private Set<String> getCustomMetadataValues(String devName, String defaultValue) {
        Set<String> customMetadataValuesSet = new Set<String>();
        for(Copado_Setting__mdt cs : [SELECT Id, Text_Field__c FROM Copado_Setting__mdt WHERE DeveloperName = :devName LIMIT 1]) {
            if(String.isNotBlank(cs.Text_Field__c)) {
                for(String str : cs.Text_Field__c.split(',')) {
                    str = str.trim();
                    customMetadataValuesSet.add(str);
                }
            } else {
                customMetadataValuesSet.add(defaultValue);
            }
        }
        return customMetadataValuesSet;
    }

    /**
     * This is used to populate days left field on the header
     * @return
     */
    public String getDaysLeftString() {
        Boolean closedSpring = Date.today() > sprint.End_Date__c ? true : false;
        Boolean notStartedSpring = Date.today() < sprint.Start_Date__c ? true : false;
        Boolean currentSpring = sprint.End_Date__c != null ? true : false;

        return closedSpring ? Label.SprintWall_DaysLeft_Closed : notStartedSpring ? Label.SprintWall_DaysLeft_Not_Started : currentSpring ? String.valueOf(Date.today().daysBetween(sprint.End_Date__c)) : '';
    }

    /**
     * This is used to check if org has chatter enabled so chatter button is hidden and not rendered
     * @return
     */
    public Boolean getIsChatterEnabled() {
        return Schema.SObjectType.User.isFeedEnabled() && Schema.SObjectType.Sprint__c.isFeedEnabled();
    }

    /**
     * This is used to clear filter and refresh the user story table
     */
    public void refreshTable() {
        // To close the filter panel changing value to 'onlyUS'
        sectionRenderer = ONLYUS;
        getUserStories();
    }

    /**
     * This is used to avoid SOQL injection
     * @param str
     * @return
     */
    private String sqlStr(String str) {
        return '\'' + String.escapeSingleQuotes(str) + '\'';
    }

    /**
     * This is used to add where condition to the main user story query by using selected values on the page
     */
    public void applyFilter() {
        offSetCounter = 0;
        sectionRenderer = ONLYUS;
        getUserStories();
    }

    /**
     * Main user stories query.
     */
    public void getUserStories() {
        // Preparing developer, status and recordtype conditions
        Set<String> developerSet = new Set<String>();
        Set<String> statusSet = new Set<String>();
        Set<String> recordTypeSet = new Set<String>();

        List<String> whereConditions = new List<String>();

        if(usDevWrapperList != null) {
            developerSet.clear();
            for(userStoryDeveloperWrapper t : usDevWrapperList) {
                if(t.isSelected) {
                    developerSet.add(t.fieldValue);
                }
            }
            if(!developerSet.isEmpty()) {
                whereConditions.add('Developer__r.Name IN :developerSet');
            }
        }

        if(pickListValuesWrapperList != null) {
            statusSet.clear();
            for(userStoryStatusWrapper t : pickListValuesWrapperList) {
                if(t.isSelected) {
                    statusSet.add(t.fieldValue);
                }
            }
            if(!statusSet.isEmpty()) {
                whereConditions.add('Status__c IN :statusSet');
            }
        }

        if(rtValuesWrapperList != null) {
            recordTypeSet.clear();
            for(userStoryRecordTypeWrapper t : rtValuesWrapperList) {
                if(t.isSelected) {
                    recordTypeSet.add(t.fieldValue);
                }
            }
            if(!recordTypeSet.isEmpty()) {
                whereConditions.add('Recordtype.Name IN :recordTypeSet');
            }
        }

        filterWhereConditions = whereConditions.isEmpty() ? '' : C_AND + String.join(whereConditions, C_AND);

        try {
            String sprintId = sprint.Id;
            String fieldsetFields = '';
            for(Schema.FieldSetMember fs : SObjectType.User_Story__c.fieldSets.Sprint_Wall_Columns.getFields()) {
                fieldsetFields += fs.getFieldPath() + ',';
            }
            String usQuery = '';
            if(Schema.SObjectType.User_Story__c.isQueryable() && Schema.SObjectType.User_Story__c.isAccessible()) {
                usQuery = 'SELECT Id, Name, toLabel(Status__c), RecordTypeId, Recordtype.Name, Developer__c, Developer__r.Name, ' +
                    'Owner.Name, OwnerId, User_Story_Title__c, Business_Analyst__c, ' +
                    'Test_Script_Owner__c, Order__c, Story_Points_SFDC__c, ' +
                    fieldsetFields +
                    '(SELECT Id, Subject__c, Hours_Remaining__c, Status__c, User_Story__c ' +
                    'FROM User_Story_Tasks__r ' +
                    'ORDER BY Hours_Remaining__c) ' +
                    'FROM User_Story__c ' +
                    'WHERE Sprint__c = :sprintId ' +
                    filterWhereConditions +
                    ' ORDER BY Order__c ASC NULLS LAST, CreatedDate ' +
                    'LIMIT :listSize ' +
                    'OFFSET :offSetCounter';
                usWrapperList = new List<userStoryWrapper>();

                if(Schema.SObjectType.User_Story__c.isAccessible() && Schema.SObjectType.User_Story__c.isQueryable()) {
                    for(User_Story__c userStory : Database.query(usQuery)) {
                        usWrapperList.add(new userStoryWrapper(userStory));
                    }

                    totalListSizeCache = Database.countQuery('SELECT COUNT() FROM User_Story__c WHERE Sprint__c =:sprintId' + filterWhereConditions);
                } else {
                    UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.User_Story__c.getLabel());
                    return;
                }
            }
        } catch(Exception excp) {
            UIDesignHelper.catchExceptionMessage(excp);
        }
    }

    /**
     * This is used to retrieve possible filter values for all user stories in the sprint
     */
    public void getUserStoryFilterValues() {
        try {
            // Filling possible developer name from all user stories in the sprint.
            String sprintId = sprint.Id;
            String usQuery = '';
            Set<String> developerNameSet = new Set<String>();
            if(Schema.SObjectType.User_Story__c.isAccessible() && Schema.SObjectType.User_Story__c.isQueryable()) {
                usQuery = 'SELECT Id, Status__c, Recordtype.Name, Developer__r.Name ' +
                    'FROM User_Story__c ' +
                    'WHERE Sprint__c = :sprintId ' +
                    'ORDER BY Order__c ASC, CreatedDate NULLS LAST ';
                for(User_Story__c userStory : Database.query(usQuery)) {
                    if(String.isNotBlank(userStory.Developer__r.Name) && !developerNameSet.contains(userStory.Developer__r.Name)) {
                        developerNameSet.add(userStory.Developer__r.Name);
                    }
                }
            } else {
                UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.User_Story__c.getLabel());
                return;
            }
            if(usDevWrapperList == null || usDevWrapperList.isEmpty()) {
                usDevWrapperList = new List<userStoryDeveloperWrapper>();
                for(String str : developerNameSet) {
                    usDevWrapperList.add(new userStoryDeveloperWrapper(str));
                }
            } else {
                Set<String> existingNameSet = new Set<String>();
                for(userStoryDeveloperWrapper dw : usDevWrapperList) {
                    existingNameSet.add(dw.fieldValue);
                }
                for(String str : developerNameSet) {
                    if(!existingNameSet.contains(str)) {
                        usDevWrapperList.add(new userStoryDeveloperWrapper(str));
                    }
                }
            }

            if(pickListValuesWrapperList == null || pickListValuesWrapperList.isEmpty()) {
                // picklist value of the status field of the user stories
                pickListValuesWrapperList = new List<userStoryStatusWrapper>();
                Schema.DescribeFieldResult fieldResult = User_Story__c.Status__c.getDescribe();
                List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
                for(Schema.PicklistEntry pickListVal : ple) {
                    pickListValuesWrapperList.add(new userStoryStatusWrapper(pickListVal.getLabel()));
                }
            }

            if(rtValuesWrapperList == null || rtValuesWrapperList.isEmpty()) {
                // record type values of the user stories
                rtValuesWrapperList = new List<userStoryRecordTypeWrapper>();
                List<RecordType> recordTypeList = new List<RecordType>();
                if(Schema.SObjectType.RecordType.isAccessible() && Schema.SObjectType.RecordType.isQueryable()) {
                    recordTypeList = [SELECT Name FROM RecordType WHERE SobjectType = :Schema.SObjectType.User_Story__c.getName()];
                } else {
                    UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.User_Story__c.getLabel());
                    return;
                }
                for(RecordType rt : recordTypeList) {
                    rtValuesWrapperList.add(new userStoryRecordTypeWrapper(rt.Name));
                }
            }
        } catch(Exception excp) {
            UIDesignHelper.catchExceptionMessage(excp);
        }
    }

    /**
     * This is used to move the user story to the next sprint
     */
    public void moveUsToNextSprint() {
        String usId = ApexPages.currentPage().getParameters().get(C_USID);
        String nextSprintId = getNextSprint();
        if(String.isNotBlank(usId) && String.isNotBlank(nextSprintId)) {
            Decimal currentOrderNumber = findCurrentOrderNumber(usId);
            User_Story__c us = new User_Story__c(Id = usId, Sprint__c = nextSprintId);
            User_Story__c cloneUserStory = new User_Story__c();
            // Checking the FLS and CRUD for each field in the user story task
            for(String fieldName : getUserStoryFLS(us, true)) {
                cloneUserStory.put(fieldName, us.get(fieldName));
            }
            //Utilities.Secure_DML(cloneUserStory, Utilities.DML_Action.UPD, schema.SObjectType.User_Story__c);
            updateUserStoriesOrder(currentOrderNumber, cloneUserStory); // updating user stories to adjust order field
            getUserStories();
        }
    }

    /**
     * This is used to clear sprint lookup from user story
     */
    public void removeSprintFromUs() {
        String usId = ApexPages.currentPage().getParameters().get(C_USID);
        if(String.isNotBlank(usId)) {
            Decimal currentOrderNumber = findCurrentOrderNumber(usId);
            User_Story__c us = new User_Story__c(Id = usId, Sprint__c = null);
            User_Story__c cloneUserStory = new User_Story__c();
            // Checking the FLS and CRUD for each field in the user story task
            for(String fieldName : getUserStoryFLS(us, true)) {
                cloneUserStory.put(fieldName, us.get(fieldName));
            }
            //Utilities.Secure_DML(cloneUserStory, Utilities.DML_Action.UPD, schema.SObjectType.User_Story__c);
            updateUserStoriesOrder(currentOrderNumber, cloneUserStory); // updating user stories to adjust order field
            getUserStories();
        }
    }

    /**
     * This is used to get new instance of the user story and auto populate the user story for modal
     */
    public void prepareUserStory() {
        // new instance is needed to clear object
        us = new User_Story__c();
        // 'usId' will be used to update user story
        String usId = ApexPages.currentPage().getParameters().get(C_USID);
        // 'usModalMode' will be used to auto populate user story
        usModalMode = ApexPages.currentPage().getParameters().get('mode');

        if(String.isNotBlank(usId) && usModalMode == C_EDIT) {
            for(userStoryWrapper existingUs : usWrapperList) {
                if(usId == existingUs.userStory.Id) {
                    us = existingUs.userStory;
                }
            }
        }
    }

    /**
     * getUserStoryFLS(false) to return the field list for CREATE, true for UPDATE
     * @param tempUs
     * @param forCreateandUpdate
     * @return
     */
    private Set<String> getUserStoryFLS(User_Story__c tempUs, Boolean forCreateAndUpdate) {
        // cache the list fo fields
        userStoryFLS = new Map<String, Integer>();
        Map<String, Schema.SObjectField> userStoryFieldsMap = Schema.SObjectType.User_Story__c.fields.getMap();
        userStoryFLS.put(C_ID, 2);
        for(String fieldName : tempUs.getPopulatedFieldsAsMap().keySet()) {
            if(!fieldName.contains('__r') && fieldName != 'RecordType' && fieldName != 'Owner' && fieldName != C_ID) {
                Schema.DescribeFieldResult t = userStoryFieldsMap.get(fieldName).getDescribe();
                userStoryFLS.put(fieldName, t.isUpdateable() ? 2 : (t.isCreateable() ? 1 : 0));
            }
        }

        Set<String> fieldSet = new Set<String>();
        for(String t : userStoryFLS.keySet()) {
            if(forCreateAndUpdate && userStoryFLS.get(t) == 2) {
                fieldSet.add(t);
            } else if(!forCreateAndUpdate && userStoryFLS.get(t) >= 1) {
                fieldSet.add(t);
            }
        }
        return fieldSet;
    }

    /**
     * This is used to create new us
     * @return
     */
    public PageReference userStoryCreateOperation() {
        try {
            PageReference pUsReference = null;
            User_Story__c cloneUserStory = new User_Story__c();
            if(us != null && String.isNotBlank(sprint.Id) && usModalMode == 'new') {
                us.Sprint__c = sprint.Id;

                // Checking the FLS and CRUD for each field in the user story task
                for(String fieldName : getUserStoryFLS(us, false)) {
                    cloneUserStory.put(fieldName, us.get(fieldName));
                }

                Utilities.Secure_DML(cloneUserStory, Utilities.DML_Action.INS, schema.SObjectType.User_Story__c);

                if(String.isNotBlank(cloneUserStory.Id) && String.isNotBlank(sprint.Id)) {
                    pUsReference = new ApexPages.StandardController(cloneUserStory).edit();
                    pUsReference.setRedirect(true);
                    return pUsReference;
                }
            }
            return pUsReference;
        } catch(Exception excp) {
            UIDesignHelper.catchExceptionMessage(excp);
            return null;
        }
    }

    /**
     * This is used to edit us and mass update the us
     * @return
     */
    public void userStoryUpdateOperation() {
        User_Story__c cloneUserStory = new User_Story__c();
        try {
            if(String.isNotBlank(us.Id) && usModalMode == C_EDIT) {
                // Checking the FLS and CRUD for each field in the user story task
                for(String fieldName : getUserStoryFLS(us, true)) {
                    cloneUserStory.put(fieldName, us.get(fieldName));
                }
                Utilities.Secure_DML(cloneUserStory, Utilities.DML_Action.UPD, schema.SObjectType.User_Story__c);
            } else if(us != null && String.isNotBlank(sprint.Id) && usModalMode == 'massupdate') {
                // prepare an UPDATEABLE FLS list of field names.
                Set<String> userStoryFieldsSet = new Set<String>();
                Map<String, Schema.SObjectField> userStoryFieldsMap = Schema.SObjectType.User_Story__c.fields.getMap();
                for(Schema.FieldSetMember fs : SObjectType.User_Story__c.fieldSets.SprintWall_MassUpdate.getFields()) {
                    if(us.get(fs.getFieldPath()) != null && userStoryFieldsMap.get(fs.getFieldPath()).getDescribe().isUpdateable()) {
                        userStoryFieldsSet.add(fs.getFieldPath());
                    }
                }

                // now, for each selected US, put the value of each field in newUsList.
                List<User_Story__c> newUsList = new List<User_Story__c>();
                Set<String> usIdSet = new Set<String>();
                for(userStoryWrapper existingUs : usWrapperList) {
                    if(existingUs.isSelected) {
                        for(String fieldName : userStoryFieldsSet) {
                            existingUs.userStory.put(fieldName, us.get(fieldName));
                            if(!usIdSet.contains(existingUs.userStory.Id)) {
                                newUsList.add(existingUs.userStory);
                                usIdSet.add(existingUs.userStory.Id);
                            }
                        }
                    }
                }
                if(!newUsList.isEmpty()) {
                    Utilities.Secure_DML(newUsList, Utilities.DML_Action.UPD, schema.SObjectType.User_Story__c);
                }
            }
            getUserStories();
        } catch(Exception excp) {
            UIDesignHelper.catchExceptionMessage(excp);
        }
    }

    /**
     * This is used to get new instance of the user story task and auto populate the user story task for modal
     */
    public void prepareUserStoryTask() {
        // new instance is needed to clear object
        usTask = new User_Story_Task__c();
        // 'usId' will be used to match user story task
        String usId = ApexPages.currentPage().getParameters().get(C_USID);
        // 'usTaskId' will be used to update user story task
        String usTaskId = ApexPages.currentPage().getParameters().get(C_USTASKID);
        if(String.isNotBlank(usId) && String.isBlank(usTaskId)) {
            usTask.User_Story__c = usId;
            usTask.Status__c = 'Not Started';
        } else if(String.isNotBlank(usId) && String.isNotBlank(usTaskId)) {
            for(userStoryWrapper existingUs : usWrapperList) {
                if(usId == existingUs.userStory.Id) {
                    for(User_Story_Task__c ust : existingUs.userStory.User_Story_Tasks__r) {
                        if(ust.Id == usTaskId) {
                            usTask = ust;
                        }
                    }
                }
            }
        }
    }

    /**
     * This is used to create and update new user story task
     */
    public void userStoryTaskOperation() {
        try {
            // Checking the FLS and CRUD for each field in the user story task
            User_Story_Task__c cloneUserStoryTask = new User_Story_Task__c();
            Map<String, Schema.SObjectField> userStoryTaskFieldsMap = Schema.SObjectType.User_Story_Task__c.fields.getMap();
            for(String fieldName : usTask.getPopulatedFieldsAsMap().keySet()) {
                if(userStoryTaskFieldsMap.get(fieldName).getDescribe().isCreateable() || userStoryTaskFieldsMap.get(fieldName).getDescribe().isUpdateable() || (String.isNotBlank(fieldName) && fieldName == C_ID)) {
                    cloneUserStoryTask.put(fieldName, usTask.get(fieldName));
                }
            }
            if(cloneUserStoryTask != null) {
                Utilities.Secure_DML(cloneUserStoryTask, Utilities.DML_Action.UPS, schema.SObjectType.User_Story_Task__c);
                getUserStories();
            }
        } catch(Exception excp) {
            UIDesignHelper.catchExceptionMessage(excp);
        }
    }

    /**
     * This is used to delete new user story task
     */
    public void userStoryTaskDeletion() {
        try {
            String usTaskId = ApexPages.currentPage().getParameters().get(C_USTASKID);
            if(String.isNotBlank(usTaskId) && Schema.SObjectType.User_Story_Task__c.isQueryable() && Schema.SObjectType.User_Story_Task__c.isAccessible()) {
                List<User_Story_Task__c> ustList = new List<User_Story_Task__c>([SELECT Id FROM User_Story_Task__c WHERE Id = :usTaskId]);
                if(!ustList.isEmpty()) {
                    Utilities.Secure_DML(ustList, Utilities.DML_Action.DEL, schema.SObjectType.User_Story_Task__c);
                    getUserStories();
                }
            } else {
                UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.User_Story_Task__c.getLabel());
                return;
            }
        } catch(Exception excp) {
            UIDesignHelper.catchExceptionMessage(excp);
        }
    }

    /**
     * this wrapper is used to mass update us
     */
    public class userStoryWrapper {
        public Boolean isSelected { get; set; }
        public User_Story__c userStory { get; set; }

        public userStoryWrapper(User_Story__c us) {
            this.isSelected = false;
            this.userStory = us;
        }
    }

    /**
     * this wrapper is used for status filters
     */
    public class userStoryStatusWrapper {
        public Boolean isSelected { get; set; }
        public String fieldValue { get; set; }

        public userStoryStatusWrapper(String fieldVal) {
            this.isSelected = false;
            this.fieldValue = fieldVal;
        }
    }

    /**
     * this wrapper is used for developer name filters
     */
    public class userStoryDeveloperWrapper {
        public Boolean isSelected { get; set; }
        public String fieldValue { get; set; }

        public userStoryDeveloperWrapper(String fieldVal) {
            this.isSelected = false;
            this.fieldValue = fieldVal;
        }
    }

    /**
     * this wrapper is used for record type filters
     */
    public class userStoryRecordTypeWrapper {
        public Boolean isSelected { get; set; }
        public String fieldValue { get; set; }

        public userStoryRecordTypeWrapper(String fieldVal) {
            this.isSelected = false;
            this.fieldValue = fieldVal;
        }
    }

    /**
     * This is used to update status of the user story task by drag and drop
     * @param recordId
     * @param newPicklistValue
     */
    @RemoteAction
    public static void updateRecordsPicklistValue(String recordId, String newPicklistValue) {
        try {
            User_Story_Task__c usTask = new User_Story_Task__c(Id = recordId, Status__c = newPicklistValue);

            // Checking the FLS and CRUD for each field in the user story task
            User_Story_Task__c cloneUserStoryTask = new User_Story_Task__c();
            Map<String, Schema.SObjectField> userStoryTaskFieldsMap = Schema.SObjectType.User_Story_Task__c.fields.getMap();
            for(String fieldName : usTask.getPopulatedFieldsAsMap().keySet()) {
                if(userStoryTaskFieldsMap.get(fieldName).getDescribe().isUpdateable() || fieldName == 'Id') {
                    cloneUserStoryTask.put(fieldName, usTask.get(fieldName));
                }
            }
            if(String.isNotBlank(recordId) && String.isNotBlank(newPicklistValue) && Schema.SObjectType.User_Story_Task__c.isUpdateable()) {
                Utilities.Secure_DML(cloneUserStoryTask, Utilities.DML_Action.UPD, schema.SObjectType.User_Story_Task__c);
            }
        } catch(Exception excp) {
            UIDesignHelper.catchExceptionMessage(excp);
        }
    }

    /**
     * This is used to redirect to the next or previous sprint
     * @return
     */
    public PageReference goToStandardRecordView() {
        String sprMode = ApexPages.currentPage().getParameters().get('sprMode');
        String sprId = sprMode == 'next' ? getNextSprint() : sprMode == 'previous' ? getPreviousSprint() : '';
        if(String.isNotBlank(sprId)) {
            Id newSprintId = sprId;
            return new ApexPages.StandardController(newSprintId.getSobjectType().newSObject(newSprintId)).view();
        }
        return null;
    }

    /**
     * Return a list of data points for a chart
     * @return
     */
    public List<BurndownItem> getData() {
        List<BurndownItem> chartDataList = new List<BurndownItem>();

        // If sprint is closed, we need to check the attachment and read the data from attachament
        if(String.isNotBlank(sprint.Id) && sprint.End_Date__c != null && Date.today() > sprint.End_Date__c) {
            if(Schema.SObjectType.Attachment.isQueryable() && Schema.SObjectType.Attachment.isAccessible()) {
                List<Attachment> attList = [SELECT Body FROM Attachment WHERE ParentId = :sprint.Id AND Name = 'BurnDownItems' LIMIT 1];

                if(!attList.isEmpty()) {
                    String attachmentBody = attList[0].Body.toString();
                    if(String.isNotBlank(attachmentBody)) {
                        // Parse entire JSON response.
                        JSONParser parser = JSON.createParser(attachmentBody);
                        while(parser.nextToken() != null) {
                            if(parser.getCurrentToken() == JSONToken.START_OBJECT) {
                                BurndownItem bdi = (BurndownItem) parser.readValueAs(BurndownItem.class);
                                chartDataList.add(bdi);
                            }
                        }
                    }
                }
            } else {
                UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.Attachment.getLabel());
                return chartDataList;
            }
        } else if(String.isNotBlank(sprint.Id)) {
            if(Schema.SObjectType.Burndown_Item__c.isQueryable() && Schema.SObjectType.Burndown_Item__c.isAccessible()) {
                for(Burndown_Item__c bdi : [SELECT Id, Total_Story_Point__c, Expected_Story_Point__c, Date__c FROM Burndown_Item__c WHERE Sprint__c = :sprint.Id ORDER BY Date__c ASC]) {
                    chartDataList.add(new burndownItem(String.valueOf(bdi.Date__c), bdi.Expected_Story_Point__c, bdi.Total_Story_Point__c));
                }
            } else {
                UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.Burndown_Item__c.getLabel());
                return chartDataList;
            }
        }
        return chartDataList;
    }

    /**
     * Returns the total number of completed user stories in the sprint
     * @return
     */
    public Integer getCompletedUsNumber() {
        Integer completedUS = 0;
        if(Schema.SObjectType.User_Story__c.isQueryable() && Schema.SObjectType.User_Story__c.isAccessible()) {
            completedUS = [SELECT COUNT() FROM User_Story__c WHERE Sprint__c = :sprint.Id AND Status__c NOT IN :getCustomMetadataValues(C_SPRCOMPLETE, C_INPROGRESS)];
        } else {
            UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.User_Story__c.getLabel());
            return completedUS;
        }
        return completedUS;
    }

    /**
     * Returns the total number of incompleted user stories in the sprint
     * @return
     */
    public Integer getInCompletedUsNumber() {
        Integer inCompletedUS = 0;
        if(Schema.SObjectType.User_Story__c.isQueryable() && Schema.SObjectType.User_Story__c.isAccessible()) {
            inCompletedUS = [SELECT COUNT() FROM User_Story__c WHERE Sprint__c = :sprint.Id AND Status__c IN :getCustomMetadataValues(C_SPRCOMPLETE, C_INPROGRESS)];
        } else {
            UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.User_Story__c.getLabel());
            return inCompletedUS;
        }
        return inCompletedUS;
    }

    /**
     * Returns possible option for completing the sprint
     * @return
     */
    public List<SelectOption> getSprintCompleteOptions() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption(BACKLOG, C_BACKLOG));
        if(String.isNotBlank(getNextSprint())) {
            options.add(new SelectOption(C_NEXTSPRINT, 'Next Sprint'));
            options.add(new SelectOption('splitmove', 'Split & Move'));
        }
        return options;
    }

    /**
     * it is used to complete sprint
     */
    public void completeSprint() {
        Map<String, Schema.SObjectField> schemaFieldMap = Schema.SObjectType.User_Story__c.fields.getMap();
        Set<String> statusSet = getCustomMetadataValues(C_SPRCOMPLETE, C_INPROGRESS);
        String fields = '';
        for(String s : schemaFieldMap.keySet()) {
            if(schemaFieldMap.get(s).getDescribe().isCreateable()) {
                fields += s + ',';
            }
        }
        fields = fields.substring(0, fields.length() - 1);
        String sprintId = sprint.Id;
        String query = 'SELECT ' + fields + ' FROM User_Story__c WHERE Sprint__c = :sprintId AND Status__c IN : statusSet';

        List<User_Story__c> usUpsList = new List<User_Story__c>();
        List<User_Story__c> usList = new List<User_Story__c>();
        if(Schema.SObjectType.User_Story__c.isQueryable() && Schema.SObjectType.User_Story__c.isAccessible()) {
            usList = Database.query(query);
        } else {
            UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.User_Story__c.getLabel());
            return;
        }

        try {
            for(User_Story__c us : usList) {
                if(selectedSprintCompleteOption == BACKLOG) {
                    if(Schema.SObjectType.User_Story__c.fields.Status__c.isUpdateable()) {
                        us.Status__c = C_BACKLOG;
                    }
                    if(Schema.SObjectType.User_Story__c.fields.Sprint__c.isUpdateable()) {
                        us.Sprint__c = null;
                    }
                } else if(selectedSprintCompleteOption == C_NEXTSPRINT) {
                    if(Schema.SObjectType.User_Story__c.fields.Sprint__c.isUpdateable()) {
                        us.Sprint__c = getNextSprint();
                    }
                } else {
                    if(us.Progress__c == null || us.Progress__c == 0) {
                        if(Schema.SObjectType.User_Story__c.fields.Sprint__c.isUpdateable()) {
                            us.Sprint__c = getNextSprint();
                        }
                    } else {
                        User_Story__c usClone = us.clone(false, false, false, false);
                        usClone.User_Story_Title__c = usClone.User_Story_Title__c + ' ' + Label.USER_STORY_UNFINISHED_SUFFIX;
                        usClone.Status__c = C_COMPLETED;

                        // story point calculation for completed part
                        Decimal storyPointsClone = usClone.Story_Points_SFDC__c != null ? usClone.Story_Points_SFDC__c : 0;
                        Decimal progressClone = usClone.Progress__c != null ? usClone.Progress__c : 100;
                        Decimal completedStoryPoint = storyPointsClone * (progressClone / 100);

                        if(Schema.SObjectType.User_Story__c.fields.Story_Points_SFDC__c.isUpdateable()) {
                            usClone.Story_Points_SFDC__c = completedStoryPoint.setScale(0, System.RoundingMode.UP);
                        }
                        if(Schema.SObjectType.User_Story__c.fields.Progress__c.isUpdateable()) {
                            usClone.Progress__c = 100;
                        }

                        usUpsList.add(usClone);

                        if(Schema.SObjectType.User_Story__c.fields.Sprint__c.isUpdateable()) {
                            us.Sprint__c = getNextSprint();
                        }
                        if(Schema.SObjectType.User_Story__c.fields.User_Story_Title__c.isUpdateable()) {
                            us.User_Story_Title__c = us.User_Story_Title__c + ' ' + Label.USER_STORY_CONTINUATION_SUFFIX;
                        }

                        // story point calculation for remaining part
                        Decimal storyPoints = us.Story_Points_SFDC__c != null ? us.Story_Points_SFDC__c : 0;
                        Decimal progress = us.Progress__c != null ? us.Progress__c : 100;
                        Decimal remainingStoryPoint = storyPoints - (storyPoints * (progress / 100));

                        if(Schema.SObjectType.User_Story__c.fields.Story_Points_SFDC__c.isUpdateable()) {
                            us.Story_Points_SFDC__c = remainingStoryPoint.setScale(0, System.RoundingMode.UP);
                        }
                        if(Schema.SObjectType.User_Story__c.fields.Progress__c.isUpdateable()) {
                            us.Progress__c = 0;
                        }
                    }
                }
                usUpsList.add(us);
            }
        } catch(Exception excp) {
            UIDesignHelper.catchExceptionMessage(excp);
            return;
        }

        if(!usUpsList.isEmpty()) {
            Utilities.Secure_DML(usUpsList, Utilities.DML_Action.UPS, schema.SObjectType.User_Story__c);
            getUserStories();

            if(Schema.SObjectType.Sprint__c.fields.Status__c.isUpdateable()) {
                sprint.Status__c = C_COMPLETED;
                Utilities.Secure_DML(sprint, Utilities.DML_Action.UPD, schema.SObjectType.Sprint__c);
            }
        }
    }

    /**
     * it is used to open kanban board for current sprint
     * @return
     */
    public PageReference kanbanBoardOperations() {
        String kanbanBoardName = 'Kanban Board For ' + sprint.Name.replace('(previous)', '').replace('(current)', '').replace('(next)', '');

        Kanban_Board__c kb = new Kanban_Board__c();
        if(Schema.SObjectType.Kanban_Board__c.isQueryable() && Schema.SObjectType.Kanban_Board__c.isAccessible()) {
            List<Kanban_Board__c> kbList = new List<Kanban_Board__c>([SELECT Id FROM Kanban_Board__c WHERE Name = :kanbanBoardName LIMIT 1]);
            if(!kbList.isEmpty()) {
                kb = kbList.get(0);
            } else {
                String soqlQuery = 'SELECT Id,Name,RecordTypeId,OwnerId,'
                    + namespace + 'Developer__c,'
                    + namespace + 'User_Story_Title__c,'
                    + namespace + 'Progress_Status__c,'
                    + namespace + 'Status__c,'
                    + namespace + 'Story_Points_SFDC__c,'
                    + namespace + 'Progress__c FROM '
                    + namespace + 'user_story__c WHERE '
                    + namespace + 'Sprint__c = ' + sqlStr(sprint.Id) + ' LIMIT 200';

                QueryEditor dummyQEditor = new QueryEditor();
                QueryEditor.SoqlWrapper dummySoqlJsonWrapper = new QueryEditor.SoqlWrapper();

                QueryEditor.CriteriaWrapper dummyCriteriaWrapper = new QueryEditor.CriteriaWrapper();
                dummyCriteriaWrapper.order = 1;
                dummyCriteriaWrapper.operatorSet = null;
                dummyCriteriaWrapper.operator = 'e';
                dummyCriteriaWrapper.input = sprint.Id;
                dummyCriteriaWrapper.fieldType = 'REFERENCE';
                dummyCriteriaWrapper.fieldName = namespace + 'Sprint__c';
                dummyCriteriaWrapper.dateInput = null;
                dummyCriteriaWrapper.dateTimeInput = null;

                dummySoqlJsonWrapper.viewName = kanbanBoardName;
                dummySoqlJsonWrapper.selectedFields = new List<String>{
                    C_ID, 'OwnerId', 'Name', 'CreatedDate', 'RecordTypeId', namespace + 'Developer__c', namespace + 'User_Story_Title__c', namespace + 'Progress_Status__c', namespace + 'Status__c', namespace + 'Story_Points_SFDC__c', namespace + 'Progress__c'
                };
                dummySoqlJsonWrapper.selectedFooterFields = new List<String>{
                };
                dummySoqlJsonWrapper.summarizeByList = new List<QueryEditor.SummarizeByWrapper>{
                };
                dummySoqlJsonWrapper.criteriaList = new List<QueryEditor.CriteriaWrapper>{
                    dummyCriteriaWrapper
                };
                dummySoqlJsonWrapper.orderByList = new List<String>{
                };
                dummySoqlJsonWrapper.queryLimit = '200';
                dummySoqlJsonWrapper.wholeSoql = soqlQuery;
                dummySoqlJsonWrapper.fieldToReadUpdate = namespace + 'Status__c';
                dummySoqlJsonWrapper.headerField = NONE;
                dummySoqlJsonWrapper.orderedIn = NONE;
                dummySoqlJsonWrapper.nullValues = NONE;
                dummySoqlJsonWrapper.sobjectTypeName = namespace + 'user_story__c';
                dummySoqlJsonWrapper.enableFilterLogic = false;
                dummySoqlJsonWrapper.filterLogic = '';
                dummySoqlJsonWrapper.kanbanDescription = kanbanBoardName;
                dummySoqlJsonWrapper.userImageField = NONE;
                dummySoqlJsonWrapper.colorField = NONE;

                dummyQEditor.queryWrapper = dummySoqlJsonWrapper;

                try {
                    if(Schema.SObjectType.Kanban_Board__c.fields.Name.isCreateable() && Schema.SObjectType.Kanban_Board__c.fields.Description__c.isCreateable() && Schema.SObjectType.Kanban_Board__c.fields.Field_to_read_update__c.isCreateable() && Schema.SObjectType.Kanban_Board__c.fields.SOQL_Query__c.isCreateable() && Schema.SObjectType.Kanban_Board__c.fields.JSON_Settings__c.isCreateable()) {
                        kb.Name = kanbanBoardName;
                        kb.Description__c = kanbanBoardName;
                        kb.Field_to_read_update__c = namespace + 'user_story__c.' + namespace + 'Status__c' ;
                        kb.SOQL_Query__c = soqlQuery;
                        kb.JSON_Settings__c = JSON.serialize(dummyQEditor);

                        Utilities.Secure_DML(kb, Utilities.DML_Action.INS, schema.SObjectType.Kanban_Board__c);
                    }
                } catch(Exception excp) {
                    UIDesignHelper.catchExceptionMessage(excp);
                    return null;
                }
            }
            PageReference pReference = Page.KanbanBoardView;
            if(String.isNotBlank(kb.Id)) {
                pReference.getParameters().put(C_ID, kb.Id);
            }
            pReference.setRedirect(true);
            return pReference;
        } else {
            UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.Kanban_Board__c.getLabel());
            return null;
        }
    }

    /**
     * it is used to run burndown item batch class to update burndown item records
     */
    public void runBatchNow() {
        BurnDownItemBatchClass batch = new BurnDownItemBatchClass();
        Database.executeBatch(batch, 200);
    }

    /**
     * updates user story order based on Order__c field. New and old order is coming from visualfroce page.
     */
    public void updateUSOrder() {
        String newUSOrder = ApexPages.currentPage().getParameters().get('newUSOrder');
        List<String> newUSOrderList = new List<String>();
        if(String.isNotBlank(newUSOrder)) {
            newUSOrderList = (List<String>) JSON.deserialize(newUSOrder, List<String>.class);
        }
        String oldUSOrder = ApexPages.currentPage().getParameters().get('oldUSOrder');
        List<String> oldUSOrderList = new List<String>();
        if(String.isNotBlank(oldUSOrder)) {
            oldUSOrderList = (List<String>) JSON.deserialize(oldUSOrder, List<String>.class);
        }

        Map<Id, User_Story__c> usMap = new Map<Id, User_Story__c>();
        for(userStoryWrapper usw : usWrapperList) {
            for(Integer i = 0; i < newUSOrderList.size(); i++) {
                if(usw.userStory.Order__c == Decimal.valueOf(newUSOrderList[i]) && !usMap.containsKey(usw.userStory.Id)) {
                    if(!Schema.SObjectType.User_Story__c.fields.Order__c.isUpdateable()) {
                        UIDesignHelper.genericWarningMessage(ApexPages.Severity.WARNING, Label.Insufficient_Access_Order_Field);
                        return;
                    }
                    usw.userStory.Order__c = Decimal.valueOf(oldUSOrderList[i]);
                    usMap.put(usw.userStory.Id, usw.userStory);
                }
            }
        }

        try {
            if(!usMap.isEmpty()) {
                Utilities.Secure_DML(usMap.values(), Utilities.DML_Action.UPD, schema.SObjectType.User_Story__c);
                getUserStories();
            }
        } catch(Exception excp) {
            UIDesignHelper.catchExceptionMessage(excp);
        }
    }

    /**
     * Define current order number of the user story
     * @param usId
     * @return
     */
    private Decimal findCurrentOrderNumber(String usId) {
        Decimal currentOrder = 0;
        if(Schema.SObjectType.User_Story__c.isQueryable() && Schema.SObjectType.User_Story__c.isAccessible() && String.isNotBlank(usId)) {
            currentOrder = [SELECT Order__c FROM User_Story__c WHERE Sprint__c = :sprint.Id AND Id = :usId].Order__c;
        } else {
            UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.User_Story__c.getLabel());
            return currentOrder;
        }
        return currentOrder;
    }

    /**
     *  update user stories order field based on sprint actions (update, delete). We will update Order field to null and trigger will update new order correctly
     * @param orderNumber
     */
    private void updateUserStoriesOrder(Decimal orderNumber, User_Story__c us2update) {
        if(Schema.SObjectType.User_Story__c.isQueryable() && Schema.SObjectType.User_Story__c.isAccessible()) {
            List<User_Story__c> usList = new List<User_Story__c>{
                    us2update
            };
            for(User_Story__c us : [SELECT Order__c FROM User_Story__c WHERE Sprint__c = :sprint.Id AND Order__c > :orderNumber]) {
                if(!Schema.SObjectType.User_Story__c.fields.Order__c.isUpdateable()) {
                    UIDesignHelper.genericWarningMessage(ApexPages.Severity.WARNING, Label.Insufficient_Access_Order_Field);
                    return;
                }
                us.Order__c = us.Order__c - 1;
                usList.add(us);
            }
            if(!usList.isEmpty()) {
                try {
                    Utilities.Secure_DML(usList, Utilities.DML_Action.UPD, schema.SObjectType.User_Story__c);
                } catch(Exception excp) {
                    UIDesignHelper.catchExceptionMessage(excp);
                    return;
                }
            }
        } else {
            UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.User_Story__c.getLabel());
            return;
        }
    }
}