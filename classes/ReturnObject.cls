/**
 * usage example "https://instance.salesforce.com/services/apexrest/ReturnObject?object={!object}&name={!name}&fields={!fields}&Id={Id}"
 * @author Ümit Can Uçkan
 * @version 1.0
 * @since 22/10/2018
 * @purpose for backend to be able to fetch encrypted Username & Password of Git Repository for the commit
 */
@RestResource(urlMapping='/ReturnObject/*')
global with sharing class ReturnObject {
    @HttpGet
    global static String doGet() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        if (!CodeScanHandshakeService.handshakeCheck(req.headers.get('handshakeId'))) {
            return DeployAPI.encryptAPIKey(Label.Insufficient_Access_Rights);
        }
        //System.debug('req===> '+req);
        String dymanicSoql = 'SELECT {0} FROM {1} WHERE {2} LIMIT 1';
        String ObjectName = req.params.get('object');
        String recordName = req.params.get('name');
        String fieldNames = req.params.get('fields');
        String rId = req.params.get('id');

        String dynamicQuery = String.format(
            dymanicSoql,
            new List<String>{
                fieldNames,
                ObjectName,
                (null != recordName ? 'Name LIKE \'' + String.escapeSingleQuotes(recordName) + '%\'' : 'Id=:rId')
            }
        );

        SObject result = Database.query(dynamicQuery);
        return DeployAPI.encryptAPIKey(JSON.serialize(result));
    }

    @HttpPost
    global static String manageSensitiveInformation() {
        RestRequest req = RestContext.request;
        if (!CodeScanHandshakeService.handshakeCheck(req.headers.get('handshakeId'))) {
            return returnMessage(Label.Insufficient_Access_Rights, '1');
        }
        try {
            List<Sensitive_Information__c> sensitiveInformationRecords = (List<Sensitive_Information__c>) JSON.deserialize(
                req.requestBody.toString(),
                List<Sensitive_Information__c>.class
            );
            for (Sensitive_Information__c sensitiveInfoItem : sensitiveInformationRecords) {
                if (String.isNotBlank(sensitiveInfoItem.Password__c)) {
                    sensitiveInfoItem.Password__c = DeployAPI.encryptAPIKey(sensitiveInfoItem.Password__c);
                }
            }
            upsert sensitiveInformationRecords;
            return returnMessage('Ok', '0');
        } catch (Exception ex) {
            return returnMessage(ex.getMessage(), '1');
        }
    }

    private static String returnMessage(String message, String code) {
        ReturnObjectResponse result = new ReturnObjectResponse();
        result.errorCode = code;
        result.message = message;
        return JSON.serialize(result);
    }

    private class ReturnObjectResponse {
        private String errorCode;
        private String message;
    }
}