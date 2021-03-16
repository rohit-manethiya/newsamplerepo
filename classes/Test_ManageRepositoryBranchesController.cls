/**
 * Created by mertyalti on 18/04/2018.
 */
@isTest
public with sharing class Test_ManageRepositoryBranchesController {
    @testSetup static void setupTest(){
        insert TestUtilities.getTestSettings();
        TestUtilities.assignLicense(UserInfo.getUserName(), true,true,true,true,true);
    }
    @isTest static void successKnownTypeTest(){
        Git_Repository__c gitRepo = new Git_Repository__c(name = 'test1');
        insert gitRepo;
        ManageRepositoryBranchesController handler = new ManageRepositoryBranchesController();
        handler.repositoryId = gitRepo.Id;
        PageReference pageRef = Page.UserStoryBranchSelection;
        Test.setCurrentPage(pageRef);
        // put the repo id as a parameter
        Map<String, String> pageParams = ApexPages.currentPage().getParameters();
        pageParams.put('repoId',gitRepo.id);
        pageParams.put('jobFinished','true');
        pageParams.put('jobSuccess','true');
        pageParams.put('jobMessage','Success Message');
        pageParams.put('jobType',CopadoNotificationHelper.DX_LIST_REPO_BRANCHES);
        handler.jobStatusNotification();
    }
    @isTest static void successUnknownTypeTest(){
        Git_Repository__c gitRepo = new Git_Repository__c(name = 'test2');
        insert gitRepo;
        ManageRepositoryBranchesController handler = new ManageRepositoryBranchesController();
        handler.repositoryId = gitRepo.Id;
        PageReference pageRef = Page.UserStoryBranchSelection;
        Test.setCurrentPage(pageRef);
        // put the repo id as a parameter
        Map<String, String> pageParams = ApexPages.currentPage().getParameters();
        pageParams.put('repoId',gitRepo.id);
        pageParams.put('jobFinished','true');
        pageParams.put('jobSuccess','true');
        pageParams.put('jobMessage','Success Message');
        pageParams.put('jobType', 'UnknownJobType');
        handler.jobStatusNotification();
    }
    @isTest static void failureTest(){
        Git_Repository__c gitRepo = new Git_Repository__c(name = 'test3');
        insert gitRepo;
        ManageRepositoryBranchesController handler = new ManageRepositoryBranchesController();
        handler.repositoryId = gitRepo.Id;
        PageReference pageRef = Page.UserStoryBranchSelection;
        Test.setCurrentPage(pageRef);
        // put the repo id as a parameter
        Map<String, String> pageParams = ApexPages.currentPage().getParameters();
        pageParams.put('repoId',gitRepo.id);
        pageParams.put('jobFinished','true');
        pageParams.put('jobSuccess','false');
        pageParams.put('jobMessage','Success Message');
        pageParams.put('jobType',CopadoNotificationHelper.DX_LIST_REPO_BRANCHES);
        handler.jobStatusNotification();
    }
}