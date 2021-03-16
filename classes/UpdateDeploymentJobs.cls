public with sharing class UpdateDeploymentJobs implements Queueable {
    private List<Deployment_Job__c> jobs;

    // CTOR

    public UpdateDeploymentJobs(List<Deployment_Job__c> jobs) {
        this.jobs = jobs;
    }

    // PUBLIC

    public void execute(QueueableContext ctx) {
        jobs = Security.stripInaccessible(AccessType.UPDATABLE, jobs).getRecords();
        update jobs;
    }
}