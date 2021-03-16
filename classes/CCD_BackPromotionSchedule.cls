/**
 * Schedulable class to Execute CCD_BackPromotionBatch class for CCD back promotion
 *
 * @author Ümit Can Uçkan
 * @version 1.0
 * @since Copado v15
 */
public class CCD_BackPromotionSchedule implements Schedulable {
    String executerId;
    Integer batchSize;
    Set<Id> destEnvIds;

    public CCD_BackPromotionSchedule(Integer batchSize) {
        executerId = UserInfo.getUserId();
        this.batchSize = batchSize;
    }

    public CCD_BackPromotionSchedule(Integer batchSize, Set<Id> destEnvIds) {
        executerId = UserInfo.getUserId();
        this.batchSize = batchSize;
        this.destEnvIds = destEnvIds;
    }

    public void execute(SchedulableContext sc) {
        Id ccd_BackPromotionScheduleId = Database.executeBatch(new CCD_BackPromotionBatch(this.executerId, destEnvIds), batchSize);
        System.debug('ccd_BackPromotionScheduleId===> '+ccd_BackPromotionScheduleId);
    }
}