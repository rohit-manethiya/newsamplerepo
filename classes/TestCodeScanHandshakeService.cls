@isTest
public class TestCodeScanHandshakeService {

    static testMethod void testHandshake() {

        Sensitive_Information__c sensitiveInformations = new Sensitive_Information__c(
                API_Token__c = 'TESTTOKEN',
                Name = 'SOMEFAKEID');
        insert sensitiveInformations;

        Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.headers.put('handshakeId', DeployAPI.encryptAPIKey(DeployAPI.getAuthToken()));
        req.params.put('settingsId', 'SOMEFAKEID');
        req.httpMethod = 'GET';
        //req.addHeader('Content-Type', 'application/json');
        RestContext.request = req;
        RestContext.response = res;
        List<CodeScanHandshakeService.CodeScanResponse> responses = CodeScanHandshakeService.handshakeAndReturnEncryptedToken();
        System.assertEquals(1, responses.size());
        if(!responses.isEmpty()) {
            System.assertEquals('0', responses[0].errorCode);
        }
        Test.stopTest();
    }

    static testMethod void testNoHandshake() {

        Sensitive_Information__c sensitiveInformations = new Sensitive_Information__c(
                API_Token__c = 'TESTTOKEN',
                Name = 'SOMEFAKEID');
        insert sensitiveInformations;

        Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.params.put('settingsId', 'SOMEFAKEID');
        req.httpMethod = 'GET';
        //req.addHeader('Content-Type', 'application/json');
        RestContext.request = req;
        RestContext.response = res;
        List<CodeScanHandshakeService.CodeScanResponse> responses = CodeScanHandshakeService.handshakeAndReturnEncryptedToken();
        System.assertEquals(1, responses.size());
        if(!responses.isEmpty()) {
            System.assertEquals('1', responses[0].errorCode);
            System.assertEquals(Label.Insufficient_Access_Rights, responses[0].message);
        }
        Test.stopTest();
    }

    static testMethod void testNoSettingsId() {

        Sensitive_Information__c sensitiveInformations = new Sensitive_Information__c(
                API_Token__c = 'TESTTOKEN',
                Name = 'SOMEFAKEID');
        insert sensitiveInformations;

        Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.headers.put('handshakeId', DeployAPI.encryptAPIKey(DeployAPI.getAuthToken()));
        req.httpMethod = 'GET';
        //req.addHeader('Content-Type', 'application/json');
        RestContext.request = req;
        RestContext.response = res;
        List<CodeScanHandshakeService.CodeScanResponse> responses = CodeScanHandshakeService.handshakeAndReturnEncryptedToken();
        System.assertEquals(1, responses.size());
        if(!responses.isEmpty()) {
            System.assertEquals('1', responses[0].errorCode);
            System.assertEquals(Label.UNABLE_TO_FIND_SCA_SETTING_RECORD, responses[0].message);
        }
        Test.stopTest();
    }
}