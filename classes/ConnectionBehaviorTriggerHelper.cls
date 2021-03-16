/**
 * @author Umit Can Uckan
 * @description Controls Connection Behavior driven scheduled operations
 * @date 6/9/19
 */
public with sharing class ConnectionBehaviorTriggerHelper {
    //CONSTANT variables
    public static final String C_SCHEDULEDBEHAVIOR = 'Scheduled';
    public static final String USER_STORY_QUERY = 'SELECT Id FROM User_Story__c';
    public static final String SOQL_WHERE = ' WHERE ';
    //NON-CONSTANT variables
    private static Map<Id, Connection_Behavior__c> connectionBehaviorMap = new Map<Id, Connection_Behavior__c>();
    public static List<Connection_Behavior__c> backScheduleList = new List<Connection_Behavior__c>();
    public static List<Connection_Behavior__c> forwardScheduleList = new List<Connection_Behavior__c>();
    public static List<Connection_Behavior__c> listToAbortForwardJobs = new List<Connection_Behavior__c>();
    public static List<Connection_Behavior__c> listToAbortBackJobs = new List<Connection_Behavior__c>();

    /**
     *  It will run the SOQL on User Story object by entered values on Promotion_Criteria__c and Back_Promotion_Criteria__c fields to see if entered values are accurate
     * @param newList
     */
    public static void validateUserStoryCriterias(List<Connection_Behavior__c> newList) {
        String whereClause = SOQL_WHERE;
        Integer counter = 1;

        // Promotion_Criteria__c validation
        try {
            for (Connection_Behavior__c connectionBehavior : newList) {
                if (String.isNotBlank(connectionBehavior.Promotion_Criteria__c)) {
                    whereClause += counter > 1
                        ? ' OR (' + connectionBehavior.Promotion_Criteria__c + ')'
                        : '(' + connectionBehavior.Promotion_Criteria__c + ')';
                    counter++;
                }
            }
            List<User_Story__c> userStories = Database.query(USER_STORY_QUERY + whereClause);
        } catch (Exception exc) {
            for (Connection_Behavior__c connectionBehavior : newList) {
                if (String.isNotBlank(connectionBehavior.Promotion_Criteria__c)) {
                    connectionBehavior.addError(
                        SObjectType.Connection_Behavior__c.fields.Promotion_Criteria__c.getLabel() +
                        ' ' +
                        Label.Validation_Failed.toLowerCase() +
                        ': ' +
                        exc.getMessage()
                    );
                }
            }
        }

        // Back_Promotion_Criteria__c validation
        try {
            whereClause = SOQL_WHERE;
            counter = 1;
            for (Connection_Behavior__c connectionBehavior : newList) {
                if (String.isNotBlank(connectionBehavior.Back_Promotion_Criteria__c)) {
                    whereClause += counter > 1
                        ? ' OR (' + connectionBehavior.Back_Promotion_Criteria__c + ')'
                        : '(' + connectionBehavior.Back_Promotion_Criteria__c + ')';
                    counter++;
                }
            }
            List<User_Story__c> userStories = Database.query(USER_STORY_QUERY + whereClause);
        } catch (Exception exc) {
            for (Connection_Behavior__c connectionBehavior : newList) {
                if (String.isNotBlank(connectionBehavior.Back_Promotion_Criteria__c)) {
                    connectionBehavior.addError(
                        SObjectType.Connection_Behavior__c.fields.Back_Promotion_Criteria__c.getLabel() +
                        ' ' +
                        Label.Validation_Failed.toLowerCase() +
                        ': ' +
                        exc.getMessage()
                    );
                }
            }
        }
    }

    /**
     *  If the schedule is changed for either promotions or back-promotions we should update the schedule for the scheduled Job
     *  If the promotion or backpromotion behavior is changed to "Scheduled" we should ensure that the corresponding Scheduled Job exists, and we should overwrite the existing schedule with the schedule from the Connection Behavior
     *  If a promotion or backpromotion behavior is changed to something different than "Scheduled", we should delete the corresponding Scheduled Job
     *
     * @param newList
     * @param oldList
     */
    public static void schedulePromotionsForConnectionBehavior(List<Connection_Behavior__c> newList, List<Connection_Behavior__c> oldList) {
        Integer listSize = null != newList ? newList.size() : 0;
        Boolean isInsert = (null == oldList);
        if (listSize != 0) {
            Set<Id> connectionBehaviorIds = new Set<Id>();
            for (Integer i = 0; i < listSize; i++) {
                connectionBehaviorIds.add(newList[i].Id);
            }
            connectionBehaviorMap = new Map<Id, Connection_Behavior__c>(
                [
                    SELECT
                        Id,
                        (SELECT Id, Source_Environment__c, Destination_Environment__c FROM Pipeline_Connections__r),
                        (SELECT Id, Connection_Behavior__c FROM Environments__r),
                        Back_Promotion_Scheduled_Job_ID__c,
                        Back_Promotion_Schedule__c,
                        Max_Scheduled_Back_Promotion_Batch_Size__c,
                        Back_Promotion_Behavior__c,
                        Promotion_Schedule__c,
                        Promotion_Behavior__c,
                        Promotion_Criteria__c,
                        Back_Promotion_Criteria__c,
                        Max_Scheduled_Promotion_Batch_Size__c,
                        Promotion_Scheduled_Job_ID__c
                    FROM Connection_Behavior__c
                    WHERE Id IN :connectionBehaviorIds
                ]
            );

            for (Integer i = 0; i < listSize; i++) {
                defineForwardAbortAndSchedule(newList[i], (isInsert ? null : oldList[i]), isInsert);

                defineBackAbortAndSchedule(newList[i], (isInsert ? null : oldList[i]), isInsert);
            }

            handleAbortOperation();

            handleReScheduleOperation();
        }
    }
    /**
     * check if we need to schedule or abort any schedule job for forward promotion based on changes of current connection behavior item
     *
     * @param newItem current new record
     * @param OldItem current old record
     * @param isInsert
     */
    public static void defineForwardAbortAndSchedule(Connection_Behavior__c newItem, Connection_Behavior__c oldItem, Boolean isInsert) {
        Boolean proScheduleHasChanged = isInsert ? true : newItem.Promotion_Schedule__c != oldItem.Promotion_Schedule__c;
        Boolean proBehaviorHasChanged = isInsert ? true : newItem.Promotion_Behavior__c != oldItem.Promotion_Behavior__c;
        Boolean proBatchSizeHasChanged = isInsert
            ? true
            : newItem.Max_Scheduled_Promotion_Batch_Size__c != oldItem.Max_Scheduled_Promotion_Batch_Size__c;
        if (
            newItem.Promotion_Behavior__c == C_SCHEDULEDBEHAVIOR &&
            ((String.isNotBlank(newItem.Promotion_Schedule__c) && isInsert) ||
            (!isInsert &&
            String.isNotBlank(newItem.Promotion_Schedule__c) &&
            (proScheduleHasChanged ||
            proBehaviorHasChanged ||
            proBatchSizeHasChanged)))
        ) {
            forwardScheduleList.add(newItem);
        } else if (
            String.isNotBlank(newItem.Promotion_Scheduled_Job_ID__c) &&
            ((!isInsert &&
            proScheduleHasChanged &&
            String.isEmpty(newItem.Promotion_Schedule__c)) ||
            (!isInsert &&
            newItem.Promotion_Behavior__c != C_SCHEDULEDBEHAVIOR &&
            proBehaviorHasChanged) ||
            (!isInsert && proBatchSizeHasChanged))
        ) {
            listToAbortForwardJobs.add(newItem);
        }
    }
    /**
     * check if we need to schedule or abort any schedule job for back promotion based on changes of current connection behavior item
     *
     * @param newItem current new record
     * @param oldItem current old record
     * @param isInsert
     */
    public static void defineBackAbortAndSchedule(Connection_Behavior__c newItem, Connection_Behavior__c oldItem, Boolean isInsert) {
        Boolean backProScheduleHasChanged = isInsert ? true : newItem.Back_Promotion_Schedule__c != oldItem.Back_Promotion_Schedule__c;
        Boolean backProBehaviorHasChanged = isInsert ? true : newItem.Back_Promotion_Behavior__c != oldItem.Back_Promotion_Behavior__c;
        Boolean backProBatchSizeHasChanged = isInsert
            ? true
            : newItem.Max_Scheduled_Back_Promotion_Batch_Size__c != oldItem.Max_Scheduled_Back_Promotion_Batch_Size__c;
        if (
            newItem.Back_Promotion_Behavior__c == C_SCHEDULEDBEHAVIOR &&
            ((String.isNotBlank(newItem.Back_Promotion_Schedule__c) && isInsert) ||
            (!isInsert &&
            String.isNotBlank(newItem.Back_Promotion_Schedule__c) &&
            (backProScheduleHasChanged ||
            backProBehaviorHasChanged ||
            backProBatchSizeHasChanged)))
        ) {
            backScheduleList.add(newItem);
        } else if (
            String.isNotBlank(newItem.Back_Promotion_Scheduled_Job_ID__c) &&
            ((!isInsert &&
            backProScheduleHasChanged &&
            String.isEmpty(newItem.Back_Promotion_Schedule__c)) ||
            (!isInsert &&
            newItem.Back_Promotion_Behavior__c != C_SCHEDULEDBEHAVIOR &&
            backProBehaviorHasChanged) ||
            (!isInsert && backProBatchSizeHasChanged))
        ) {
            listToAbortBackJobs.add(newItem);
        }
    }
    /**
     * handles re-scheduling operation of changed Connection behaviors
     */
    public static void handleReScheduleOperation() {
        Set<Id> sourceEnvIds = calculateDestionationIds(null, forwardScheduleList);
        for (Connection_Behavior__c connectionBehavior : forwardScheduleList) {
            abortJob(connectionBehavior.Promotion_Scheduled_Job_ID__c);
            Integer batchSize = (null != connectionBehavior.Max_Scheduled_Promotion_Batch_Size__c
                ? (Integer) connectionBehavior.Max_Scheduled_Promotion_Batch_Size__c
                : 1);
            CCD_PromotionSchedule ccdPromotionScheduleClass = new CCD_PromotionSchedule(batchSize, sourceEnvIds, connectionBehavior);
            connectionBehavior.Promotion_Scheduled_Job_ID__c = System.schedule(
                'CCD Forward Promotion Schedule - ' +
                DateTime.now() +
                '.' +
                Math.mod(DateTime.now().getTime(), 1000),
                connectionBehavior.Promotion_Schedule__c,
                ccdPromotionScheduleClass
            );
        }
        Set<Id> destEnvIds = calculateDestionationIds(backScheduleList, null);
        for (Connection_Behavior__c connectionBehavior : backScheduleList) {
            abortJob(connectionBehavior.Back_Promotion_Scheduled_Job_ID__c);
            Integer batchSize = (null != connectionBehavior.Max_Scheduled_Back_Promotion_Batch_Size__c
                ? (Integer) connectionBehavior.Max_Scheduled_Back_Promotion_Batch_Size__c
                : 10);
            CCD_BackPromotionSchedule ccdBackPromotionScheduleClass = new CCD_BackPromotionSchedule(batchSize, destEnvIds);
            connectionBehavior.Back_Promotion_Scheduled_Job_ID__c = System.schedule(
                'CCD Back Promotion Schedule - ' +
                DateTime.now() +
                '.' +
                Math.mod(DateTime.now().getTime(), 1000),
                connectionBehavior.Back_Promotion_Schedule__c,
                ccdBackPromotionScheduleClass
            );
        }
    }

    /**
     * calculates the environments to use on a related batch class queries for filtering down records purpose
     *
     * @param connectionBehaviorListForDest
     * @param connectionBehaviorListForSource
     *
     * @return identified Environment Ids to run the batch job via
     */
    private static Set<Id> calculateDestionationIds(
        List<Connection_Behavior__c> connectionBehaviorListForDest,
        List<Connection_Behavior__c> connectionBehaviorListForSource
    ) {
        Set<Id> destEnvIds = new Set<Id>();
        Set<Id> sourceEnvIds = new Set<Id>();
        Set<Id> tempEnvIdsForSourceCalculation = new Set<Id>();
        List<Connection_Behavior__c> connectionBehaviorList = (null != connectionBehaviorListForDest
            ? connectionBehaviorListForDest
            : connectionBehaviorListForSource);
        for (Connection_Behavior__c connectionBehavior : connectionBehaviorList) {
            for (Deployment_Flow_Step__c deploymentFlowStepRecord : connectionBehaviorMap.get(connectionBehavior.Id).Pipeline_Connections__r) {
                destEnvIds.add(deploymentFlowStepRecord.Destination_Environment__c);
                sourceEnvIds.add(deploymentFlowStepRecord.Source_Environment__c);
            }
            for (Environment__c environmentRecord : connectionBehaviorMap.get(connectionBehavior.Id).Environments__r) {
                destEnvIds.add(environmentRecord.Id);
                tempEnvIdsForSourceCalculation.add(environmentRecord.Id);
            }
        }
        //additional calculation to be able to spot source environment when scheduled forward promotion connection behavior is set on environment level instead of pipeline connection level
        //reason: always destination environment control the behavior
        if (connectionBehaviorListForDest == null && !tempEnvIdsForSourceCalculation.isEmpty()) {
            for (Deployment_Flow_Step__c deploymentFlowStepRecord : [
                SELECT Id, Source_Environment__c
                FROM Deployment_Flow_Step__c
                WHERE Destination_Environment__c IN :tempEnvIdsForSourceCalculation
            ]) {
                sourceEnvIds.add(deploymentFlowStepRecord.Source_Environment__c);
            }
        }
        return (null != connectionBehaviorListForDest ? destEnvIds : sourceEnvIds);
    }

    /**
     * Handles job abort operation before re-scheduling them
     */
    public static void handleAbortOperation() {
        for (Connection_Behavior__c connectionBehavior : listToAbortForwardJobs) {
            abortJob(connectionBehavior.Promotion_Scheduled_Job_ID__c);
            connectionBehavior.Promotion_Scheduled_Job_ID__c = '';
        }

        for (Connection_Behavior__c connectionBehavior : listToAbortBackJobs) {
            abortJob(connectionBehavior.Back_Promotion_Scheduled_Job_ID__c);
            connectionBehavior.Back_Promotion_Scheduled_Job_ID__c = '';
        }
    }

    /**
     * Aborts the job via jobId if it exist
     *
     * @param jobId
     */
    public static void abortJob(String jobId) {
        if (String.isNotBlank(jobId)) {
            try {
                System.abortJob(jobId);
            } catch (Exception ex) {
                System.debug('exception ===> ' + ex.getMessage());
            }
        }
    }

    /**
     * deletes the related Quality gates before delete of connection behavior records
     *
     * @param oldMap before update old Map
     */
    public static void deepDelete(Map<Id, SObject> oldMap) {
        try {
            Utilities.Secure_DML(
                [SELECT Id FROM Quality_Gate__c WHERE Connection_Behavior__c IN :oldMap.keySet()],
                Utilities.DML_Action.DEL,
                Schema.SObjectType.Quality_Gate__c
            );
        } catch (DmlException exp) {
            System.debug('exception===> ' + exp.getMessage());
        }
    }
}