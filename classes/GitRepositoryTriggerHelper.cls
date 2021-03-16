public with sharing class GitRepositoryTriggerHelper {

    private static Set<Id> gitRepoIdsSet = new Set<Id>();

    public static void collectRepoIds(Git_Repository__c gitRepo) {
        gitRepoIdsSet.add(gitRepo.Id);
    }

    public static void deleteSensitiveInformations() {
        if(!gitRepoIdsSet.isEmpty()) {
            List<Sensitive_Information__c> sensitiveInfList = [SELECT Id FROM Sensitive_Information__c WHERE Name IN :gitRepoIdsSet];

            if(!sensitiveInfList.isEmpty()) {
                delete sensitiveInfList;
            }
        }
    }
}