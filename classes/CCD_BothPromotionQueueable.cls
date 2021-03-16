/**
 * callout the backend endpoint to start deployment for each ready promotion record
 * its already in future context so needed queueable class
 */
public class CCD_BothPromotionQueueable implements Queueable {
    public final List<String> calloutVariables;
    public CCD_BothPromotionQueueable(List<String> input) {
        calloutVariables = input;
    }
    public void execute(QueueableContext context) {
        for(String str : calloutVariables) {
            calloutWrapper cItem = (calloutWrapper) JSON.deserialize(str, calloutWrapper.class);
            DeployAPI.deployPromotionAsync(cItem.promotionId, cItem.userStoryName, cItem.checkOnly, cItem.singleStep, cItem.testLevel, cItem.isDeployParam, cItem.commitUserIdParam);
        }
    }

    public class calloutWrapper {
        public Id promotionId;
        public String userStoryName;
        public Boolean checkOnly;
        public Boolean singleStep;
        public String testLevel;
        public Boolean isDeployParam;
        public String commitUserIdParam;
        public calloutWrapper(Id promotionId, String userStoryName, Boolean checkOnly, Boolean singleStep, String testLevel, Boolean isDeployParam, String commitUserIdParam) {
            this.promotionId = promotionId;
            this.userStoryName = userStoryName.length() > 80 ? userStoryName.substring(0, 80) : userStoryName;
            this.checkOnly = checkOnly;
            this.singleStep = singleStep;
            this.testLevel = testLevel;
            this.isDeployParam = isDeployParam;
            this.commitUserIdParam = commitUserIdParam;
        }
    }
}