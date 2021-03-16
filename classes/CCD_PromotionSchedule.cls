/**
 * Schedulable class to Execute CCD_PromotionBatch class for CCD forward promotion
 *
 * @author Ümit Can Uçkan
 * @version 1.0
 * @since Copado v15
 */
public class CCD_PromotionSchedule implements Schedulable {
    String executerId;
    Integer batchSize;
    Set<Id> sourceEnvIds;
    Connection_Behavior__c connectionBehavior;

    public CCD_PromotionSchedule(Integer batchSize) {
        executerId = UserInfo.getUserId();
        this.batchSize = batchSize;
    }

    public CCD_PromotionSchedule(Integer batchSize, Set<Id> sourceEnvIds) {
        executerId = UserInfo.getUserId();
        this.batchSize = batchSize;
        this.sourceEnvIds = sourceEnvIds;
    }

    public CCD_PromotionSchedule(Integer batchSize, Set<Id> sourceEnvIds, Connection_Behavior__c connectionBehavior) {
        executerId = UserInfo.getUserId();
        this.batchSize = batchSize;
        this.sourceEnvIds = sourceEnvIds;
        this.connectionBehavior = connectionBehavior;
    }

    public void execute(SchedulableContext sc) {
        Id ccd_PromotionScheduleId = Database.executeBatch(new CCD_PromotionBatch(this.executerId, sourceEnvIds, connectionBehavior), batchSize);
    }
}