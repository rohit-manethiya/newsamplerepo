@IsTest
public with sharing class Test_ErrorHandlingComponentController {

    @TestSetup static void setup() {
        // Create common test records
        insert TestUtilities.getTestSettings();
        TestUtilities.insertUser('user1-dxOperations@test-copado.org', 'System Administrator');
        TestUtilities.assignLicense(UserInfo.getUserName(), true, true, true, true, true);
        TestUtilities.createAllDXTestData();
    }
    
    @IsTest static void testErrorMessage() {
        Test.startTest();
        List<String> resultString = new List<String>{
                'step 1', 'step 2'
        };
        ErrorHandlingComponentController controller = new ErrorHandlingComponentController();
        controller.errorMessage = new UIDesignHelper.CustomExceptionData(ApexPages.Severity.ERROR, 'Error message', new List<String>{
                'step 1', 'step 2'
        }, 0, '', '');

        controller.errorMessageJSON = JSON.serialize(controller.errorMessage);
        controller.populateErrorMessage();

        System.assertEquals(controller.overrideMessage, 'Error message');
        System.assertEquals(controller.stepsToFixIssueList, resultString);

        Test.stopTest();
    }

    // TODO delete methods below after v13 beta version and create real test case for them
    @IsTest static void uiDesignHelper() {
        Test.startTest();

        UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.User_Story__c.label);
        ApexPages.Message[] pageMessages = ApexPages.getMessages();
        System.assertNotEquals(0, pageMessages.size());
        // Check that the error message you are expecting is in pageMessages
        Boolean messageFound = false;
        for(ApexPages.Message message : pageMessages) {
            System.debug('**f** : ' + message.getDetail());
            String errorMessage = Label.Insufficient_Access_Rights;
            if(message.getDetail() == errorMessage && message.getSeverity() == ApexPages.Severity.WARNING) {
                messageFound = true;
            }
        }
        System.assert(messageFound);

        UIDesignHelper.genericWarningMessage(ApexPages.Severity.WARNING, Label.Insufficient_Access_Rights);
        List<Object> objectList = new List<Object>();
        UIDesignHelper.genericWarningMessage(ApexPages.Severity.WARNING, objectList);


        Map<String, List<Object>> dummyMap = new Map<String, List<Object>>();
        dummyMap = UIDesignHelper.genericWarningMessage('warning', objectList);

        Map<String, Set<Object>> dummy2Map = new Map<String, Set<Object>>();
        dummy2Map = UIDesignHelper.accumulativeGenericWarningMessage('warning', objectList, dummy2Map);
        dummy2Map = UIDesignHelper.accumulativeGenericWarningMessage('warning', objectList, dummy2Map);

        UIDesignHelper.clearPageMessages();

        Test.stopTest();
    }

}