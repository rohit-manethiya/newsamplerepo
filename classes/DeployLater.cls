/**
 * Created by ferhatozsavran on 4/25/18.
 */

global with sharing class DeployLater implements Schedulable {
    global Id deploymentId {get;set;}
    global DeployLater(Id deploymentId){
        this.deploymentId = deploymentId;
    }
    global void execute(SchedulableContext sc) {
        List<Id> depIds = new List<Id>{deploymentId};
        DeployAPI.deploy(depIds,UserInfo.getSessionId());
    }
}