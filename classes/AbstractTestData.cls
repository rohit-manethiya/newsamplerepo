public abstract with sharing class AbstractTestData implements ITestDefaults {
    private static final Integer MAX_DIFFERENT_SOBJECTTYPES_PER_DML = 10;
    private static final String SYSTEM_ADMINISTRATOR = 'System Administrator';
    private static final String STANDARD_USER = 'Standard User';
    private static final String STANDARD_USER_NAME = 'test_user@myorg.com';
    private static final String ADMIN = 'Admin';
    private static final String STANDARD = 'Standard';
    private static final String GIVEN_OBJECT_NOT_FOUND = 'Given object\'s setup not found!';
    protected Map<Schema.SObjectType, Map<Schema.SObjectField, Object>> testDataFieldDefaultsByObject = new Map<Schema.SObjectType, Map<Schema.SObjectField, Object>>();
    protected Map<Schema.SObjectType, Integer> dataSizeByObject = new Map<Schema.SObjectType, Integer>();
    private Map<Schema.SObjectType, List<SObject>> testDataByObject = new Map<Schema.SObjectType, List<SObject>>();
    private Map<Schema.SObjectType, Set<Schema.SObjectField>> incrementalFieldByObject = new Map<Schema.SObjectType, Set<Schema.SObjectField>>();
    private Map<Schema.SObjectType, List<SObjectRelationWrapper>> sObjectRelationsByObject = new Map<Schema.SObjectType, List<SObjectRelationWrapper>>();
    private Map<Integer, Map<SObjectType, List<SObject>>> objectsToBeInsertedByPriority = new Map<Integer, Map<SObjectType, List<SObject>>>();
    private Map<SObjectType, Integer> levelOfHierarchyBySObjectType = new Map<SObjectType, Integer>();
    private static Integer currentLevelOfHierarchy = 0;
    private static Set<SObjectType> objectTypesWithChilds = new Set<SObjectType>();

    abstract ITestDefaults setFieldDefaults();

    /**
     * This method is to override a FieldDefault value given in setFieldDefaults.
     * @see setFieldDefaults
     * @param objectType
     * @param objectField
     * @param fieldValue
     *
     * @return ITestDefaults
     * @throw AbstractFactoryException
     */
    public ITestDefaults setFieldValue(Schema.SObjectType objectType, Schema.SObjectField objectField, Object fieldValue) {
        if (testDataFieldDefaultsByObject.containsKey(objectType)) {
            testDataFieldDefaultsByObject.get(objectType).put(objectField, fieldValue);
            return this;
        } else {
            throw new AbstractFactoryException(GIVEN_OBJECT_NOT_FOUND);
        }
    }

    /**
     * Given an SObjectType you can set which fields have to be treated as incremental. Ex: User Story Title 1, User Story Title 2,etc...
     * @param incrementalFields
     *
     * @return ITestDefaults
     */
    // TODO: check if fields in Set<Schema.SObjectField> exists in testDataFieldDefaultsByObject. if not return an AbstractFactoryException.
    public ITestDefaults setIncrementalFields(Map<Schema.SObjectType, Set<Schema.SObjectField>> incrementalFields) {
        incrementalFieldByObject.putAll(incrementalFields);
        return this;
    }

    /**
     * Given main SObjectType, you can add more SObjectTypes in chained method.
     * @param childDefaults
     *
     * @return ITestDefaults
     */
    public ITestDefaults includeDefaults(Type childDefaults) {
        // Check if ChildDefaults variable is null, and throw standard assert exception in that case
        if (childDefaults == null) {
            throw new AbstractFactoryException('In order to include secondary defaults the variable (childDefaults) cannot be null.');
        }

        Object childInstance = childDefaults.newInstance();
        if (childInstance instanceof ITestDefaults) {
            ITestDefaults children = (ITestDefaults) childInstance;
            children.setFieldDefaults();
            this.testDataFieldDefaultsByObject.putAll(children.getTestDataFieldDefaultsByObject());
            return this;
        } else {
            throw new AbstractFactoryException(GIVEN_OBJECT_NOT_FOUND);
        }
    }

    /**
     * Having several SObjectTypes declared, you can set the relation among SObjectTypes relation.
     * @param objectType
     * @param parentObjectType
     * @param chunkSizeByField is made of: child object field and a chunk to point out how many records will be assign to same parent object
     * @warn  this method will not work to self relantionships, or if relantionships between objects are done bidirectionally
     * @return ITestDefaults
     */
    public ITestDefaults setSObjectRelation(
        Schema.SObjectType objectType,
        Schema.SObjectType parentObjectType,
        Map<Schema.SObjectField, Integer> chunkSizeByField
    ) {
        objectTypesWithChilds.add(parentObjectType);
        if (!sObjectRelationsByObject.containsKey(objectType)) {
            sObjectRelationsByObject.put(objectType, new List<SObjectRelationWrapper>());
        }
        sObjectRelationsByObject.get(objectType).add(new SObjectRelationWrapper(parentObjectType, chunkSizeByField));
        return this;
    }

    /**
     * Sets the number of records to create per SObjectType
     * @param objectType
     * @param size
     *
     * @return ITestDefaults
     */
    public ITestDefaults setDataSize(Schema.SObjectType objectType, Integer size) {
        dataSizeByObject.put(objectType, size);
        return this;
    }

    /**
     * Having all previous steps setup: foreach SObjectType declared it creates data according its settings. (no DML at this point)
     * (!sObjectsUnique.equals(newSObjectsUnique)) is preventing duplicates when using several times: .generateDefaults() in the same block.
     * @see TestDataFactory.createSObjectList
     *
     * @return ITestDefaults
     */
    public ITestDefaults generateDefaults() {
        for (Schema.SObjectType objectType : dataSizeByObject.keySet()) {
            List<SObject> sObjects = new List<SObject>(testDataByObject.get(objectType));
            Set<SObject> uniqueSObjects = new Set<SObject>(sObjects);
            Map<Schema.SObjectField, Object> objectDefaultsByField = testDataFieldDefaultsByObject.get(objectType);
            List<SObject> newSObjects = TestDataFactory.createSObjectList(
                objectType.newSObject(),
                dataSizeByObject.get(objectType),
                objectDefaultsByField,
                incrementalFieldByObject
            );
            Set<SObject> newUniqueSObjects = new Set<SObject>(newSObjects);
            if (!uniqueSObjects.equals(newUniqueSObjects)) {
                sObjects.addAll(newSObjects);
                testDataByObject.put(objectType, sObjects);
            }
        }
        return this;
    }

    /**
     * Based on Defaults generated in "generateDefaults()"
     * 1) Separate records by its SObjectType and priority"
     * 2) Set their relantionships and insert them
     *
     * @see generateDefaults
     * @return ITestDefaults
     */
    public ITestDefaults executeDML() {
        for (Schema.SObjectType sobjtype : testDataByObject.keySet()) {
            // if this SObjectType is parent in a relationship, it is skipped and will be processed when proccessing its childs
            if (objectTypesWithChilds.contains(sobjtype)) {
                continue;
            }
            checkHaveParentsAndCategorize(sobjtype);
            if (!objectsToBeInsertedByPriority.containsKey(currentLevelOfHierarchy)) {
                objectsToBeInsertedByPriority.put(currentLevelOfHierarchy, new Map<SobjectType, List<Sobject>>());
            }
            if (!objectsToBeInsertedByPriority.get(currentLevelOfHierarchy).containsKey(sobjtype)) {
                objectsToBeInsertedByPriority.get(currentLevelOfHierarchy).put(sobjtype, new List<SObject>(testDataByObject.get(sobjtype)));
                // for levels of hierarchy 0 we should never need this assignment since they are not parents in any relationship
                levelOfHierarchyBySObjectType.put(sobjtype, currentLevelOfHierarchy);
            }
        }
        insertCategorizedData();
        return this;
    }

    /**
     * Checks if a sobjectype is child in a relantionship, recursively for its parents and store its records by priority
     */
    private void checkHaveParentsAndCategorize(SObjectType sobjtype) {
        if (sObjectRelationsByObject.containsKey(sobjtype)) {
            currentLevelOfHierarchy++;
            for (SObjectRelationWrapper objectRelation : sObjectRelationsByObject.get(sobjtype)) {
                // Check if the SobjectType has already been added to the map with its priority to be inserted, if not, just add it
                if (levelOfHierarchyBySObjectType.containsKey(objectRelation.parentObjectType)) {
                    // If it has been added, check if the priority it had previosly is less important than the current one
                    // If the priority was less important, delete it from the previous priority and add it again with the current higher priority
                    // On the contrary, if the priority that existed previously was higher than the current one, just do nothing
                    if (levelOfHierarchyBySObjectType.get(objectRelation.parentObjectType) < currentLevelOfHierarchy) {
                        // Check if the map has already a map of SobjectType with its records associated with the current priority,
                        // If not, put the current priority as a key in the map and assign an empty map to it
                        if (!objectsToBeInsertedByPriority.containsKey(currentLevelOfHierarchy)) {
                            objectsToBeInsertedByPriority.put(currentLevelOfHierarchy, new Map<SobjectType, List<Sobject>>());
                        }
                        objectsToBeInsertedByPriority.get(currentLevelOfHierarchy)
                            .put(
                                objectRelation.parentObjectType,
                                objectsToBeInsertedByPriority.get(levelOfHierarchyBySObjectType.get(objectRelation.parentObjectType))
                                    // Delete from the previous hierarchy level (it returns the associated value)
                                    .remove(objectRelation.parentObjectType)
                            );
                        levelOfHierarchyBySObjectType.put(objectRelation.parentObjectType, currentLevelOfHierarchy);
                        // process also accounts fathers to increase its levels of hierarchy too
                        checkHaveParentsAndCategorize(objectRelation.parentObjectType);
                    }
                } else {
                    checkHaveParentsAndCategorize(objectRelation.parentObjectType);
                    if (!objectsToBeInsertedByPriority.containsKey(currentLevelOfHierarchy)) {
                        objectsToBeInsertedByPriority.put(currentLevelOfHierarchy, new Map<SobjectType, List<Sobject>>());
                    }
                    if (!objectsToBeInsertedByPriority.get(currentLevelOfHierarchy).containsKey(objectRelation.parentObjectType)) {
                        objectsToBeInsertedByPriority.get(currentLevelOfHierarchy)
                            .put(objectRelation.parentObjectType, new List<SObject>(testDataByObject.get(objectRelation.parentObjectType)));
                        levelOfHierarchyBySObjectType.put(objectRelation.parentObjectType, currentLevelOfHierarchy);
                    }
                }
            }
            currentLevelOfHierarchy--;
        }
    }

    /**
     * Having the data separated by priority, aka hierarchy, set their relantionships and insert them in the proper order
     */
    private void insertCategorizedData() {
        List<Integer> orderedLevelsOfHierarchy = new List<Integer>(objectsToBeInsertedByPriority.keySet());
        orderedLevelsOfHierarchy.sort();
        for (Integer i = orderedLevelsOfHierarchy.size() - 1, j = 0; i >= j; i--) {
            Map<SObjectType, List<SObject>> objectsToInsertByType = objectsToBeInsertedByPriority.get(orderedLevelsOfHierarchy[i]);
            List<SObject> recordsToInsert = new List<SObject>();
            Integer numberOfSobjectsProcessed = 0;

            for (SObjectType currentSobjectType : objectsToInsertByType.keySet()) {
                if (numberOfSObjectsProcessed != 0 && Math.mod(numberOfSObjectsProcessed, MAX_DIFFERENT_SOBJECTTYPES_PER_DML) == 0) {
                    insert recordsToInsert;
                    recordsToInsert = new List<SObject>();
                }
                if (sObjectRelationsByObject.containsKey(currentSObjectType)) {
                    assignSObjectRelation(currentSobjectType);
                }
                recordsToInsert.addAll(objectsToInsertByType.get(currentSObjectType));
                numberOfSobjectsProcessed++;
            }
            insert recordsToInsert;
        }
    }

    /**
     * Create 1 Adming User and 1 Standard User, with their corresponent permission sets
     *
     * @return ITestDefaults
     */
    public ITestDefaults createRunAsUsers() {
        Map<String, Profile> profileByName = getProfiles(new Set<String>{ SYSTEM_ADMINISTRATOR, STANDARD_USER });

        ITestDefaults userCreation = new CopadoSetupTestDefaults.UserDefaults()
            .setFieldDefaults()
            .setFieldValue(User.SObjectType, User.ProfileId, profileByName.get(SYSTEM_ADMINISTRATOR).Id)
            .setFieldValue(User.SObjectType, User.Username, 'test_admin@myorg.com')
            .setDataSize(User.SObjectType, 1)
            .generateDefaults()
            .includeDefaults(CopadoSetupTestDefaults.UserDefaults.class)
            .setFieldValue(User.SObjectType, User.ProfileId, profileByName.get(STANDARD_USER).Id)
            .setFieldValue(User.SObjectType, User.Username, STANDARD_USER_NAME)
            .setDataSize(User.SObjectType, 1)
            .includeDefaults(CopadoSetupTestDefaults.PermissionSetAssignmentDefaults.class)
            .setDataSize(PermissionSetAssignment.SObjectType, 2) // You must add as much as permission assignment records as users you will add.
            .generateDefaults();

        testDataByObject.put(User.SObjectType, userCreation.getTestData(User.SObjectType));
        testDataByObject.put(PermissionSetAssignment.SObjectType, userCreation.getTestData(PermissionSetAssignment.SObjectType.SObjectType));
        // Objectrelation has to be done this way to keep current instance. Doing it in chained method causes loose current instante
        sObjectRelationsByObject.put(
            PermissionSetAssignment.SObjectType,
            new List<SObjectRelationWrapper>{
                new SObjectRelationWrapper(User.SObjectType, new Map<Schema.SObjectField, Integer>{ PermissionSetAssignment.AssigneeId => 1 })
            }
        );
        return this;
    }

    /**
     * Retrieve the created users, accessible by their type (admin or standard)
     *
     * @see createRunAsUsers
     *
     * @return Map<String, List<User>>
     */
    public Map<String, List<User>> getRunAsUsers() {
        Map<String, List<User>> usersByType = new Map<String, List<User>>();
        List<User> userList = (List<User>) testDataByObject.get(User.SObjectType);
        for (User usr : UserList) {
            String userType;
            switch on usr.Username {
                when 'test_admin@myorg.com' {
                    userType = ADMIN;
                }
                when 'test_user@myorg.com' {
                    userType = STANDARD;
                }
            }
            if (usersByType.get(userType) == null) {
                usersByType.put(userType, new List<User>());
            }
            usersByType.get(userType).add(usr);
        }
        return usersByType;
    }

    /**
     * Assign lookups with its parent ids. It uses chunk parameter per field to know how many records will be assign to same parent object per field.
     *
     * @param objectType
     */
    private void assignSObjectRelation(Schema.SObjectType objectType) {
        List<SObjectRelationWrapper> objectTypeRelationships = sObjectRelationsByObject.get(objectType);
        List<SObject> mainChildRecrods = testDataByObject.get(objectType);
        for (SObjectRelationWrapper objectRelation : objectTypeRelationships) {
            List<SObject> parentRecords = testDataByObject.get(objectRelation.parentObjectType);
            Integer numberOfParentRecords = parentRecords.size();
            for (Schema.SObjectField relationField : objectRelation.chunkSizeByField.keySet()) {
                Integer maxChildRecordsWithSameParent = objectRelation.chunkSizeByField.get(relationField);
                Integer indexOfParentRecordToAssign = 0;
                for (Integer i = 0, j = mainChildRecrods.size(); i < j; i++) {
                    if (i != 0 && Math.mod(i, maxChildRecordsWithSameParent) == 0 && (indexOfParentRecordToAssign + 1) < numberOfParentRecords) {
                        indexOfParentRecordToAssign++;
                    }
                    mainChildRecrods[i].put(relationField, parentRecords[indexOfParentRecordToAssign].get('Id'));
                }
            }
        }
    }

    /**
     * Returns "testDataByObject" for the current instance.
     * @return testDataByObject
     */

    public List<SObject> getTestData(Schema.SObjectType objectType) {
        if (objectType == User.SObjectType) {
            System.debug(LoggingLevel.WARN, 'Use getRunAsUsers instead to get Users by Profile');
        }
        return this.testDataByObject.get(objectType);
    }

    /**
     * Returns "testDataFieldDefaultsByObject" for the current instance.
     * @return testDataFieldDefaultsByObject
     */
    public Map<Schema.SObjectType, Map<Schema.SObjectField, Object>> getTestDataFieldDefaultsByObject() {
        return this.testDataFieldDefaultsByObject;
    }

    /**
     * Given a set of profile names, returns the profile objects with that name, accesible by its name
     * @return Map<String, Profile>
     */
    public Map<String, Profile> getProfiles(Set<String> profileNames) {
        Map<String, Profile> profileById = new Map<String, Profile>();
        List<Profile> profiles = [SELECT Id, Name FROM Profile WHERE Name = :profileNames];
        for (Profile prof : profiles) {
            if (profileNames.contains(prof.Name)) {
                profileById.put(prof.Name, prof);
            }
        }
        return profileById;
    }

    /**
     * Relation wrapper to support all information needed for SObjectType relations.
     */
    private with sharing class SObjectRelationWrapper {
        public Schema.SObjectType parentObjectType { get; set; }
        public Map<Schema.SObjectField, Integer> chunkSizeByField { get; set; }
        public SObjectRelationWrapper(Schema.SObjectType parentObjectType, Map<Schema.SObjectField, Integer> chunkSizeByField) {
            this.parentObjectType = parentObjectType;
            this.chunkSizeByField = chunkSizeByField;
        }
    }

    /**
     * Returns standard user to use in test classes.
     */
    public static User getStandardUser() {
        return [SELECT Username FROM User WHERE Username = :STANDARD_USER_NAME LIMIT 1];
    }

    public with sharing class AbstractFactoryException extends Exception {
    }
}