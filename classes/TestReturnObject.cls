/**
 * created by Umit Can Uckan on 22.10.2018
 * covers ReturnObject rest service get method
 */
@IsTest
public class TestReturnObject {
    @IsTest
    static void getMethodTest() {
        Sensitive_Information__c siItem = new Sensitive_Information__c(Name = 'testName', Username__c = 'testUsername', Password__c = 'testPassword');
        insert siItem;
        Test.startTest();
        RestResponse res = new RestResponse();
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/ReturnObject'; //Request URL
        req.httpMethod = 'GET';
        req.addHeader('Content-Type', 'application/json');
        req.headers.put('handshakeId', DeployAPI.encryptAPIKey(DeployAPI.getAuthToken()));
        req.params.put('object', 'Sensitive_Information__c');
        req.params.put('name', 'testName');
        req.params.put('fields', 'Username__c,Password__c');
        RestContext.request = req;
        RestContext.response = res;
        String strResponse = ReturnObject.doGet();
        String local = DeployAPI.decryptAPIKey(strResponse);
        Sensitive_Information__c siLocal = (Sensitive_Information__c) JSON.deserialize(local, Sensitive_Information__c.class);
        System.assertEquals(siLocal.Username__c, siItem.Username__c);
        System.assertEquals(siLocal.Id, siItem.Id);
        System.assertEquals(siLocal.Password__c, siItem.Password__c);
        Test.stopTest();
    }

    @IsTest
    static void testManageSensitiveInformation() {

        String namespace = Settings.ns;
        String body =
            '[{"attributes":{"type":"Sensitive_Information__c"},"' +
            namespace +
            'Version_Name__c":"version name","' +
            namespace +
            'Username__c":"myusername","' +
            namespace +
            'Password__c":"mypassword","' +
            namespace +
            'API_Token__c":"RecordToken","Name":"Record Name"}]';

        Test.startTest();
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/ReturnObject';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        req.headers.put('handshakeId', DeployAPI.encryptAPIKey(DeployAPI.getAuthToken()));
        req.requestBody = Blob.valueOf(body);
        RestContext.request = req;
        String strResponse = ReturnObject.manageSensitiveInformation();

        Sensitive_Information__c assertResult = [
            SELECT Name, Version_Name__c, Username__c, Password__c, API_Token__c
            FROM Sensitive_Information__c
            WHERE Name = 'Record Name'
        ];

        System.assert(strResponse.containsAny('Ok'), 'Message');
        System.assertEquals('version name', assertResult.Version_Name__c, 'Version Name is not correct');
        System.assertEquals('myusername', assertResult.Username__c, 'UserName is not correct');
        System.assertEquals('mypassword', DeployAPI.decryptAPIKey(assertResult.Password__c), 'Password is not correct');
        System.assertEquals('RecordToken', assertResult.API_Token__c, 'Token is not correct');

        Test.stopTest();
    }
}